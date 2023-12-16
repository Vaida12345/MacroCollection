//
//  codable.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder


public enum codable: ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else { throw CodableError.appliedToInvalidDeclaration }
        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "Codable" }) {
            return []
        }
        
        return try [ExtensionDeclSyntax("extension \(type): Codable") {
            if let line = try generateCodingKeys(of: node, providingMembersOf: declaration, in: context) { .init(leadingTrivia: .newlines(2), decl: line, trailingTrivia: .newlines(2)) }
            if let line = try generateEncode(of: node, providingMembersOf: declaration, in: context) { .init(decl: line, trailingTrivia: .newlines(2)) }
            if let line = try generateDecode(of: node, providingMembersOf: declaration, in: context) { .init(decl: line) }
        }]
    }
    
    private static func generateEncode(of node: SwiftSyntax.AttributeSyntax,
                                       providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                       in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> FunctionDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(FunctionDeclSyntax.self),
                  member.name.text == "encode" else { return false }
            let parameters = member.signature.parameterClause.parameters
            guard parameters.count == 1, let parameter = parameters.first else { return false }
            return parameter.firstName.text == "to" && parameter.type.as(IdentifierTypeSyntax.self)?.name.text == "Encoder"
        }) else { return nil } // `encode` already exists
        
        let lines = try _memberwiseMap(for: declaration) { variable, decl, name in
            let syntax: CodeBlockItemSyntax
            
            let type = try getType(for: variable, decl: decl, name: name, of: node)
            if type.isOptional {
                syntax = "try container.encodeIfPresent(self.\(raw: name), forKey: .\(raw: name))"
            } else {
                syntax = "try container.encode(self.\(raw: name), forKey: .\(raw: name))"
            }
            
            return syntax
        }
        
        return FunctionDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name == .keyword(.public) || $0.name == .keyword(.open) }),
                                  name: "encode",
                                  signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "to", secondName: "encoder", type: .identifier("Encoder"))])),
                                                   effectSpecifiers: .init(throwsSpecifier: .keyword(.throws)))) {
            "var container = encoder.container(keyedBy: CodingKeys.self)"
            
            for line in lines {
                line
            }
        }
    }
    
    private static func generateDecode(of node: SwiftSyntax.AttributeSyntax,
                                       providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                       in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> InitializerDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(InitializerDeclSyntax.self) else { return false }
            let parameters = member.signature.parameterClause.parameters
            guard parameters.count == 1, let parameter = parameters.first else { return false }
            return parameter.firstName.text == "from" && parameter.type.as(IdentifierTypeSyntax.self)?.name.text == "Decoder"
        }) else { return nil } // `encode` already exists
        
        let lines = try _memberwiseMap(for: declaration) { variable, decl, name in
            let syntax: CodeBlockItemSyntax
            
            let type = try getType(for: variable, decl: decl, name: name, of: node)
            if type.isOptional {
                syntax = "self.\(raw: name) = try container.decodeIfPresent(forKey: .\(raw: name))"
            } else {
                syntax = "self.\(raw: name) = try container.decode(forKey: .\(raw: name))"
            }
            
            return syntax
        }
        
        return InitializerDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name == .keyword(.public) || $0.name == .keyword(.open) }),
                                     signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "from", secondName: "decoder", type: .identifier("Decoder"))])),
                                                      effectSpecifiers: .init(throwsSpecifier: .keyword(.throws)))) {
            "let container = try decoder.container(keyedBy: CodingKeys.self)"
            
            for line in lines {
                line
            }
        }
    }
    
    private static func generateCodingKeys(of node: SwiftSyntax.AttributeSyntax,
                                           providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                           in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> EnumDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(EnumDeclSyntax.self),
                  member.name.text == "CodingKeys" else { return false }
            return true
            
        }) else { return nil } // `CodingKeys` already exists
        
        let members = _memberwiseMap(for: declaration) { variable, variables, name in
            let caseDecl = EnumCaseDeclSyntax(elements: [EnumCaseElementSyntax(name: variable.pattern.as(IdentifierPatternSyntax.self)!.identifier)])
            return MemberBlockItemSyntax(decl: caseDecl)
        }
        
        return EnumDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name == .keyword(.public) || $0.name == .keyword(.open) }),
                              name: "CodingKeys",
                              inheritanceClause: InheritanceClauseSyntax(inheritedTypes: [InheritedTypeSyntax(type: .identifier("CodingKey"))]),
                              memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(members)))
    }
    
    fileprivate static func _memberwiseMap<T>(for declaration: some SwiftSyntax.DeclGroupSyntax,
                                          ignoreComputedProperties: Bool = true,
                                          ignoreConstantProperties: Bool = true,
                                          handler: (_ variable: PatternBindingListSyntax.Element, _ decl: VariableDeclSyntax, _ name: String) throws -> T?
    ) rethrows -> [T] {
        try memberwiseMap(for: declaration,
                      ignoreComputedProperties: ignoreComputedProperties,
                      ignoreConstantProperties: ignoreConstantProperties) { variable, decl, name in
            guard !decl.attributes.contains(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "transient" }) else { return nil }
            
            return try handler(variable, decl, name)
        }
    }
    
    
    enum CodableError: CustomStringConvertible, Error {
        case appliedToInvalidDeclaration
        
        var description: String {
            switch self {
            case .appliedToInvalidDeclaration:
                "@Codable should only be applied to `struct` or `class`"
            }
        }
    }
}
