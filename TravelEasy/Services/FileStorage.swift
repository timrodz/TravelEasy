import Foundation

struct FileStorage {
    static let shared = FileStorage()

    private let attachmentsRoot: URL

    init(attachmentsRoot: URL? = nil) {
        if let attachmentsRoot {
            self.attachmentsRoot = attachmentsRoot
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.attachmentsRoot = appSupport
                .appendingPathComponent("com.timrodz.traveleasy", isDirectory: true)
                .appendingPathComponent("Attachments", isDirectory: true)
        }
    }

    /// Copies `sourceURL` into Application Support and returns display name + stable relative path.
    func importFile(from sourceURL: URL) throws -> (originalFilename: String, storedRelativePath: String) {
        try FileManager.default.createDirectory(at: attachmentsRoot, withIntermediateDirectories: true)
        let originalFilename = sourceURL.lastPathComponent
        let storedName = "\(UUID().uuidString)-\(originalFilename)"
        let destination = attachmentsRoot.appendingPathComponent(storedName)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return (originalFilename, storedName)
    }

    func fileURL(for storedRelativePath: String) -> URL {
        attachmentsRoot.appendingPathComponent(storedRelativePath)
    }

    func deleteFile(at storedRelativePath: String) {
        let url = fileURL(for: storedRelativePath)
        try? FileManager.default.removeItem(at: url)
    }
}

extension Booking {
    func deleteAttachmentFiles(using storage: FileStorage = .shared) {
        for attachment in attachments {
            storage.deleteFile(at: attachment.storedRelativePath)
        }
    }
}
