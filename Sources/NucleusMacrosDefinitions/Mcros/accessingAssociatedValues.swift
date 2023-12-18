//
//  accessingAssociatedValues.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/18.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder


public enum accessingAssociatedValues: ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let declaration = declaration.as(EnumDeclSyntax.self) else { throw shouldRemoveMacroError(for: declaration,
                                                                                                        macroName: "@accessingAssociatedValues",
                                                                                                        message: "@codable should only be applied to `enum`") }
        
        let enumMembers = declaration.memberBlock.members.flatMap { members in
            let decl = members.decl.as(EnumCaseDeclSyntax.self)!
            return decl.elements.map {
                EnumMember(decl: decl, name: $0.name, parameterClause: $0.parameterClause)
            }
        }
        
        let modifiers = declaration.modifiers.filter({ $0.name == .keyword(.public) || $0.name == .keyword(.open) }).map(\.name.text).joined(separator: " ")
        
        let asFunction = try FunctionDeclSyntax("\(raw: asDocumentation)\n\(raw: modifiers)func `as`<T>(_ property: EnumProperty<T>) -> T?") {
            try SwitchExprSyntax("switch property.root") {
                for member in enumMembers {
                    SwitchCaseSyntax("case .\(member.name):") {
                        if let args = member.args {
                            "if case let .\(member.name)(\(raw: args.map{ $0.0.text }.joined(separator: ", "))) = self { return (\(raw: args.map{ $0.0.text }.joined(separator: ", "))) as? T }"
                        } else {
                            "if case .\(member.name) = self { return nil }"
                        }
                    }
                }
            }
            
            "return nil"
        }
        
        let isFunction = try FunctionDeclSyntax("\(raw: isDocumentation)\n\(raw: modifiers)func `is`<T>(_ property: EnumProperty<T>) -> Bool") {
            try SwitchExprSyntax("switch property.root") {
                for member in enumMembers {
                    SwitchCaseSyntax("case .\(member.name):") {
                        "if case .\(member.name) = self { return true }"
                    }
                }
            }
            
            "return false"
        }
        
        let propertyStruct = try StructDeclSyntax("\(raw: propertyStructDocumentation.replacingOccurrences(of: "``Model``", with: "``\(declaration.name.text)``"))\n\(raw: modifiers)struct EnumProperty<T>") {
            
            try EnumDeclSyntax("""
                           /// The cases used as an identifier to the property.
                           fileprivate enum __Case
                           """) {
                "case \(raw: enumMembers.map(\.name).map(\.text).joined(separator: ", "))"
            }
            
            """
            /// The property identifier.
            fileprivate let root: __Case
            
            fileprivate init(root: __Case) {
                self.root = root
            }
            """
            
            for member in enumMembers {
                """
                /// Indicates the value of ``\(declaration.name)/\(raw: member.caseName)``
                static var \(member.name): EnumProperty<\(raw: member.type)> { EnumProperty<\(raw: member.type)>(root: .\(member.name)) }
                """
            }
            
        }
        
        return try [ExtensionDeclSyntax("extension \(declaration.name)") {
            asFunction
            isFunction
            propertyStruct
        }]
    }
    
    struct EnumMember {
        
        let decl: EnumCaseDeclSyntax
        
        let name: TokenSyntax
        
        let parameterClause: EnumCaseParameterClauseSyntax?
        
        var args: [(TokenSyntax, TypeSyntax)]? {
            guard let parameterClause else { return nil }
            return parameterClause.parameters.enumerated().map { (index, element) in (element.firstName ?? IdentifierTypeSyntax(name: .identifier("v\(index)")).cast(TokenSyntax.self), element.type) }
        }
        
        var rawArgs: [(TokenSyntax?, TypeSyntax)]? {
            guard let parameterClause else { return nil }
            return parameterClause.parameters.map { element in (element.firstName, element.type) }
        }
        
        var caseName: String {
            var caseName = "\(self.name)"
            
            if let rawArgs = self.rawArgs {
                caseName += "(" + rawArgs.map { name, _ in
                    "\(name ?? "_"):"
                }.joined(separator: "") + ")"
            }
            
            return caseName
        }
        
        var type: String {
            guard let rawArgs else { return "Void" }
            
            if rawArgs.count == 1 {
                return rawArgs[0].1.description
            } else {
                return "(\(rawArgs.map(\.1.description).joined(separator: ", "))"
            }
        }
        
    }
    
    static let asDocumentation = """
    /// Returns the value associated with `property`, if the case matches.
    ///
    /// This method can be considered as an alternative to `if case let`.
    ///
    /// ```swift
    /// enum Model {
    ///     case car(name: String)
    ///     case bus(length: Int)
    /// }
    ///
    /// let shortBus: Model = .bus(length: 10)
    /// shortBus.as(.bus) // 10
    /// shortBus.as(.car) // nil
    /// ```
    ///
    /// The *casting* is considered successful if the case matches `property`, and returns the value associated with it.
    ///
    /// If there isn't any value associated with `property`, this function would always return `nil`.
    ///
    /// - SeeAlso: If you are not interested in the value associated with `property`, see ``as(_:)``.
    """
    
    static let isDocumentation = """
    /// Returns whether the given case matches `property`.
    ///
    /// This method can be considered as an alternative to `if case`.
    ///
    /// ```swift
    /// enum Model {
    ///     case car(name: String)
    ///     case bus(length: Int)
    /// }
    ///
    /// let shortBus: Model = .bus(length: 10)
    /// shortBus.is(.bus) // true
    /// shortBus.is(.car) // false
    /// ```
    ///
    /// - SeeAlso: If you want to retrieve the value associated with `property`, see ``as(_:)``.
    """
    
    static let propertyStructDocumentation = """
    /// Auto generated type to access properties for ``Model``.
    ///
    /// - Important: Please do not interact with this structure directly.
    """
    
    
}
