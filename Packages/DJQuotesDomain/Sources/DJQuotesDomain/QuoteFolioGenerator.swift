import Foundation

enum QuoteFolioGenerator {
    static func generate(year: Int, number: Int) -> String {
        let padded = String(format: "%05d", number)
        return "COT-\(year)-\(padded)"
    }

    static func nextQuoteNumber(existingNumbers: [Int]) -> Int {
        (existingNumbers.max() ?? 0) + 1
    }
}