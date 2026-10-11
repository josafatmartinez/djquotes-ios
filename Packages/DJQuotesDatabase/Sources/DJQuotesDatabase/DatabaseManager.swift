import Foundation
import GRDB

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?

    var database: DatabaseQueue {
        get throws {
            guard let queue = dbQueue else {
                throw DatabaseError.notInitialized
            }
            return queue
        }
    }

    private init() {}

    func initialize() throws {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbDirectory = appSupport.appendingPathComponent("DJQuotes", isDirectory: true)
        try fileManager.createDirectory(at: dbDirectory, withIntermediateDirectories: true)

        let dbPath = dbDirectory.appendingPathComponent("djquotes.sqlite").path
        let queue = try DatabaseQueue(path: dbPath)
        try Migrations.apply(to: queue)
        dbQueue = queue
    }
}

enum DatabaseError: Error {
    case notInitialized
}