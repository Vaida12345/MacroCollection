//
//  Macro.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros


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
    
}


fileprivate extension Bool {
    
    static func implies(_ lhs: Bool, _ rhs: Bool) -> Bool {
        !lhs || rhs
    }
    
}
