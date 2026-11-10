//
//  encodeOptions.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import MacroEssentials
import SwiftDiagnostics


public enum encodeOptions: PeerMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "@\(node.attributeName) can only attached to a variable declaration")
        }
        
        for property in variable.properties {
            
            if property.isStatic {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a static property")
            } else if property.storage == .computed {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a computed property")
            } else if property.isConstant && property.initializer != nil {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a constant that cannot be changed")
            }
        }
        
        if !isWithinCodable(context: context) {
            context.diagnose(Diagnostic(
                node: node,
                message: .diagnostic(message: "@\(node.attributeName.trimmed) is ignored outside of a type annotated with @codable", diagnosticID: "notWithinCodable", severity: .warning)
            ))
        }
        
        return [] // the macro itself does nothing
    }
    
    /// Whether the type declaring the property is annotated with `@codable`, which reads the options.
    private static func isWithinCodable(context: some MacroExpansionContext) -> Bool {
        guard let type = context.lexicalContext.lazy.compactMap({ $0.asProtocol((any DeclGroupSyntax).self) }).first else { return false }
        
        return type.attributes.contains { element in
            guard case .attribute(let attribute) = element else { return false }
            return attribute.baseName == "codable"
        }
    }
    
}
