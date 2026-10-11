import Testing
import Foundation
@testable import DJQuotesDomain

@Test func moneyInitializationValidAmount() {
    let money = Money("1500.50")
    #expect(money != nil)
    #expect(money?.formattedPlain() == "1,500.50")
}

@Test func moneyInitializationInvalidString() {
    #expect(Money("abc") == nil)
}

@Test func moneyInitializationZero() {
    let money = Money("0.00")
    #expect(money?.isZero == true)
}

@Test func moneyAddition() {
    let a = Money("100.00")!
    let b = Money("50.25")!
    let result = a + b
    #expect(result.formattedPlain() == "150.25")
}

@Test func moneySubtraction() {
    let a = Money("200.00")!
    let b = Money("75.50")!
    let result = a - b
    #expect(result.formattedPlain() == "124.50")
}

@Test func moneyMultiplicationByInt() {
    let a = Money("150.00")!
    let result = a * 3
    #expect(result.formattedPlain() == "450.00")
}

@Test func moneyRoundingToTwoDecimals() {
    let money = Money(decimal: Decimal(string: "100.456")!)
    #expect(money.formattedPlain() == "100.46")
}

@Test func moneyFormattedMXN() {
    let money = Money("1500.00")!
    #expect(money.formatted() == "$1,500.00")
}

@Test func moneyFormattedPlainUS() {
    let money = Money("1500.00")!
    #expect(money.formattedPlain() == "1,500.00")
}

@Test func pricingSubtotalCalculation() {
    let items: [(unitPrice: Money, quantity: Int)] = [
        (Money("150.00")!, 2),
        (Money("300.00")!, 1),
    ]
    let subtotal = PricingEngine.calculateSubtotal(items: items)
    #expect(subtotal.formattedPlain() == "600.00")
}

@Test func pricingTotalCalculation() {
    let subtotal = Money("1000.00")!
    let extrasSubtotal = Money("200.00")!
    let travelCharge = Money("150.00")!
    let discountRate = Decimal(string: "0.10")!

    let total = PricingEngine.calculateTotal(
        subtotal: subtotal,
        extrasSubtotal: extrasSubtotal,
        travelCharge: travelCharge,
        discountRate: discountRate
    )
    let discountable = Money("1200.00")!
    let discountAmount = Money("120.00")!
    let expectedTotal = discountable + travelCharge - discountAmount
    #expect(total == expectedTotal)
}

@Test func pricingDiscountExcludesTravel() {
    let subtotal = Money("800.00")!
    let extrasSubtotal = Money("200.00")!
    let travelCharge = Money("500.00")!
    let discountRate = Decimal(string: "0.10")!

    let total = PricingEngine.calculateTotal(
        subtotal: subtotal,
        extrasSubtotal: extrasSubtotal,
        travelCharge: travelCharge,
        discountRate: discountRate
    )
    let expectedTotal = Money("1400.00")!
    #expect(total == expectedTotal)
}

@Test func pricingBalanceCalculation() {
    let total = Money("3000.00")!
    let deposit = Money("1000.00")!
    let balance = PricingEngine.calculateBalance(total: total, depositAmount: deposit)
    #expect(balance.formattedPlain() == "2,000.00")
}

@Test func pricingProfitCalculation() {
    let income = Money("5000.00")!
    let costItems: [(unitCost: Money, quantity: Int)] = [
        (Money("500.00")!, 2),
        (Money("300.00")!, 1),
    ]
    let installerRate = Money("700.00")!

    let profit = PricingEngine.calculateProfit(
        income: income,
        costItems: costItems,
        installerCount: 2,
        installerRatePerEvent: installerRate
    )
    let expectedProfit = Money("2300.00")!
    #expect(profit == expectedProfit)
}

@Test func quoteLifecycleDraftToSentValid() {
    #expect(QuoteLifecycle.canTransition(from: .draft, to: .sent))
}

@Test func quoteLifecycleSentToAcceptedValid() {
    #expect(QuoteLifecycle.canTransition(from: .sent, to: .accepted))
}

@Test func quoteLifecycleSentToDraftInvalid() {
    #expect(!QuoteLifecycle.canTransition(from: .sent, to: .draft))
}

@Test func quoteLifecycleAcceptedCannotTransition() {
    #expect(!QuoteLifecycle.canTransition(from: .accepted, to: .sent))
    #expect(!QuoteLifecycle.canTransition(from: .accepted, to: .draft))
}

@Test func quoteLifecycleTerminalStatuses() {
    #expect(QuoteLifecycle.isTerminal(.accepted))
    #expect(QuoteLifecycle.isTerminal(.rejected))
    #expect(QuoteLifecycle.isTerminal(.expired))
    #expect(QuoteLifecycle.isTerminal(.cancelled))
    #expect(!QuoteLifecycle.isTerminal(.draft))
    #expect(!QuoteLifecycle.isTerminal(.sent))
}

@Test func quoteFolioFormat() {
    let folio = QuoteFolioGenerator.generate(year: 2026, number: 42)
    #expect(folio == "COT-2026-00042")
}

@Test func quoteFolioNextNumber() {
    let existing = [1, 2, 3, 41]
    let next = QuoteFolioGenerator.nextQuoteNumber(existingNumbers: existing)
    #expect(next == 42)
}

@Test func quoteFolioNextNumberEmptyList() {
    let next = QuoteFolioGenerator.nextQuoteNumber(existingNumbers: [])
    #expect(next == 1)
}

// MARK: - ADR-020 Money precision fixture

@Test func moneyPrecisionFixture() {
    let fixtures: [(Decimal, String)] = [
        (Decimal(string: "100.00")!, "100.00"),
        (Decimal(string: "100.456")!, "100.46"),
        (Decimal(string: "99.999")!, "100.00"),
        (Decimal(string: "0.005")!, "0.01"),
        (Decimal(string: "0.004")!, "0.00"),
        (Decimal(string: "1500.00")!, "1,500.00"),
        (Decimal(string: "1234567.89")!, "1,234,567.89"),
    ]

    for (input, expected) in fixtures {
        let money = Money(decimal: input)
        #expect(money.formattedPlain() == expected)
    }
}