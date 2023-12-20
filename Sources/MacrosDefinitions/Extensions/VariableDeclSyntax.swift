//
//  Extensions.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation
import SwiftSyntax


extension VariableDeclSyntax {
    
    /// Determines whether the variable is a stored instance property.
    ///
    /// - Note: `weak` and `unowned` are considered stored instance property
    internal var isStoredInstanceProperty: Bool {
        if modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
            // if it is `static`, then it is type property, ignored.
            return false
        }
        
        guard let binding = self.bindings.last else { return false } // only observe the last binding. As only the last binding is declared in full.
        
        switch binding.accessorBlock?.accessors {
        case nil:
            return true
        case let .accessors(accessors):
            for accessor in accessors {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.get), .keyword(.set):
                    return false
                default:
                    continue
                }
            }
            return true
        case .getter:
            return false
        }
    }
    
}
