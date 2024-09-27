import SwiftUI
import WebKit

#if os(macOS)
    typealias PlatformViewRepresentable = NSViewRepresentable
#else
    typealias PlatformViewRepresentable = UIViewRepresentable
#endif

@available(macOS 11.0, iOS 14.0, *)
public struct MarkdownWebView: PlatformViewRepresentable {
    var markdownContent: String
    let customStylesheet: MarkdownTheme
    let highlightString: String? // Pass if want to highlight substrings
    let baseURL: String // Shows up on activity monitor
    let fontSize: CGFloat

    public init(
        _ markdownContent: String,
        baseURL: String = "Web Content",
        highlightString: String? = nil,
        customStylesheet: MarkdownTheme = .atom,
        fontSize: CGFloat = 13
    ) {
        self.markdownContent = markdownContent
        self.customStylesheet = customStylesheet
        self.highlightString = highlightString
        self.baseURL = baseURL
        self.fontSize = fontSize
    }

    public func makeCoordinator() -> Coordinator { .init(parent: self) }

    #if os(macOS)
        public func makeNSView(context: Context) -> CustomWebView { context.coordinator.platformView }
    #else
        public func makeUIView(context: Context) -> CustomWebView { context.coordinator.platformView }
    #endif

    public func updatePlatformView(_ platformView: CustomWebView, context _: Context) {
        guard !platformView.isLoading else { return }
        
        // Load the new stylesheet
//        if let customStylesheetFileURL = Bundle.module.url(forResource: self.customStylesheet.fileName, withExtension: ""),
//           let customStylesheet = try? String(contentsOf: customStylesheetFileURL) {
//            platformView.updateStylesheet(customStylesheet)
//        }
//        
        platformView.updateMarkdownContent(markdownContent, highlightString: highlightString, fontSize: fontSize)
    }

    #if os(macOS)
        public func updateNSView(_ nsView: CustomWebView, context: Context) { updatePlatformView(nsView, context: context) }
    #else
        public func updateUIView(_ uiView: CustomWebView, context: Context) { updatePlatformView(uiView, context: context) }
    #endif
}
