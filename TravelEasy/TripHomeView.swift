import SwiftUI

struct TripHomeView: View {
    @Bindable var trip: Trip
    @FocusState private var tripTitleFocused: Bool
    var onAddCountry: () -> Void = {}
    var onTripSettings: () -> Void = {}

    private var summary: TripSummary {
        trip.tripSummary()
    }

    private var upNext: UpNextSnapshot {
        trip.upNext()
    }

    private var currencyCode: String {
        trip.homeCurrency
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TextField("My Trip", text: $trip.name)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                    .focused($tripTitleFocused)
                    .onSubmit { normalizeTripName() }
                    .onChange(of: tripTitleFocused) { _, focused in
                        if !focused { normalizeTripName() }
                    }

                GroupBox("Up Next") {
                    upNextContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }

                GroupBox("Budget") {
                    VStack(alignment: .leading, spacing: 8) {
                        summaryRow(
                            title: "Committed (booked)",
                            value: summary.committedBudget
                        )
                        summaryRow(
                            title: "Projected (+ planned)",
                            value: summary.projectedBudget
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }

                GroupBox("Trip dates") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let span = tripDateSpanText {
                            Text(span)
                                .font(.body)
                        } else {
                            Text("No dated bookings yet")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }

                GroupBox("Split (paid items only)") {
                    VStack(alignment: .leading, spacing: 8) {
                        summaryRow(
                            title: "\(trip.personAName) paid",
                            value: summary.personATotalPaid
                        )
                        summaryRow(
                            title: "\(trip.personBName) paid",
                            value: summary.personBTotalPaid
                        )

                        Divider()

                        Text(settlementText)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Trip Home")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: onAddCountry) {
                    Label("Add Country", systemImage: "plus")
                }
                .help("Add a country to the trip")

                Button(action: onTripSettings) {
                    Label("Trip Settings", systemImage: "gearshape")
                }
                .help("Edit trip name, currency, and traveler labels")
            }
        }
    }

    @ViewBuilder
    private var upNextContent: some View {
        if !upNext.hasAnyDatedBookings {
            Text("No dated bookings yet")
                .foregroundStyle(.secondary)
        } else if !upNext.hasVisibleRows {
            Text("Nothing upcoming — add dates to flights, stays, or activities.")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if let item = upNext.nextTravel {
                    upNextRow(label: "Next travel", item: item, systemImage: "airplane")
                }
                if let item = upNext.currentAccommodation {
                    upNextRow(label: "Current stay", item: item, systemImage: "bed.double")
                }
                if let item = upNext.nextAccommodation {
                    upNextRow(label: "Next stay", item: item, systemImage: "bed.double")
                }
                if let item = upNext.nextActivity {
                    upNextRow(label: "Next activity", item: item, systemImage: "figure.walk")
                }
            }
        }
    }

    private func upNextRow(label: String, item: UpNextItem, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(item.countryName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let span = BookingDateFormatting.span(start: item.startAt, end: item.endAt) {
                        Text(span)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .bookingAttentionBadge(if: item.needsAttentionBadge)
    }

    private var tripDateSpanText: String? {
        TripDateSpanFormatting.span(start: summary.tripStart, end: summary.tripEnd)
    }

    private var settlementText: String {
        let net = summary.netOwedByBToA
        if net == 0 {
            return "Settled up on paid expenses (50/50)."
        }
        let absAmount = net < 0 ? -net : net
        let formatted = DecimalAmountFormatting.formatted(amount: absAmount, currencyCode: currencyCode)
        if net > 0 {
            return "\(trip.personBName) owes \(trip.personAName) \(formatted)"
        }
        return "\(trip.personAName) owes \(trip.personBName) \(formatted)"
    }

    private func normalizeTripName() {
        let trimmed = trip.name.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.name = trimmed.isEmpty ? "My Trip" : trimmed
    }

    @ViewBuilder
    private func summaryRow(title: String, value: Decimal) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(DecimalAmountFormatting.formatted(amount: value, currencyCode: currencyCode))
                .fontWeight(.medium)
        }
    }
}

enum TripDateSpanFormatting {
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
            return "From \(dateOnly.string(from: start))"
        case (nil, let end?):
            return "Until \(dateOnly.string(from: end))"
        case (let start?, let end?):
            if Calendar.current.isDate(start, inSameDayAs: end) {
                return dateOnly.string(from: start)
            }
            return "\(dateOnly.string(from: start)) – \(dateOnly.string(from: end))"
        }
    }
}
