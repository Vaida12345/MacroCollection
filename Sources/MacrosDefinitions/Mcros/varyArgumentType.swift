//
//  varyArgumentType.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling


public enum varyArgumentType: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declaration = declaration.as(FunctionDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "`@variateArgumentType` only works on functions")
        }
        guard declaration.genericWhereClause == nil else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: nil, node: node, message: "`@variateArgumentType` does not work with generics")
        }
        
        guard let attributeArgList = node.arguments?.as(LabeledExprListSyntax.self),
              let sourceExpr = attributeArgList.first?.expression.as(MemberAccessExprSyntax.self),
              let source = sourceExpr.base,
              let destExpr = attributeArgList.last?.expression.as(MemberAccessExprSyntax.self),
              let dest = destExpr.base
        else { fatalError("Invalid attribute arguments") }
        
        var parameters = declaration.signature.parameterClause.parameters
        var index = parameters.startIndex
        
        while index < parameters.endIndex {
            let parameter = parameters[index]
            if parameter.type.description == source.description {
                parameters[index].type = .init(IdentifierTypeSyntax.identifier("\(dest)"))
            }
            
            parameters.formIndex(after: &index)
        }
        
        var decl = declaration
        while let index = decl.attributes.firstIndex(where: { $0.as(AttributeSyntax.self)?.attributeName.description == "varyArgumentType" }) {
            decl.attributes.remove(at: index)
        }
        
        decl.signature.parameterClause.parameters = parameters
        return [DeclSyntax(decl)]
    }
    
}
