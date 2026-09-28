import XCTest
@testable import TravelEasy

final class TripSummaryLogicTests: XCTestCase {
    func testSplitOnlyCountsPaidItemsWithAmount() {
        let lines = [
            TripBookingLine(
                amount: 200,
                confirmationStatus: .booked,
                paymentStatus: .paid,
                paidBy: .personA,
                startAt: nil,
                endAt: nil
            ),
            TripBookingLine(
                amount: 100,
                confirmationStatus: .planned,
                paymentStatus: .unset,
                paidBy: nil,
                startAt: nil,
                endAt: nil
            ),
        ]

        let summary = TripSummaryCalculator.compute(from: lines)
        XCTAssertEqual(summary.totalPaidExpenses, 200)
        XCTAssertEqual(summary.personATotalPaid, 200)
        XCTAssertEqual(summary.personBTotalPaid, 0)
        XCTAssertEqual(summary.netOwedByBToA, 100)
    }

    func testSplitAlreadyCountsHalfEach() {
        let lines = [
            TripBookingLine(
                amount: 100,
                confirmationStatus: .booked,
                paymentStatus: .paid,
                paidBy: .splitAlready,
                startAt: nil,
                endAt: nil
            ),
        ]

        let summary = TripSummaryCalculator.compute(from: lines)
        XCTAssertEqual(summary.personATotalPaid, 50)
        XCTAssertEqual(summary.personBTotalPaid, 50)
        XCTAssertEqual(summary.netOwedByBToA, 0)
    }

    func testBudgetCommittedAndProjected() {
        let lines = [
            TripBookingLine(
                amount: 80,
                confirmationStatus: .booked,
                paymentStatus: .payLater,
                paidBy: nil,
                startAt: nil,
                endAt: nil
            ),
            TripBookingLine(
                amount: 20,
                confirmationStatus: .planned,
                paymentStatus: .unset,
                paidBy: nil,
                startAt: nil,
                endAt: nil
            ),
        ]

        let summary = TripSummaryCalculator.compute(from: lines)
        XCTAssertEqual(summary.committedBudget, 80)
        XCTAssertEqual(summary.projectedBudget, 100)
    }

    func testTripDateSpanMinStartMaxEnd() {
        let early = Date(timeIntervalSince1970: 1_000_000)
        let mid = Date(timeIntervalSince1970: 2_000_000)
        let late = Date(timeIntervalSince1970: 3_000_000)

        let lines = [
            TripBookingLine(
                amount: nil,
                confirmationStatus: .planned,
                paymentStatus: .unset,
                paidBy: nil,
                startAt: mid,
                endAt: late
            ),
            TripBookingLine(
                amount: nil,
                confirmationStatus: .booked,
                paymentStatus: .paid,
                paidBy: .personA,
                startAt: early,
                endAt: nil
            ),
        ]

        let summary = TripSummaryCalculator.compute(from: lines)
        XCTAssertEqual(summary.tripStart, early)
        XCTAssertEqual(summary.tripEnd, late)
    }
}
