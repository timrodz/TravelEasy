import XCTest
@testable import TravelEasy

final class UpNextLogicTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000)

    func testEmptyWhenNoDatedBookings() {
        let lines = [
            UpNextBookingLine(
                bookingType: .flight,
                title: "TBD",
                countryName: "Japan",
                startAt: nil,
                endAt: nil,
                confirmationStatus: .planned,
                paymentStatus: .unset
            ),
        ]

        let snapshot = UpNextCalculator.compute(from: lines, now: now)
        XCTAssertFalse(snapshot.hasAnyDatedBookings)
        XCTAssertFalse(snapshot.hasVisibleRows)
    }

    func testNextTravelPicksSoonestFutureFlightOrTransport() {
        let sooner = now.addingTimeInterval(3600)
        let later = now.addingTimeInterval(7200)

        let lines = [
            line(type: .transport, title: "Train", start: later),
            line(type: .flight, title: "NZ123", start: sooner),
            line(type: .flight, title: "Past", start: now.addingTimeInterval(-3600)),
        ]

        let snapshot = UpNextCalculator.compute(from: lines, now: now)
        XCTAssertEqual(snapshot.nextTravel?.title, "NZ123")
    }

    func testCurrentAccommodationWithinStayWindow() {
        let start = now.addingTimeInterval(-86400)
        let end = now.addingTimeInterval(86400)

        let lines = [
            line(type: .hotel, title: "Current Hotel", start: start, end: end),
            line(type: .hotel, title: "Future Hotel", start: now.addingTimeInterval(86400 * 3)),
        ]

        let snapshot = UpNextCalculator.compute(from: lines, now: now)
        XCTAssertEqual(snapshot.currentAccommodation?.title, "Current Hotel")
        XCTAssertEqual(snapshot.nextAccommodation?.title, "Future Hotel")
    }

    func testNextActivityIgnoresPastAndOtherTypes() {
        let activityStart = now.addingTimeInterval(1800)

        let lines = [
            line(type: .activity, title: "Museum", start: activityStart),
            line(type: .activity, title: "Old tour", start: now.addingTimeInterval(-100)),
            line(type: .hotel, title: "Hotel", start: now.addingTimeInterval(5000)),
        ]

        let snapshot = UpNextCalculator.compute(from: lines, now: now)
        XCTAssertEqual(snapshot.nextActivity?.title, "Museum")
    }

    func testOmitsRowsWhenNotApplicable() {
        let snapshot = UpNextCalculator.compute(from: [], now: now)
        XCTAssertNil(snapshot.nextTravel)
        XCTAssertNil(snapshot.currentAccommodation)
        XCTAssertNil(snapshot.nextAccommodation)
        XCTAssertNil(snapshot.nextActivity)
    }

    private func line(
        type: BookingType,
        title: String,
        start: Date,
        end: Date? = nil,
        countryName: String = "France"
    ) -> UpNextBookingLine {
        UpNextBookingLine(
            bookingType: type,
            title: title,
            countryName: countryName,
            startAt: start,
            endAt: end,
            confirmationStatus: .booked,
            paymentStatus: .paid
        )
    }
}
