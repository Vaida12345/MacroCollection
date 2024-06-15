//
//  customCodable.swift
//
//
//  Created by Vaida on 2024/3/6.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics


public enum customCodable: ExtensionMacro, MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else { return [] } // the other expansion will handle the throwing.
        
        let customDecode = declaration.memberBlock.members.first(where: {
            guard let decl = $0.decl.as(InitializerDeclSyntax.self) else { return false }
            let parameters = decl.signature.parameterClause.parameters
            guard parameters.count == 1,
                  let parameter = parameters.first else { return false }
            return parameter.firstName.text == "_from" && parameter.secondName?.text == "container" && parameter.type.description == "inout KeyedDecodingContainer<CodingKeys>"
        })?.decl.as(InitializerDeclSyntax.self)?.body?.statements
        guard let customDecode else { return [] } // the other expansion will handle the throwing.
        
        let memberwiseInitializer: [DeclSyntax] = if !_has(attribute: "dataProviding", declaration: declaration) {
            try memberwiseInitializable.expansion(of: node, providingMembersOf: declaration, in: context)
        } else {
            []
        }
        
        return try [generateDecode(of: node, providingMembersOf: declaration, in: context, customDecode: customDecode).cast(DeclSyntax.self)] + memberwiseInitializer
    }
    
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let declarationName: TokenSyntax
        if let declaration = declaration.as(StructDeclSyntax.self) {
            declarationName = declaration.name
        } else if let declaration = declaration.as(ClassDeclSyntax.self) {
            declarationName = declaration.name
        } else {
            throw DiagnosticsError.shouldRemoveMacro(for: declaration, node: node, message: "@customCodable should only be applied to `struct` or `class`")
        }
        
        // MARK: - Ensures conforms to protocol requirements.
        let customEncode = declaration.memberBlock.members.first(where: {
            guard let decl = $0.decl.as(FunctionDeclSyntax.self),
                  decl.name.text == "_encode" else { return false }
            let parameters = decl.signature.parameterClause.parameters
            guard parameters.count == 1,
                  let parameter = parameters.first else { return false }
            return parameter.firstName.text == "to" && parameter.secondName?.text == "container" && parameter.type.description == "inout KeyedEncodingContainer<CodingKeys>"
        })?.decl.as(FunctionDeclSyntax.self)?.body?.statements
        
        let customDecode = declaration.memberBlock.members.first(where: {
            guard let decl = $0.decl.as(InitializerDeclSyntax.self) else { return false }
            let parameters = decl.signature.parameterClause.parameters
            guard parameters.count == 1,
                  let parameter = parameters.first else { return false }
            return parameter.firstName.text == "_from" && parameter.secondName?.text == "container" && parameter.type.description == "inout KeyedDecodingContainer<CodingKeys>"
        })
        
        guard customEncode != nil && customDecode != nil else {
            throw DiagnosticsError("Type '\(declarationName)' does not conform to protocol 'CustomCodable'", highlighting: node,
                                   replacing: declaration.memberBlock, message: "Do you want to add protocol stubs?") { replacement in
                if customEncode == nil {
                    replacement.members.append(MemberBlockItemSyntax(leadingTrivia: .newlines(2),
                                                                     decl: """
                        /// `CustomCodable` protocol requirement.
                        ///
                        /// Within this function, encode the properties that need *special care*. The properties not defined will be encoded according to its attributes, such as ``encodeOptions(:_)``.
                        ///
                        /// - Note: A key not present here does not mean not encoded.
                         private func _encode(to container: inout KeyedEncodingContainer<CodingKeys>) throws { \n\n }
                        """ as DeclSyntax))
                }
                if customDecode == nil {
                    replacement.members.append(MemberBlockItemSyntax(leadingTrivia: .newlines(2),
                                                                     decl: """
                        /// `CustomCodable` protocol requirement.
                        ///
                        /// Within this function, decode the properties that need *special care*. The properties not defined will be decode according to its attributes, such as ``encodeOptions(:_)``.
                        ///
                        /// - Returns: Always return `nil` to enable partial initializations.
                        ///
                        /// - Note: A key not present here does not mean not being decoded.
                        private init?(_from container: inout KeyedDecodingContainer<CodingKeys>) throws {
                            
                            return nil // Protocol requirement: enabling partial initialization
                        }
                        """ as DeclSyntax ))
                }
            }
        }
        
        // MARK: -
        
        let shouldDeclareInheritance = !_has(inheritance: "Codable", declaration: declaration)
        
        return try [ExtensionDeclSyntax("extension \(type)\(raw: shouldDeclareInheritance ? ": Codable" : "")") {
            if let line = try codable.generateCodingKeys(of: node, providingMembersOf: declaration, in: context) { .init(leadingTrivia: .newlines(2), decl: line, trailingTrivia: .newlines(2)) }
            if let line = try generateEncode(of: node, providingMembersOf: declaration, in: context, customEncode: customEncode!) { .init(decl: line) }
        }]
    }
    
    
    static func generateEncode(of node: SwiftSyntax.AttributeSyntax,
                               providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext,
                               customEncode: CodeBlockItemListSyntax
    ) throws -> FunctionDeclSyntax? {
        let encodedProperties = customEncode.description.matches(of: try! Regex<(Substring, Substring)>(#"container\.encode.*\(.+, forKey: \.(\w+\d*)\)"#)).map { String($0.1) }
        
        let lines: [CodeBlockItemSyntax] = try codable.memberwiseMap(for: declaration) { variable, decl, name, additionalInfo in
            guard !encodedProperties.contains(name) else { return nil }
            
            let syntax: CodeBlockItemSyntax
            if additionalInfo.encodeIfNoneDefault, let defaultValue = additionalInfo.defaultValue {
                syntax = """
                if self.\(raw: name) != \(raw: defaultValue) {
                    try container.encodeIfPresent(self.\(raw: name), forKey: .\(raw: name))
                }
                """
            } else if try additionalInfo.encodeOptionalAsIfPresent && _getType(for: variable, decl: decl, name: name, of: node).isOptional {
                syntax = "try container.encodeIfPresent(self.\(raw: name), forKey: .\(raw: name))"
            } else {
                syntax = "try container.encode(self.\(raw: name), forKey: .\(raw: name))"
            }
            
            return syntax
        }
        
        return FunctionDeclSyntax(modifiers: declaration.modifiers.filter({ $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) }),
                                  name: "encode",
                                  signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "to", secondName: "encoder", type: .identifier("Encoder"))])),
                                                   effectSpecifiers: .init(throwsSpecifier: .keyword(.throws)))) {
            if !lines.isEmpty && !customEncode.isEmpty {
                "var container = encoder.container(keyedBy: CodingKeys.self)"
            }
            
            for line in lines {
                line
            }
            
            for line in customEncode {
                line.trimmed
            }
        }
    }
    
    static func generateDecode(of node: SwiftSyntax.AttributeSyntax,
                               providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext,
                               customDecode: CodeBlockItemListSyntax
    ) throws -> InitializerDeclSyntax {
        let decodedProperties = customDecode.description.matches(of: try! Regex<(Substring, Substring)>(#"container\.decode.*\(.*forKey: \.(\w+\d*)\)"#)).map { String($0.1) }
        
        let lines: [CodeBlockItemSyntax] = try codable.memberwiseMap(for: declaration) { variable, decl, name, additionalInfo in
            guard !decodedProperties.contains(name) else { return nil }
            
            let syntax: CodeBlockItemSyntax
            
            if additionalInfo.encodeIfNoneDefault, let defaultValue = additionalInfo.defaultValue {
                syntax = "self.\(raw: name) = try container.decodeIfPresent(forKey: .\(raw: name)) ?? \(raw: defaultValue)"
            } else if try additionalInfo.encodeOptionalAsIfPresent && _getType(for: variable, decl: decl, name: name, of: node).isOptional {
                syntax = "self.\(raw: name) = try container.decodeIfPresent(forKey: .\(raw: name))"
            } else {
                syntax = "self.\(raw: name) = try container.decode(forKey: .\(raw: name))"
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
        
        let signature: FunctionSignatureSyntax = .init(parameterClause: .init(parameters: .init([.init(firstName: "from", secondName: "decoder", type: .identifier("Decoder"))])),
                                                       effectSpecifiers: .init(throwsSpecifier: .keyword(.throws)))
        
        return try InitializerDeclSyntax(modifiers: modifiers, signature: signature) {
            if !lines.isEmpty && !customDecode.dropLast().isEmpty {
                "let container = try decoder.container(keyedBy: CodingKeys.self)"
            }
            
            for line in lines {
                line
            }
            
            for line in customDecode.dropLast() {
                line.trimmed
            }
            
            if let function: FunctionDeclSyntax = try declaration.memberBlock.members.compactMap({ (block: MemberBlockItemSyntax) -> FunctionDeclSyntax? in
                guard let function = block.as(MemberBlockItemSyntax.self)?.decl.as(FunctionDeclSyntax.self) else { return nil }
                guard function.name.isEqual(to: "postDecodeAction") else { return nil }
                guard function.signature.effectSpecifiers?.asyncSpecifier == nil else {
                    throw DiagnosticsError("function `postDecodeAction` cannot be async", highlighting: function)
                }
                return function
            }).first {
                let hasTry = function.signature.effectSpecifiers?.throwsSpecifier != nil
                let isStatic = function.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
                
                "\(raw: hasTry ? "try " : "")\(raw: isStatic ? "Self" : "self").postDecodeAction()"
            }
        }
    }
    
}
