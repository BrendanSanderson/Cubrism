import UIKit

@MainActor
enum DelveBootstrap {
    static let legacyKeys = ["Level", "Experience", "TotalExperience", "LevelCompleted", "Gear", "Inventory", "equipUpdated"]
    static let resetMarker = "DelveLegacyResetVersion"

    static func load(fileURL: URL, defaults: UserDefaults = .standard) throws -> DelveGameSession {
        let store = try DelveSaveStore(fileURL: fileURL) { try DelveProgression.freshAccount() }
        let session = try DelveGameSession(store: store)
        // Create/read and validate the new account before discarding old data.
        // Invalid or unsupported Delve saves never trigger a reset.
        if defaults.integer(forKey: resetMarker) < 1 {
            for key in legacyKeys { defaults.removeObject(forKey: key) }
            defaults.set(1, forKey: resetMarker)
        }
        return session
    }

    static func accountURL() throws -> URL {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        return directory.appendingPathComponent("Cubrism", isDirectory: true).appendingPathComponent("delve.json")
    }
}
