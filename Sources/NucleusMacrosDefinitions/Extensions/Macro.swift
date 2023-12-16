//
//  Macro.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics


extension Macro {
    
    /// Applies map to every member, ie, properties to a Data Type.
    ///
    /// - Parameters:
    ///   - declaration: The data type declaration.
    ///   - ignoreComputedProperties: If `true`, computed properties and type properties will be ignored.
    ///   - ignoreConstantProperties: If `true`, initialized constant properties will be ignored, such as, `let a = 1`.
    ///   - handler: The handler for building the return value.
    ///   - variable: Each property itself.
    ///   - decl: The declaration in which the `variable` is defined.
    ///   - name: The shorthand for `variable` name.
    internal static func memberwiseMap<T>(for declaration: some SwiftSyntax.DeclGroupSyntax,
                                          ignoreComputedProperties: Bool = true,
                                          ignoreConstantProperties: Bool = true,
                                          handler: (_ variable: PatternBindingListSyntax.Element, _ decl: VariableDeclSyntax, _ name: String) throws -> T?
    ) rethrows -> [T] {
        let lines: [[T]] = try declaration.memberBlock.members.map { member in
            guard let variables = member.decl.as(VariableDeclSyntax.self), Bool.implies(ignoreComputedProperties, variables.isStoredInstanceProperty) else { return [] }
            
            // there may be multiple identifiers associated with the same member declaration, ie, `let a, b = 1`
            return try variables.bindings.compactMap { variable -> T? in
                guard let name = variable.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
                
                // if constant property with default value, ignore.
                if Bool.implies(ignoreConstantProperties, variables.bindingSpecifier.tokenKind == .keyword(.let) && variable.initializer != nil) { return nil }
                
                return try handler(variable, variables, name)
            }
        }
        return lines.flatMap({ $0 })
    }
    
    internal static func getType(for variable: PatternBindingListSyntax.Element, decl: VariableDeclSyntax, name: String, of declaration: some SyntaxProtocol) throws -> any TypeSyntaxProtocol {
        do {
            return try variable.inferredType
        } catch {
            // additional info: what if it is an initializer?
            var replacementNote = decl
            let lastBinding = decl.bindings.last!
            
            var typeName: String?
            if let initializer = lastBinding.initializer,
               let value = initializer.value.as(FunctionCallExprSyntax.self),
               let baseName = value.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName,
               baseName.text.first?.isUppercase ?? false {
                typeName = baseName.text
            }
                
                
            let replacementPattern = lastBinding.pattern.with(\.trailingTrivia, [])
            let replacementBinding = PatternBindingSyntax(pattern: replacementPattern,
                                                          typeAnnotation: TypeAnnotationSyntax(colon: .colonToken(trailingTrivia: .space),
                                                                                               type: MissingTypeSyntax(placeholder: .identifier(typeName ?? "<#type#>"),
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
    }
    
}


fileprivate extension Bool {
    
    static func implies(_ lhs: Bool, _ rhs: Bool) -> Bool {
        !lhs || rhs
    }
    
}
