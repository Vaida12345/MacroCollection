//
//  NotingMessage.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftDiagnostics


struct NotingMessage: NoteMessage {
    
    var message: String
    
    var fixItID: SwiftDiagnostics.MessageID
    
    init(message: String, diagnosticID: String) {
        self.message = message
        self.fixItID = MessageID(domain: "NucleusMacros", id: diagnosticID)
    }
    
}


extension NoteMessage {
    
    static func note(message: String, diagnosticID: String) -> NotingMessage where Self == NotingMessage {
        NotingMessage(message: message, diagnosticID: diagnosticID)
    }
    
}
