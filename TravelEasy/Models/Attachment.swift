import Foundation
import SwiftData

@Model
final class Attachment {
    var originalFilename: String
    var storedRelativePath: String

    var booking: Booking?

    init(originalFilename: String, storedRelativePath: String) {
        self.originalFilename = originalFilename
        self.storedRelativePath = storedRelativePath
    }
}
