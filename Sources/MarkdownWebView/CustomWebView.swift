//
//  CustomWebView.swift
//  markdown-webview
//
//  Created by Zabir Raihan on 27/09/2024.
//

import WebKit
import SwiftUI

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
