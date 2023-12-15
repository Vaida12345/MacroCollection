//
//  Extensions.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation
import SwiftSyntax


extension TypeSyntaxProtocol {
    
    static func identifier(_ syntax: TokenSyntax) -> IdentifierTypeSyntax where Self == IdentifierTypeSyntax {
        IdentifierTypeSyntax(name: syntax)
    }
    
}
