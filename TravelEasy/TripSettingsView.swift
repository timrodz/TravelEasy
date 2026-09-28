import SwiftData
import SwiftUI

struct TripSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var trip: Trip

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Trip name", text: $trip.name)
                    TextField("Home currency", text: $trip.homeCurrency)
                }
                Section("Travelers") {
                    TextField("Person A", text: $trip.personAName)
                    TextField("Person B", text: $trip.personBName)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Trip Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .frame(minWidth: 360, minHeight: 280)
        }
    }
}
