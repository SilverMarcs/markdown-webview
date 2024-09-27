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
    let customStylesheet: MarkdownTheme // New property for the custom stylesheet
    let linkActivationHandler: ((URL) -> Void)?
    let renderedContentHandler: ((String) -> Void)?
    let highlightString: String? // New property for the highlight string
    let baseURL: String // Shows up on activity monitor
    let fontSize: CGFloat

    public init(_ markdownContent: String, baseURL: String = "Web Content", highlightString: String? = nil, customStylesheet: MarkdownTheme = .atom, fontSize: CGFloat = 13) {
        self.markdownContent = markdownContent
        self.customStylesheet = customStylesheet
        self.highlightString = highlightString
        self.baseURL = baseURL
        self.fontSize = fontSize
        linkActivationHandler = nil
        renderedContentHandler = nil
    }

    init(_ markdownContent: String, baseURL: String = "Web Content", highlightString: String?, customStylesheet: MarkdownTheme = .atom, fontSize: CGFloat, linkActivationHandler: ((URL) -> Void)?, renderedContentHandler: ((String) -> Void)?) {
        self.markdownContent = markdownContent
        self.customStylesheet = customStylesheet
        self.linkActivationHandler = linkActivationHandler
        self.renderedContentHandler = renderedContentHandler
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

    public func onLinkActivation(_ linkActivationHandler: @escaping (URL) -> Void) -> Self {
        .init(markdownContent, baseURL: baseURL, highlightString: highlightString, customStylesheet: customStylesheet, fontSize: fontSize, linkActivationHandler: linkActivationHandler, renderedContentHandler: renderedContentHandler)
    }

    public func onRendered(_ renderedContentHandler: @escaping (String) -> Void) -> Self {
        .init(markdownContent, baseURL: baseURL, highlightString: highlightString, customStylesheet: customStylesheet, fontSize: fontSize, linkActivationHandler: linkActivationHandler, renderedContentHandler: renderedContentHandler)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        let parent: MarkdownWebView
        let platformView: CustomWebView

        init(parent: MarkdownWebView) {
            self.parent = parent
            platformView = .init()
            super.init()

            platformView.navigationDelegate = self

            #if DEBUG && !os(macOS)
                if #available(iOS 16.4, *) {
                    self.platformView.isInspectable = true
                }
            #endif

            platformView.setContentHuggingPriority(.required, for: .vertical)

            #if !os(macOS)
                platformView.scrollView.isScrollEnabled = false
            #endif

            #if os(macOS)
                platformView.setValue(false, forKey: "drawsBackground")
            #else
                platformView.isOpaque = false
            #endif

            let defaultStylesheetFileName = self.getDefaultStylesheetFileName()

            let resources = ResourceLoader.shared
            let customStylesheet = resources.customStylesheets[parent.customStylesheet] ?? ""
            let combinedStylesheet = resources.defaultStylesheet + "\n" + customStylesheet + "\n" + resources.style

            let htmlString = resources.templateString
                .replacingOccurrences(of: "PLACEHOLDER_SCRIPT", with: resources.clipboardScript)
                .replacingOccurrences(of: "PLACEHOLDER_STYLESHEET", with: combinedStylesheet)

            let baseURL = URL(string: parent.baseURL)
            platformView.loadHTMLString(htmlString, baseURL: baseURL)
        }

        private func getDefaultStylesheetFileName() -> String {
            #if os(macOS) || targetEnvironment(macCatalyst)
                return "default-macOS"
            #else
                return "default-iOS"
            #endif
        }

        private func loadResources(defaultStylesheetFileName: String) -> (templateString: String, clipboardScript: String, defaultStylesheet: String, customStylesheet: String, style: String)? {
            guard let templateFileURL = Bundle.module.url(forResource: "template", withExtension: "html"),
                  let templateString = try? String(contentsOf: templateFileURL),
                  let clipboardScriptFileURL = Bundle.module.url(forResource: "script", withExtension: "js"),
                  let clipboardScript = try? String(contentsOf: clipboardScriptFileURL),
                  let defaultStylesheetFileURL = Bundle.module.url(forResource: defaultStylesheetFileName, withExtension: "css"),
                  let defaultStylesheet = try? String(contentsOf: defaultStylesheetFileURL),
                  let customStylesheetFileURL = Bundle.module.url(forResource: self.parent.customStylesheet.fileName, withExtension: "css"),
                  let customStylesheet = try? String(contentsOf: customStylesheetFileURL),
                  let styleFileURL = Bundle.module.url(forResource: "commonStyle", withExtension: "css"),
                  let style = try? String(contentsOf: styleFileURL)
            else {
                return nil
            }
            return (templateString, clipboardScript, defaultStylesheet, customStylesheet, style)
        }

        public func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            (webView as! CustomWebView).updateMarkdownContent(parent.markdownContent, highlightString: parent.highlightString, fontSize: parent.fontSize)
            
            self.parent.renderedContentHandler?("rendered")
        }

        public func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated {
                guard let url = navigationAction.request.url else { return .cancel }

                if let linkActivationHandler = parent.linkActivationHandler {
                    linkActivationHandler(url)
                } else {
                    #if os(macOS)
                        NSWorkspace.shared.open(url)
                    #else
                        DispatchQueue.main.async {
                            Task { await UIApplication.shared.open(url) }
                        }
                    #endif
                }

                return .cancel
            } else {
                return .allow
            }
        }
    }

    public class CustomWebView: WKWebView {
        var contentHeight: CGFloat = 0

        override public var intrinsicContentSize: CGSize {
            .init(width: super.intrinsicContentSize.width, height: contentHeight)
        }

        /// Disables scrolling.
        #if os(macOS)
            override public func scrollWheel(with event: NSEvent) {
                super.scrollWheel(with: event)
                nextResponder?.scrollWheel(with: event)
            }
        #endif

        /// Removes "Reload" from the context menu.
        #if os(macOS)
            override public func willOpenMenu(_ menu: NSMenu, with _: NSEvent) {
                menu.items.removeAll { $0.identifier == .init("WKMenuItemIdentifierReload") }
            }
        #endif

        func updateMarkdownContent(_ markdownContent: String, highlightString: String?, fontSize: CGFloat) {
            guard let markdownContentBase64Encoded = markdownContent.data(using: .utf8)?.base64EncodedString() else { return }
            
            let highlightStringBase64Encoded = highlightString?.data(using: .utf8)?.base64EncodedString() ?? ""

            callAsyncJavaScript("window.updateWithMarkdownContentBase64Encoded(`\(markdownContentBase64Encoded)`, `\(highlightStringBase64Encoded)`, \(fontSize))", in: nil, in: .page, completionHandler: nil)
            
            evaluateJavaScript("document.body.scrollHeight", in: nil, in: .page) { result in
                guard let contentHeight = try? result.get() as? Double else { return }
                self.contentHeight = contentHeight
                self.invalidateIntrinsicContentSize()
            }
        }
        
        func updateStylesheet(_ stylesheet: String) {
            let script = """
            (function() {
                var style = document.createElement('style');
                style.textContent = `\(stylesheet)`;
                document.head.appendChild(style);
            })();
            """
            evaluateJavaScript(script, completionHandler: nil)
        }

        #if os(macOS)
            override public func keyDown(with event: NSEvent) {
                nextResponder?.keyDown(with: event)
            }

            override public func keyUp(with event: NSEvent) {
                nextResponder?.keyUp(with: event)
            }

            override public func flagsChanged(with event: NSEvent) {
                nextResponder?.flagsChanged(with: event)
            }

        #else
            override public func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesBegan(presses, with: event)
                next?.pressesBegan(presses, with: event)
            }

            override public func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesEnded(presses, with: event)
                next?.pressesEnded(presses, with: event)
            }

            override public func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
                super.pressesChanged(presses, with: event)
                next?.pressesChanged(presses, with: event)
            }
        #endif
    }
}

