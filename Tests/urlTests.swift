//
//  urlTests.swift
//  MacroCollection
//
//  Created by Vaida on 2026-11-10.
//

#if os(macOS)
import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions
@testable import MacroCollection

@available(macOS 14.0, *)
fileprivate let testMacros: [String: any Macro.Type] = [
    "url": url.self,
]


@available(macOS 14.0, *)
final class UrlTests: XCTestCase {
    
    func testUrl() {
        assertMacroExpansion(
            """
            #url("https://example.com/cat")
            """,
            expandedSource: """
            URL(string: "https://example.com/cat", encodingInvalidCharacters: true)!
            """,
            macros: testMacros
        )
    }
    
    func testStringWithoutSchemeIsRelativeUrl() {
        assertMacroExpansion(
            """
            #url("cat")
            """,
            expandedSource: """
            URL(string: "cat", encodingInvalidCharacters: true)!
            """,
            macros: testMacros
        )
    }
    
    func testNotAnUrlIsDiagnosed() {
        assertMacroExpansion(
            """
            #url("")
            """,
            expandedSource: """
            #url("")
            """,
            diagnostics: [
                DiagnosticSpec(message: "The given string is not an url.", line: 1, column: 6)
            ],
            macros: testMacros
        )
    }
    
    func testNonLiteralIsDiagnosed() {
        // A `StaticString` parameter also takes, eg, a constant, which the macro cannot read.
        assertMacroExpansion(
            """
            #url(address)
            """,
            expandedSource: """
            #url(address)
            """,
            diagnostics: [
                DiagnosticSpec(message: "Expected a string literal", line: 1, column: 6)
            ],
            macros: testMacros
        )
    }
    
    func testInvalidCharactersAreEncoded() {
        XCTAssertEqual(#url("https://example.com/a b").absoluteString, "https://example.com/a%20b")
        XCTAssertEqual(#url("cat").absoluteString, "cat")
    }
    
}
#endif
