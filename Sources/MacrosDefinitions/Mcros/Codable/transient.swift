//
//  transient.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros


public enum transient: PeerMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, 
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        try encodeOptions.expansion(of: node, providingPeersOf: declaration, in: context) // check if the macro should be removed.
    }
    
}
