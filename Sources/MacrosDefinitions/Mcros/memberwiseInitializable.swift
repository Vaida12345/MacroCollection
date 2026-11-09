//
//  memberwiseInitializable.swift
//  MacroCollection
//
//  Created by Vaida on 2023/12/16.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import MacroEssentials


/// The implementation of `@memberwiseInitializable`, see the macro declaration in `MacroCollection` for the documentation.
public enum memberwiseInitializable: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) || declaration.is(ActorDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "@memberwiseInitializable should only be applied to `struct`, `class`, or `actor`")
        }

        let modifiers = try accessModifiers(of: node)
        let properties = try storedProperties(of: declaration)

        // Declaring any initializer disables the implicit `init()`, so it is offered again when every property is able to take its default value.
        var initializers = [makeInitializer(taking: properties, modifiers: modifiers)]
        if !properties.isEmpty && properties.allSatisfy({ $0.defaultValue != nil }) {
            initializers.append(makeInitializer(taking: [], modifiers: modifiers))
        }

        let declared = Set(declaration.memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self)?.overloadSignature })
        return initializers
            .filter { !declared.contains($0.overloadSignature) }
            .map { DeclSyntax($0) }
    }

    /// The keywords accepted as the macro argument, keyed by the spelling of the matching case of `MacroCollection.AccessControl`.
    ///
    /// `MacroCollection` depends on this module, so its enum cannot be imported here, and its cases are mirrored by name instead. Keep both in sync.
    private static let accessKeywords: [String: Keyword] = [
        "public": .public,
        "internal": .internal,
        "private": .private,
    ]

    /// Reads the access control from the macro argument, eg, `.public` in `@memberwiseInitializable(.public)`.
    ///
    /// - Returns: The modifiers for the generated initializers, which is empty when no access control is given.
    private static func accessModifiers(of node: AttributeSyntax) throws -> DeclModifierListSyntax {
        guard case .argumentList(let arguments) = node.arguments,
              let argument = arguments.first?.expression,
              !argument.is(NilLiteralExprSyntax.self) else { return [] }

        guard let name = argument.as(MemberAccessExprSyntax.self)?.declName.baseName.text,
              let keyword = accessKeywords[name] else {
            throw DiagnosticsError("The access control must be written as a literal, such as `.public`, `.internal`, or `.private`.", highlighting: argument)
        }

        return [DeclModifierSyntax(name: .keyword(keyword))]
    }

    /// A stored property assigned by the generated initializer.
    private struct StoredProperty {

        let name: String

        let type: TypeSyntax

        let defaultValue: InitializerClauseSyntax?

        /// The parameter through which the initializer receives the property.
        var parameter: FunctionParameterSyntax {
            FunctionParameterSyntax(firstName: .identifier(name), colon: .colonToken(), type: type, defaultValue: defaultValue)
        }

        /// The statement assigning the received parameter to the property.
        var assignment: CodeBlockItemSyntax {
            "self.\(raw: name) = \(raw: name)"
        }
    }

    /// The stored properties that the memberwise initializer assigns, in the order of declaration.
    private static func storedProperties(of declaration: some DeclGroupSyntax) throws -> [StoredProperty] {
        try declaration.mapProperties { binding, variable, name, kind in
            let isAssignable = switch kind {
            case .storedVariable: true
            case .storedConstant: binding.initializer == nil // a constant that already has its value cannot be assigned again.
            case .storedLazyVariable, .computed, .staticConstant, .staticVariable: false
            }
            guard isAssignable else { return nil }

            // trivia, such as trailing comments, would otherwise leak into the generated signature.
            let type = try binding.inferredType(in: variable)
            return StoredProperty(name: name, type: TypeSyntax(type).trimmed, defaultValue: binding.initializer?.trimmed)
        }
    }

    /// Creates an initializer that takes, and assigns, each of the `properties`.
    private static func makeInitializer(taking properties: [StoredProperty], modifiers: DeclModifierListSyntax) -> InitializerDeclSyntax {
        InitializerDeclSyntax(
            modifiers: modifiers,
            signature: FunctionSignatureSyntax(parameterClause: FunctionParameterClauseSyntax {
                for property in properties { property.parameter }
            })
        ) {
            for property in properties { property.assignment }
        }
    }

}


private extension InitializerDeclSyntax {

    /// What tells one initializer apart from another: the argument labels and the types, in order.
    ///
    /// Neither the parameter names, the default values, nor the effects (eg, failable or throwing) make an overload distinct.
    var overloadSignature: [String] {
        signature.parameterClause.parameters.map { parameter in
            "\(parameter.firstName.text): \(parameter.type.trimmedDescription)\(parameter.ellipsis?.text ?? "")"
        }
    }

}
