import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {

    private var scrollView: NSScrollView!
    private var textView: NSTextView!

    override func loadView() {
        let frame = NSRect(x: 0, y: 0, width: 800, height: 600)

        scrollView = NSScrollView(frame: frame)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]

        textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 30, height: 30)
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true

        scrollView.documentView = textView
        self.view = scrollView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let markdown = try String(contentsOf: url, encoding: .utf8)
                let attributed = MarkdownAttributedRenderer.render(markdown)
                DispatchQueue.main.async {
                    self.textView.textStorage?.setAttributedString(attributed)
                    handler(nil)
                }
            } catch {
                DispatchQueue.main.async { handler(error) }
            }
        }
    }
}
