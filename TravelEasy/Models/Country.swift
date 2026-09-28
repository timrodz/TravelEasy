import Foundation
import SwiftData

@Model
final class Country {
    var name: String
    var sortOrder: Int

    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \Booking.country)
    var bookings: [Booking] = []

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}
