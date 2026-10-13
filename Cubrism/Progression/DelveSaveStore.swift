import Foundation

enum DelveSaveError: Error, Equatable {
    case unrecognizedFormat
    case unsupportedVersion(Int)
    case invalidLocation
}

private struct DelveSaveHeader: Decodable {
    let format: String
    let version: Int
}

private struct DelveSaveDocument: Codable {
    let format: String
    let version: Int
    let progression: DelveProgression
}

// The app owns one store for its account. Main-actor isolation serializes game
// events, checkpoint actions and lifecycle saves through the same owner.
@MainActor
final class DelveSaveStore {
    private static let format = "cubrism.delve"
    // Required stored encounters change the foundation-only v1 payload. Reject
    // that schema explicitly; do not generate replacement encounters on load.
    private static let version = 2
    private let fileURL: URL
    private(set) var progression: DelveProgression

    // A fresh account is created only when the file is absent. Corruption,
    // unsupported versions and I/O failures propagate without resetting a run.
    // This separate file does not read or reset the legacy UserDefaults save.
    init(fileURL: URL, makeNewAccount: () throws -> DelveProgression) throws {
        guard fileURL.isFileURL, !fileURL.hasDirectoryPath else { throw DelveSaveError.invalidLocation }
        self.fileURL = fileURL
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
            guard header.format == Self.format else { throw DelveSaveError.unrecognizedFormat }
            guard header.version == Self.version else { throw DelveSaveError.unsupportedVersion(header.version) }
            progression = try decoder.decode(DelveSaveDocument.self, from: data).progression
            try progression.validateSnapshot()
        } else {
            progression = try makeNewAccount()
            try Self.write(progression, to: fileURL)
        }
    }

    // Apply related events in one transaction (for example boss XP + clear).
    // Publish the new state and result only after atomic file replacement has
    // succeeded. A rejected event or failed write leaves in-memory state alone.
    // Callers must keep scene/UI side effects outside this closure and pause on
    // write failure. The closure is synchronous and must not reenter the store.
    @discardableResult
    func transaction<Result>(_ change: (inout DelveProgression) throws -> Result) throws -> Result {
        var next = progression
        let result = try change(&next)
        if next != progression {
            try Self.write(next, to: fileURL)
            progression = next
        }
        return result
    }

    private static func write(_ progression: DelveProgression, to fileURL: URL) throws {
        try progression.validateSnapshot()
        let document = DelveSaveDocument(format: format, version: version, progression: progression)
        let data = try JSONEncoder().encode(document)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        // Foundation writes a sibling temporary file and replaces the destination.
        // No separate account/run files can be left at mismatched checkpoints.
        try data.write(to: fileURL, options: .atomic)
    }
}
