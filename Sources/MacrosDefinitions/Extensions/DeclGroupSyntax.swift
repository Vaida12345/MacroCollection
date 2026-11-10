//
//  DeclGroupSyntax.swift
//  MacroCollection
//
//  Created by Vaida on 2026-11-10.
//

import SwiftSyntax


internal extension DeclGroupSyntax {
    
    /// The access control to give the declarations that a macro adds to this one: `public`, `package`, or none.
    ///
    /// A declaration has to be as accessible as its type to witness a requirement of a protocol, hence the access control is copied.
    ///
    /// - Parameter allowingOpen: Whether `open` is copied. Only classes, and their overridable members, can be `open`, hence everything else gets `public` instead.
    func accessModifiers(allowingOpen: Bool = false) -> DeclModifierListSyntax {
        for modifier in self.modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.open):
                return [DeclModifierSyntax(name: .keyword(allowingOpen ? .open : .public))]
            case .keyword(.public):
                return [DeclModifierSyntax(name: .keyword(.public))]
            case .keyword(.package):
                return [DeclModifierSyntax(name: .keyword(.package))]
            default:
                continue
            }
        }
        
        return []
    }
    
}
