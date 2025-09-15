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

nonisolated(unsafe) fileprivate let testMacros: [String: any Macro.Type] = [
    "varyArgumentType": varyArgumentType.self,
]


final class VaryTests: XCTestCase {
    
    func testExample() async throws {
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
    
}
#endif
