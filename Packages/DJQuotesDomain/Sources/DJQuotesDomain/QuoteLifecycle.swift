import Foundation

enum QuoteLifecycle {
    private static let transitions: [QuoteStatus: Set<QuoteStatus>] = [
        .draft: [.sent, .cancelled],
        .sent: [.accepted, .rejected, .expired, .cancelled],
        .accepted: [],
        .rejected: [],
        .expired: [],
        .cancelled: [],
    ]

    static func canTransition(from current: QuoteStatus, to target: QuoteStatus) -> Bool {
        guard let allowed = transitions[current] else { return false }
        return allowed.contains(target)
    }

    static func isTerminal(_ status: QuoteStatus) -> Bool {
        status != .draft && status != .sent
    }

    static func isEditable(_ status: QuoteStatus) -> Bool {
        status == .draft
    }

    static func isImmutable(_ status: QuoteStatus) -> Bool {
        status != .draft
    }
}

enum QuoteStatus: String, Codable, CaseIterable {
    case draft = "DRAFT"
    case sent = "SENT"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"
    case cancelled = "CANCELLED"
}