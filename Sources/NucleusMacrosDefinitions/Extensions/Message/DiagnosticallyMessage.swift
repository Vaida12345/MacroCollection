//
//  DiagnosticallyMessage.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/16.
//

import Foundation
import SwiftDiagnostics

struct DiagnosticallyMessage: DiagnosticMessage {
    
    var message: String
    
    var diagnosticID: SwiftDiagnostics.MessageID
    
    var severity: SwiftDiagnostics.DiagnosticSeverity
    
    init(message: String, diagnosticID: String, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = MessageID(domain: "NucleusMacros", id: diagnosticID)
        self.severity = severity
    }
    
}


extension DiagnosticMessage {
    
    static func diagnostic(message: String, diagnosticID: String, severity: SwiftDiagnostics.DiagnosticSeverity = .error) -> DiagnosticallyMessage where Self == DiagnosticallyMessage {
        DiagnosticallyMessage(message: message, diagnosticID: diagnosticID, severity: severity)
    }
    
}
