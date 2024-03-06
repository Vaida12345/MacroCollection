//
//  IdentifierTypeSyntax.swift
//
//
//  Created by Vaida on 2024/3/6.
//

import Foundation
import Foundation
import SwiftSyntax


extension IdentifierTypeSyntax {
    
    static func == (_ lhs: IdentifierTypeSyntax, _ rhs: String) -> Bool { lhs.name == rhs }

}


extension Optional<IdentifierTypeSyntax> {
    
    static func == (_ lhs: IdentifierTypeSyntax?, _ rhs: String) -> Bool { lhs?.name == rhs }
    
}
