import SwiftUI

struct TripHomeView: View {
    let trip: Trip
    var onAddCountry: () -> Void = {}
    var onTripSettings: () -> Void = {}

    private var summary: TripSummary {
        trip.tripSummary()
    }

    private var currencyCode: String {
        trip.homeCurrency
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(trip.name)
                    .font(.largeTitle)
                    .fontWeight(.semibold)

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
