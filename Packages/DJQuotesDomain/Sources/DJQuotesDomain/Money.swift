import Foundation

public struct Money: Equatable, Hashable, Sendable {
    public let amount: Decimal

    public init?(_ string: String) {
        guard let value = Decimal(string: string) else { return nil }
        guard value.isFinite else { return nil }
        amount = value.rounded(scale: 2)
    }

    public init(decimal: Decimal) {
        amount = decimal.rounded(scale: 2)
    }

    public var isZero: Bool { amount.isZero }
    public var isPositive: Bool { amount > 0 }

    public func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    public func formattedPlain() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    func formattedPlainMX() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "es_MX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(decimal: lhs.amount + rhs.amount)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(decimal: lhs.amount - rhs.amount)
    }

    public static func * (lhs: Money, rhs: Int) -> Money {
        Money(decimal: lhs.amount * Decimal(rhs))
    }

    public static func * (lhs: Money, rhs: Decimal) -> Money {
        Money(decimal: lhs.amount * rhs)
    }

    public static func > (lhs: Money, rhs: Money) -> Bool {
        lhs.amount > rhs.amount
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.amount < rhs.amount
    }

    public static func >= (lhs: Money, rhs: Money) -> Bool {
        lhs.amount >= rhs.amount
    }

    public static func <= (lhs: Money, rhs: Money) -> Bool {
        lhs.amount <= rhs.amount
    }

    public static let zero = Money(decimal: .zero)
}

extension Decimal {
    var isFinite: Bool {
        !isNaN && !isInfinite
    }

    func rounded(scale: Int) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }
}