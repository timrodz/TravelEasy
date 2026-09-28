import SwiftUI

struct BookingRowView: View {
    var booking: Booking
    var homeCurrency: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: booking.type.systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.title)
                    .font(.headline)
                Text(booking.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let span = BookingDateFormatting.span(start: booking.startAt, end: booking.endAt) {
                    Label(span, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    statusChip(booking.confirmationStatus.displayName, systemImage: "checkmark.seal")
                    statusChip(booking.paymentStatus.displayName, systemImage: "creditcard")
                    if let amount = booking.amount {
                        Text(DecimalAmountFormatting.formatted(amount: amount, currencyCode: homeCurrency))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func statusChip(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.6), in: Capsule())
    }
}
