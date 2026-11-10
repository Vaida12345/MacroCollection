//
//  AttributeDeclMacro.swift
//  MacroCollection
//
//  Created by Vaida on 2024/2/24.
//

#if canImport(SwiftUI)
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import MacroEssentials


public enum AttributeDeclMacro: DeclarationMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, 
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let macroName: String
        let arguments: LabeledExprListSyntax
        
        if let declaration = node.as(MacroExpansionExprSyntax.self) {
            macroName = declaration.macroName.text
            arguments = declaration.arguments
        } else if let declaration = node.as(MacroExpansionDeclSyntax.self) {
            macroName = declaration.macroName.text
            arguments = declaration.arguments
        } else {
            throw DiagnosticsError("Expected a macro expansion", highlighting: node)
        }
        
        let wrapperName = macroName.frontToUpper()
        
        if arguments.allSatisfy({ $0.expression.is(KeyPathExprSyntax.self) }) { // key path
            return try arguments.map { argument in
                guard let expression = argument.expression.as(KeyPathExprSyntax.self) else { throw DiagnosticsError("Expression is invalid", highlighting: argument) }
                guard expression.components.count == 1, let component = expression.components.first?.component else { throw DiagnosticsError("Nested key path is not supported", highlighting: argument) }
                guard let property = component.as(KeyPathPropertyComponentSyntax.self) else { throw DiagnosticsError("Only property key path is supported", highlighting: argument) }
                
                let identifier = property.declName
                return DeclSyntax("@\(raw: wrapperName)(\\.\(identifier)) private var \(identifier)")
            }
        } else if arguments.allSatisfy({ $0.expression.is(MemberAccessExprSyntax.self) }) { // Model.self
            
            return try arguments.map { argument in
                guard let type = argument.expression.referencedType, let name = type.referencedName else { throw DiagnosticsError("Expected type reference", highlighting: argument) }
                
                return DeclSyntax("@\(raw: wrapperName)(\(type).self) private var \(raw: name.frontToLower())")
            }
        } else {
            if arguments.count > 1 {
                throw DiagnosticsError("Mixing argument types is not allowed", highlighting: node)
            } else {
                throw DiagnosticsError("Unsupported arguments", highlighting: node)
            }
        }
    }
    
    
}


private extension TypeSyntax {
    
    /// The name of the type, without the types it is nested in, ie, `Provider` for `Namespace.Provider`.
    var referencedName: String? {
        if let type = self.as(IdentifierTypeSyntax.self) { return type.name.text }
        if let type = self.as(MemberTypeSyntax.self) { return type.name.text }
        
        return nil
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
