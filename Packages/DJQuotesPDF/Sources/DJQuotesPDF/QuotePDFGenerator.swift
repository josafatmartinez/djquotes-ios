import CoreGraphics
import UIKit
import DJQuotesDatabase
import DJQuotesDomain

public enum QuotePDFGenerator {

    private static let pageWidth: CGFloat = 595.28
    private static let pageHeight: CGFloat = 841.89
    private static let margin: CGFloat = 40
    private static let contentWidth: CGFloat = pageWidth - margin * 2

    public static func generate(
        folio: String,
        customerName: String,
        customerPhone: String,
        customerEmail: String?,
        eventName: String?,
        eventDate: String?,
        items: [(label: String, quantity: String, unitPrice: String)],
        extras: [(label: String, quantity: String, unitPrice: String)],
        subtotal: String,
        extrasSubtotal: String,
        discount: String,
        travelCharge: String,
        total: String,
        deposit: String,
        balance: String,
        notes: String?,
        generatedAt: Date = Date()
    ) -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return Data()
        }

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        context.beginPage(mediaBox: &mediaBox)

        let parastyle = NSMutableParagraphStyle()
        parastyle.alignment = .left
        parastyle.lineBreakMode = .byWordWrapping

        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center

        let rightStyle = NSMutableParagraphStyle()
        rightStyle.alignment = .right

        var y: CGFloat = pageHeight - margin

        drawTitle(
            context: context,
            text: "app.name".localized(),
            y: &y,
            centerStyle: centerStyle
        )

        drawSubtitle(
            context: context,
            left: String(localized: "quote.folio", table: nil) + ": " + folio,
            right: DateFormatter.localizedString(from: generatedAt, dateStyle: .long, timeStyle: .short),
            y: &y,
            rightStyle: rightStyle
        )

        drawLine(context: context, y: &y)

        drawSectionTitle(context: context, text: String(localized: "quote.customer", table: nil), y: &y)
        drawText(context: context, text: customerName, y: &y)
        drawText(context: context, text: customerPhone, y: &y)
        if let email = customerEmail, !email.isEmpty {
            drawText(context: context, text: email, y: &y)
        }
        y -= 8

        if let event = eventName, !event.isEmpty {
            drawSectionTitle(context: context, text: String(localized: "quote.event", table: nil), y: &y)
            drawText(context: context, text: event, y: &y)
            if let date = eventDate {
                drawText(context: context, text: date, y: &y)
            }
            y -= 8
        }

        drawLine(context: context, y: &y)

        if !items.isEmpty {
            drawSectionTitle(context: context, text: String(localized: "quote.items", table: nil), y: &y)
            drawTableHeader(context: context, y: &y, rightStyle: rightStyle)
            for item in items {
                drawTableRow(context: context, label: item.label, quantity: item.quantity, unitPrice: item.unitPrice, y: &y, rightStyle: rightStyle)
            }
            y -= 4
        }

        if !extras.isEmpty {
            drawSectionTitle(context: context, text: String(localized: "quote.extras.items", table: nil), y: &y)
            drawTableHeader(context: context, y: &y, rightStyle: rightStyle)
            for item in extras {
                drawTableRow(context: context, label: item.label, quantity: item.quantity, unitPrice: item.unitPrice, y: &y, rightStyle: rightStyle)
            }
            y -= 4
        }

        drawLine(context: context, y: &y)

        drawSectionTitle(context: context, text: String(localized: "quote.financial", table: nil), y: &y)
        drawLabeledRow(context: context, label: "quote.subtotal", value: Money(subtotal)?.formatted() ?? "$0.00", y: &y, rightStyle: rightStyle)
        if !extras.isEmpty {
            drawLabeledRow(context: context, label: "quote.extrasSubtotal", value: Money(extrasSubtotal)?.formatted() ?? "$0.00", y: &y, rightStyle: rightStyle)
        }
        drawLabeledRow(context: context, label: "quote.travelCharge", value: Money(travelCharge)?.formatted() ?? "$0.00", y: &y, rightStyle: rightStyle)
        drawLabeledRow(context: context, label: "quote.discount", value: "\(discount)%", y: &y, rightStyle: rightStyle)

        y -= 4
        drawBoldLabeledRow(context: context, label: "quote.total", value: Money(total)?.formatted() ?? "$0.00", y: &y, rightStyle: rightStyle)

        let depositMoney = Money(deposit) ?? .zero
        if depositMoney.amount > 0 {
            y -= 4
            drawLabeledRow(context: context, label: "quote.deposit", value: depositMoney.formatted(), y: &y, rightStyle: rightStyle)
            drawBoldLabeledRow(context: context, label: "quote.balance", value: Money(balance)?.formatted() ?? "$0.00", y: &y, rightStyle: rightStyle)
        }

        if let notes = notes, !notes.isEmpty {
            y -= 8
            drawLine(context: context, y: &y)
            drawSectionTitle(context: context, text: String(localized: "quote.notes", table: nil), y: &y)
            drawText(context: context, text: notes, y: &y)
        }

        y = margin + 20
        drawLine(context: context, y: &y)

        let footerText = "app.name".localized() + " — " + generatedAt.formatted(date: .abbreviated, time: .shortened)
        drawFooter(context: context, text: footerText, y: &y, centerStyle: centerStyle)

        context.endPage()
        context.closePDF()

        return data as Data
    }

    // MARK: - Drawing helpers

    private static func drawTitle(context: CGContext, text: String, y: inout CGFloat, centerStyle: NSParagraphStyle) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .paragraphStyle: centerStyle,
        ]
        let rect = CGRect(x: margin, y: y - 28, width: contentWidth, height: 28)
        text.draw(in: rect, withAttributes: attrs)
        y -= 40
    }

    private static func drawSubtitle(context: CGContext, left: String, right: String, y: inout CGFloat, rightStyle: NSParagraphStyle) {
        let leftAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray,
        ]
        left.draw(at: CGPoint(x: margin, y: y - 12), withAttributes: leftAttrs)

        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: rightStyle,
        ]
        right.draw(in: CGRect(x: margin + contentWidth - 200, y: y - 12, width: 200, height: 14), withAttributes: rightAttrs)
        y -= 20
    }

    private static func drawLine(context: CGContext, y: inout CGFloat) {
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        context.strokePath()
        y -= 12
    }

    private static func drawSectionTitle(context: CGContext, text: String, y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
        ]
        text.draw(at: CGPoint(x: margin, y: y - 14), withAttributes: attrs)
        y -= 20
    }

    private static func drawText(context: CGContext, text: String, y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
        ]
        text.draw(at: CGPoint(x: margin, y: y - 13), withAttributes: attrs)
        y -= 16
    }

    private static func drawTableHeader(context: CGContext, y: inout CGFloat, rightStyle: NSParagraphStyle) {
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
        ]
        let labelHeader = String(localized: "catalog.name", table: nil)
        labelHeader.draw(at: CGPoint(x: margin, y: y - 11), withAttributes: headerAttrs)

        let qtyHeader = String(localized: "Qty", table: nil)
        qtyHeader.draw(in: CGRect(x: margin + contentWidth - 160, y: y - 11, width: 50, height: 12), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: rightStyle,
        ])

        let priceHeader = String(localized: "catalog.salePrice", table: nil)
        priceHeader.draw(in: CGRect(x: margin + contentWidth - 100, y: y - 11, width: 100, height: 12), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: rightStyle,
        ])
        y -= 16
    }

    private static func drawTableRow(context: CGContext, label: String, quantity: String, unitPrice: String, y: inout CGFloat, rightStyle: NSParagraphStyle) {
        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
        ]
        let qty = Int(quantity) ?? 1
        let unit = Money(unitPrice) ?? .zero
        let rowTotal = unit * qty

        label.draw(at: CGPoint(x: margin, y: y - 12), withAttributes: rowAttrs)

        "\(qty)".draw(in: CGRect(x: margin + contentWidth - 160, y: y - 12, width: 50, height: 12), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10),
            .paragraphStyle: rightStyle,
        ])

        rowTotal.formatted().draw(in: CGRect(x: margin + contentWidth - 100, y: y - 12, width: 100, height: 12), withAttributes: [
            .font: UIFont.systemFont(ofSize: 10),
            .paragraphStyle: rightStyle,
        ])
        y -= 16
    }

    private static func drawLabeledRow(context: CGContext, label: String, value: String, y: inout CGFloat, rightStyle: NSParagraphStyle) {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
        ]
        label.localized().draw(at: CGPoint(x: margin + 20, y: y - 12), withAttributes: labelAttrs)

        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .paragraphStyle: rightStyle,
        ]
        value.draw(in: CGRect(x: margin + contentWidth - 100, y: y - 12, width: 100, height: 12), withAttributes: valueAttrs)
        y -= 16
    }

    private static func drawBoldLabeledRow(context: CGContext, label: String, value: String, y: inout CGFloat, rightStyle: NSParagraphStyle) {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
        ]
        label.localized().draw(at: CGPoint(x: margin + 20, y: y - 13), withAttributes: labelAttrs)

        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .paragraphStyle: rightStyle,
        ]
        value.draw(in: CGRect(x: margin + contentWidth - 100, y: y - 13, width: 100, height: 14), withAttributes: valueAttrs)
        y -= 18
    }

    private static func drawFooter(context: CGContext, text: String, y: inout CGFloat, centerStyle: NSParagraphStyle) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.lightGray,
            .paragraphStyle: centerStyle,
        ]
        let rect = CGRect(x: margin, y: y - 10, width: contentWidth, height: 10)
        text.draw(in: rect, withAttributes: attrs)
    }
}

private extension String {
    static let localizedTable: String? = nil

    func localized() -> String {
        NSLocalizedString(self, tableName: Self.localizedTable, comment: "")
    }
}