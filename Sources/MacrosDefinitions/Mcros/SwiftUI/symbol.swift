//
//  symbol.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftUI


public enum symbol: ExpressionMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.arguments.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let segment)? = segments.first
        else {
            fatalError("Compiler Bug: The passed argument is not static string")
        }
        
        let name = segment.content.text
        
#if canImport(UIKit)
        guard UIImage(systemName: name) != nil else { throw MacroError.noSuchSymbol(name) }
#else
        guard NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil else { throw MacroError.noSuchSymbol(name) }
#endif
        
        return argument
    }
    
    
    enum MacroError: CustomStringConvertible, Error {
        case noSuchSymbol(String)
        
        var description: String {
            switch self {
            case let .noSuchSymbol(string):
                "No such symbol `\(string)`."
            }
        }
    }
    
}
