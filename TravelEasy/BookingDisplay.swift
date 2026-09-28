import Foundation
import SwiftUI

extension BookingType {
    var displayName: String {
        switch self {
        case .flight: "Flight"
        case .hotel: "Hotel"
        case .activity: "Activity"
        case .transport: "Transport"
        }
    }

    var systemImage: String {
        switch self {
        case .flight: "airplane"
        case .hotel: "bed.double"
        case .activity: "figure.walk"
        case .transport: "car"
        }
    }
}

extension ConfirmationStatus {
    var displayName: String {
        switch self {
        case .planned: "Planned"
        case .booked: "Booked"
        }
    }
}

extension PaymentStatus {
    var displayName: String {
        switch self {
        case .unset: "Unset"
        case .paid: "Paid"
        case .payLater: "Pay later"
        }
    }
}

extension PaidBy {
    func displayName(personA: String, personB: String) -> String {
        switch self {
        case .personA: personA
        case .personB: personB
        case .splitAlready: "Already split"
        }
    }
}

enum BookingDateFormatting {
    private static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func span(start: Date?, end: Date?) -> String? {
        switch (start, end) {
        case (nil, nil):
            return nil
        case (let start?, nil):
            return dateTime.string(from: start)
        case (nil, let end?):
            return "Until \(dateTime.string(from: end))"
        case (let start?, let end?):
            if Calendar.current.isDate(start, inSameDayAs: end) {
                return "\(dateOnly.string(from: start)), \(timeRange(start: start, end: end))"
            }
            return "\(dateTime.string(from: start)) – \(dateTime.string(from: end))"
        }
    }

    private static func timeRange(start: Date, end: Date) -> String {
        let t = DateFormatter()
        t.dateStyle = .none
        t.timeStyle = .short
        return "\(t.string(from: start)) – \(t.string(from: end))"
    }
}

enum DecimalAmountFormatting {
    static func string(from amount: Decimal?) -> String {
        guard let amount else { return "" }
        return NSDecimalNumber(decimal: amount).stringValue
    }

    static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return Decimal(string: trimmed, locale: Locale.current)
            ?? Decimal(string: trimmed.replacingOccurrences(of: ",", with: "."))
    }

    static func formatted(amount: Decimal, currencyCode: String) -> String {
        let n = amount as NSDecimalNumber
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f.string(from: n) ?? "\(currencyCode) \(n.stringValue)"
    }
}
