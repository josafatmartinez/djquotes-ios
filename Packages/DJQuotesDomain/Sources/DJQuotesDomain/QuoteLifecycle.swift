import Foundation

public enum QuoteLifecycle {
    nonisolated(unsafe) private static let transitions: [String: Set<String>] = [
        "DRAFT": ["SENT", "CANCELLED"],
        "SENT": ["ACCEPTED", "REJECTED", "EXPIRED", "CANCELLED"],
        "ACCEPTED": [],
        "REJECTED": [],
        "EXPIRED": [],
        "CANCELLED": [],
    ]

    public static func canTransition(from current: String, to target: String) -> Bool {
        guard let allowed = transitions[current] else { return false }
        return allowed.contains(target)
    }

    public static func isTerminal(_ status: String) -> Bool {
        status != "DRAFT" && status != "SENT"
    }

    public static func isEditable(_ status: String) -> Bool {
        status == "DRAFT"
    }

    public static func isImmutable(_ status: String) -> Bool {
        status != "DRAFT"
    }
}