//
//  encodeOptions.swift
//  NucleusMacros
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
        
        for binding in variable.bindings {
            let type = PropertyType(of: variable)
            
            if type == .computed {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a computed property")
            } else if type.isStatic {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a static property")
            } else if (type == .staticConstant || type == .storedConstant) && binding.initializer != nil {
                throw DiagnosticsError.shouldRemoveMacro(attributes: variable.attributes, node: node, message: "@\(node.attributeName) cannot be applied to a constant that cannot be changed")
            }
        }
        
        return [] // the macro itself does nothing
    }
    
}
