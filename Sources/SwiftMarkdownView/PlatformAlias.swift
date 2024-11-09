//
//  PlatformAlias.swift
//  SwiftMarkdownView
//
//  Created by Zabir Raihan on 09/11/2024.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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

#if os(macOS)
typealias PlatformView = NSView
#else
typealias PlatformView = UIView
#endif

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif
