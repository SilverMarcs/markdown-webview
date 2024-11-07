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
    var skeletonLayer: CAShapeLayer?
    
    override public var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width, height: contentHeight)
    }
    
    func showPlainTextContent(_ content: String) {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(containerSize: CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let textStorage = NSTextStorage(string: content)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        
    let font = NSFont.systemFont(ofSize: NSFont.systemFontSize + 2.3)
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
        
        // Create and add the skeleton layer
        DispatchQueue.main.async {
            self.createSkeletonLayer()
        }
        
        // Notify the parent view that our size has changed
        superview?.needsLayout = true
    }
    
    private func createSkeletonLayer() {
        // Remove existing skeleton layer if any
        skeletonLayer?.removeFromSuperlayer()
        
        // Create a new container layer
        let containerLayer = CAShapeLayer()
        containerLayer.frame = bounds
        
        let blockHeight: CGFloat = 16
        let blockSpacing: CGFloat = 8
        let horizontalPadding: CGFloat = 16
        let availableWidth = bounds.width - (2 * horizontalPadding)
        
        var yPosition: CGFloat = blockSpacing
        
        while yPosition < contentHeight - blockHeight {
            // Full-width block
            let fullWidthBlock = createSkeletonBlock(
                x: horizontalPadding,
                y: yPosition,
                width: availableWidth,
                height: blockHeight
            )
            containerLayer.addSublayer(fullWidthBlock)
            yPosition += blockHeight + blockSpacing
            
            // Two half-width blocks
            if yPosition < contentHeight - blockHeight {
                let halfWidth = (availableWidth - blockSpacing) / 2
                let leftBlock = createSkeletonBlock(
                    x: horizontalPadding,
                    y: yPosition,
                    width: halfWidth,
                    height: blockHeight
                )
                containerLayer.addSublayer(leftBlock)
                
                let rightBlock = createSkeletonBlock(
                    x: horizontalPadding + halfWidth + blockSpacing,
                    y: yPosition,
                    width: halfWidth,
                    height: blockHeight
                )
                containerLayer.addSublayer(rightBlock)
                yPosition += blockHeight + blockSpacing
            }
            
            // Shorter block
            if yPosition < contentHeight - blockHeight {
                let shortBlockWidth = availableWidth * 0.6
                let shortBlock = createSkeletonBlock(
                    x: horizontalPadding,
                    y: yPosition,
                    width: shortBlockWidth,
                    height: blockHeight
                )
                containerLayer.addSublayer(shortBlock)
                yPosition += blockHeight + blockSpacing
            }
        }
        
        // Add the container layer to the view
        layer?.addSublayer(containerLayer)
        skeletonLayer = containerLayer
    }
    
    private func createSkeletonBlock(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CAShapeLayer {
        let block = CAShapeLayer()
        block.frame = CGRect(x: x, y: y, width: width, height: height)
        block.backgroundColor = NSColor.lightGray.withAlphaComponent(0.3).cgColor
        block.cornerRadius = 4
        return block
    }
    
    func hideSkeletonLayer() {
        guard let skeletonLayer = skeletonLayer else { return }
        
        // Create a fade out animation
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = 0.2 // Adjust duration as needed
        
        // Set the final state
        skeletonLayer.opacity = 0.0
        
        // Add the animation to the layer
        skeletonLayer.add(fadeOutAnimation, forKey: "fadeOut")
        
        // Remove the layer after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutAnimation.duration) {
            skeletonLayer.removeFromSuperlayer()
            self.skeletonLayer = nil
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
