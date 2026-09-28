import SwiftData
import SwiftUI

struct BookingEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var country: Country
    var booking: Booking?

    @State private var type: BookingType = .activity
    @State private var title = ""
    @State private var amountText = ""
    @State private var hasStart = false
    @State private var startAt = Date()
    @State private var hasEnd = false
    @State private var endAt = Date()
    @State private var confirmationStatus: ConfirmationStatus = .planned
    @State private var paymentStatus: PaymentStatus = .unset
    @State private var paidBy: PaidBy?
    @State private var notes = ""
    @State private var pendingAttachments: [StoredAttachmentDraft] = []

    private var isEditing: Bool { booking != nil }

    private var trip: Trip? { country.trip }

    private var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }
        if paymentStatus == .paid && paidBy == nil { return false }
        if hasStart && hasEnd && endAt < startAt { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Booking") {
                    Picker("Type", selection: $type) {
                        ForEach(BookingType.allCases, id: \.self) { t in
                            Label(t.displayName, systemImage: t.systemImage)
                                .tag(t)
                        }
                    }
                    TextField("Title", text: $title)
                }

                Section("Amount") {
                    TextField("Amount (optional)", text: $amountText)
                }

                Section("Schedule") {
                    Toggle("Start date & time", isOn: $hasStart)
                    if hasStart {
                        DatePicker("Starts", selection: $startAt)
                    }
                    Toggle("End date & time", isOn: $hasEnd)
                    if hasEnd {
                        DatePicker("Ends", selection: $endAt)
                    }
                }

                Section("Status") {
                    Picker("Confirmation", selection: $confirmationStatus) {
                        ForEach([ConfirmationStatus.planned, .booked], id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    Picker("Payment", selection: $paymentStatus) {
                        ForEach([PaymentStatus.unset, .paid, .payLater], id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .onChange(of: paymentStatus) { _, newValue in
                        if newValue != .paid {
                            paidBy = nil
                        }
                    }

                    if paymentStatus == .paid {
                        Picker("Paid by", selection: paidByBinding) {
                            Text("Select…").tag(PaidBy?.none)
                            if let trip {
                                Text(trip.personAName).tag(PaidBy?.some(.personA))
                                Text(trip.personBName).tag(PaidBy?.some(.personB))
                            }
                            Text("Already split").tag(PaidBy?.some(.splitAlready))
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                BookingAttachmentsSection(booking: booking, pendingAttachments: $pendingAttachments)
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Booking" : "New Booking")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .frame(minWidth: 420, minHeight: 580)
            .onAppear { loadFromModel() }
        }
    }

    private var paidByBinding: Binding<PaidBy?> {
        Binding(
            get: { paidBy },
            set: { paidBy = $0 }
        )
    }

    private func cancel() {
        if booking == nil {
            pendingAttachments.deleteStoredFiles()
        }
        dismiss()
    }

    private func loadFromModel() {
        guard let booking else { return }
        type = booking.type
        title = booking.title
        amountText = DecimalAmountFormatting.string(from: booking.amount)
        if let start = booking.startAt {
            hasStart = true
            startAt = start
        }
        if let end = booking.endAt {
            hasEnd = true
            endAt = end
        }
        confirmationStatus = booking.confirmationStatus
        paymentStatus = booking.paymentStatus
        paidBy = booking.paidBy
        notes = booking.notes
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = DecimalAmountFormatting.decimal(from: amountText)
        let start = hasStart ? startAt : nil
        let end = hasEnd ? endAt : nil
        let resolvedPaidBy = paymentStatus == .paid ? paidBy : nil

        if let booking {
            booking.type = type
            booking.title = trimmedTitle
            booking.amount = amount
            booking.startAt = start
            booking.endAt = end
            booking.confirmationStatus = confirmationStatus
            booking.paymentStatus = paymentStatus
            booking.paidBy = resolvedPaidBy
            booking.notes = notes
        } else {
            let nextSortOrder = (country.bookings.compactMap(\.sortOrder).max() ?? -1) + 1
            let newBooking = Booking(
                type: type,
                title: trimmedTitle,
                startAt: start,
                endAt: end,
                amount: amount,
                confirmationStatus: confirmationStatus,
                paymentStatus: paymentStatus,
                paidBy: resolvedPaidBy,
                notes: notes,
                sortOrder: nextSortOrder
            )
            newBooking.country = country
            modelContext.insert(newBooking)
            for draft in pendingAttachments {
                let attachment = Attachment(
                    originalFilename: draft.originalFilename,
                    storedRelativePath: draft.storedRelativePath
                )
                attachment.booking = newBooking
                modelContext.insert(attachment)
            }
            pendingAttachments = []
        }
        dismiss()
    }
}
