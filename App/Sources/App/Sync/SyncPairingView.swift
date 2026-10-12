import SwiftUI
import MultipeerConnectivity

struct SyncPairingView: View {
    @Environment(SyncManager.self) private var sync
    @State private var mode: PairingMode = .join
    @State private var paired = false

    enum PairingMode: String, CaseIterable {
        case join
        case share
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Mode", selection: $mode) {
                    Text("Join a device")
                        .tag(PairingMode.join)
                    Text("Share with others")
                        .tag(PairingMode.share)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if mode == .share {
                    sharingView
                } else {
                    joiningView
                }
            }
            .navigationTitle("Sync")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { sync.disconnect() }
        }
    }

    private var sharingView: some View {
        VStack(spacing: 20) {
            if sync.isAdvertising {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Waiting for connection...")
                        .font(.headline)
                    Text("Your device is visible to nearby devices.\nThey can connect using the Join tab.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 40)

                Button(role: .destructive) {
                    sync.stopAdvertising()
                } label: {
                    Text("Stop sharing")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.bordered)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    Text("Share your data")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Make your catalogs, customers, and packages available to nearby devices.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        sync.startAdvertising()
                    } label: {
                        Label("Start sharing", systemImage: "antenna.radiowaves.left.and.right")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }

            if !sync.connectedPeers.isEmpty {
                List {
                    Section("Connected") {
                        ForEach(sync.connectedPeers.map { $0.displayName }, id: \.self) { name in
                            Label(name, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }

    private var joiningView: some View {
        VStack(spacing: 20) {
            if sync.connectedPeers.isEmpty {
                if sync.isBrowsing {
                    if sync.nearbyPeers.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Searching for nearby devices...")
                                .font(.headline)
                            Text("Make sure the other device is sharing and nearby.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.vertical, 40)
                    } else {
                        List(sync.nearbyPeers) { peer in
                            Button {
                                sync.invite(peer: peer)
                            } label: {
                                HStack {
                                    Image(systemName: "iphone")
                                        .font(.title2)
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading) {
                                        Text(peer.name)
                                            .font(.headline)
                                        Text("Tap to connect")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundStyle(.tint)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 56))
                            .foregroundStyle(.tint)

                        Text("Join a device")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Connect to a nearby device to receive their catalogs, customers, and packages.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button {
                            sync.startBrowsing()
                        } label: {
                            Label("Search for devices", systemImage: "iphone.radiowaves.left.and.right")
                                .frame(maxWidth: 280)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }

                if sync.isBrowsing || sync.isAdvertising {
                    Button(role: .destructive) {
                        sync.disconnect()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)

                    Text("Connected!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Data sync is ready. You can now sync your catalogs, customers, and packages.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        sync.disconnect()
                    } label: {
                        Text("Disconnect")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}