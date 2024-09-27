//
//  ResourceLoader.swift
//  markdown-webview
//
//  Created by Zabir Raihan on 27/09/2024.
//

import Foundation

class ResourceLoader {
    static let shared = ResourceLoader()
    private init() {}

    lazy var templateString: String = Self.loadResource(named: "template", withExtension: "html")
    lazy var clipboardScript: String = Self.loadResource(named: "script", withExtension: "js")
    lazy var defaultStylesheet: String = Self.loadResource(named: Self.getDefaultStylesheetFileName(), withExtension: "css")
    lazy var style: String = Self.loadResource(named: "commonStyle", withExtension: "css")
    
    lazy var customStylesheets: [MarkdownTheme: String] = Dictionary(uniqueKeysWithValues: MarkdownTheme.allCases.map {
        ($0, Self.loadResource(named: $0.fileName, withExtension: "css"))
    })

    private var cachedHTMLString: String?

    private static func loadResource(named name: String, withExtension ext: String) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            print("Failed to find resource: \(name).\(ext)")
            return ""
        }
        do {
            return try String(contentsOf: url)
        } catch {
            print("Failed to load resource \(name).\(ext): \(error)")
            return ""
        }
    }

    func getCachedHTMLString(for customStylesheet: MarkdownTheme) -> String {
        if cachedHTMLString == nil {
            let customStylesheetContent = customStylesheets[customStylesheet] ?? ""
            let combinedStylesheet = defaultStylesheet + "\n" + customStylesheetContent + "\n" + style

            let replacements = [
                "PLACEHOLDER_SCRIPT": clipboardScript,
                "PLACEHOLDER_STYLESHEET": combinedStylesheet
            ]

            var htmlString = templateString
            for (placeholder, replacement) in replacements {
                htmlString = htmlString.replacingOccurrences(of: placeholder, with: replacement)
            }
            
            cachedHTMLString = htmlString
        }
        
        return cachedHTMLString! // TODO: use if let or guard let
    }
    
    private static func getDefaultStylesheetFileName() -> String {
        #if os(macOS) || targetEnvironment(macCatalyst)
            return "default-macOS"
        #else
            return "default-iOS"
        #endif
    }
}
