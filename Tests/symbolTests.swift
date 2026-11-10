//
//  symbolTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-07-05.
//

import Testing
import MacroCollection

@Test func symbolTest() {
    #expect(#symbol("shippingbox") == "shippingbox")
}


#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions

fileprivate let testMacros: [String: any Macro.Type] = [
    "symbol": symbol.self,
]


final class SymbolTests: XCTestCase {
    
    func testSymbol() {
        assertMacroExpansion(
            """
            #symbol("shippingbox")
            """,
            expandedSource: """
            "shippingbox"
            """,
            macros: testMacros
        )
    }
    
    func testUnknownSymbolIsDiagnosed() {
        assertMacroExpansion(
            """
            #symbol("no.such.symbol")
            """,
            expandedSource: """
            #symbol("no.such.symbol")
            """,
            diagnostics: [
                DiagnosticSpec(message: "No such symbol `no.such.symbol`.", line: 1, column: 9)
            ],
            macros: testMacros
        )
    }
    
    func testNonLiteralIsDiagnosed() {
        // A `StaticString` parameter also takes, eg, a constant, which the macro cannot read.
        assertMacroExpansion(
            """
            #symbol(name)
            """,
            expandedSource: """
            #symbol(name)
            """,
            diagnostics: [
                DiagnosticSpec(message: "Expected a string literal", line: 1, column: 9)
            ],
            macros: testMacros
        )
    }
    
}
#endif
