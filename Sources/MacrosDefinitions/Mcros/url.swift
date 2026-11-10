//
//  url.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import MacroEssentials


@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public enum url: ExpressionMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        let (argument, string) = try node.stringLiteralArgument()
        
        guard URL(string: string, encodingInvalidCharacters: true) != nil else {
            throw DiagnosticsError("The given string is not an url.", highlighting: argument)
        }
        
        return "URL(string: \(argument), encodingInvalidCharacters: true)!"
    }
    
}
