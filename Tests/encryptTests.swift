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
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


@Test func encryptTests() {
    let string = "1234567890"
    let encrypted = #encrypt("1234567890")
    #expect(encrypted == string)
}

/// The cipher text is padded to a multiple of eight bytes, whose length depends on the length of the string.
@Test func encryptedStringsOfEveryPaddingRoundTrip() {
    let encrypted = [#encrypt(""), #encrypt("a"), #encrypt("ab"), #encrypt("abc"), #encrypt("abcd"), #encrypt("abcde"), #encrypt("abcdef"), #encrypt("abcdefg"), #encrypt("abcdefgh")]
    #expect(encrypted == ["", "a", "ab", "abc", "abcd", "abcde", "abcdef", "abcdefg", "abcdefgh"])
}

@Test func encryptedUnicodeRoundTrips() {
    #expect(#encrypt("héllo 🌍 ünïcode") == "héllo 🌍 ünïcode")
}


#if os(macOS)
fileprivate let testMacros: [String: any Macro.Type] = [
    "encrypt": encrypt.self,
]


final class EncryptTests: XCTestCase {
    
    func testNonLiteralIsDiagnosed() {
        // A `StaticString` parameter also takes, eg, a constant, which the macro cannot read.
        assertMacroExpansion(
            """
            #encrypt(secret)
            """,
            expandedSource: """
            #encrypt(secret)
            """,
            diagnostics: [
                DiagnosticSpec(message: "Expected a string literal", line: 1, column: 10)
            ],
            macros: testMacros
        )
    }
    
}
#endif
