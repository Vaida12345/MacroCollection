//
//  AttributeDeclMacroTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-06-27.
//

#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions

fileprivate let testMacros: [String: any Macro.Type] = [
    "environment": AttributeDeclMacro.self,
    "appStorage": AttributeDeclMacro.self,
]


final class EnvironmentTests: XCTestCase {
    
    func testSingleEnvironmentKey() async throws {
        let source = #"#environment(\.undoManager)"#
        let expected = #"@Environment(\.undoManager) private var undoManager"#
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    func testSingleEnvironmentKeyInStruct() async throws {
        let source = """
        struct Model {
            #environment(\\.undoManager)
        }
        """
        let expected = """
        struct Model {
            @Environment(\\.undoManager) private var undoManager
        }
        """
        
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
    
    func testSingleAppStorage() async throws {
        let source = #"#appStorage(\.memorySaver)"#
        let expected = #"@AppStorage(\.memorySaver) private var memorySaver"#
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }

    func testMultipleAppStorageKeys() async throws {
        let source = #"#appStorage(\.memorySaver, \.launchCount)"#
        let expected = """
            @AppStorage(\\.memorySaver) private var memorySaver
            @AppStorage(\\.launchCount) private var launchCount
            """

        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }

    func testObservableNameLowercasing() async throws {
        let source = #"#environment(URLModel.self)"#
        let expected = #"@Environment(URLModel.self) private var uRLModel"#

        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }

    func testNestedKeyPathNotSupported() async throws {
        assertMacroExpansion(
            #"#environment(\.foo.bar)"#,
            expandedSource: #"#environment(\.foo.bar)"#,
            diagnostics: [
                DiagnosticSpec(
                    message: "Nested key path is not supported",
                    line: 1,
                    column: 14
                )
            ],
            macros: testMacros
        )
    }

    func testTypeReferenceWithoutSelfIsUnsupported() async throws {
        assertMacroExpansion(
            #"#environment(Model)"#,
            expandedSource: #"#environment(Model)"#,
            diagnostics: [
                DiagnosticSpec(
                    message: "Unsupported arguments",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func testTypeReferenceWithoutBaseIsRejected() async throws {
        assertMacroExpansion(
            #"#environment(.self)"#,
            expandedSource: #"#environment(.self)"#,
            diagnostics: [
                DiagnosticSpec(
                    message: "Expected type reference",
                    line: 1,
                    column: 14
                )
            ],
            macros: testMacros
        )
    }

    func testMixedArgumentKindsAreRejected() async throws {
        assertMacroExpansion(
            #"#environment(\.undoManager, Model.self)"#,
            expandedSource: #"#environment(\.undoManager, Model.self)"#,
            diagnostics: [
                DiagnosticSpec(
                    message: "Mixing argument types is not allowed",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
    
}
#endif
