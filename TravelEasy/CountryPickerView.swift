import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedISOCode: String
    var excludedISOCodes: Set<String> = []
    var allowsDeselection: Bool = true
    var onSelect: ((ISOCountry) -> Void)?

    @State private var searchText = ""

    private var filteredCountries: [ISOCountry] {
        let available = ISOCountryCatalog.all.filter { !excludedISOCodes.contains($0.isoCode) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return available }
        return available.filter { iso in
            iso.name.localizedCaseInsensitiveContains(query)
                || iso.isoCode.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            ForEach(filteredCountries, id: \ISOCountry.isoCode) { isoCountry in
                countryRow(isoCountry)
            }
        }
        .searchable(text: $searchText, prompt: "Search countries")
    }

    private func countryRow(_ isoCountry: ISOCountry) -> some View {
        let isSelected = selectedISOCode == isoCountry.isoCode

        return HStack(spacing: 10) {
            Text(isoCountry.flagEmoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(isoCountry.name)
                Text(isoCountry.isoCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection(for: isoCountry)
        }
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
    }

    private func toggleSelection(for isoCountry: ISOCountry) {
        if selectedISOCode == isoCountry.isoCode {
            guard allowsDeselection else { return }
            selectedISOCode = ""
        } else {
            selectedISOCode = isoCountry.isoCode
            onSelect?(isoCountry)
        }
    }
}
