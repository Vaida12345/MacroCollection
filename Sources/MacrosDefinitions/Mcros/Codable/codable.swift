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
import SwiftDiagnostics
import MacroEssentials


public enum codable: ExtensionMacro, MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else { return [] } // let the other expand handle the throwing.
        return try generateDecode(of: node, providingMembersOf: declaration, in: context).map { [DeclSyntax($0)] } ?? []
    }
    
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "@codable should only be applied to `struct` or `class`")
        }
        
        return try [ExtensionDeclSyntax("extension \(type)\(raw: !declaration.conformances.contains("Codable") ? ": Codable" : "")") {
            if let line = try generateCodingKeys(of: node, providingMembersOf: declaration, in: context) { .init(leadingTrivia: .newlines(2), decl: line, trailingTrivia: .newlines(2)) }
            if let line = try generateEncode(of: node, providingMembersOf: declaration, in: context) { .init(decl: line) }
        }]
    }
    
    static func generateEncode(
        of node: SwiftSyntax.AttributeSyntax,
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
        
        let lines = try memberwiseMap(for: declaration) { variable, decl, name, additionalInfo in
            let syntax: CodeBlockItemSyntax
            
            if additionalInfo.encodeIfNoneDefault, let defaultValue = additionalInfo.defaultValue {
                syntax = """
                if self.\(raw: name) != \(raw: defaultValue) {
                    try container.encodeIfPresent(self.\(raw: name), forKey: .\(raw: name))
                }
                """
            } else if try additionalInfo.encodeOptionalAsIfPresent && variable.inferredType(in: decl).isOptional {
                syntax = "try container.encodeIfPresent(self.\(raw: name), forKey: .\(raw: name))"
            } else {
                syntax = "try container.encode(self.\(raw: name), forKey: .\(raw: name))"
            }
            
            return syntax
        }
        
        return FunctionDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) }),
                                  name: "encode",
                                  signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "to", secondName: "encoder", type: .identifier("Encoder"))])),
                                                   effectSpecifiers: .throws)) {
            if !lines.isEmpty {
                "var container = encoder.container(keyedBy: CodingKeys.self)"
            }
            
            for line in lines {
                line
            }
        }
    }
    
    static func generateDecode(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> InitializerDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(InitializerDeclSyntax.self) else { return false }
            let parameters = member.signature.parameterClause.parameters
            guard parameters.count == 1, let parameter = parameters.first else { return false }
            return parameter.firstName.text == "from" && parameter.type.as(IdentifierTypeSyntax.self)?.name.text == "Decoder"
        }) else { return nil } // `decode` already exists
        
        let lines = try memberwiseMap(for: declaration) { variable, decl, name, additionalInfo in
            let syntax: CodeBlockItemSyntax
            let type = try variable.inferredType(in: decl)
            
            if additionalInfo.encodeIfNoneDefault, let defaultValue = additionalInfo.defaultValue {
                syntax = "self.\(raw: name) = try container.decodeIfPresent(\(type).self, forKey: .\(raw: name)) ?? \(raw: defaultValue)"
            } else if try additionalInfo.encodeOptionalAsIfPresent && variable.inferredType(in: decl).isOptional {
                syntax = "self.\(raw: name) = try container.decodeIfPresent(\(type).self, forKey: .\(raw: name))"
            } else {
                syntax = "self.\(raw: name) = try container.decode(\(type).self, forKey: .\(raw: name))"
            }
            
            return syntax
        }
        
        var modifiers = declaration.modifiers.filter({ $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) })
        if let decl = declaration.as(ClassDeclSyntax.self) {
            if !decl.modifiers.contains(where: { $0.name == .keyword(.final) }) {
                // if non final, must add `required`.
                modifiers.append(.init(name: .keyword(.required)))
            }
        }
        
        return try InitializerDeclSyntax(modifiers: modifiers,
                                         signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "from", secondName: "decoder", type: .identifier("Decoder"))])),
                                                          effectSpecifiers: .throws)) {
            if !lines.isEmpty {
                "let container = try decoder.container(keyedBy: CodingKeys.self)"
            }
            
            for line in lines {
                line
            }
            
            if let function: FunctionDeclSyntax = try declaration.memberBlock.members.compactMap({ (block: MemberBlockItemSyntax) -> FunctionDeclSyntax? in
                guard let function = block.decl.as(FunctionDeclSyntax.self) else { return nil }
                guard function.name.isEqual(to: "postDecodeAction") else { return nil }
                guard function.signature.effectSpecifiers?.asyncSpecifier == nil else {
                    throw DiagnosticsError("function `postDecodeAction` cannot be async", highlighting: function)
                }
                return function
            }).first {
                let hasTry = function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
                let isStatic = function.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
                
                "\(raw: hasTry ? "try " : "")\(raw: isStatic ? "Self" : "self").postDecodeAction()"
            }
        }
    }
    
    static func generateCodingKeys(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> EnumDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(EnumDeclSyntax.self),
                  member.name.text == "CodingKeys" else { return false }
            return true
            
        }) else { return nil } // `CodingKeys` already exists
        
        let members = memberwiseMap(for: declaration) { variable, variables, name, additionalInfo  in
            let caseDecl = EnumCaseDeclSyntax(elements: [EnumCaseElementSyntax(name: variable.pattern.as(IdentifierPatternSyntax.self)!.identifier)])
            return MemberBlockItemSyntax(decl: caseDecl)
        }
        
        return EnumDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) }),
                              name: "CodingKeys",
                              inheritanceClause: InheritanceClauseSyntax(inheritedTypes: [InheritedTypeSyntax(type: .identifier("CodingKey"))]),
                              memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(members)))
    }
    
    static func memberwiseMap<T>(
        for declaration: some SwiftSyntax.DeclGroupSyntax,
        handler: (_ variable: PatternBindingListSyntax.Element, _ decl: VariableDeclSyntax, _ name: String, _ additionalInfo: AdditionalInfo) throws -> T?
    ) rethrows -> [T] {
        return try declaration.mapProperties { variable, decl, name, type in
            guard type != .computed && !type.isStatic && !((type == .staticConstant || type == .storedConstant) && variable.initializer != nil) else { return nil }
            
            var isIgnored = false
            var warnNonNilEncodeIfPresent = false
            var encodeOptionsArgsCount = 0
            var additionalInfo = AdditionalInfo()
            
            for attribute in decl.attributes {
                guard let attribute = attribute.as(AttributeSyntax.self),
                      let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self) else { continue }
                if attributeName.name.text == "transient" { isIgnored = true }
                if let args = attribute.arguments?.as(LabeledExprListSyntax.self) {
                    encodeOptionsArgsCount = args.count
                    if attributeName.name.text == "encodeOptions" {
                        for arg in args {
                            guard let memberName = arg.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else { continue }
                            if memberName == "ignored" {
                                isIgnored = true
                            } else if memberName == "encodeIfPresent" {
                                if try !variable.inferredType(in: decl).isOptional {
                                    warnNonNilEncodeIfPresent = true
                                } else {
                                    additionalInfo.encodeOptionalAsIfPresent = true
                                }
                            } else if memberName == "encodeIfNoneDefault" {
                                additionalInfo.encodeIfNoneDefault = true
                            }
                        }
                    }
                }
            }
            
            if let initializer = variable.initializer {
                additionalInfo.defaultValue = initializer.value
            }
            
            if isIgnored {
                guard variable.initializer == nil else { return nil }
                throw DiagnosticsError("A default value must be provided for transient values.", highlighting: variable,
                                       replacing: variable, message: "Provide a default value") { replacement in
                    replacement.initializer = InitializerClauseSyntax(equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                                                      value: EditorPlaceholderExprSyntax(placeholder: .identifier("<#default value#>")))
                }
            } else if warnNonNilEncodeIfPresent {
                if encodeOptionsArgsCount == 1 {
                    throw DiagnosticsError("`encodeIfPresent` can only be applied to optional values.", highlighting: variable,
                                           replacing: decl.attributes, message: "Remove the `codeOptions` macro`") { replacement in
                        replacement = AttributeListSyntax(decl.attributes.drop { attribute in
                            guard let attribute = attribute.as(AttributeSyntax.self),
                                  let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self) else { return false }
                            if let args = attribute.arguments?.as(LabeledExprListSyntax.self){
                                if attributeName.name.text == "encodeOptions" {
                                    if args.contains(where: { $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "encodeIfPresent" }) {
                                        return true
                                    }
                                }
                            }
                            
                            return false
                        })
                    }
                } else {
                    throw DiagnosticsError("`encodeIfPresent` can only be applied to optional values.", highlighting: variable,
                                           replacing: decl.attributes, message: "Remove the `encodeIfPresent` option") { replacement in
                        replacement = AttributeListSyntax(replacement.map { _attribute in
                            guard var attribute = _attribute.as(AttributeSyntax.self),
                                  let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self) else { return _attribute }
                            if var args = attribute.arguments?.as(LabeledExprListSyntax.self) {
                                if attributeName.name.text == "encodeOptions" {
                                    if let encodeIfPresentArg = args.firstIndex(where: { $0.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "encodeIfPresent" }) {
                                        args.remove(at: encodeIfPresentArg)
                                        args[args.index(before: encodeIfPresentArg)].trailingComma = nil
                                        attribute.arguments = args.as(AttributeSyntax.Arguments.self)
                                        return .attribute(attribute)
                                    }
                                }
                            }
                            
                            return _attribute
                        })
                    }
                }
            } else if additionalInfo.encodeIfNoneDefault && variable.initializer == nil {
                throw DiagnosticsError("A default value must be provided for `encodeIfNoneDefault` option.", highlighting: variable,
                                       replacing: variable, message: "Provide a default value") { replacement in
                    replacement.initializer = InitializerClauseSyntax(equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                                                      value: EditorPlaceholderExprSyntax(placeholder: .identifier("<#default value#>")))
                }
            }
            
            return try handler(variable, decl, name, additionalInfo)
        }
    }
    
    struct AdditionalInfo {
        var encodeOptionalAsIfPresent = false
        var encodeIfNoneDefault = false
        var defaultValue: ExprSyntax? = nil
    }
}
