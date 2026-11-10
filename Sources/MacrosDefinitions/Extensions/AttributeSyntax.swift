//
//  AttributeSyntax.swift
//  MacroCollection
//
//  Created by Vaida on 2026-11-10.
//

import SwiftSyntax


internal extension AttributeSyntax {
    
    /// The name of the attribute, without the module, ie, `codable` for both `@codable` and `@MacroCollection.codable`.
    var baseName: String? {
        if let type = self.attributeName.as(IdentifierTypeSyntax.self) { return type.name.text }
        if let type = self.attributeName.as(MemberTypeSyntax.self) { return type.name.text }
        
        return nil
    }
    
}
