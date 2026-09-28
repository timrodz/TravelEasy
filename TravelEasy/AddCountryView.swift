import SwiftUI

struct AddCountryView: View {
    @Environment(\.dismiss) private var dismiss

    var excludedISOCodes: Set<String>
    var onAdd: (ISOCountry) -> Void

    @State private var selectedISOCode = ""

    var body: some View {
        NavigationStack {
            CountryPickerView(
                selectedISOCode: $selectedISOCode,
                excludedISOCodes: excludedISOCodes
            )
            .navigationTitle("Add Country")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSelected() }
                        .disabled(selectedISOCode.isEmpty)
                }
            }
            .frame(minWidth: 360, minHeight: 440)
        }
    }

    private func addSelected() {
        guard let country = ISOCountryCatalog.country(for: selectedISOCode) else { return }
        onAdd(country)
        dismiss()
    }
}

struct ChangeCountryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var country: Country
    var excludedISOCodes: Set<String>

    @State private var selectedISOCode = ""

    var body: some View {
        NavigationStack {
            CountryPickerView(
                selectedISOCode: $selectedISOCode,
                excludedISOCodes: excludedISOCodes,
                allowsDeselection: false
            )
            .navigationTitle("Change Country")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedISOCode.isEmpty || selectedISOCode == country.isoCode)
                }
            }
            .frame(minWidth: 360, minHeight: 440)
            .onAppear {
                selectedISOCode = country.isoCode
            }
        }
    }

    private func save() {
        guard let isoCountry = ISOCountryCatalog.country(for: selectedISOCode) else { return }
        country.apply(isoCountry: isoCountry)
        dismiss()
    }
}
