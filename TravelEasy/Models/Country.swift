import Foundation
import SwiftData

@Model
final class Country {
    var name: String
    /// ISO 3166-1 alpha-2 (e.g. `NZ`, `JP`).
    var isoCode: String
    var sortOrder: Int

    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \Booking.country)
    var bookings: [Booking] = []

    init(name: String, isoCode: String = "", sortOrder: Int = 0) {
        self.name = name
        self.isoCode = isoCode
        self.sortOrder = sortOrder
    }

    init(isoCountry: ISOCountry, sortOrder: Int = 0) {
        self.name = isoCountry.name
        self.isoCode = isoCountry.isoCode
        self.sortOrder = sortOrder
    }
}
