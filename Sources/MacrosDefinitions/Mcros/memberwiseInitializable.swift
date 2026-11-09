//
//  memberwiseInitializable.swift
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


public enum memberwiseInitializable: MemberMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext,
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let members = declaration.mapProperties { variable, variables, name, type -> CodeBlockItemSyntax? in
            guard type != .computed && !type.isStatic && !type.isLazy && !((type == .staticConstant || type == .storedConstant) && variable.initializer != nil) else { return nil }
            return "self.\(raw: name) = \(raw: name)"
        }
        
        var allHaveInitializer = true
        var parameters = try declaration.mapProperties { variable, decl, name, type -> FunctionParameterSyntax? in
            guard type != .computed && !type.isStatic && !type.isLazy && !((type == .staticConstant || type == .storedConstant) && variable.initializer != nil) else { return nil }
            
            let firstName = variable.pattern.as(IdentifierPatternSyntax.self)!.identifier
            let type = try variable.inferredType(in: decl)
            
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
        }
        
        var result: [SwiftSyntax.DeclSyntax] = []
        
        if !declaration.memberBlock.members.contains(where: { member in
            guard let decl = member.decl.as(InitializerDeclSyntax.self) else { return false }
            if parameters.isEmpty && decl.signature.parameterClause.parameters.isEmpty { return true }
            
            let parametersSet = decl.signature.parameterClause.parameters.map {
                $0.firstName.text + ($0.secondName?.text ?? "") + ($0.type.as(IdentifierTypeSyntax.self)?.name.text ?? "")
            }
            return Set(parametersSet) == Set(parameters.map {
                $0.firstName.text + ($0.secondName?.text ?? "") + ($0.type.as(IdentifierTypeSyntax.self)?.name.text ?? "")
            })
        }) {
            result.append(memberwiseInitializer)
        }
        
        let accessControl = AccessControl.accessControl(declaration: declaration)
        let initText = if let accessControl {
            "\(accessControl.rawValue) init()"
        } else {
            "init()"
        }
        
        if allHaveInitializer && !parameters.isEmpty {
            if !declaration.memberBlock.members.contains(where: { member in
                guard let decl = member.decl.as(InitializerDeclSyntax.self) else { return false }
                return decl.signature.parameterClause.parameters.isEmpty
            }) {
                try result.append {
                    try InitializerDeclSyntax("\(raw: initText)") {
                        
                    }
                }
            }
        }
        
        return result
    }
    
}


private enum AccessControl: String, BitwiseCopyable, Sendable, Hashable {
    case `public`
    case `internal`
    case `private`
    
    static func accessControl(declaration: some DeclGroupSyntax) -> AccessControl? {
        if let decl = declaration.as(ClassDeclSyntax.self) {
            for attribute in decl.attributes {
                guard case .attribute(let attribute) = attribute else { continue }
                guard attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.isEqual(to: "memberwiseInitializable") ?? false else { continue }
                guard let arg = attribute.arguments?.children(viewMode: .sourceAccurate).first else { continue }
                guard let expr = arg.as(LabeledExprSyntax.self)?.expression.as(MemberAccessExprSyntax.self) else { continue }
                
                switch expr.declName.baseName.text {
                case "public": return .public
                case "internal": return .internal
                case "private": return .private
                default: return nil
                }
            }
        } else if let decl = declaration.as(StructDeclSyntax.self) {
            for attribute in decl.attributes {
                guard case .attribute(let attribute) = attribute else { continue }
                guard attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.isEqual(to: "memberwiseInitializable") ?? false else { continue }
                guard let arg = attribute.arguments?.children(viewMode: .sourceAccurate).first else { continue }
                guard let expr = arg.as(LabeledExprSyntax.self)?.expression.as(MemberAccessExprSyntax.self) else { continue }
                
                switch expr.declName.baseName.text {
                case "public": return .public
                case "internal": return .internal
                case "private": return .private
                default: return nil
                }
            }
        }
        
        return nil
    }
}
