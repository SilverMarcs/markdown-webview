//
//  MarkdownFontSizeKey.swift
//  markdown-webview
//
//  Created by Zabir Raihan on 16/10/2024.
//


import SwiftUI

private struct MarkdownFontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 13
}

private struct MarkdownHighlightStringKey: EnvironmentKey {
    static let defaultValue: String = ""
}

private struct MarkdownBaseURLKey: EnvironmentKey {
    static let defaultValue: String = "Web Content"
}

private struct RenderSkeletonKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var markdownFontSize: CGFloat {
        get { self[MarkdownFontSizeKey.self] }
        set { self[MarkdownFontSizeKey.self] = newValue }
    }
    
    var markdownHighlightString: String {
        get { self[MarkdownHighlightStringKey.self] }
        set { self[MarkdownHighlightStringKey.self] = newValue }
    }
    
    var markdownBaseURL: String {
        get { self[MarkdownBaseURLKey.self] }
        set { self[MarkdownBaseURLKey.self] = newValue }
    }
    
    var renderSkeleton: Bool {
        get { self[RenderSkeletonKey.self] }
        set { self[RenderSkeletonKey.self] = newValue }
    }
}

extension View {
    public func markdownFontSize(_ size: CGFloat) -> some View {
        environment(\.markdownFontSize, size)
    }
    
    public func markdownHighlightString(_ string: String) -> some View {
        environment(\.markdownHighlightString, string)
    }
    
    public func markdownBaseURL(_ url: String) -> some View {
        environment(\.markdownBaseURL, url)
    }
    
    public func renderSkeleton(_ render: Bool) -> some View {
        environment(\.renderSkeleton, render)
    }
}
