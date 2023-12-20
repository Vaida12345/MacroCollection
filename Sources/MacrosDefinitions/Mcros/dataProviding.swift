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
import Nucleus


public enum dataProviding: MemberMacro, ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // asserts
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { throw shouldRemoveMacroError(for: declaration,
                                                                                                         macroName: "@dataProviding",
                                                                                                         message: "@dataProviding should only be applied to `class`") }
        
        guard declaration.attributes.contains(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Observable" }) ||
                (declaration.inheritanceClause?.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "ObservableObject" }) ?? false) else {
            var replacement_observable = declaration.attributes
            replacement_observable.append(.attribute(AttributeSyntax(leadingTrivia: .newline, attributeName: .identifier("Observable"))))
            
            var replacement_observableObject = declaration
            replacement_observableObject.appendInheritedTypes(identifier: "ObservableObject")
            
            let id =  "\(Self.self).dataProviding.requiresObservable"
            
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: declaration.attributes,
                           message: .diagnostic(message: "DataProvider should be declared `Observable` or `ObservableObject`",
                                                diagnosticID: id),
                           fixIts: [
                            FixIt(message: .fixing(message: "declare `Observable`", diagnosticID: id),
                                  changes: [.replace(oldNode: declaration.attributes.cast(Syntax.self), newNode: replacement_observable.cast(Syntax.self))]),
                            FixIt(message: .fixing(message: "declare `ObservableObject`", diagnosticID: id),
                                  changes: [.replace(oldNode: declaration.cast(Syntax.self), newNode: replacement_observableObject.cast(Syntax.self))])
                           ])
            ])
        }
        
        
        try assertAllMembersHaveDefaultValue(declaration: declaration)
        
        // decl
        let decodableDecl = try codable.generateDecode(of: node, providingMembersOf: declaration, in: context)
        let memberwiseInitializers = try memberwiseInitializable.expansion(of: node, providingMembersOf: declaration, in: context)
        let instanceDecl: DeclSyntax = """
        /// The main ``DataProvider`` to work with.
        ///
        /// This structure can be accessed across the app, and any mutations are observed in all views.
        static var instance: \(declaration.name) = {
            do {
                return try \(declaration.name)(at: \(declaration.name).storageItem, format: .plist)
            } catch {
                return \(declaration.name)()
            }
        }()
        """
        
        return [instanceDecl.cast(DeclSyntax.self)].appending(decodableDecl?.cast(DeclSyntax.self)) + memberwiseInitializers
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { throw shouldRemoveMacroError(for: declaration,
                                                                                                         macroName: "@dataProviding",
                                                                                                         message: "@dataProviding should only be applied to `class`") }
        var shouldDeclareDataProviderInheritance = true
        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes {
            shouldDeclareDataProviderInheritance = !inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "DataProvider" })
        }
        
        let extensionTypes: String
        if shouldDeclareDataProviderInheritance {
            extensionTypes = ": DataProvider"
        } else {
            extensionTypes = ""
        }
        
        return try [ExtensionDeclSyntax("extension \(type)\(raw: extensionTypes)") {
            if let line = try codable.generateEncode(of: node, providingMembersOf: declaration, in: context) { line }
            if let line = try codable.generateCodingKeys(of: node, providingMembersOf: declaration, in: context) { line }
        }]
    }
    
    static func assertAllMembersHaveDefaultValue(declaration: some SwiftSyntax.DeclGroupSyntax) throws {
        let _: [Void] = try memberwiseMap(for: declaration) { variable, decl, name in
            guard variable.initializer != nil else {
                var replacement = variable
                replacement.initializer = InitializerClauseSyntax(equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                                                  value: EditorPlaceholderExprSyntax(placeholder: .identifier("<#default value#>")))
                let id = "dataProviding.\(name).missing_default_value"
                throw DiagnosticsError(diagnostics: [
                    Diagnostic(node: variable,
                               message: .diagnostic(message: "A default value must be provided for data provider properties.",
                                                    diagnosticID: id),
                               fixIt: .replace(message: .fixing(message: "Provide a default value", diagnosticID: id),
                                               oldNode: variable,
                                               newNode: replacement))
                ])
            }
            
            return
        }
    }
    
}
