import SwiftData
import SwiftUI

private enum SidebarSelection: Hashable {
    case tripHome
    case country(PersistentIdentifier)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]

    @State private var sidebarSelection: SidebarSelection? = .tripHome
    @State private var showingAddCountry = false
    @State private var showingTripSettings = false
    @State private var countryPendingDelete: Country?

    private var trip: Trip? { trips.first }

    private var sortedCountries: [Country] {
        guard let trip else { return [] }
        return trip.countries.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var existingISOCodes: Set<String> {
        guard let trip else { return [] }
        return Set(trip.countries.map(\.isoCode).filter { !$0.isEmpty })
    }

    private var selectedCountry: Country? {
        guard case .country(let id) = sidebarSelection else { return nil }
        return sortedCountries.first { $0.persistentModelID == id }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            detail
        }
        .task { ensureDefaultTrip() }
        .onChange(of: sortedCountries.map(\.persistentModelID)) { _, _ in
            reconcileSidebarSelection()
        }
        .sheet(isPresented: $showingTripSettings) {
            if let trip {
                TripSettingsView(trip: trip)
            }
        }
        .sheet(isPresented: $showingAddCountry) {
            AddCountryView(excludedISOCodes: existingISOCodes) { isoCountry in
                addCountry(isoCountry)
            }
        }
        .alert(
            "Delete \(countryPendingDelete?.labeledName ?? "country")?",
            isPresented: deleteAlertBinding,
            presenting: countryPendingDelete
        ) { country in
            Button("Delete Country", role: .destructive) {
                deleteCountry(country)
            }
            Button("Cancel", role: .cancel) {
                countryPendingDelete = nil
            }
        } message: { country in
            Text(deleteCountryMessage(for: country))
        }
    }

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            Section {
                Label("Trip Home", systemImage: "house")
                    .tag(SidebarSelection.tripHome)

                ForEach(sortedCountries) { country in
                    Label {
                        Text(country.name)
                    } icon: {
                        Text(country.flagEmoji)
                            .font(.title3)
                    }
                    .tag(SidebarSelection.country(country.persistentModelID))
                    .contextMenu {
                        Button("Change Country…") {
                            sidebarSelection = .country(country.persistentModelID)
                        }
                        Button("Delete…", role: .destructive) {
                            countryPendingDelete = country
                        }
                    }
                }
                .onMove(perform: moveCountries)
            } header: {
                Text(trip?.name ?? "Trip")
            }
        }
        .navigationTitle(trip?.name ?? "TravelEasy")
    }

    @ViewBuilder
    private var detail: some View {
        Group {
            if let country = selectedCountry {
                CountryDetailView(
                    country: country,
                    excludedISOCodes: excludedISOCodes(for: country)
                )
            } else if let trip {
                TripHomeView(
                    trip: trip,
                    onAddCountry: { showingAddCountry = true },
                    onTripSettings: { showingTripSettings = true }
                )
            } else {
                ContentUnavailableView(
                    "Loading trip…",
                    systemImage: "suitcase",
                    description: Text("Setting up your trip.")
                )
            }
        }
        .toolbar {
            if selectedCountry != nil {
                ToolbarItem(placement: .navigation) {
                    Button {
                        sidebarSelection = .tripHome
                    } label: {
                        Label("Trip Home", systemImage: "house")
                    }
                    .help("Show trip summary")
                }
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { countryPendingDelete != nil },
            set: { if !$0 { countryPendingDelete = nil } }
        )
    }

    private func ensureDefaultTrip() {
        guard trips.isEmpty else { return }
        modelContext.insert(Trip())
    }

    private func reconcileSidebarSelection() {
        guard case .country(let id) = sidebarSelection else { return }
        if !sortedCountries.contains(where: { $0.persistentModelID == id }) {
            sidebarSelection = .tripHome
        }
    }

    private func excludedISOCodes(for country: Country) -> Set<String> {
        guard let trip else { return [] }
        return Set(
            trip.countries
                .filter { $0.persistentModelID != country.persistentModelID }
                .map(\.isoCode)
                .filter { !$0.isEmpty }
        )
    }

    private func addCountry(_ isoCountry: ISOCountry) {
        guard let trip else { return }
        guard !existingISOCodes.contains(isoCountry.isoCode) else { return }

        let nextOrder = (trip.countries.map(\.sortOrder).max() ?? -1) + 1
        let country = Country(isoCountry: isoCountry, sortOrder: nextOrder)
        country.trip = trip
        modelContext.insert(country)
        sidebarSelection = .country(country.persistentModelID)
    }

    private func moveCountries(from source: IndexSet, to destination: Int) {
        guard trip != nil else { return }
        var ordered = sortedCountries
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, country) in ordered.enumerated() {
            country.sortOrder = index
        }
    }

    private func deleteCountry(_ country: Country) {
        if case .country(let id) = sidebarSelection, id == country.persistentModelID {
            sidebarSelection = .tripHome
        }
        for booking in country.bookings {
            booking.deleteAttachmentFiles()
        }
        modelContext.delete(country)
        countryPendingDelete = nil
    }

    private func deleteCountryMessage(for country: Country) -> String {
        let bookingCount = country.bookings.count
        if bookingCount == 0 {
            return "This country will be removed from your trip."
        }
        let bookingWord = bookingCount == 1 ? "booking" : "bookings"
        return "This will permanently delete the country and its \(bookingCount) \(bookingWord) (including attachments)."
    }
}

