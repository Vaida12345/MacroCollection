//
//  memberwiseTests.swift
//  MacroCollection
//
//  Created by Vaida on 2026-11-10.
//

#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions
@testable import MacroCollection

fileprivate let testMacros: [String: any Macro.Type] = [
    "memberwiseInitializable": memberwiseInitializable.self,
]


final class MemberwiseInitializableTests: XCTestCase {
    
    // MARK: - Generated Members
    
    func testClass() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            class Cat {
                let name: String = "cat"
                let age: Int
            }
            """,
            expandedSource: """
            class Cat {
                let name: String = "cat"
                let age: Int

                init(age: Int) {
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testStruct() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String
                var age: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String
                var age: Int

                init(name: String, age: Int) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testActor() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            actor Cat {
                var name: String
            }
            """,
            expandedSource: """
            actor Cat {
                var name: String

                init(name: String) {
                    self.name = name
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testAllPropertiesHaveDefaultValues() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String = "cat"
                var age = 3
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String = "cat"
                var age = 3

                init(name: String = "cat", age: Int = 3) {
                    self.name = name
                    self.age = age
                }

                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testNoStoredProperties() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
            }
            """,
            expandedSource: """
            struct Cat {

                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testNonStoredPropertiesAreIgnored() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String
                static var count = 0
                static let limit = 9
                lazy var cache: [String] = []
                var description: String { name }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String
                static var count = 0
                static let limit = 9
                lazy var cache: [String] = []
                var description: String { name }

                init(name: String) {
                    self.name = name
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testBackticksArePreserved() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var `default`: Int
                var `class`: String
            }
            """,
            expandedSource: """
            struct Cat {
                var `default`: Int
                var `class`: String

                init(`default`: Int, `class`: String) {
                    self.`default` = `default`
                    self.`class` = `class`
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testTrailingCommentsAreNotCopiedIntoTheSignature() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String // the name
                var age: Int = 3 // the age
                var tag = "x" // the tag
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String // the name
                var age: Int = 3 // the age
                var tag = "x" // the tag

                init(name: String, age: Int = 3, tag: String = "x") {
                    self.name = name
                    self.age = age
                    self.tag = tag
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testSignedLiteralsAreInferred() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var index = -1
            }
            """,
            expandedSource: """
            struct Cat {
                var index = -1

                init(index: Int = -1) {
                    self.index = index
                }

                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testSharedTypeAnnotation() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var a, b: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var a, b: Int

                init(a: Int, b: Int) {
                    self.a = a
                    self.b = b
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testTupleTypesKeepTheirLabels() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var point = (x: 1, y: 2)
            }
            """,
            expandedSource: """
            struct Cat {
                var point = (x: 1, y: 2)

                init(point: (x: Int, y: Int) = (x: 1, y: 2)) {
                    self.point = point
                }

                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testTypesSpelledByTheInitializerAreInferred() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var items = [String]()
                var ids = Set<Int>()
            }
            """,
            expandedSource: """
            struct Cat {
                var items = [String]()
                var ids = Set<Int>()

                init(items: [String] = [String](), ids: Set<Int> = Set<Int>()) {
                    self.items = items
                    self.ids = ids
                }

                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testOverriddenObserversAreNotAssigned() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            class Dog: Animal {
                var tricks: [String]
                override var name: String { didSet { print(name) } }
            }
            """,
            expandedSource: """
            class Dog: Animal {
                var tricks: [String]
                override var name: String { didSet { print(name) } }

                init(tricks: [String]) {
                    self.tricks = tricks
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testComputedAccessorsAreNotAssigned() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var _age: Int
                var age: Int { _read { yield _age } }
            }
            """,
            expandedSource: """
            struct Cat {
                var _age: Int
                var age: Int { _read { yield _age } }

                init(_age: Int) {
                    self._age = _age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Existing Initializers
    
    func testExistingInitializerWithSameSignatureSuppressesGeneration() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String
                var age: Int

                init(name: String, age: Int) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String
                var age: Int

                init(name: String, age: Int) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testExistingInitializerWithRenamedParameterSuppressesGeneration() {
        // `init(name n:)` and `init(name:)` share the argument label, so they would be redeclarations of each other.
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String
                init(name n: String) { self.name = n }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String
                init(name n: String) { self.name = n }
            }
            """,
            macros: testMacros
        )
    }
    
    func testExistingInitializersWithDifferentSignaturesDoNotSuppressGeneration() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var names: [String]
                init(names: [Int]) { self.names = [] }
                init(_ names: [String]) { self.names = names }
            }
            """,
            expandedSource: """
            struct Cat {
                var names: [String]
                init(names: [Int]) { self.names = [] }
                init(_ names: [String]) { self.names = names }

                init(names: [String]) {
                    self.names = names
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testParameterOrderIsPartOfTheSignature() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var a: Int
                var b: Int
                init(b: Int, a: Int) { self.a = a; self.b = b }
            }
            """,
            expandedSource: """
            struct Cat {
                var a: Int
                var b: Int
                init(b: Int, a: Int) { self.a = a; self.b = b }

                init(a: Int, b: Int) {
                    self.a = a
                    self.b = b
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testExistingEmptyInitializerSuppressesSynthesizedEmptyInitializer() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            struct Cat {
                var name: String = "cat"

                init() { }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String = "cat"

                init() { }

                init(name: String = "cat") {
                    self.name = name
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Access Control
    
    func testPublicAccessControl() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(.public)
            public struct Cat {
                var name: String = "cat"
                var age = 3
            }
            """,
            expandedSource: """
            public struct Cat {
                var name: String = "cat"
                var age = 3

                public init(name: String = "cat", age: Int = 3) {
                    self.name = name
                    self.age = age
                }

                public init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testInternalAccessControl() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(.internal)
            struct Cat {
                var age: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int

                internal init(age: Int) {
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testPrivateAccessControl() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(.private)
            struct Cat {
                var age: Int = 3
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 3

                private init(age: Int = 3) {
                    self.age = age
                }

                private init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testAccessControlOnClass() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(.public)
            public final class Cat {
                public var name: String
                private var age: Int = 3
            }
            """,
            expandedSource: """
            public final class Cat {
                public var name: String
                private var age: Int = 3

                public init(name: String, age: Int = 3) {
                    self.name = name
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testAccessControlOnActor() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(.public)
            public actor Cat {
                var age: Int = 3
            }
            """,
            expandedSource: """
            public actor Cat {
                var age: Int = 3

                public init(age: Int = 3) {
                    self.age = age
                }

                public init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testNilAccessControlLeavesAccessUnspecified() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(nil)
            struct Cat {
                var age: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int

                init(age: Int) {
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testAccessControlWrittenWithItsType() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(AccessControl.public)
            public struct Cat {
                var age: Int
            }
            """,
            expandedSource: """
            public struct Cat {
                var age: Int

                public init(age: Int) {
                    self.age = age
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // MARK: - Diagnostics
    
    func testNonLiteralAccessControlIsDiagnosed() {
        assertMacroExpansion(
            """
            @memberwiseInitializable(level)
            public struct Cat {
                var age: Int = 3
            }
            """,
            expandedSource: """
            public struct Cat {
                var age: Int = 3
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Expected one of `.public`, `.internal`, `.private`",
                    line: 1,
                    column: 26
                )
            ],
            macros: testMacros
        )
    }
    
    func testUnsupportedDeclarationIsDiagnosed() {
        assertMacroExpansion(
            """
            @memberwiseInitializable
            enum Cat {
                case tabby
            }
            """,
            expandedSource: """
            enum Cat {
                case tabby
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@memberwiseInitializable should only be applied to `struct`, `class`, or `actor`",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @memberwiseInitializable")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Compiled Usage
    
    // Classes, unlike structs, have no implicit memberwise initializer. Hence these only compile when the macros are expanded.
    
    @memberwiseInitializable
    final class DefaultAccess {
        var a: Int
        var b = "b"
    }
    
    @memberwiseInitializable(.public)
    final class PublicAccess {
        var a: Int = 1
    }
    
    @memberwiseInitializable(.private)
    final class PrivateAccess {
        var a: Int = 1
        
        static func make(a: Int) -> PrivateAccess { PrivateAccess(a: a) }
        static func make() -> PrivateAccess { PrivateAccess() }
    }
    
    /// Unlike the expansion tests, this one lets the compiler expand the macros, and compile the result.
    func testGeneratedInitializersCompile() {
        XCTAssertEqual(DefaultAccess(a: 1).b, "b")
        XCTAssertEqual(DefaultAccess(a: 1, b: "c").b, "c")
        
        XCTAssertEqual(PublicAccess().a, 1)
        XCTAssertEqual(PublicAccess(a: 2).a, 2)
        
        XCTAssertEqual(PrivateAccess.make().a, 1)
        XCTAssertEqual(PrivateAccess.make(a: 2).a, 2)
    }
    
}
#endif
