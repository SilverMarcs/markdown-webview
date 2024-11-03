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
    lazy var style: String = Self.loadResource(named: Self.styleSheetFileName, withExtension: "css")

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

    func getCachedHTMLString() -> String {
        if cachedHTMLString == nil {
            let replacements = [
                "PLACEHOLDER_SCRIPT": clipboardScript,
                "PLACEHOLDER_STYLESHEET": style
            ]

            var htmlString = templateString
            for (placeholder, replacement) in replacements {
                htmlString = htmlString.replacingOccurrences(of: placeholder, with: replacement)
            }
            
            cachedHTMLString = htmlString
        }
        
        return cachedHTMLString!
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    static let styleSheetFileName = "default-macOS"
    #else
    static let styleSheetFileName = "default-iOS"
    #endif
}
