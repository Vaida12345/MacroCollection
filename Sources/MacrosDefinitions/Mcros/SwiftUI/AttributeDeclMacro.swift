//
//  environment.swift
//  NucleusMacros
//
//  Created by Vaida on 2024/2/24.
//

#if canImport(SwiftUI)
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling


public enum AttributeDeclMacro: DeclarationMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, 
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declaration = node.as(MacroExpansionExprSyntax.self) else { fatalError("Swift Macro Error: input node is not a macro.") }
        let macroName = declaration.macroName.text
        let wrapperName = macroName.frontToUpper()
        
        let arguments = declaration.arguments
        
        // key path
        if arguments.allSatisfy({ $0.expression.is(KeyPathExprSyntax.self) }) {
            return try arguments.map { argument in
                guard let expression = argument.expression.as(KeyPathExprSyntax.self) else { throw DiagnosticsError("Expression is invalid", highlighting: argument) }
                guard expression.components.count == 1, let component = expression.components.first?.component else { throw DiagnosticsError("Nested key path is not supported", highlighting: argument) }
                guard let property = component.as(KeyPathPropertyComponentSyntax.self) else { throw DiagnosticsError("Only property key path is supported", highlighting: argument) }
                
                let identifier = property.declName
                return DeclSyntax("@\(raw: wrapperName)(\\.\(identifier)) private var \(identifier)")
            }
        } else if arguments.allSatisfy({ $0.expression.is(MemberAccessExprSyntax.self) }) {
            
            return try arguments.map { argument in
                guard let expression = argument.expression.as(MemberAccessExprSyntax.self) else { throw DiagnosticsError("Expression is invalid", highlighting: argument) }
                guard expression.declName.baseName.isEqual(to: "self") else { throw DiagnosticsError("Expected type reference", highlighting: argument) }
                
                guard let identifier = expression.base?.as(DeclReferenceExprSyntax.self) else { throw DiagnosticsError("Expected type reference", highlighting: argument) }
                
                return DeclSyntax("@\(raw: wrapperName)(\(identifier).self) private var \(raw: identifier.baseName.text.frontToLower())")
            }
        } else {
            if arguments.count > 1 {
                throw DiagnosticsError("Mixing argument types is not allowed", highlighting: declaration)
            } else {
                throw DiagnosticsError("Unsupported arguments", highlighting: declaration)
            }
        }
    }
    
    
}


internal extension String {
    func frontToLower() -> String {
        guard !self.isEmpty else { return "" }
        return self.replacingCharacters(in: self.startIndex..<self.index(after: self.startIndex), with: self.first!.lowercased())
    }
    func frontToUpper() -> String {
        guard !self.isEmpty else { return "" }
        return self.replacingCharacters(in: self.startIndex..<self.index(after: self.startIndex), with: self.first!.uppercased())
    }
}

#endif
