//
//  environmentTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-06-27.
//

#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions

nonisolated(unsafe) fileprivate let testMacros: [String: any Macro.Type] = [
    "environment": environment.self,
]


final class EnvironmentTests: XCTestCase {
    
    func testSingleEnvironmentKey() async throws {
        let source = #"#environment(\.undoManager)"#
        let expected = #"@Environment(\.undoManager) private var undoManager"#
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testMultipleEnvironmentKeys() async throws {
        let source = #"#environment(\.undoManager, \.dismiss)"#
        let expected = """
            @Environment(\\.undoManager) private var undoManager
            @Environment(\\.dismiss) private var dismiss
            """
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testSingleObservable() async throws {
        let source = #"#environment(Model.self)"#
        let expected = #"@Environment(Model.self) private var model"#
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testMultipleObservables() async throws {
        let source = #"#environment(Model1.self, Model2.self)"#
        let expected = """
            @Environment(Model1.self) private var model1
            @Environment(Model2.self) private var model2
            """
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
}
#endif
