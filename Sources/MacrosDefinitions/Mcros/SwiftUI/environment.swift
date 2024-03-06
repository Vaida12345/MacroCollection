//
//  environment.swift
//  NucleusMacros
//
//  Created by Vaida on 2024/2/24.
//

#if canImport(SwiftUI)
import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPluginMessageHandling
import SwiftUI


public enum environment: DeclarationMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, 
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        let nodes: [SwiftSyntax.DeclSyntax] = node.as(MacroExpansionDeclSyntax.self)!.arguments.compactMap {
            guard let identifier = $0.expression.as(KeyPathExprSyntax.self)?.components.last?.component else { return nil }
            return DeclSyntax("@Environment(\\.\(identifier)) private var \(identifier)")
        }
        
        guard nodes.isEmpty else { return nodes }
        return node.as(MacroExpansionDeclSyntax.self)!.arguments.compactMap {
            guard let identifier = $0.expression.as(MemberAccessExprSyntax.self)?.base else { return nil }
            return DeclSyntax("@Environment(\($0)) private var \(raw: identifier.description.frontToLower())")
        }
    }
    
    
}


internal extension String {
    func frontToLower() -> String {
        guard !self.isEmpty else { return "" }
        return self.replacingCharacters(in: self.startIndex..<self.index(after: self.startIndex), with: self.first!.lowercased())
    }
}

#endif
