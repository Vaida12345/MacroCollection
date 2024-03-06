//
//  DiagnosticsError.swift
//  
//
//  Created by Vaida on 2024/3/6.
//

import Foundation
import SwiftDiagnostics
import SwiftSyntax

extension DiagnosticsError {
    
    init<Node>(_ title: String, highlighting node: some SyntaxProtocol, replacing oldNode: Node, message: String, with handler: (_ replacement: inout Node) -> Void) where Node: SyntaxProtocol {
        let id = UUID().description
        
        var copy = oldNode
        handler(&copy)
        
        self.init(diagnostics: [
            Diagnostic(node: node, message: .diagnostic(message: title, diagnosticID: id), fixIt: .replace(message: .fixing(message: message, diagnosticID: id), oldNode: oldNode, newNode: copy))
        ])
    }
    
}
