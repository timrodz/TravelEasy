import Foundation

/// Snapshot of booking fields used for trip-level money and date summaries (no SwiftData).
struct TripBookingLine: Equatable, Sendable {
    var amount: Decimal?
    var confirmationStatus: ConfirmationStatus
    var paymentStatus: PaymentStatus
    var paidBy: PaidBy?
    var startAt: Date?
    var endAt: Date?
}

struct TripSummary: Equatable, Sendable {
    /// Total paid on items marked `paid` where `paidBy == .personA`.
    var personATotalPaid: Decimal
    /// Total paid on items marked `paid` where `paidBy == .personB`.
    var personBTotalPaid: Decimal
    /// Sum of amounts on paid items (with amounts).
    var totalPaidExpenses: Decimal
    /// Positive: person B owes person A; negative: person A owes person B; zero: even.
    var netOwedByBToA: Decimal
    var committedBudget: Decimal
    var projectedBudget: Decimal
    var tripStart: Date?
    var tripEnd: Date?
}

enum TripSummaryCalculator {
    static func compute(from bookings: [TripBookingLine]) -> TripSummary {
        var personAPaid = Decimal.zero
        var personBPaid = Decimal.zero
        var totalPaid = Decimal.zero
        var committed = Decimal.zero
        var plannedOnly = Decimal.zero
        var tripStart: Date?
        var tripEnd: Date?

        for line in bookings {
            if let amount = line.amount {
                switch line.confirmationStatus {
                case .booked:
                    committed = committed + amount
                case .planned:
                    plannedOnly = plannedOnly + amount
                }

                if line.paymentStatus == .paid {
                    totalPaid = totalPaid + amount
                    let share = decimalHalf(amount)
                    switch line.paidBy {
                    case .personA:
                        personAPaid = personAPaid + amount
                    case .personB:
                        personBPaid = personBPaid + amount
                    case .splitAlready:
                        personAPaid = personAPaid + share
                        personBPaid = personBPaid + share
                    case nil:
                        break
                    }
                }
            }

            if let start = line.startAt {
                tripStart = minOptional(tripStart, start)
            }
            if let end = line.endAt {
                tripEnd = maxOptional(tripEnd, end)
            }
        }

        let eachShare = decimalHalf(totalPaid)
        let netOwed = personAPaid - eachShare

        return TripSummary(
            personATotalPaid: personAPaid,
            personBTotalPaid: personBPaid,
            totalPaidExpenses: totalPaid,
            netOwedByBToA: netOwed,
            committedBudget: committed,
            projectedBudget: committed + plannedOnly,
            tripStart: tripStart,
            tripEnd: tripEnd
        )
    }

    private static func decimalHalf(_ amount: Decimal) -> Decimal {
        var result = Decimal()
        var value = amount
        var divisor = Decimal(2)
        NSDecimalDivide(&result, &value, &divisor, .plain)
        return result
    }

    private static func minOptional(_ current: Date?, _ candidate: Date) -> Date {
        guard let current else { return candidate }
        return min(current, candidate)
    }

    private static func maxOptional(_ current: Date?, _ candidate: Date) -> Date {
        guard let current else { return candidate }
        return max(current, candidate)
    }
}

extension Booking {
    var tripSummaryLine: TripBookingLine {
        TripBookingLine(
            amount: amount,
            confirmationStatus: confirmationStatus,
            paymentStatus: paymentStatus,
            paidBy: paidBy,
            startAt: startAt,
            endAt: endAt
        )
    }
}

extension Trip {
    var tripSummaryLines: [TripBookingLine] {
        countries.flatMap(\.bookings).map(\.tripSummaryLine)
    }

    func tripSummary() -> TripSummary {
        TripSummaryCalculator.compute(from: tripSummaryLines)
    }
}
