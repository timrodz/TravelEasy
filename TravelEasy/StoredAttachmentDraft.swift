import Foundation

struct StoredAttachmentDraft: Identifiable {
    let id = UUID()
    var originalFilename: String
    var storedRelativePath: String
}

extension Array where Element == StoredAttachmentDraft {
    func sortedByFilename() -> [StoredAttachmentDraft] {
        sorted {
            $0.originalFilename.localizedCaseInsensitiveCompare($1.originalFilename) == .orderedAscending
        }
    }

    func deleteStoredFiles(using storage: FileStorage = .shared) {
        for draft in self {
            storage.deleteFile(at: draft.storedRelativePath)
        }
    }
}
