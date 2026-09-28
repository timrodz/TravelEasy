import Foundation

/// Booking fields used to compute Trip Home “Up Next” rows (no SwiftData).
struct UpNextBookingLine: Equatable, Sendable {
    var bookingType: BookingType
    var title: String
    var countryName: String
    var startAt: Date?
    var endAt: Date?
    var confirmationStatus: ConfirmationStatus
    var paymentStatus: PaymentStatus
}

struct UpNextItem: Equatable, Sendable {
    var title: String
    var countryName: String
    var startAt: Date?
    var endAt: Date?
    var confirmationStatus: ConfirmationStatus
    var paymentStatus: PaymentStatus

    var needsAttentionBadge: Bool {
        BookingAttention.needsBadge(
            confirmationStatus: confirmationStatus,
            paymentStatus: paymentStatus
        )
    }
}

struct UpNextSnapshot: Equatable, Sendable {
    /// False when no booking in the trip has `startAt` or `endAt`.
    var hasAnyDatedBookings: Bool
    var nextTravel: UpNextItem?
    var currentAccommodation: UpNextItem?
    var nextAccommodation: UpNextItem?
    var nextActivity: UpNextItem?

    var hasVisibleRows: Bool {
        nextTravel != nil
            || currentAccommodation != nil
            || nextAccommodation != nil
            || nextActivity != nil
    }
}

enum UpNextCalculator {
    static func compute(from lines: [UpNextBookingLine], now: Date) -> UpNextSnapshot {
        let hasAnyDatedBookings = lines.contains { $0.startAt != nil || $0.endAt != nil }

        let nextTravel = soonestFuture(
            in: lines.filter { $0.bookingType == .flight || $0.bookingType == .transport },
            now: now
        )

        let hotels = lines.filter { $0.bookingType == .hotel }
        let currentAccommodation = hotels
            .filter { isCurrentAccommodation($0, now: now) }
            .max(by: { ($0.startAt ?? .distantPast) < ($1.startAt ?? .distantPast) })
            .map(upNextItem(from:))

        let nextAccommodation = soonestFuture(in: hotels, now: now)

        let nextActivity = soonestFuture(
            in: lines.filter { $0.bookingType == .activity },
            now: now
        )

        return UpNextSnapshot(
            hasAnyDatedBookings: hasAnyDatedBookings,
            nextTravel: nextTravel,
            currentAccommodation: currentAccommodation,
            nextAccommodation: nextAccommodation,
            nextActivity: nextActivity
        )
    }

    private static func soonestFuture(in lines: [UpNextBookingLine], now: Date) -> UpNextItem? {
        lines
            .compactMap { line -> (Date, UpNextBookingLine)? in
                guard let start = line.startAt, start > now else { return nil }
                return (start, line)
            }
            .min(by: { $0.0 < $1.0 })
            .map { upNextItem(from: $0.1) }
    }

    private static func isCurrentAccommodation(_ line: UpNextBookingLine, now: Date) -> Bool {
        guard let start = line.startAt, start <= now else { return false }
        if let end = line.endAt {
            return now <= end
        }
        return true
    }

    private static func upNextItem(from line: UpNextBookingLine) -> UpNextItem {
        UpNextItem(
            title: line.title,
            countryName: line.countryName,
            startAt: line.startAt,
            endAt: line.endAt,
            confirmationStatus: line.confirmationStatus,
            paymentStatus: line.paymentStatus
        )
    }
}

extension Booking {
    func upNextLine(countryName: String) -> UpNextBookingLine {
        UpNextBookingLine(
            bookingType: type,
            title: title,
            countryName: countryName,
            startAt: startAt,
            endAt: endAt,
            confirmationStatus: confirmationStatus,
            paymentStatus: paymentStatus
        )
    }
}

extension Trip {
    func upNext(now: Date = Date()) -> UpNextSnapshot {
        let lines = countries.flatMap { country in
            country.bookings.map { $0.upNextLine(countryName: country.name) }
        }
        return UpNextCalculator.compute(from: lines, now: now)
    }
}
