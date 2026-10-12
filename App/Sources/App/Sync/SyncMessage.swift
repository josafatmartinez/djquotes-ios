import Foundation

enum SyncMessageType: String, Codable {
    case pairingRequest
    case pairingAccepted
    case pairingRejected
    case dataSnapshot
    case dataSnapshotReceived
}

struct SyncMessage: Codable {
    let type: SyncMessageType
    let payload: Data?

    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func decode(from data: Data) -> SyncMessage? {
        try? JSONDecoder().decode(SyncMessage.self, from: data)
    }
}

struct PairingRequest: Codable {
    let deviceId: String
    let deviceName: String
}

struct DataSnapshot: Codable {
    let deviceId: String
    let timestamp: Date
    let customers: [CustomerSnapshot]
    let catalogItems: [CatalogItemSnapshot]
    let packages: [PackageSnapshot]

    struct CustomerSnapshot: Codable {
        let id: String
        let name: String
        let phone: String
        let email: String?
        let createdAt: Date
    }

    struct CatalogItemSnapshot: Codable {
        let id: String
        let name: String
        let description: String?
        let type: String
        let salePrice: String
        let internalCost: String?
        let archived: Bool
        let createdAt: Date
    }

    struct PackageSnapshot: Codable {
        let id: String
        let name: String
        let description: String?
        let pricingMode: String
        let commercialPrice: String?
        let manualPrice: String?
        let suggestedInstallerCount: Int
        let isActive: Bool
        let createdAt: Date
    }
}