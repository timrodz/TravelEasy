import Foundation
import SwiftData

@Model
final class Trip {
    var name: String
    var homeCurrency: String
    var personAName: String
    var personBName: String

    @Relationship(deleteRule: .cascade, inverse: \Country.trip)
    var countries: [Country] = []

    init(
        name: String = "My Trip",
        homeCurrency: String = "NZD",
        personAName: String = "Me",
        personBName: String = "Partner"
    ) {
        self.name = name
        self.homeCurrency = homeCurrency
        self.personAName = personAName
        self.personBName = personBName
    }
}
