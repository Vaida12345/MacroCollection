//
//  PatternBindingSyntax.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation
import SwiftSyntax


extension PatternBindingSyntax {
    
    /// Returns the type associated with the variable.
    internal var inferredType: any TypeSyntaxProtocol {
        get throws {
            // The base case, where the type is explicitly declared.
            if let type = self.typeAnnotation?.type {
                return type
            }
            
            return try self.initializer!.value.analysis.inferredType
        }
    }
    
}
