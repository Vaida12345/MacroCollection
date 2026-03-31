//
//  url.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros


@available(macOS 14.0, iOS 17.0, watchOS 10.0, *)
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
        
        if URL(string: segment.content.text, encodingInvalidCharacters: true) != nil {
            return "URL(string: \(argument), encodingInvalidCharacters: true)!"
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
