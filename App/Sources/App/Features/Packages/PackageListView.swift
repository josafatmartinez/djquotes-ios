import SwiftUI
import GRDB
import DJQuotesDatabase

struct PackageListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = PackageViewModel()
    @State private var showForm = false
    @State private var editingPackage: Package?

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
            } else if vm.packages.isEmpty {
                ContentUnavailableView(
                    String(localized: "packages.empty"),
                    systemImage: "shippingbox",
                    description: Text("packages.emptyDescription")
                )
            } else {
                List {
                    ForEach(vm.packages) { pkg in
                        Button { editingPackage = pkg } label: {
                            PackageRowView(package: pkg, itemCount: vm.packageItems[pkg.id]?.count ?? 0)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(String(localized: "packages.duplicate")) { Task { await vm.duplicate(pkg) } }.tint(.blue)
                            Button(pkg.isActive
                                ? String(localized: "packages.deactivate")
                                : String(localized: "packages.activate")
                            ) { Task { await vm.toggleActive(pkg) } }.tint(pkg.isActive ? .orange : .green)
                        }
                    }
                }
            }
        }
        .navigationTitle("tab.packages")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editingPackage = nil; showForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showForm) {
            PackageFormView(vm: vm, existingPackage: nil, createdBy: auth.currentProfile?.id ?? "")
        }
        .sheet(item: $editingPackage) { pkg in
            PackageFormView(vm: vm, existingPackage: pkg, createdBy: auth.currentProfile?.id ?? "")
        }
        .task { await vm.load() }
    }
}

struct PackageRowView: View {
    let package: Package
    let itemCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.name).font(.headline)
                Text(package.pricingMode.displayName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(itemCount) items").font(.subheadline).foregroundStyle(.secondary)
                if !package.isActive {
                    Text("Inactive").font(.caption2).foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension PackagePricingMode {
    var displayName: String {
        switch self {
        case .automatic: String(localized: "packages.mode.automatic")
        case .commercial: String(localized: "packages.mode.commercial")
        case .manual: String(localized: "packages.mode.manual")
        }
    }
}