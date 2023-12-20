//
//  memberwiseInitializable.swift
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


public enum memberwiseInitializable: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else { throw shouldRemoveMacroError(for: declaration,
                                                                                       macroName: "@memberwiseInitializable",
                                                                                       message: "@memberwiseInitializable should only be applied to `class`. Use the synthesized initializer instead") }
        
        let members = memberwiseMap(for: declaration) { variable, variables, name -> CodeBlockItemSyntax in
            "self.\(raw: name) = \(raw: name)"
        }
        
        var allHaveInitializer = true
        var parameters = try memberwiseMap(for: declaration) { variable, decl, name -> FunctionParameterSyntax? in
            let firstName = variable.pattern.as(IdentifierPatternSyntax.self)!.identifier
            let type = try getType(for: variable, decl: decl, name: name, of: node)
            
            if variable.initializer == nil { allHaveInitializer = false }
            
            return FunctionParameterSyntax(firstName: firstName.with(\.trailingTrivia, []), colon: .colonToken(), type: type, defaultValue: variable.initializer)
        }
        for index in 0..<parameters.count {
            if index == parameters.count - 1 { break }
            parameters[index].trailingComma = .commaToken()
        }
        
        
        let memberwiseInitializer = InitializerDeclSyntax(signature: .init(parameterClause: .init(parameters: .init(parameters)))) {
            for member in members {
                member
            }
        }.cast(DeclSyntax.self)
        
        var result: [SwiftSyntax.DeclSyntax] = []
        
        if !declaration.memberBlock.members.contains(where: { member in
            guard let decl = member.decl.as(InitializerDeclSyntax.self) else { return false }
            let parametersSet = decl.signature.parameterClause.parameters.map {
                $0.firstName.text + ($0.secondName?.text ?? "") + $0.type.as(IdentifierTypeSyntax.self)!.name.text
            }
            return Set(parametersSet) == Set(parameters.map {
                $0.firstName.text + ($0.secondName?.text ?? "") + $0.type.as(IdentifierTypeSyntax.self)!.name.text
            })
        }) {
            result.append(memberwiseInitializer)
        }
        
        if allHaveInitializer && !parameters.isEmpty {
            if !declaration.memberBlock.members.contains(where: { member in
                guard let decl = member.decl.as(InitializerDeclSyntax.self) else { return false }
                return decl.signature.parameterClause.parameters.isEmpty
            }) {
                result.append(try InitializerDeclSyntax("init()", bodyBuilder: {
                    
                }).cast(DeclSyntax.self))
            }
        }
        
        return result
    }
    
}
