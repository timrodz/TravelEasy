import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]

    @State private var selectedCountry: Country?
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

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            detail
        }
        .task { ensureDefaultTrip() }
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
        List(selection: $selectedCountry) {
            Section {
                ForEach(sortedCountries) { country in
                    Label {
                        Text(country.name)
                    } icon: {
                        Text(country.flagEmoji)
                            .font(.title3)
                    }
                    .tag(country)
                    .contextMenu {
                        Button("Change Country…") {
                            selectedCountry = country
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
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingAddCountry = true
                } label: {
                    Label("Add Country", systemImage: "plus")
                }
                Button {
                    showingTripSettings = true
                } label: {
                    Label("Trip Settings", systemImage: "gearshape")
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let country = selectedCountry {
            CountryDetailView(
                country: country,
                excludedISOCodes: excludedISOCodes(for: country)
            )
        } else {
            ContentUnavailableView(
                "Select a country",
                systemImage: "globe",
                description: Text("Choose a country in the sidebar, or add one from the ISO list.")
            )
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
        selectedCountry = country
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
        if selectedCountry?.persistentModelID == country.persistentModelID {
            selectedCountry = nil
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
    @Bindable var country: Country
    var excludedISOCodes: Set<String>

    @State private var showingChangeCountry = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Text(country.flagEmoji)
                    .font(.system(size: 44))
                VStack(alignment: .leading, spacing: 4) {
                    Text(country.name)
                        .font(.title2)
                    if !country.isoCode.isEmpty {
                        Text(country.isoCode)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Button("Change Country…") {
                showingChangeCountry = true
            }

            if country.bookings.isEmpty {
                ContentUnavailableView(
                    "No bookings yet",
                    systemImage: "calendar",
                    description: Text("Bookings for this country will appear here.")
                )
            } else {
                Text("\(country.bookings.count) booking(s) in this country.")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(country.labeledName)
        .sheet(isPresented: $showingChangeCountry) {
            ChangeCountryView(country: country, excludedISOCodes: excludedISOCodes)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, Country.self, Booking.self, Attachment.self], inMemory: true)
}
