//
//  codable.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/15.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import MacroEssentials


/// The implementation of `@codable`, see the macro declaration in `MacroCollection` for the documentation.
public enum codable: ExtensionMacro, MemberMacro {
    
    // MARK: - Expansion
    
    /// Provides the `init(from:)` and `encode(to:)` of a class.
    ///
    /// Those of a struct are provided by the extension, since an initializer declared in the body of a struct removes its memberwise initializer.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else { return [] } // the extension handles the structs, and the throwing.
        guard let properties = try? codingProperties(of: declaration) else { return [] } // the extension reports the problems, hence they are reported once.
        
        let overrides = inheritsConformance(node: node, declaration: declaration, protocols: protocols)
        
        var result: [DeclSyntax] = []
        if let decode = try makeDecode(of: declaration, properties: properties, overrides: overrides) {
            result.append(DeclSyntax(decode))
        }
        if let encode = makeEncode(of: declaration, properties: properties, overrides: overrides) {
            result.append(DeclSyntax(encode))
        }
        
        return result
    }
    
    /// Provides the `CodingKeys` and the conformance, as well as the `init(from:)` and `encode(to:)` of a struct.
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "@codable should only be applied to `struct` or `class`")
        }
        
        let properties = try codingProperties(of: declaration)
        let overrides = inheritsConformance(node: node, declaration: declaration, protocols: protocols)
        
        var declarations: [DeclSyntax] = []
        if let keys = makeCodingKeys(of: declaration, properties: properties) {
            declarations.append(DeclSyntax(keys))
        }
        if declaration.is(StructDeclSyntax.self) {
            if let decode = try makeDecode(of: declaration, properties: properties, overrides: overrides) {
                declarations.append(DeclSyntax(decode))
            }
            if let encode = makeEncode(of: declaration, properties: properties, overrides: overrides) {
                declarations.append(DeclSyntax(encode))
            }
        }
        
        let members = declarations.map { MemberBlockItemSyntax(leadingTrivia: .newlines(2), decl: $0) }
        return try [ExtensionDeclSyntax("extension \(type)\(raw: conformanceClause(of: protocols))") {
            for member in members { member }
        }]
    }
    
    /// The conformances to declare, which are the ones the type does not have yet, ie, `: Codable` for a type conforming to neither `Decodable` nor `Encodable`.
    private static func conformanceClause(of protocols: [TypeSyntax]) -> String {
        let names = protocols.map(\.trimmedDescription)
        if names.contains("Decodable") && names.contains("Encodable") { return ": Codable" }
        
        return names.isEmpty ? "" : ": " + names.joined(separator: ", ")
    }
    
    /// Whether the class takes its conformance from its superclass, in which case the generated coding builds on the one of the superclass.
    ///
    /// The compiler lists the protocols the type does not conform to yet. Hence none is listed when the conformance is inherited, unless the class declares it again. The `.override` option states it explicitly.
    private static func inheritsConformance(node: AttributeSyntax, declaration: some DeclGroupSyntax, protocols: [TypeSyntax]) -> Bool {
        guard declaration.is(ClassDeclSyntax.self) else { return false }
        if node.argumentList.contains(where: { $0.expression.memberName == "override" }) { return true }
        
        return protocols.isEmpty && !declaration.conformances.contains(where: { ["Codable", "Decodable", "Encodable"].contains($0) })
    }
    
    
    // MARK: - Generation
    
    private static func makeCodingKeys(of declaration: some DeclGroupSyntax, properties: [CodingProperty]) -> EnumDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { $0.decl.as(EnumDeclSyntax.self)?.name.text == "CodingKeys" }) else { return nil } // `CodingKeys` already exists
        
        let cases = properties.map { MemberBlockItemSyntax(decl: EnumCaseDeclSyntax(elements: [EnumCaseElementSyntax(name: $0.identifier)])) }
        return EnumDeclSyntax(modifiers: declaration.accessModifiers(),
                              name: "CodingKeys",
                              inheritanceClause: InheritanceClauseSyntax(inheritedTypes: [InheritedTypeSyntax(type: .identifier("CodingKey"))]),
                              memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(cases)))
    }
    
    private static func makeEncode(of declaration: some DeclGroupSyntax, properties: [CodingProperty], overrides: Bool) -> FunctionDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(FunctionDeclSyntax.self),
                  member.name.text == "encode" else { return false }
            let parameters = member.signature.parameterClause.parameters
            guard parameters.count == 1, let parameter = parameters.first else { return false }
            return parameter.firstName.text == "to" && parameter.type.as(IdentifierTypeSyntax.self)?.name.text == "Encoder"
        }) else { return nil } // `encode` already exists
        
        // Only a class can be `open`, whose method can then be overridden.
        var modifiers = declaration.accessModifiers(allowingOpen: declaration.is(ClassDeclSyntax.self))
        if overrides {
            modifiers.append(DeclModifierSyntax(name: .keyword(.override)))
        }
        
        return FunctionDeclSyntax(
            modifiers: modifiers,
            name: "encode",
            signature: .init(
                parameterClause: .init(
                    parameters: .init([.init(firstName: "to", secondName: "encoder", type: .identifier("Encoder"))])
                ),
                effectSpecifiers: .throws
            )
        ) {
            if overrides {
                "try super.encode(to: encoder)"
            }
            
            if !properties.isEmpty {
                "var container = encoder.container(keyedBy: CodingKeys.self)"
            }
            
            for property in properties {
                property.encoding
            }
        }
    }
    
    private static func makeDecode(of declaration: some DeclGroupSyntax, properties: [CodingProperty], overrides: Bool) throws -> InitializerDeclSyntax? {
        guard !declaration.memberBlock.members.contains(where: { member in
            guard let member = member.decl.as(InitializerDeclSyntax.self) else { return false }
            let parameters = member.signature.parameterClause.parameters
            guard parameters.count == 1, let parameter = parameters.first else { return false }
            return parameter.firstName.text == "from" && parameter.type.as(IdentifierTypeSyntax.self)?.name.text == "Decoder"
        }) else { return nil } // `decode` already exists
        
        var modifiers = declaration.accessModifiers()
        if declaration.is(ClassDeclSyntax.self), overrides || !declaration.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) }) {
            // if non final, must add `required`. So must an override of the `required` initializer of the superclass, whether final or not.
            modifiers.append(DeclModifierSyntax(name: .keyword(.required)))
        }
        
        let postDecodeAction = try postDecodeAction(of: declaration)
        
        return InitializerDeclSyntax(modifiers: modifiers,
                                     signature: .init(parameterClause: .init(parameters: .init([.init(firstName: "from", secondName: "decoder", type: .identifier("Decoder"))])),
                                                      effectSpecifiers: .throws)) {
            if !properties.isEmpty {
                "let container = try decoder.container(keyedBy: CodingKeys.self)"
            }
            
            for property in properties {
                property.decoding
            }
            
            if overrides {
                "try super.init(from: decoder)"
            }
            
            // an instance method can only be called once the superclass is initialized.
            if let postDecodeAction {
                postDecodeAction
            }
        }
    }
    
    /// The call to the `postDecodeAction` that the type declares, which is made at the end of the decoding.
    private static func postDecodeAction(of declaration: some DeclGroupSyntax) throws -> CodeBlockItemSyntax? {
        guard let function: FunctionDeclSyntax = try declaration.memberBlock.members.compactMap({ (block: MemberBlockItemSyntax) -> FunctionDeclSyntax? in
            guard let function = block.decl.as(FunctionDeclSyntax.self) else { return nil }
            guard function.name.isEqual(to: "postDecodeAction") else { return nil }
            guard function.signature.effectSpecifiers?.asyncSpecifier == nil else {
                throw DiagnosticsError("function `postDecodeAction` cannot be async", highlighting: function)
            }
            return function
        }).first else { return nil }
        
        let hasTry = function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
        let isStatic = function.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) })
        
        return "\(raw: hasTry ? "try " : "")\(raw: isStatic ? "Self" : "self").postDecodeAction()"
    }
    
    
    // MARK: - Properties
    
    /// The options of `@encodeOptions`, which mirror the cases of `MacroCollection.AttributeEncodeOptions`.
    ///
    /// `MacroCollection` depends on this module, so its enum cannot be imported here, and its cases are mirrored by name instead. Keep both in sync.
    private enum EncodeOption: String, CaseIterable {
        case ignored
        case encodeIfPresent
        case encodeIfNoneDefault
    }
    
    /// A property that is encoded and decoded.
    private struct CodingProperty {
        
        let name: String
        
        let identifier: TokenSyntax
        
        let type: TypeSyntax
        
        let defaultValue: ExprSyntax?
        
        /// Whether the value is encoded only if it is not `nil`.
        let encodesIfPresent: Bool
        
        /// Whether the value is encoded only if it is not the default value.
        let omitsDefault: Bool
        
        /// The statement that decodes the value.
        ///
        /// An optional is always decoded using `decodeIfPresent`, as Swift does: the key may be missing.
        var decoding: CodeBlockItemSyntax {
            let wrapped = self.type.wrappedType
            
            if self.omitsDefault, let defaultValue = self.defaultValue {
                return "self.\(raw: self.name) = try container.decodeIfPresent(\(wrapped ?? self.type).self, forKey: .\(raw: self.name)) ?? \(raw: defaultValue)"
            } else if let wrapped {
                return "self.\(raw: self.name) = try container.decodeIfPresent(\(wrapped).self, forKey: .\(raw: self.name))"
            } else {
                return "self.\(raw: self.name) = try container.decode(\(self.type).self, forKey: .\(raw: self.name))"
            }
        }
        
        /// The statement that encodes the value.
        var encoding: CodeBlockItemSyntax {
            if self.omitsDefault, let defaultValue = self.defaultValue {
                return """
                if self.\(raw: self.name) != \(raw: defaultValue) {
                    try container.encodeIfPresent(self.\(raw: self.name), forKey: .\(raw: self.name))
                }
                """
            } else if self.encodesIfPresent {
                return "try container.encodeIfPresent(self.\(raw: self.name), forKey: .\(raw: self.name))"
            } else {
                return "try container.encode(self.\(raw: self.name), forKey: .\(raw: self.name))"
            }
        }
        
    }
    
    /// The properties that are encoded and decoded, in the order of declaration.
    ///
    /// - Throws: A diagnostic for each property that is misconfigured.
    private static func codingProperties(of declaration: some DeclGroupSyntax) throws -> [CodingProperty] {
        var properties: [CodingProperty] = []
        var diagnostics: [Diagnostic] = []
        
        for property in declaration.properties where property.isMemberwiseInitializable {
            do {
                if let property = try codingProperty(of: property) {
                    properties.append(property)
                }
            } catch let error as DiagnosticsError {
                diagnostics.append(contentsOf: error.diagnostics)
            }
        }
        
        guard diagnostics.isEmpty else { throw DiagnosticsError(diagnostics: diagnostics) }
        return properties
    }
    
    /// Reads the options of the property.
    ///
    /// - Returns: `nil` if the property is not coded.
    private static func codingProperty(of property: Property) throws -> CodingProperty? {
        var options: Set<EncodeOption> = []
        for attribute in property.declaration.attributes {
            guard case .attribute(let attribute) = attribute else { continue }
            
            switch attribute.baseName {
            case "transient":
                options.insert(.ignored)
            case "encodeOptions":
                options.formUnion(try attribute.argumentList.cases(of: EncodeOption.self))
            default:
                break
            }
        }
        
        if options.contains(.ignored) {
            guard property.initializer == nil else { return nil }
            throw DiagnosticsError("A default value must be provided for transient values.", highlighting: property.binding,
                                   replacing: property.binding, message: "Provide a default value", with: providingDefaultValue)
        }
        
        let type = try property.type()
        
        if options.contains(.encodeIfPresent) && !type.isOptional {
            let isAlone = property.declaration.attributes.contains { element in
                guard case .attribute(let attribute) = element, attribute.baseName == "encodeOptions" else { return false }
                return attribute.argumentList.count == 1 && attribute.argumentList.first?.expression.memberName == "encodeIfPresent"
            }
            
            throw DiagnosticsError("`encodeIfPresent` can only be applied to optional values.", highlighting: property.binding,
                                   replacing: property.declaration.attributes, message: isAlone ? "Remove @encodeOptions" : "Remove the `encodeIfPresent` option") { attributes in
                attributes = removingEncodeIfPresent(from: attributes)
            }
        } else if options.contains(.encodeIfNoneDefault) && property.initializer == nil {
            throw DiagnosticsError("A default value must be provided for `encodeIfNoneDefault` option.", highlighting: property.binding,
                                   replacing: property.binding, message: "Provide a default value", with: providingDefaultValue)
        }
        
        return CodingProperty(
            name: property.name,
            identifier: property.identifier,
            type: type,
            defaultValue: property.initializer?.value,
            encodesIfPresent: options.contains(.encodeIfPresent),
            omitsDefault: options.contains(.encodeIfNoneDefault)
        )
    }
    
    /// Gives the binding a placeholder as its default value.
    private static func providingDefaultValue(_ binding: inout PatternBindingSyntax) {
        binding.initializer = InitializerClauseSyntax(equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                                      value: EditorPlaceholderExprSyntax(placeholder: .identifier("<#default value#>")))
    }
    
    /// The attributes without the `.encodeIfPresent` option, nor the `@encodeOptions` which has no other option.
    private static func removingEncodeIfPresent(from attributes: AttributeListSyntax) -> AttributeListSyntax {
        AttributeListSyntax(attributes.compactMap { element -> AttributeListSyntax.Element? in
            guard case .attribute(var attribute) = element, attribute.baseName == "encodeOptions",
                  attribute.argumentList.contains(where: { $0.expression.memberName == "encodeIfPresent" }) else { return element }
            
            var remaining = Array(attribute.argumentList.filter { $0.expression.memberName != "encodeIfPresent" })
            guard !remaining.isEmpty else { return nil }
            
            remaining[0].leadingTrivia = []
            remaining[remaining.count - 1].trailingComma = nil
            attribute.arguments = .argumentList(LabeledExprListSyntax(remaining))
            
            return .attribute(attribute)
        })
    }
    
}


private extension TypeSyntax {
    
    /// The type wrapped by an optional, ie, `Int` for `Int?`, `Int!`, and `Optional<Int>`.
    ///
    /// This is `nil` if the type is not an optional.
    var wrappedType: TypeSyntax? {
        if let type = self.as(OptionalTypeSyntax.self) { return type.wrappedType.trimmed }
        if let type = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) { return type.wrappedType.trimmed }
        guard self.isOptional else { return nil }
        
        let clause = self.as(IdentifierTypeSyntax.self)?.genericArgumentClause ?? self.as(MemberTypeSyntax.self)?.genericArgumentClause
        guard case .type(let wrapped)? = clause?.arguments.first?.argument else { return nil }
        
        return wrapped.trimmed
    }
    
}
