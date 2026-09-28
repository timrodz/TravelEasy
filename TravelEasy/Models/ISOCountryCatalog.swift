import Foundation
import SwiftData

struct ISOCountry: Identifiable, Hashable {
    let isoCode: String

    var id: String { isoCode }

    var name: String {
        Locale.current.localizedString(forRegionCode: isoCode) ?? isoCode
    }

    var flagEmoji: String {
        FlagEmoji.from(isoCode: isoCode)
    }
}

enum FlagEmoji {
    static func from(isoCode: String) -> String {
        isoCode
            .uppercased()
            .unicodeScalars
            .compactMap { scalar -> UnicodeScalar? in
                guard (65 ... 90).contains(scalar.value) else { return nil }
                return UnicodeScalar(127397 + scalar.value)
            }
            .map { String($0) }
            .joined()
    }
}

enum ISOCountryCatalog {
    static let all: [ISOCountry] = Locale.isoRegionCodes
        .filter { $0.count == 2 }
        .sorted { lhs, rhs in
            let left = Locale.current.localizedString(forRegionCode: lhs) ?? lhs
            let right = Locale.current.localizedString(forRegionCode: rhs) ?? rhs
            return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
        }
        .map { ISOCountry(isoCode: $0) }

    static func country(for isoCode: String) -> ISOCountry? {
        guard !isoCode.isEmpty else { return nil }
        return ISOCountry(isoCode: isoCode.uppercased())
    }
}

extension Country {
    var flagEmoji: String {
        guard !isoCode.isEmpty else { return "🌐" }
        return FlagEmoji.from(isoCode: isoCode)
    }

    var labeledName: String {
        "\(flagEmoji) \(name)"
    }

    func apply(isoCountry: ISOCountry) {
        isoCode = isoCountry.isoCode
        name = isoCountry.name
    }
}
