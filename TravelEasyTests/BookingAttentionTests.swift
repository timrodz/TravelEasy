import XCTest
@testable import TravelEasy

final class BookingAttentionTests: XCTestCase {
    func testPlannedShowsBadge() {
        XCTAssertTrue(
            BookingAttention.needsBadge(confirmationStatus: .planned, paymentStatus: .unset)
        )
        XCTAssertTrue(
            BookingAttention.needsBadge(confirmationStatus: .planned, paymentStatus: .paid)
        )
    }

    func testPayLaterShowsBadgeWhenBooked() {
        XCTAssertTrue(
            BookingAttention.needsBadge(confirmationStatus: .booked, paymentStatus: .payLater)
        )
    }

    func testBookedAndNotPayLaterHidesBadge() {
        XCTAssertFalse(
            BookingAttention.needsBadge(confirmationStatus: .booked, paymentStatus: .unset)
        )
        XCTAssertFalse(
            BookingAttention.needsBadge(confirmationStatus: .booked, paymentStatus: .paid)
        )
    }
}
