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
import SwiftDiagnostics


public enum accessingAssociatedValues: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(EnumDeclSyntax.self) else {
            throw DiagnosticsError.shouldRemoveMacro(attributes: declaration.attributes, node: node, message: "@codable should only be applied to `enum`")
        }
        
        let needPublicModifier = declaration.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) })
        let enumMembers = declaration.memberBlock.members.flatMap { member in
            let decl = member.decl.as(EnumCaseDeclSyntax.self)!
            return decl.elements.map {
                EnumMember(decl: decl, name: $0.name, parameterClause: $0.parameterClause)
            }
        }
        
        let asFunction = try FunctionDeclSyntax("\(raw: asDocumentation)\nfunc `as`<T>(_ property: EnumProperty<T>) -> T?") {
            try SwitchExprSyntax("switch property.root") {
                for member in enumMembers {
                    SwitchCaseSyntax("case .\(member.name):") {
                        if let args = member.args {
                            let tuple = args.map{ $0.0.text.trimmingCharacters(in: .whitespaces) }.joined(separator: ", ")
                            "if case let .\(member.name)(\(raw: tuple)) = self { return (\(raw: tuple)) as? T }"
                        } else {
                            "if case .\(member.name) = self { return () as? T }"
                        }
                    }
                }
            }
            
            "return nil"
        }
        
        let isFunction = try FunctionDeclSyntax("\(raw: isDocumentation)\nfunc `is`<T>(_ property: EnumProperty<T>) -> Bool") {
            try SwitchExprSyntax("switch property.root") {
                for member in enumMembers {
                    SwitchCaseSyntax("case .\(member.name):") {
                        "if case .\(member.name) = self { return true }"
                    }
                }
            }
            
            "return false"
        }
        
        let propertyStruct = try StructDeclSyntax("\(raw: propertyStructDocumentation.replacingOccurrences(of: "``Model``", with: "``\(declaration.name.text)``"))\nstruct EnumProperty<T>: Sendable") {
            
            try EnumDeclSyntax("""
                           /// The cases used as an identifier to the property.
                           fileprivate enum __Case: Sendable
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
                /// Indicates the value of ``\(declaration.name.trimmed)/\(raw: member.caseName)``
                \(raw: needPublicModifier ? "public" : "") static var \(member.name): EnumProperty<\(raw: member.type)> { EnumProperty<\(raw: member.type)>(root: .\(member.name)) }
                """
            }
            
        }
        
        return [
            DeclSyntax(asFunction),
            DeclSyntax(isFunction),
            DeclSyntax(propertyStruct)
        ]
    }
    
    struct EnumMember {
        
        let decl: EnumCaseDeclSyntax
        
        let name: TokenSyntax
        
        let parameterClause: EnumCaseParameterClauseSyntax?
        
        var args: [(TokenSyntax, TypeSyntax)]? {
            guard let parameterClause else { return nil }
            return parameterClause.parameters.enumerated().map { (index, element) in (element.firstName ?? TokenSyntax.identifier("v\(index)"), element.type) }
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
                return "(\(rawArgs.map({ ($0.0.map({ "\($0):" }) ?? "") + "\($0.1)" }).joined(separator: ", ")))"
            }
        }
        
    }
    
    static let asDocumentation: StaticString = """
    /// Returns the value associated with `property`, if the case matches.
    ///
    /// This method can be considered as an alternative to `if case let`.
    ///
    /// ```swift
    /// @accessingAssociatedValues
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
    /// If there isn't any value associated with `property`, this function would always return `Void`.
    ///
    /// - SeeAlso: If you are not interested in the value associated with `property`, see ``is(_:)``.
    """
    
    static let isDocumentation: StaticString = """
    /// Returns whether the given case matches `property`.
    ///
    /// This method can be considered as an alternative to `if case`.
    ///
    /// ```swift
    /// @accessingAssociatedValues
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
    
    static let propertyStructDocumentation: String = """
    /// Auto generated type to access properties for ``Model``.
    ///
    /// You can use the static properties to retrieve enum cases.
    """
    
    
}
