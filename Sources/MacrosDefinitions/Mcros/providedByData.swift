//
//  providedByData.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/20.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling


public enum providedByData: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declaration = declaration.as(StructDeclSyntax.self),
              (declaration.inheritanceClause?.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "App" }) ?? false) else {
            throw shouldRemoveMacroError(for: declaration,
                                         macroName: "@providedByData",
                                         message: "@providedByData should only be applied to @main App")
        }
        
        guard let bodyViewBlock = declaration.memberBlock.members.first(where: { $0.as(VariableDeclSyntax.self)?.bindings.last?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body" }) else {
            return [] // wait for other declarations
        }
    }
    
}
