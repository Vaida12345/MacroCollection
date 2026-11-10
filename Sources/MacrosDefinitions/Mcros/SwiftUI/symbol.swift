//
//  symbol.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import MacroEssentials
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif


public enum symbol: ExpressionMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        let (argument, name) = try node.stringLiteralArgument()
        
#if canImport(UIKit)
        guard UIImage(systemName: name) != nil else { throw DiagnosticsError("No such symbol `\(name)`.", highlighting: argument) }
#else
        guard NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil else { throw DiagnosticsError("No such symbol `\(name)`.", highlighting: argument) }
#endif
        
        return argument
    }
    
}
