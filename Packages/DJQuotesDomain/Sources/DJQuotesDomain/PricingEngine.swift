import Foundation

public struct PricingEngine {
    public static func calculateSubtotal(items: [(unitPrice: Money, quantity: Int)]) -> Money {
        items.reduce(Money.zero) { subtotal, item in
            let lineTotal = item.unitPrice * item.quantity
            return subtotal + lineTotal
        }
    }

    public static func calculateTotal(
        subtotal: Money,
        extrasSubtotal: Money,
        travelCharge: Money,
        discountRate: Decimal
    ) -> Money {
        let discountable = subtotal + extrasSubtotal
        let discountAmount = discountable * discountRate
        let roundedDiscount = Money(decimal: discountAmount.amount.rounded(scale: 2))
        return discountable + travelCharge - roundedDiscount
    }

    public static func calculateBalance(total: Money, depositAmount: Money) -> Money {
        total - depositAmount
    }

    public static func calculateProfit(
        income: Money,
        costItems: [(unitCost: Money, quantity: Int)],
        installerCount: Int,
        installerRatePerEvent: Money
    ) -> Money {
        let totalCosts = costItems.reduce(Money.zero) { total, item in
            total + (item.unitCost * item.quantity)
        }
        let installerCost = installerRatePerEvent * installerCount
        return income - totalCosts - installerCost
    }

    public static func calculateDiscountAmount(
        base: Money,
        discountRate: Decimal
    ) -> Money {
        Money(decimal: (base.amount * discountRate).rounded(scale: 2))
    }
}