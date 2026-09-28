import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BookingAttachmentsSection: View {
    @Environment(\.modelContext) private var modelContext

    var booking: Booking?
    @Binding var pendingAttachments: [StoredAttachmentDraft]

    @State private var showingFileImporter = false
    @State private var importErrorMessage: String?

    private let storage = FileStorage.shared

    private var sortedModelAttachments: [Attachment] {
        booking?.attachmentsSortedByFilename ?? []
    }

    private var sortedPendingAttachments: [StoredAttachmentDraft] {
        pendingAttachments.sortedByFilename()
    }

    private var isEmpty: Bool {
        if booking != nil {
            sortedModelAttachments.isEmpty
        } else {
            pendingAttachments.isEmpty
        }
    }

    var body: some View {
        Section("Attachments") {
            if isEmpty {
                Text("No attachments yet")
                    .foregroundStyle(.secondary)
            } else if let booking {
                ForEach(sortedModelAttachments, id: \.persistentModelID) { attachment in
                    modelAttachmentRow(attachment)
                }
            } else {
                ForEach(sortedPendingAttachments) { draft in
                    pendingAttachmentRow(draft)
                }
            }

            Button("Add Attachment…") {
                showingFileImporter = true
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            importFiles(from: result)
        }
        .alert(
            "Couldn’t add attachment",
            isPresented: importErrorPresented,
            actions: {
                Button("OK", role: .cancel) {
                    importErrorMessage = nil
                }
            },
            message: {
                if let importErrorMessage {
                    Text(importErrorMessage)
                }
            }
        )
    }

    private var importErrorPresented: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )
    }

    @ViewBuilder
    private func modelAttachmentRow(_ attachment: Attachment) -> some View {
        HStack {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            Text(attachment.originalFilename)
                .lineLimit(1)
            Spacer()
            Button("Open") {
                openFile(at: attachment.storedRelativePath)
            }
            Button(role: .destructive) {
                removeModelAttachment(attachment)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove attachment")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            openFile(at: attachment.storedRelativePath)
        }
    }

    @ViewBuilder
    private func pendingAttachmentRow(_ draft: StoredAttachmentDraft) -> some View {
        HStack {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
            Text(draft.originalFilename)
                .lineLimit(1)
            Spacer()
            Button("Open") {
                openFile(at: draft.storedRelativePath)
            }
            Button(role: .destructive) {
                removePendingAttachment(draft)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove attachment")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            openFile(at: draft.storedRelativePath)
        }
    }

    private func importFiles(from result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        case .success(let urls):
            for url in urls {
                importSingleFile(url)
            }
        }
    }

    private func importSingleFile(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let (originalFilename, storedRelativePath) = try storage.importFile(from: url)
            if let booking {
                let attachment = Attachment(originalFilename: originalFilename, storedRelativePath: storedRelativePath)
                attachment.booking = booking
                modelContext.insert(attachment)
            } else {
                let draft = StoredAttachmentDraft(
                    originalFilename: originalFilename,
                    storedRelativePath: storedRelativePath
                )
                pendingAttachments.append(draft)
            }
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func openFile(at storedRelativePath: String) {
        let url = storage.fileURL(for: storedRelativePath)
        NSWorkspace.shared.open(url)
    }

    private func removeModelAttachment(_ attachment: Attachment) {
        storage.deleteFile(at: attachment.storedRelativePath)
        modelContext.delete(attachment)
    }

    private func removePendingAttachment(_ draft: StoredAttachmentDraft) {
        storage.deleteFile(at: draft.storedRelativePath)
        pendingAttachments.removeAll { $0.id == draft.id }
    }
}
