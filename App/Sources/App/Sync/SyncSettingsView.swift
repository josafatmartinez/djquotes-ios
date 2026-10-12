import SwiftUI
import GRDB
import DJQuotesDatabase

struct SyncSettingsView: View {
    @Environment(SyncManager.self) private var sync
    @State private var registries: [SyncRegistry] = []
    @State private var showPairing = false
    @State private var isSyncing = false

    var body: some View {
        List {
            if !registries.isEmpty {
                Section("Linked devices") {
                    ForEach(registries) { registry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(registry.targetDeviceId)
                                    .font(.subheadline)
                                    .fontDesign(.monospaced)
                                Text("Since \(registry.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if registry.enabled {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                let registry = registries[index]
                                try? await DatabaseManager.shared.write { db in
                                    try registry.delete(db)
                                }
                            }
                            await load()
                        }
                    }
                }

                Section("Sync data") {
                    Button {
                        Task { await syncNow() }
                    } label: {
                        HStack {
                            Text("Sync now")
                            Spacer()
                            if isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSyncing || sync.connectedPeers.isEmpty)

                    Button {
                        sync.startAdvertising()
                        showPairing = true
                    } label: {
                        Label("Add device", systemImage: "plus")
                    }
                }
            }

            Section {
                Button {
                    sync.startBrowsing()
                    showPairing = true
                } label: {
                    Label("Connect to a nearby device", systemImage: "iphone.radiowaves.left.and.right")
                }
            } footer: {
                Text("Sync shares your catalog, customers, and packages with nearby devices. Quotes remain local to each device.")
            }
        }
        .navigationTitle("Sync")
        .sheet(isPresented: $showPairing) {
            SyncPairingView()
        }
        .task { await load() }
    }

    private func load() async {
        do {
            registries = try await DatabaseManager.shared.read { db in
                try SyncRegistry
                    .filter(Column("sourceDeviceId") == sync.deviceId || Column("targetDeviceId") == sync.deviceId)
                    .filter(Column("enabled") == true)
                    .fetchAll(db)
            }
        } catch {
            registries = []
        }
    }

    private func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }
        guard let snapshot = await SyncDataExporter.buildSnapshot() else { return }
        sync.sendSnapshot(snapshot)
    }
}