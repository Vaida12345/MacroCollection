//
//  url.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros


public enum url: ExpressionMacro {
    
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
        
        if URL(string: segment.content.text) != nil {
            return "URL(string: \(argument))!"
        } else {
            throw MacroError.notURL
        }
    }
    
    
    enum MacroError: CustomStringConvertible, Error {
        case notURL
        
        var description: String {
            switch self {
            case .notURL:
                "The given string is not an url."
            }
        }
    }
    
}
