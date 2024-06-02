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


public enum dataProviding: MemberMacro, ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // asserts
        guard let declaration = declaration.as(ClassDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(for: declaration, node: node, message: "@dataProviding should only be applied to `class`")
        }
        
        guard _has(attribute: "Observable", declaration: declaration) || _has(inheritance: "ObservableObject", declaration: declaration) else {
            var replacement_observable = declaration.attributes
            replacement_observable.append(.attribute(AttributeSyntax(leadingTrivia: .newline, attributeName: .identifier("Observable"))))
            
            var replacement_observableObject = declaration
            replacement_observableObject.appendInheritedTypes(identifier: "ObservableObject")
            
            let id =  "\(Self.self).dataProviding.requiresObservable"
            
            throw DiagnosticsError(diagnostics: [
                Diagnostic(node: node,
                           message: .diagnostic(message: "DataProvider should be declared `Observable` or `ObservableObject`",
                                                diagnosticID: id),
                           fixIts: [
                            FixIt(message: .diagnostic(message: "declare `Observable`", diagnosticID: id),
                                  changes: [.replace(oldNode: declaration.attributes.cast(Syntax.self),
                                                     newNode: replacement_observable.cast(Syntax.self))]),
                            FixIt(message: .diagnostic(message: "declare `ObservableObject`", diagnosticID: id),
                                  changes: [.replace(oldNode: declaration.cast(Syntax.self),
                                                     newNode: replacement_observableObject.cast(Syntax.self))])
                           ])
            ])
        }
        
        guard declaration.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) }) else {
            throw DiagnosticsError("DataProvider should be declared `final`", highlighting: node,
                                   replacing: declaration.modifiers, message: "declare `final`") { replacement in
                replacement.append(.init(name: .keyword(.final)))
            }
        }
        
        
        try assertAllMembersHaveDefaultValue(declaration: declaration)
        
        // decl
        let decodableDecl: InitializerDeclSyntax? = if _has(attribute: "customCodable", declaration: declaration) {
            nil
        } else {
            try codable.generateDecode(of: node, providingMembersOf: declaration, in: context)
        }
        let memberwiseInitializers = try memberwiseInitializable.expansion(of: node, providingMembersOf: declaration, in: context)
        let instanceDecl: DeclSyntax = """
        /// The main ``\(declaration.name.trimmed)`` to work with.
        ///
        /// This structure can be accessed across the app, and any mutations are observed in all views.
        static var instance: \(declaration.name.trimmed) = {
            do {
                let decoder = PropertyListDecoder()
                let data = try Data(contentsOf: \(declaration.name.trimmed).storageLocation)
                return try decoder.decode(\(declaration.name.trimmed).self, from: data)
            } catch {
                return \(declaration.name.trimmed)()
            }
        }()
        """
        
        return [instanceDecl.cast(DeclSyntax.self)] + (decodableDecl != nil ? [decodableDecl!.cast(DeclSyntax.self)] : []) + memberwiseInitializers
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let declaration = declaration.as(ClassDeclSyntax.self) else { 
            throw DiagnosticsError.shouldRemoveMacro(for: declaration, node: node, message: "@dataProviding should only be applied to `class`") }
        let shouldDeclareDataProviderInheritance = !_has(inheritance: "DataProvider", declaration: declaration)
        var shouldDeclareCodableInheritance = !_has(inheritance: "Codable", declaration: declaration)
        let isCustomCodable = _has(attribute: "customCodable", declaration: declaration)
        if shouldDeclareCodableInheritance {
            if isCustomCodable {
                shouldDeclareCodableInheritance = false
            }
        }
        
        let extensionTypes: String
        if shouldDeclareDataProviderInheritance && shouldDeclareCodableInheritance {
            extensionTypes = ": DataProvider, Codable"
        } else if shouldDeclareDataProviderInheritance {
            extensionTypes = ": DataProvider"
        } else if shouldDeclareCodableInheritance {
            extensionTypes = ": Codable"
        } else {
            extensionTypes = ""
        }
        
        return try [
            ExtensionDeclSyntax("extension \(type)\(raw: extensionTypes)") {
                if !isCustomCodable, let line = try codable.generateEncode(of: node, providingMembersOf: declaration, in: context) { line }
                if !isCustomCodable, let line = try codable.generateCodingKeys(of: node, providingMembersOf: declaration, in: context) { line }
            },
//            ExtensionDeclSyntax("extension EnvironmentValues") {
//                """
//                /// The ``\(type.trimmed)/instance`` of ``\(type.trimmed)`` stored in the environment.
//                var \(raw: type.trimmed.description.frontToLower()): \(type.trimmed) {
//                    get { self[\(type.trimmed)Key.self] }
//                    set { self[\(type.trimmed)Key.self] = newValue }
//                }
//                
//                private struct \(type.trimmed)Key: EnvironmentKey {
//                    static var defaultValue: \(type.trimmed) = .instance
//                }
//                """
//            }
        ]
    }
    
    static func assertAllMembersHaveDefaultValue(declaration: some SwiftSyntax.DeclGroupSyntax) throws {
        let _: [Void] = try _memberwiseMap(for: declaration) { variable, decl, name, type in
            guard type != .computed && !type.isStatic && !(type == .staticConstant && variable.initializer != nil) else { return }
            
            guard variable.initializer != nil else {
                throw DiagnosticsError("A default value must be provided for data provider properties", highlighting: variable,
                                       replacing: variable, message: "Provide a default value") { replacement in
                    replacement.initializer = InitializerClauseSyntax(equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
                                                                      value: EditorPlaceholderExprSyntax(placeholder: .identifier("<#default value#>")))
                }
            }
            
            return
        }
    }
    
}
