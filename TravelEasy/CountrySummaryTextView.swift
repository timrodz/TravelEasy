import AppKit
import SwiftUI

struct CountrySummaryLinkTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        configure(textView)
        textView.string = text
        textView.checkTextInDocument(nil)
        context.coordinator.reportHeight()
        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        if textView.string != text {
            context.coordinator.isProgrammaticUpdate = true
            textView.string = text
            textView.checkTextInDocument(nil)
            context.coordinator.isProgrammaticUpdate = false
        }
        context.coordinator.reportHeight()
    }

    private func configure(_ textView: NSTextView) {
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isAutomaticLinkDetectionEnabled = true
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .cursor: NSCursor.pointingHand,
        ]
        let bodyFont = NSFont.preferredFont(forTextStyle: .body)
        textView.font = bodyFont
        textView.typingAttributes = [
            .font: bodyFont,
            .foregroundColor: NSColor.labelColor,
        ]
        textView.textContainerInset = NSSize(width: 1, height: 4)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 4
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CountrySummaryLinkTextView
        weak var textView: NSTextView?
        var isProgrammaticUpdate = false

        init(parent: CountrySummaryLinkTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if !isProgrammaticUpdate {
                parent.text = textView.string
            }
            reportHeight()
        }

        func reportHeight() {
            guard let textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer
            else { return }

            layoutManager.ensureLayout(for: textContainer)
            let used = layoutManager.usedRect(for: textContainer)
            let inset = textView.textContainerInset
            let measured = used.height + inset.height * 2
            let nextHeight = max(36, ceil(measured))
            if abs(parent.height - nextHeight) > 0.5 {
                parent.height = nextHeight
            }
        }
    }
}
