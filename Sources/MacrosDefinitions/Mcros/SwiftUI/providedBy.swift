//
//  providedBy.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/20.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling


public enum providedBy: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declaration = declaration.as(StructDeclSyntax.self),
              (declaration.inheritanceClause?.inheritedTypes.contains(where: { $0.type.as(IdentifierTypeSyntax.self)?.name.text == "App" }) ?? false) else {
            throw shouldRemoveMacroError(for: declaration,
                                         macroName: "@providedByData",
                                         message: "@providedByData should only be applied to @main App")
        }
        
//        guard let bodyViewBlock = declaration.memberBlock.members.first(where: { $0.as(VariableDeclSyntax.self)?.bindings.last?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body" }) else {
//            return [] // wait for other declarations
//        }
        
//        let functionName = "attachDataProviderEnvironment"
        guard let attribute = declaration.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "provided" }),
              let argument = attribute.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first(where: { $0.label?.text == "by" }),
              let providers = argument.expression.as(ArrayExprSyntax.self)?.elements.compactMap({ $0.expression.as(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName }),
              !providers.isEmpty
        else { return [] }
        
        let providersDecl = providers.map { provider in
            var name = provider.text
            name = name[name.startIndex].lowercased() + name.dropFirst()
            return VariableDeclSyntax(attributes: [.attribute(AttributeSyntax(attributeName: .identifier("State")))],
                               modifiers: [DeclModifierSyntax(name: .keyword(.private))],
                               .var,
                               name: "\(raw: name)",
                               initializer: InitializerClauseSyntax(value: MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: provider),
                                                                                                  declName: DeclReferenceExprSyntax(baseName: .identifier("instance")))))
                        .cast(DeclSyntax.self)
        }
        
        let applicationDelegateDecl: DeclSyntax = """
        #if canImport(AppKit)
        @NSApplicationDelegateAdaptor(ApplicationDelegate.self) private var applicationDelegate
        #else
        @UIApplicationDelegateAdaptor(ApplicationDelegate.self) private var applicationDelegate
        #endif
        """

        
        let applicationDelegateDef: DeclSyntax = """
        #if canImport(AppKit)
        final class ApplicationDelegate: NSObject, NSApplicationDelegate {
        
            func applicationWillTerminate(_ notification: Notification) {
                \(raw: providers.map({ "try? \($0).instance.save()" }).joined(separator: "\n"))
            }
        
            func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
                true
            }
        
            func applicationDidFinishLaunching(_ notification: Notification) {
                try? FileManager.default.createDirectory(at: URL(filePath: NSHomeDirectory() + "/Library/Application Support/DataProviders", directoryHint: .isDirectory), withIntermediateDirectories: true)
            }
        }
        #else
        final class ApplicationDelegate: NSObject, UIApplicationDelegate {
        
            func applicationWillTerminate(_ application: UIApplication) {
                \(raw: providers.map({ "try? \($0).instance.save()" }).joined(separator: "\n"))
            }
        
            func applicationDidFinishLaunching(_ application: UIApplication) {
                try? FileManager.default.createDirectory(at: URL(filePath: NSHomeDirectory() + "/Library/Application Support/DataProviders", directoryHint: .isDirectory), withIntermediateDirectories: true)
            }
        }
        #endif
        """
        
        return providersDecl + [applicationDelegateDecl, applicationDelegateDef]
    }
    
}
