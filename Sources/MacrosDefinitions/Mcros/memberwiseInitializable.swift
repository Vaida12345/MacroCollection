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
    
    /// The access controls accepted as the macro argument, which mirror the cases of `MacroCollection.AccessControl`.
    ///
    /// `MacroCollection` depends on this module, so its enum cannot be imported here, and its cases are mirrored by name instead. Keep both in sync.
    private enum AccessControl: String, CaseIterable {
        case `public`
        case `internal`
        case `private`
        
        var keyword: Keyword {
            switch self {
            case .public: .public
            case .internal: .internal
            case .private: .private
            }
        }
    }
    
    /// Reads the access control from the macro argument, eg, `.public` in `@memberwiseInitializable(.public)`.
    ///
    /// - Returns: The modifiers for the generated initializers, which is empty when no access control is given.
    private static func accessModifiers(of node: AttributeSyntax) throws -> DeclModifierListSyntax {
        guard let access = try node.argumentList.cases(of: AccessControl.self).first else { return [] }
        return [DeclModifierSyntax(name: .keyword(access.keyword))]
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
        try declaration.properties
            .filter { $0.isMemberwiseInitializable && !$0.isLazy }
            .map { StoredProperty(name: $0.name, type: try $0.type(), defaultValue: $0.initializer) }
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
