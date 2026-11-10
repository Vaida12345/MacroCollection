//
//  varyArgumentType.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling
import MacroEssentials


public enum varyArgumentType: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        if let declaration = declaration.as(FunctionDeclSyntax.self) {
            guard declaration.genericWhereClause == nil else {
                throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "`@varyArgumentType` does not work with generics")
            }
            
            guard let source = node.argumentList.first?.expression.referencedType,
                  let dest = node.argumentList.last?.expression.referencedType
            else { throw DiagnosticsError("Expected the types to vary, eg, `String.self`.", highlighting: node) }
            
            var parameters = declaration.signature.parameterClause.parameters
            var index = parameters.startIndex
            
            while index < parameters.endIndex {
                let parameter = parameters[index]
                if parameter.type.trimmedDescription == source.description {
                    parameters[index].type = dest
                }
                
                parameters.formIndex(after: &index)
            }
            
            var decl = declaration
            while let index = decl.attributes.firstIndex(where: { $0.as(AttributeSyntax.self)?.attributeName.description == "varyArgumentType" }) {
                decl.attributes.remove(at: index)
            }
            
            decl.signature.parameterClause.parameters = parameters
            return [DeclSyntax(decl)]
        } else if let declaration = declaration.as(InitializerDeclSyntax.self) {
            guard declaration.genericWhereClause == nil else {
                throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "`@varyArgumentType` does not work with generics")
            }
            
            guard let source = node.argumentList.first?.expression.referencedType,
                  let dest = node.argumentList.last?.expression.referencedType
            else { throw DiagnosticsError("Expected the types to vary, eg, `String.self`.", highlighting: node) }
            
            var parameters = declaration.signature.parameterClause.parameters
            var index = parameters.startIndex
            
            while index < parameters.endIndex {
                let parameter = parameters[index]
                if parameter.type.trimmedDescription == source.description {
                    parameters[index].type = dest
                }
                
                parameters.formIndex(after: &index)
            }
            
            var decl = declaration
            while let index = decl.attributes.firstIndex(where: { $0.as(AttributeSyntax.self)?.attributeName.description == "varyArgumentType" }) {
                decl.attributes.remove(at: index)
            }
            
            decl.signature.parameterClause.parameters = parameters
            return [DeclSyntax(decl)]
        } else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "`@varyArgumentType` does not work on this type of declaration.")
        }
    }
    
}