public enum MarkdownTheme: String, Codable, CaseIterable {
    case github
    case atom
    case a11y
    case panda
    case paraiso
    case stackoverflow
    case tokyo
    
    var fileName: String {
        switch self {
        case .github:
            return "github"
        case .atom:
            return "atom"
        case .a11y:
            return "a11y"
        case .panda:
            return "panda"
        case .paraiso:
            return "paraiso"
        case .stackoverflow:
            return "stackoverflow"
        case .tokyo:
            return "tokyo"
        }
    }
    
    public var name: String {
        switch self {
        case .github:
            return "GitHub"
        case .atom:
            return "Atom One"
        case .a11y:
            return "A11Y"
        case .panda:
            return "Panda"
        case .paraiso:
            return "Paraiso"
        case .stackoverflow:
            return "StackOverflow"
        case .tokyo:
            return "Tokyo"
        }
    }
}

struct ResourceLoader {
    static let shared = ResourceLoader()

    let templateString: String
    let clipboardScript: String
    let defaultStylesheet: String
    let customStylesheets: [MarkdownTheme: String]
    let style: String

    private init() {
        templateString = ResourceLoader.loadResource(named: "template", withExtension: "html")
        clipboardScript = ResourceLoader.loadResource(named: "script", withExtension: "js")
        defaultStylesheet = ResourceLoader.loadResource(named: "default-macOS", withExtension: "css")
        style = ResourceLoader.loadResource(named: "commonStyle", withExtension: "css")
        
        customStylesheets = Dictionary(uniqueKeysWithValues: MarkdownTheme.allCases.map {
            ($0, ResourceLoader.loadResource(named: $0.fileName, withExtension: "css"))
        })
    }

    private static func loadResource(named name: String, withExtension ext: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext),
              let content = try? String(contentsOf: url) else {
            return ""
        }
        return content
    }
}
