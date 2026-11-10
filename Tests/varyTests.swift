//
//  varyTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-09-15.
//


#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions
@testable import MacroCollection

fileprivate let testMacros: [String: any Macro.Type] = [
    "varyArgumentType": varyArgumentType.self,
]


final class VaryTests: XCTestCase {
    
    func testSingle() async throws {
        let source = """
            @varyArgumentType(String.self, variation: Int.self)
            func a(input: String) {
                
            }
            """
        let expected = """
            
            func a(input: String) {
                
            }
            
            func a(input: Int) {
            
            }
            """
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testInit() async throws {
        let source = """
            @varyArgumentType(String.self, variation: Int.self)
            init(input: String) {
            
            }
            """
        let expected = """
            
            init(input: String) {
            
            }
            
            init(input: Int) {
            
            }
            """
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testMultiple() async throws {
        let source = """
            @varyArgumentType(String.self, variation: Int.self)
            @varyArgumentType(String.self, variation: Bool.self)
            func a(input: String) {
                
            }
            """
        let expected = """
            
            func a(input: String) {
                
            }
            
            func a(input: Int) {
            
            }
            
            func a(input: Bool) {
            
            }
            """
            
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testDefaultValueIsNotCopied() async throws {
        let source = """
            @varyArgumentType(String.self, variation: Int.self)
            func a(input: String = "input", other: String) {
            
            }
            """
        let expected = """
            
            func a(input: String = "input", other: String) {
            
            }
            
            func a(input: Int, other: Int) {
            
            }
            """
            
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testOnlyExactTypesAreVaried() async throws {
        let source = """
            @varyArgumentType(String.self, variation: Int.self)
            func a(input: String, other: String?, many: [String]) {
            
            }
            """
        let expected = """
            
            func a(input: String, other: String?, many: [String]) {
            
            }
            
            func a(input: Int, other: String?, many: [String]) {
            
            }
            """
            
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testNoParameterToVaryIsDiagnosed() async throws {
        assertMacroExpansion(
            """
            @varyArgumentType(String.self, variation: Int.self)
            func a(input: String?) {
            
            }
            """,
            expandedSource: """
            
            func a(input: String?) {
            
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "No parameter is declared as `String`, hence there is nothing to vary",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @varyArgumentType")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    func testGenericsAreDiagnosed() async throws {
        assertMacroExpansion(
            """
            @varyArgumentType(String.self, variation: Int.self)
            func a<T>(input: String, other: T) where T: Equatable {
            
            }
            """,
            expandedSource: """
            
            func a<T>(input: String, other: T) where T: Equatable {
            
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@varyArgumentType` does not work with generics",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @varyArgumentType")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    func testUnsupportedDeclarationIsDiagnosed() async throws {
        assertMacroExpansion(
            """
            @varyArgumentType(String.self, variation: Int.self)
            struct Cat {
            
            }
            """,
            expandedSource: """
            struct Cat {
            
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`@varyArgumentType` does not work on this type of declaration.",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @varyArgumentType")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Compiled Usage
    
    // Unlike the expansion tests, these let the compiler expand the macros, and compile the result.
    
    struct Printer {
        
        @varyArgumentType(String.self, variation: Int.self)
        @varyArgumentType(String.self, variation: Bool.self)
        func describe(_ input: String, suffix: Character = "!") -> String {
            "\(input)\(suffix)"
        }
        
        let value: String
        
        @varyArgumentType(String.self, variation: Int.self)
        init(value: String) {
            self.value = "\(value)"
        }
    }
    
    func testVariationsCompile() {
        let printer = Printer(value: "a")
        XCTAssertEqual(printer.describe("a"), "a!")
        XCTAssertEqual(printer.describe("a", suffix: "?"), "a?")
        XCTAssertEqual(printer.describe(1, suffix: "?"), "1?")
        XCTAssertEqual(printer.describe(true, suffix: "?"), "true?")
        XCTAssertEqual(Printer(value: 3).value, "3")
    }
    
}

// A global function is only allowed to be overloaded, not to introduce arbitrary names.
@varyArgumentType(String.self, variation: Int.self)
func compiledGlobalVariation(_ input: String) -> String {
    "\(input)"
}

#endif
