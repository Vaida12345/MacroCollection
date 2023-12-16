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


public enum memberwiseInitializable: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else { throw memberwiseInitializableError.appliedToInvalidDeclaration }
        
        let members = memberwiseMap(for: declaration) { variable, variables, name -> CodeBlockItemSyntax in
            "self.\(raw: name) = \(raw: name)"
        }
        
        var parameters = try memberwiseMap(for: declaration) { variable, decl, name -> FunctionParameterSyntax? in
            let firstName = variable.pattern.as(IdentifierPatternSyntax.self)!.identifier
            let type: any TypeSyntaxProtocol
            do {
                type = try variable.inferredType
            } catch {
                var replacementNote = decl
                let lastBinding = decl.bindings.last!
                let replacementPattern = lastBinding.pattern.with(\.trailingTrivia, [])
                let replacementBinding = PatternBindingSyntax(pattern: replacementPattern,
                                                              typeAnnotation: TypeAnnotationSyntax(colon: .colonToken(trailingTrivia: .space),
                                                                                                   type: MissingTypeSyntax(placeholder: .identifier("<#type#>"),
                                                                                                                           trailingTrivia: .space)),
                                                              initializer: lastBinding.initializer
                )
                
                replacementNote.bindings[replacementNote.bindings.index(before: replacementNote.bindings.endIndex)] = replacementBinding
                
                throw DiagnosticsError(diagnostics: [
                    Diagnostic(node: declaration,
                               message: .diagnostic(message: "Type of `\(name)` cannot be inferred, please declare explicitly",
                                                    diagnosticID: "memberwiseInitializable.cannotInferType.\(name)",
                                                    severity: .error),
                               highlights: [decl.cast(Syntax.self)],
                               notes: [Note(node: decl.cast(Syntax.self), message: .note(message: "Please declare type explicitly", diagnosticID: ""))],
                               fixIt: .replace(message: .fixing(message: "Declare Type for `\(name)`", diagnosticID: "memberwiseInitializable.cannotInferType.\(name)"),
                                               oldNode: decl,
                                               newNode: replacementNote))
                ])
            }
            
            return FunctionParameterSyntax(firstName: firstName, type: type, defaultValue: variable.initializer)
        }
        for index in 0..<parameters.count {
            if index == parameters.count - 1 { break }
            parameters[index].trailingComma = .commaToken()
        }
        
        
        return [InitializerDeclSyntax(signature: .init(parameterClause: .init(parameters: .init(parameters)))) {
            for member in members {
                member
            }
        }.cast(DeclSyntax.self)]
    }
    
    enum memberwiseInitializableError: CustomStringConvertible, Error {
        case appliedToInvalidDeclaration
        
        var description: String {
            switch self {
            case .appliedToInvalidDeclaration:
                "@memberwiseInitializable should only be applied to `class`. Use the synthesized initializer instead"
            }
        }
    }
    
}
