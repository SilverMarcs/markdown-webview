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
    
    @Environment(\.markdownFontSize) var fontSize
    @Environment(\.markdownTheme) var customStylesheet
    @Environment(\.markdownHighlightString) var highlightString
    @Environment(\.markdownBaseURL) var baseURL

    public init(_ markdownContent: String) {
        self.markdownContent = markdownContent
    }

    public func makeCoordinator() -> Coordinator { .init(parent: self) }

    #if os(macOS)
    public func makeNSView(context: Context) -> CustomWebView { context.coordinator.platformView }
    #else
    public func makeUIView(context: Context) -> CustomWebView { context.coordinator.platformView }
    #endif

    public func updatePlatformView(_ platformView: CustomWebView, context _: Context) {
        guard !platformView.isLoading else { return }
        
//        if let customStylesheetFileURL = Bundle.module.url(forResource: self.customStylesheet.fileName, withExtension: ""),
//           let customStylesheet = try? String(contentsOf: customStylesheetFileURL) {
//            platformView.updateStylesheet(customStylesheet)
//        }
        
        platformView.updateMarkdownContent(markdownContent, highlightString: highlightString, fontSize: fontSize)
    }

    #if os(macOS)
    public func updateNSView(_ nsView: CustomWebView, context: Context) { updatePlatformView(nsView, context: context) }
    #else
    public func updateUIView(_ uiView: CustomWebView, context: Context) { updatePlatformView(uiView, context: context) }
    #endif
}
