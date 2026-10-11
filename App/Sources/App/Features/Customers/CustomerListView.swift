import SwiftUI
import GRDB
import DJQuotesDatabase

struct CustomerListFullView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = CustomerViewModel()
    @State private var showForm = false
    @State private var editingCustomer: Customer?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                } else if vm.filteredCustomers.isEmpty {
                    ContentUnavailableView(
                        String(localized: "customers.empty"),
                        systemImage: "person.2.slash",
                        description: Text("customers.emptyDescription")
                    )
                } else {
                    List {
                        ForEach(vm.filteredCustomers) { customer in
                            Button { editingCustomer = customer } label: {
                                CustomerRowView(customer: customer)
                            }
                        }
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: String(localized: "common.search"))
            .navigationTitle("tab.customers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { editingCustomer = nil; showForm = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showForm) {
                CustomerFormView(vm: vm, existingCustomer: nil, createdBy: auth.currentProfile?.id ?? "")
            }
            .sheet(item: $editingCustomer) { customer in
                CustomerFormView(vm: vm, existingCustomer: customer, createdBy: auth.currentProfile?.id ?? "")
            }
        }
        .task { await vm.load() }
    }
}

struct CustomerRowView: View {
    let customer: Customer
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.name).font(.headline)
                Text(customer.phone).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if let email = customer.email {
                Text(email).font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CustomerFormView: View {
    @Environment(\.dismiss) private var dismiss
    let vm: CustomerViewModel
    let existingCustomer: Customer?
    let createdBy: String

    @State private var name: String
    @State private var phone: String
    @State private var email: String

    init(vm: CustomerViewModel, existingCustomer: Customer?, createdBy: String) {
        self.vm = vm
        self.existingCustomer = existingCustomer
        self.createdBy = createdBy
        _name = State(initialValue: existingCustomer?.name ?? "")
        _phone = State(initialValue: existingCustomer?.phone ?? "")
        _email = State(initialValue: existingCustomer?.email ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "customers.info")) {
                    TextField(String(localized: "customers.name"), text: $name)
                        .textContentType(.name)
                    TextField(String(localized: "customers.phone"), text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField(String(localized: "customers.email"), text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section {
                    Button(existingCustomer == nil
                        ? String(localized: "customers.create")
                        : String(localized: "common.save")
                    ) { Task { await submit() } }
                    .disabled(!isValid)
                }
            }
            .navigationTitle(existingCustomer == nil
                ? String(localized: "customers.new")
                : String(localized: "customers.edit"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        if let customer = existingCustomer {
            guard await vm.update(customer, name: name, phone: phone, email: email.nilIfEmpty) else { return }
        } else {
            guard await vm.create(name: name, phone: phone, email: email.nilIfEmpty, createdBy: createdBy) else { return }
        }
        dismiss()
    }
}