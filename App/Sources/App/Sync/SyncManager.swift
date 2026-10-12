import MultipeerConnectivity
import GRDB
import DJQuotesDatabase
import SwiftUI

@MainActor
@Observable
final class SyncManager: NSObject {
    static let serviceType = "djquotes-sync"

    private(set) var isAdvertising = false
    private(set) var isBrowsing = false
    private(set) var connectedPeers: [MCPeerID] = []
    private(set) var nearbyPeers: [SyncPeer] = []
    private(set) var sessionState: MCSessionState = .notConnected

    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    var deviceId: String {
        UserDefaults.standard.string(forKey: "sync_device_id") ?? ""
    }

    var deviceName: String {
        UIDevice.current.name
    }

    override init() {
        let storedId = UserDefaults.standard.string(forKey: "sync_device_id")
        let id = storedId ?? UUID().uuidString
        if storedId == nil {
            UserDefaults.standard.set(id, forKey: "sync_device_id")
        }
        myPeerId = MCPeerID(displayName: id)
        super.init()
    }

    func startAdvertising() {
        stopBrowsing()
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["name": deviceName], serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isAdvertising = true
    }

    func startBrowsing() {
        stopAdvertising()
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        nearbyPeers.removeAll()
    }

    func invite(peer: SyncPeer) {
        guard let browser = browser, let peerId = nearbyPeers.first(where: { $0.id == peer.id })?.peerId else { return }
        browser.invitePeer(peerId, to: session ?? MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none), withContext: nil, timeout: 30)
    }

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
    }

    func disconnect() {
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
        session = nil
        connectedPeers.removeAll()
        nearbyPeers.removeAll()
        sessionState = .notConnected
    }

    func sendSnapshot(_ snapshot: DataSnapshot) {
        guard let session = session, !connectedPeers.isEmpty else { return }
        let message = SyncMessage(type: .dataSnapshot, payload: try? JSONEncoder().encode(snapshot))
        guard let data = message.encode() else { return }
        do {
            try session.send(data, toPeers: connectedPeers, with: .reliable)
        } catch {
            print("[SyncManager] send error: \(error.localizedDescription)")
        }
    }

    private func handlePairingRequest(from peerId: MCPeerID, payload: Data?) {
        guard let data = payload, let request = try? JSONDecoder().decode(PairingRequest.self, from: data) else { return }
        let response = SyncMessage(type: .pairingAccepted, payload: nil)
        if let responseData = response.encode() {
            try? session?.send(responseData, toPeers: [peerId], with: .reliable)
        }
        Task {
            try? await DatabaseManager.shared.write { [self] db in
                    var registry = SyncRegistry(
                        id: UUID().uuidString,
                        sourceDeviceId: deviceId,
                    targetDeviceId: request.deviceId,
                    syncCatalog: true,
                    syncCustomers: true,
                    syncPackages: true,
                    enabled: true,
                    createdAt: Date()
                )
                try? registry.insert(db)
            }
        }
    }

    private func handleSnapshot(payload: Data?) {
        guard let data = payload, let snapshot = try? JSONDecoder().decode(DataSnapshot.self, from: data) else { return }
        Task {
            await SyncDataImporter.importSnapshot(snapshot)
        }
        let ack = SyncMessage(type: .dataSnapshotReceived, payload: nil)
        if let ackData = ack.encode() {
            try? session?.send(ackData, toPeers: connectedPeers, with: .reliable)
        }
    }
}

// MARK: - MCSessionDelegate

extension SyncManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            sessionState = state
            if state == .connected, !connectedPeers.contains(peerID) {
                connectedPeers.append(peerID)
                let request = PairingRequest(deviceId: deviceId, deviceName: deviceName)
                let message = SyncMessage(type: .pairingRequest, payload: try? JSONEncoder().encode(request))
                if let data = message.encode() {
                    try? session.send(data, toPeers: [peerID], with: .reliable)
                }
            } else if state == .notConnected {
                connectedPeers.removeAll { $0 == peerID }
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = SyncMessage.decode(from: data) else { return }
        Task { @MainActor in
            switch message.type {
            case .pairingRequest:
                handlePairingRequest(from: peerID, payload: message.payload)
            case .dataSnapshot:
                handleSnapshot(payload: message.payload)
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension SyncManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension SyncManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            let name = info?["name"] ?? peerID.displayName
            let peer = SyncPeer(id: peerID.displayName, name: name, peerId: peerID)
            if !nearbyPeers.contains(where: { $0.id == peer.id }) {
                nearbyPeers.append(peer)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            nearbyPeers.removeAll { $0.id == peerID.displayName }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            isBrowsing = false
        }
    }
}

// MARK: - SyncPeer model for UI

struct SyncPeer: Identifiable {
    let id: String
    let name: String
    let peerId: MCPeerID
}