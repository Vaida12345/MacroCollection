//
//  FreestandingMacroExpansionSyntax.swift
//  MacroCollection
//
//  Created by Vaida on 2026-11-10.
//

import SwiftSyntax
import SwiftDiagnostics
import MacroEssentials


internal extension FreestandingMacroExpansionSyntax {
    
    /// The first argument, which has to be a string literal.
    ///
    /// A `StaticString` parameter also accepts what the macro cannot read, eg, a constant holding a string literal.
    ///
    /// - Throws: A diagnostic highlighting the argument, if it is not a string literal.
    func stringLiteralArgument() throws -> (expression: ExprSyntax, value: String) {
        guard let argument = self.arguments.first?.expression, let value = argument.stringLiteralValue else {
            throw DiagnosticsError("Expected a string literal", highlighting: self.arguments.first.map(Syntax.init) ?? Syntax(self))
        }
        
        return (argument, value)
    }
    
}
