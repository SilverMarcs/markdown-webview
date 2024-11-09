import SwiftUI
import WebKit

@available(macOS 11.0, iOS 14.0, *)
public struct SwiftMarkdownView: PlatformViewRepresentable {
    var markdownContent: String
    
    @Environment(\.markdownFontSize) var fontSize
    @Environment(\.markdownHighlightString) var highlightString
    @Environment(\.markdownBaseURL) var baseURL
    @Environment(\.renderSkeleton) var renderSkeleton

    public init(_ markdownContent: String) {
        self.markdownContent = markdownContent
    }

    public func makeCoordinator() -> Coordinator { .init(parent: self) }
    
    public func updatePlatformView(_ platformView: CustomWebView, context _: Context) {
        guard !platformView.isLoading else { return }
        platformView.updateMarkdownContent(markdownContent, highlightString: highlightString, fontSize: fontSize, renderSkeleton: renderSkeleton)
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> CustomWebView { context.coordinator.platformView }
    public func updateNSView(_ nsView: CustomWebView, context: Context) { updatePlatformView(nsView, context: context) }
    #else
    public func makeUIView(context: Context) -> CustomWebView { context.coordinator.platformView }
    public func updateUIView(_ uiView: CustomWebView, context: Context) { updatePlatformView(uiView, context: context) }
    #endif
}
