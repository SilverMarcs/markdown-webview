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
    var skeletonView: SkeletonView?
    
    override public var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width, height: contentHeight)
    }
    
    func showPlainTextContent(_ content: String) {
        let layoutManager = NSLayoutManager()
        #if os(macOS)
        let textContainer = NSTextContainer(containerSize: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        #else
        let textContainer = NSTextContainer(size: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        #endif
        let textStorage = NSTextStorage(string: content)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        
        let font = PlatformFont.systemFont(ofSize: PlatformFont.systemFontSize + 3) // extra size since webview text includes styling that takes up more space
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        textStorage.setAttributes(attributes, range: NSRange(location: 0, length: textStorage.length))
        
        layoutManager.ensureLayout(for: textContainer)
        
        let usedRect = layoutManager.usedRect(for: textContainer)
        let newHeight = usedRect.height
        
        // Update the content height and invalidate intrinsic content size
        contentHeight = newHeight
        invalidateIntrinsicContentSize()
        
        // Create and add the skeleton layer TODO: explore if this is necessary
//        DispatchQueue.main.async {
//            self.showSkeletonView()
//        }
        
        // Notify the parent view that our size has changed
        #if os(macOS)
        superview?.needsLayout = true
        #else
        superview?.setNeedsLayout()
        #endif
    }
    
    func showSkeletonView() {
        if skeletonView == nil {
            skeletonView = SkeletonView(frame: bounds)
            addSubview(skeletonView!)
        }
        
        skeletonView?.alphaValue = 1.0 // Ensure full opacity when showing
        skeletonView?.updateSkeleton(for: contentHeight)
        skeletonView?.isHidden = false
    }
    
    func hideSkeletonView() {
        guard let skeletonView = skeletonView, !skeletonView.isHidden else { return }
        
        skeletonView.fadeOut {
            skeletonView.isHidden = true
             skeletonView.removeFromSuperview()
             self.skeletonView = nil
        }
    }
    
    /// Disables scrolling.
    #if os(macOS)
    override public func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        nextResponder?.scrollWheel(with: event)
    }

    /// Removes "Reload" from the context menu.
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

#if os(macOS)
typealias PlatformColor = NSColor
#else
typealias PlatformColor = UIColor
#endif

#if os(macOS)
typealias PlatformFont = NSFont
#else
typealias PlatformFont = UIFont
#endif

class SkeletonView: NSView {
    private var blockRects: [CGRect] = []
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let color = NSColor.lightGray.withAlphaComponent(0.3).cgColor
        context.setFillColor(color)
        
        for rect in blockRects {
            let path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            context.addPath(path)
            context.fillPath()
        }
    }
    
    func updateSkeleton(for contentHeight: CGFloat) {
        let blockHeight: CGFloat = 16
        let blockSpacing: CGFloat = 8
        let horizontalPadding: CGFloat = 16
        let availableWidth = bounds.width - (2 * horizontalPadding)
        
        var yPosition: CGFloat = blockSpacing
        var newBlockRects: [CGRect] = []
        
        while yPosition < contentHeight - blockHeight {
            let rect = CGRect(x: horizontalPadding, y: yPosition, width: availableWidth, height: blockHeight)
            newBlockRects.append(rect)
            yPosition += blockHeight + blockSpacing
        }
        
        blockRects = newBlockRects
        setNeedsDisplay(bounds)
    }
    
    func fadeOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 0
        }, completionHandler: completion)
    }
}
