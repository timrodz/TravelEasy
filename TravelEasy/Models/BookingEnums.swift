import Foundation

enum BookingType: String, Codable, CaseIterable {
    case flight
    case hotel
    case activity
    case transport
}

enum ConfirmationStatus: String, Codable {
    case planned
    case booked
}

enum PaymentStatus: String, Codable {
    case unset
    case paid
    case payLater
}

enum PaidBy: String, Codable {
    case personA
    case personB
    case splitAlready
}
