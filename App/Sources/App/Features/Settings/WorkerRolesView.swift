import SwiftUI
import GRDB
import DJQuotesDatabase

struct WorkerRolesView: View {
    @State private var vm = WorkerRoleViewModel()
    @State private var showForm = false
    @State private var editingRole: WorkerRole?

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(vm.roles) { role in
                        Button { editingRole = role } label: {
                            HStack {
                                Text(role.name).font(.headline)
                                Spacer()
                                Text(role.defaultCost.formattedAsMoney()).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("settings.workerRoles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editingRole = nil; showForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showForm) {
            WorkerRoleFormView(vm: vm, existingRole: nil)
        }
        .sheet(item: $editingRole) { role in
            WorkerRoleFormView(vm: vm, existingRole: role)
        }
        .task { await vm.load() }
    }
}

struct WorkerRoleFormView: View {
    @Environment(\.dismiss) private var dismiss
    let vm: WorkerRoleViewModel
    let existingRole: WorkerRole?
    @State private var name: String
    @State private var cost: String

    init(vm: WorkerRoleViewModel, existingRole: WorkerRole?) {
        self.vm = vm
        self.existingRole = existingRole
        _name = State(initialValue: existingRole?.name ?? "")
        _cost = State(initialValue: existingRole?.defaultCost ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "settings.roleName"), text: $name)
                    TextField(String(localized: "settings.roleCost"), text: $cost).keyboardType(.decimalPad)
                }
                Section {
                    Button(existingRole == nil
                        ? String(localized: "settings.createRole")
                        : String(localized: "common.save")
                    ) { Task { await submit() } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || cost.isEmpty)
                }
            }
            .navigationTitle(existingRole == nil
                ? String(localized: "settings.newRole")
                : String(localized: "settings.editRole"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func submit() async {
        guard await vm.save(existingId: existingRole?.id, name: name, defaultCost: cost) else { return }
        dismiss()
    }
}