private struct CountryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var country: Country
    var excludedISOCodes: Set<String>

    @State private var showingChangeCountry = false
    @State private var showingAddBooking = false
    @State private var bookingToEdit: Booking?
    @State private var bookingPendingDelete: Booking?

    private var homeCurrency: String {
        country.trip?.homeCurrency ?? "NZD"
    }

    private var sortedBookings: [Booking] {
        country.bookings.sorted(by: bookingSort)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                Section {
                    HStack(spacing: 12) {
                        Text(country.flagEmoji)
                            .font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(country.name)
                                .font(.title3)
                            if !country.isoCode.isEmpty {
                                Text(country.isoCode)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Change Country…") {
                            showingChangeCountry = true
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                Section("Bookings") {
                    if sortedBookings.isEmpty {
                        ContentUnavailableView(
                            "No bookings yet",
                            systemImage: "calendar",
                            description: Text("Add flights, hotels, activities, or transport for this country.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(sortedBookings) { booking in
                            Button {
                                bookingToEdit = booking
                            } label: {
                                BookingRowView(booking: booking, homeCurrency: homeCurrency)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit") {
                                    bookingToEdit = booking
                                }
                                Button("Delete…", role: .destructive) {
                                    bookingPendingDelete = booking
                                }
                            }
                        }
                        .onDelete(perform: deleteBookingsAtOffsets)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(country.labeledName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddBooking = true
                } label: {
                    Label("Add Booking", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingChangeCountry) {
            ChangeCountryView(country: country, excludedISOCodes: excludedISOCodes)
        }
        .sheet(isPresented: $showingAddBooking) {
            BookingEditorView(country: country, booking: nil)
        }
        .sheet(item: $bookingToEdit) { booking in
            BookingEditorView(country: country, booking: booking)
        }
        .alert(
            "Delete booking?",
            isPresented: deleteBookingAlertBinding,
            presenting: bookingPendingDelete
        ) { booking in
            Button("Delete", role: .destructive) {
                deleteBooking(booking)
            }
            Button("Cancel", role: .cancel) {
                bookingPendingDelete = nil
            }
        } message: { booking in
            Text("“\(booking.title)” will be permanently removed.")
        }
    }

    private var deleteBookingAlertBinding: Binding<Bool> {
        Binding(
            get: { bookingPendingDelete != nil },
            set: { if !$0 { bookingPendingDelete = nil } }
        )
    }

    private func bookingSort(_ lhs: Booking, _ rhs: Booking) -> Bool {
        switch (lhs.startAt, rhs.startAt) {
        case (let left?, let right?):
            return left < right
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (nil, nil):
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func deleteBookingsAtOffsets(_ offsets: IndexSet) {
        for index in offsets {
            let booking = sortedBookings[index]
            booking.deleteAttachmentFiles()
            modelContext.delete(booking)
        }
    }

    private func deleteBooking(_ booking: Booking) {
        booking.deleteAttachmentFiles()
        modelContext.delete(booking)
        bookingPendingDelete = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, Country.self, Booking.self, Attachment.self], inMemory: true)
}
