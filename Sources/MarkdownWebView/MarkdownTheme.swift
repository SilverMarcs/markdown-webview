//
//  MarkdownTheme.swift
//  markdown-webview
//
//  Created by Zabir Raihan on 27/09/2024.
//

import Foundation

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
