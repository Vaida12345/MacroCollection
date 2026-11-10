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
import MacroEssentials


public enum varyArgumentType: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        if let declaration = declaration.as(FunctionDeclSyntax.self) {
            return [DeclSyntax(try variation(of: declaration, signature: \.signature, genericWhereClause: \.genericWhereClause, node: node))]
        } else if let declaration = declaration.as(InitializerDeclSyntax.self) {
            return [DeclSyntax(try variation(of: declaration, signature: \.signature, genericWhereClause: \.genericWhereClause, node: node))]
        } else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.asProtocol((any WithAttributesSyntax).self)?.attributes, node: node, message: "`@varyArgumentType` does not work on this type of declaration.")
        }
    }
    
    /// Creates the copy of the declaration, whose parameters declared as the source type take the destination type instead.
    ///
    /// A default value is not carried over, as it is written for the source type.
    private static func variation<Declaration>(
        of declaration: Declaration,
        signature: WritableKeyPath<Declaration, FunctionSignatureSyntax>,
        genericWhereClause: KeyPath<Declaration, GenericWhereClauseSyntax?>,
        node: AttributeSyntax
    ) throws -> Declaration where Declaration: DeclSyntaxProtocol & WithAttributesSyntax {
        guard declaration[keyPath: genericWhereClause] == nil else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "`@varyArgumentType` does not work with generics")
        }
        
        guard let source = node.argumentList.first?.expression.referencedType,
              let destination = node.argumentList.last?.expression.referencedType
        else { throw DiagnosticsError("Expected the types to vary, eg, `String.self`.", highlighting: node) }
        
        var parameters = declaration[keyPath: signature].parameterClause.parameters
        var isVaried = false
        for index in parameters.indices where parameters[index].type.trimmedDescription == source.trimmedDescription {
            parameters[index].type = destination
            parameters[index].defaultValue = nil
            isVaried = true
        }
        
        guard isVaried else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "No parameter is declared as `\(source.trimmedDescription)`, hence there is nothing to vary")
        }
        
        var copy = declaration
        copy[keyPath: signature].parameterClause.parameters = parameters
        copy.attributes = copy.attributes.filter { element in
            guard case .attribute(let attribute) = element else { return true }
            return attribute.baseName != "varyArgumentType"
        }
        
        return copy
    }
    
}
