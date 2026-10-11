import Foundation
import GRDB

public final class DatabaseManager: @unchecked Sendable {
    public static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue?

    private init() {}

    public func initialize() throws {
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

    public func read<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        guard let queue = dbQueue else { throw DatabaseError.notInitialized }
        return try await queue.read(block)
    }

    public func write<T>(_ block: @escaping (Database) throws -> T) async throws -> T {
        guard let queue = dbQueue else { throw DatabaseError.notInitialized }
        return try await queue.write(block)
    }
}

enum DatabaseError: Error {
    case notInitialized
}
