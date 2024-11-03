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
    private var plainTextView: NSTextView?
    
    override public var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width, height: contentHeight)
    }
    
    func showPlainTextContent(_ content: String) {
        if plainTextView == nil {
            plainTextView = NSTextView(frame: bounds)
            plainTextView?.drawsBackground = false
            plainTextView?.isEditable = false
            plainTextView?.isSelectable = false
            plainTextView?.autoresizingMask = [.width]
            plainTextView?.font = NSFont.systemFont(ofSize: NSFont.systemFontSize + 0.5)
            // invisible text
            plainTextView?.textColor = NSColor.clear
            // text color is slightly less bright than the default text color
//            plainTextView?.textColor = NSColor(calibratedWhite: 0.8, alpha: 0)
            plainTextView?.textContainer?.lineFragmentPadding = 0
            plainTextView?.textContainerInset = NSSize(width: 0, height: 9)
        }
        
        plainTextView?.string = content
        addSubview(plainTextView!)
        
        if let plainTextView = plainTextView,
           let textContainer = plainTextView.textContainer,
           let layoutManager = plainTextView.layoutManager {
            // Calculate total padding
            let insetWidth = plainTextView.textContainerInset.width * 2
            let fragmentPadding = textContainer.lineFragmentPadding * 2
            let totalPadding = insetWidth + fragmentPadding
            
            // Set the container size to the available width minus padding and infinite height
            let containerWidth = bounds.width - totalPadding
            textContainer.containerSize = CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude)
            
            // Force layout
            layoutManager.ensureLayout(for: textContainer)
            
            // Get used rectangle
            let usedRect = layoutManager.usedRect(for: textContainer)
            let newHeight = usedRect.height + plainTextView.textContainerInset.height * 2
            
            // Update frame
            plainTextView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: newHeight)
            
            // Update the content height and invalidate intrinsic content size
            contentHeight = newHeight
            invalidateIntrinsicContentSize()
            
            // Notify the parent view that our size has changed
            superview?.needsLayout = true
        }
    }
     
     func hidePlainTextContent() {
//         DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
         self.plainTextView?.removeFromSuperview()
         self.invalidateIntrinsicContentSize()
         self.superview?.needsLayout = true
//         }
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

    func updateMarkdownContent(_ markdownContent: String, highlightString: String, fontSize: CGFloat) {
        let data: [String: Any] = [
            "markdownContent": markdownContent,
            "highlightString": highlightString,
            "fontSize": fontSize
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                callAsyncJavaScript("window.updateWithMarkdownContent(\(jsonString))", in: nil, in: .page, completionHandler: nil)
            }
        } catch {
            print("Error converting to JSON: \(error)")
        }
        
        evaluateJavaScript("document.body.scrollHeight", in: nil, in: .page) { result in
            guard let contentHeight = try? result.get() as? Double else { return }
            self.contentHeight = contentHeight
            self.invalidateIntrinsicContentSize()
        }
    }
}
