//
//  encryptTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-07-05.
//

import Foundation
import Testing
import MacroCollection
@testable import MacrosDefinitions
import SwiftSyntaxMacrosTestSupport
import XCTest


@Test func encryptTests() {
    let string = "1234567890"
    let encrypted = #encrypt("1234567890")
    #expect(encrypted == string)
}

@Test func encryptTestsSegmented() {
    assertMacroExpansion(
        #"""
             #encrypt("123\n456")
        """#,
        expandedSource: #"""
             "123\n456"
            """#,
        macros: [
            "encrypt" : MacrosDefinitions.encrypt.self
        ]
    )
}
