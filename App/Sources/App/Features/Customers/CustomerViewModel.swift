import Foundation
import DJQuotesDatabase
import GRDB

@MainActor
@Observable
final class CustomerViewModel {
    var customers: [Customer] = []
    var searchText = ""
    var isLoading = false
    var error: String?

    var filteredCustomers: [Customer] {
        guard !searchText.isEmpty else { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.contains(searchText)
        }
    }

    func load() async {
        isLoading = true
        do {
            customers = try await DatabaseManager.shared.read { db in
                try Customer.order(Customer.Columns.name.asc).fetchAll(db)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func create(name: String, phone: String, email: String?, createdBy: String) async -> Bool {
        let customer = Customer(
            id: UUID().uuidString,
            name: name,
            phone: phone,
            email: email,
            createdBy: createdBy,
            createdAt: Date()
        )
        do {
            try await DatabaseManager.shared.write { db in try customer.insert(db) }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func update(_ customer: Customer, name: String, phone: String, email: String?) async -> Bool {
        var updated = customer
        updated.name = name
        updated.phone = phone
        updated.email = email
        do {
            try await DatabaseManager.shared.write { db in try updated.update(db) }
            await load()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}