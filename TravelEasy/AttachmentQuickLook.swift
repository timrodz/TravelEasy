import AppKit
import Quartz
import SwiftUI

enum QuickLookPresenter {
    private static let controller = PreviewController()

    static func show(url: URL) {
        controller.previewURL = url as NSURL
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = controller
        panel.delegate = controller
        panel.makeKeyAndOrderFront(nil)
        panel.reloadData()
    }
}

private final class PreviewController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    var previewURL: NSURL?

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL != nil ? 1 : 0
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        previewURL
    }

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }
}

struct AttachmentQuickLookChip: View {
    let attachment: Attachment

    private let storage = FileStorage.shared

    private var fileURL: URL {
        storage.fileURL(for: attachment.storedRelativePath)
    }

    var body: some View {
        Label {
            Text(attachment.originalFilename)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 140)
        } icon: {
            Image(systemName: "doc")
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.quaternary.opacity(0.6), in: Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            QuickLookPresenter.show(url: fileURL)
        }
        .help("Quick Look: \(attachment.originalFilename)")
        .contextMenu {
            Button("Open") {
                NSWorkspace.shared.open(fileURL)
            }
        }
    }
}

extension Booking {
    var attachmentsSortedByFilename: [Attachment] {
        attachments.sorted {
            $0.originalFilename.localizedCaseInsensitiveCompare($1.originalFilename) == .orderedAscending
        }
    }
}
