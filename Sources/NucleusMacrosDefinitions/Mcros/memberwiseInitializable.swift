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


public enum memberwiseInitializable: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else { throw memberwiseInitializableError.appliedToInvalidDeclaration }
        
        let members = memberwiseMap(for: declaration) { variable, variables, name -> CodeBlockItemSyntax in
            "self.\(raw: name) = \(raw: name)"
        }
        
        var parameters = try memberwiseMap(for: declaration) { variable, variables, name -> FunctionParameterSyntax in
            let firstName = variable.pattern.as(IdentifierPatternSyntax.self)!.identifier
            guard let type = try? variable.inferredType else { throw memberwiseInitializableError.cannotInferType(name) }
            
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
        case cannotInferType(String)
        
        var description: String {
            switch self {
            case .appliedToInvalidDeclaration:
                "@memberwiseInitializable should only be applied to `class`. Use the synthesized initializer instead"
            case let .cannotInferType(string):
                "The type of `\(string)` cannot be inferred, please declare explicitly"
            }
        }
    }
    
}
