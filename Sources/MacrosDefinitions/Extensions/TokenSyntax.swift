//
//  TokenSyntax.swift
//
//
//  Created by Vaida on 2024/3/6.
//

import Foundation
import Foundation
import SwiftSyntax


extension TokenSyntax {
    
    static func == (_ lhs: TokenSyntax, _ rhs: String) -> Bool {
        lhs.text == rhs
    }
    
}


extension Optional<TokenSyntax> {
    
    static func == (_ lhs: TokenSyntax?, _ rhs: String) -> Bool {
        lhs?.text == rhs
    }
    
}
