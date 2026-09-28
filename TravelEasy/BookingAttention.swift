import SwiftUI

enum BookingAttention {
    /// Red corner badge when unbooked or explicitly pay-later (not `unset` on booked items).
    static func needsBadge(
        confirmationStatus: ConfirmationStatus,
        paymentStatus: PaymentStatus
    ) -> Bool {
        confirmationStatus == .planned || paymentStatus == .payLater
    }
}

extension Booking {
    var needsAttentionBadge: Bool {
        BookingAttention.needsBadge(
            confirmationStatus: confirmationStatus,
            paymentStatus: paymentStatus
        )
    }
}

/// Small red mark for the top-right corner of a booking row/card.
struct AttentionBadgeCorner: View {
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 9, height: 9)
            .overlay {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
            }
            .accessibilityLabel("Needs attention")
    }
}

private struct AttentionBadgeOverlay: ViewModifier {
    var showsBadge: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showsBadge {
                    AttentionBadgeCorner()
                        .offset(x: 4, y: -2)
                }
            }
    }
}

extension View {
    func bookingAttentionBadge(if needsAttention: Bool) -> some View {
        modifier(AttentionBadgeOverlay(showsBadge: needsAttention))
    }
}
