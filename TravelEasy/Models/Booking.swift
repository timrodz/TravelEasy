import Foundation
import SwiftData

@Model
final class Booking {
    var type: BookingType
    var title: String
    var startAt: Date?
    var endAt: Date?
    var amount: Decimal?
    var confirmationStatus: ConfirmationStatus
    var paymentStatus: PaymentStatus
    var paidBy: PaidBy?
    var notes: String

    var country: Country?

    @Relationship(deleteRule: .cascade, inverse: \Attachment.booking)
    var attachments: [Attachment] = []

    init(
        type: BookingType,
        title: String,
        startAt: Date? = nil,
        endAt: Date? = nil,
        amount: Decimal? = nil,
        confirmationStatus: ConfirmationStatus = .planned,
        paymentStatus: PaymentStatus = .unset,
        paidBy: PaidBy? = nil,
        notes: String = ""
    ) {
        self.type = type
        self.title = title
        self.startAt = startAt
        self.endAt = endAt
        self.amount = amount
        self.confirmationStatus = confirmationStatus
        self.paymentStatus = paymentStatus
        self.paidBy = paidBy
        self.notes = notes
    }
}
