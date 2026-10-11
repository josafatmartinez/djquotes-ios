import Foundation
import DJQuotesDatabase
import GRDB

@MainActor
@Observable
final class WorkerRoleViewModel {
    var roles: [WorkerRole] = []
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        do {
            roles = try await DatabaseManager.shared.read { db in
                try WorkerRole.order(Column("name").asc).fetchAll(db)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func save(existingId: String?, name: String, defaultCost: String) async -> Bool {
        let id = existingId ?? UUID().uuidString
        do {
            try await DatabaseManager.shared.write { db in
                if let existingId = existingId {
                    var role = try WorkerRole.fetchOne(db, key: existingId)!
                    role.name = name
                    role.defaultCost = defaultCost
                    try role.update(db)
                } else {
                    let role = WorkerRole(
                        id: id,
                        name: name,
                        defaultCost: defaultCost,
                        costType: .perEvent,
                        isActive: true
                    )
                    try role.insert(db)
                }
            }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}