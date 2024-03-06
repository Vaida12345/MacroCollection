//
//  FixingMessage.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftDiagnostics


struct FixingMessage: FixItMessage {
    
    var message: String
    
    var fixItID: SwiftDiagnostics.MessageID
    
    init(message: String, diagnosticID: String) {
        self.message = message
        self.fixItID = MessageID(domain: "NucleusMacros", id: diagnosticID)
    }
    
}


extension FixItMessage {
    
    static func fixing(message: String, diagnosticID: String) -> FixingMessage where Self == FixingMessage {
        FixingMessage(message: message, diagnosticID: diagnosticID)
    }
    
}
