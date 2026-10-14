import Foundation

enum DelveSaveError: Error, Equatable {
    case unrecognizedFormat
    case unsupportedVersion(Int)
    case invalidLocation
    case pendingTransaction
    case staleTransaction
}

private struct DelveSaveHeader: Decodable {
    let format: String
    let version: Int
}

private struct DelveSaveDocument: Codable {
    static let identifier = "cubrism.delve"
    // v2 stored encounters; v3 stored balance; v4 adds combat simulation data.
    static let currentVersion = 4
    let format: String
    let version: Int
    let progression: DelveProgression
}

struct DelvePreparedSave<Result> {
    fileprivate let id = UUID()
    fileprivate let owner: UUID
    fileprivate let revision: UInt64
    fileprivate let next: DelveProgression
    fileprivate let result: Result
}

// All disk writes, including lifecycle snapshots and checkpoint commits, share
// one serial queue. An older snapshot can never replace a newer checkpoint.
private final class DelveSaveWriter {
    private let queue = DispatchQueue(label: "cubrism.delve.save", qos: .utility)
    private let fileURL: URL
    private var writtenRevision: UInt64?

    init(fileURL: URL) { self.fileURL = fileURL }

    func writeBlocking(_ progression: DelveProgression, revision: UInt64) throws {
        try queue.sync { try write(progression, revision: revision) }
    }

    func writeAsync(_ progression: DelveProgression, revision: UInt64) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.write(progression, revision: revision)
                    continuation.resume()
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func write(_ progression: DelveProgression, revision: UInt64) throws {
        if let written = writtenRevision, revision <= written { return }
        try progression.validateSnapshot()
        let document = DelveSaveDocument(format: DelveSaveDocument.identifier,
                                         version: DelveSaveDocument.currentVersion, progression: progression)
        let data = try JSONEncoder().encode(document)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        writtenRevision = revision
    }
}

// The app owns one store for its account. Main-actor isolation serializes game
// events, checkpoint actions and lifecycle saves through the same owner.
@MainActor
final class DelveSaveStore {
    private let owner = UUID()
    private let writer: DelveSaveWriter
    private var revision: UInt64 = 0
    private var durableRevision: UInt64 = 0
    private var pending: UUID?
    private var lastCommitted: UUID?
    private(set) var progression: DelveProgression
    var hasPendingCommit: Bool { pending != nil }
    var hasUnsavedCombat: Bool { revision > durableRevision }

    // A fresh account is created only when the file is absent. Corruption,
    // unsupported versions and I/O failures propagate without resetting a run.
    // This separate file does not read or reset the legacy UserDefaults save.
    init(fileURL: URL, makeNewAccount: () throws -> DelveProgression) throws {
        guard fileURL.isFileURL, !fileURL.hasDirectoryPath else { throw DelveSaveError.invalidLocation }
        writer = DelveSaveWriter(fileURL: fileURL)
        let data: Data?
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
            data = nil
        }
        if let data = data {
            let decoder = JSONDecoder()
            // Check the header first: a future payload may not have this schema.
            let header = try decoder.decode(DelveSaveHeader.self, from: data)
            guard header.format == DelveSaveDocument.identifier else { throw DelveSaveError.unrecognizedFormat }
            guard header.version == DelveSaveDocument.currentVersion else { throw DelveSaveError.unsupportedVersion(header.version) }
            progression = try decoder.decode(DelveSaveDocument.self, from: data).progression
            try progression.validateSnapshot()
        } else {
            progression = try makeNewAccount()
            try writer.writeBlocking(progression, revision: revision)
        }
    }

    // Apply related events in one transaction (for example boss XP + clear).
    // Publish the new state and result only after atomic file replacement has
    // succeeded. A rejected event or failed write leaves in-memory state alone.
    // Callers must keep scene/UI side effects outside this closure and pause on
    // write failure. The closure is synchronous and must not reenter the store.
    @discardableResult
    func transaction<Result>(_ change: (inout DelveProgression) throws -> Result) throws -> Result {
        let prepared = try prepare(change)
        do {
            if prepared.revision > durableRevision {
                try writer.writeBlocking(prepared.next, revision: prepared.revision)
            }
        } catch {
            pending = nil
            throw error
        }
        return publish(prepared)
    }

    // Update the live value without frame-by-frame disk I/O. Critical events
    // (entry, death, clear, equipment, continuation, extraction) use prepare.
    @discardableResult
    func stageCombat<Result>(_ change: (inout DelveProgression) throws -> Result) throws -> Result {
        guard pending == nil else { throw DelveSaveError.pendingTransaction }
        var next = progression
        let result = try change(&next)
        guard let before = progression.activeRun, let after = next.activeRun,
              before.floor.phase == .combat, after.floor.phase == .combat,
              before.id == after.id, before.depth == after.depth,
              before.floor.id == after.floor.id, before.floor.plan == after.floor.plan,
              progression.rating == next.rating, progression.bankedItems == next.bankedItems,
              progression.equipped == next.equipped else { throw DelveError.invalidTransition }
        try next.validateSnapshot()
        if next != progression {
            revision += 1
            progression = next
        }
        return result
    }

    func saveCombat() async throws {
        guard pending == nil else { throw DelveSaveError.pendingTransaction }
        let value = progression
        let savingRevision = revision
        guard savingRevision > durableRevision else { return }
        try await writer.writeAsync(value, revision: savingRevision)
        durableRevision = max(durableRevision, savingRevision)
    }

    // Prepare random rewards/floor generation once, then retain this token
    // while paused. A failed commit keeps the token pending for exact retry.
    func prepare<Result>(_ change: (inout DelveProgression) throws -> Result) throws -> DelvePreparedSave<Result> {
        guard pending == nil else { throw DelveSaveError.pendingTransaction }
        var next = progression
        let result = try change(&next)
        try next.validateSnapshot()
        let prepared = DelvePreparedSave(owner: owner, revision: revision + (next == progression ? 0 : 1),
                                          next: next, result: result)
        pending = prepared.id
        return prepared
    }

    @discardableResult
    func commit<Result>(_ prepared: DelvePreparedSave<Result>) async throws -> Result {
        guard prepared.owner == owner else { throw DelveSaveError.staleTransaction }
        if lastCommitted == prepared.id { return prepared.result }
        guard pending == prepared.id else { throw DelveSaveError.staleTransaction }
        if prepared.revision > durableRevision {
            try await writer.writeAsync(prepared.next, revision: prepared.revision)
        }
        // A duplicate callback may await the same token. Publish only once.
        if lastCommitted == prepared.id { return prepared.result }
        guard pending == prepared.id else { throw DelveSaveError.staleTransaction }
        return publish(prepared)
    }

    private func publish<Result>(_ prepared: DelvePreparedSave<Result>) -> Result {
        progression = prepared.next
        revision = prepared.revision
        durableRevision = max(durableRevision, prepared.revision)
        pending = nil
        lastCommitted = prepared.id
        return prepared.result
    }
}
