//
//  basicCodable.swift
//  MacroCollection
//
//  Created by Vaida on 2025-06-27.
//

#if os(macOS)
import Foundation
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import MacrosDefinitions
@testable import MacroCollection

// The compiler lists the protocols that the type does not conform to yet, which the expansion uses to declare the conformance.

/// A type conforming to neither `Decodable` nor `Encodable`.
fileprivate let testMacros: [String: MacroSpec] = [
    "codable": MacroSpec(type: codable.self, conformances: ["Decodable", "Encodable"]),
    "encodeOptions": MacroSpec(type: encodeOptions.self),
    "transient": MacroSpec(type: transient.self)
]

/// A type whose superclass conforms to `Codable`, or which declares it itself.
fileprivate let conformedMacros: [String: MacroSpec] = [
    "codable": MacroSpec(type: codable.self, conformances: []),
    "encodeOptions": MacroSpec(type: encodeOptions.self),
    "transient": MacroSpec(type: transient.self)
]

/// A type conforming to `Decodable` only.
fileprivate let decodableMacros: [String: MacroSpec] = [
    "codable": MacroSpec(type: codable.self, conformances: ["Encodable"]),
]


final class CodableTests: XCTestCase {
    
    // MARK: - Generated Members
    
    func testFoundation() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                let name: String

                func postDecodeAction() throws {

                }

                init(name: String) {
                    self.name = name
                }
            }
            """,
            expandedSource: """
            struct Cat {

                let name: String

                func postDecodeAction() throws {

                }

                init(name: String) {
                    self.name = name
                }
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    try self.postDecodeAction()
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testNothingToEncode() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                let name: String = ""

            }
            """,
            expandedSource: """
            struct Cat {

                let name: String = ""

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                }

                init(from decoder: Decoder) throws {
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testClass() {
        assertMacroExpansion(
            """
            @codable
            class Cat {
                var name: String
            }
            """,
            expandedSource: """
            class Cat {
                var name: String

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testFinalClassDoesNotNeedRequired() {
        assertMacroExpansion(
            """
            @codable
            final class Cat {
                var name: String
            }
            """,
            expandedSource: """
            final class Cat {
                var name: String

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testExistingMembersAreKept() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                var name: String

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    self.name = ""
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    self.name = ""
                }

                func encode(to encoder: Encoder) throws {
                }
            }

            extension Cat: Codable {
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    // MARK: - Conformances
    
    func testPartialConformanceOnlyDeclaresWhatIsMissing() {
        assertMacroExpansion(
            """
            @codable
            struct Cat: Decodable {
                var name: String
            }
            """,
            expandedSource: """
            struct Cat: Decodable {
                var name: String
            }

            extension Cat: Encodable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: decodableMacros
        )
    }
    
    func testDeclaredConformanceIsNotRepeated() {
        assertMacroExpansion(
            """
            @codable
            struct Cat: Codable {
                var name: String
            }
            """,
            expandedSource: """
            struct Cat: Codable {
                var name: String
            }

            extension Cat {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    func testClassDeclaringConformanceItselfDoesNotOverride() {
        assertMacroExpansion(
            """
            @codable
            class Cat: Codable {
                var name: String
            }
            """,
            expandedSource: """
            class Cat: Codable {
                var name: String

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }

            extension Cat {

                enum CodingKeys: CodingKey {
                    case name
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    // MARK: - Subclasses
    
    func testOverride() {
        assertMacroExpansion(
            """
            @codable(.override)
            class Child: Super {

                let b: String

            }
            """,
            expandedSource: """
            class Child: Super {

                let b: String

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.b = try container.decode(String.self, forKey: .b)
                    try super.init(from: decoder)
                }

                override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.b, forKey: .b)
                }

            }

            extension Child {

                enum CodingKeys: CodingKey {
                    case b
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    func testOverrideIsInferredFromTheSuperclass() {
        // The compiler lists no protocol to conform to, since the superclass conforms to `Codable`.
        assertMacroExpansion(
            """
            @codable
            class Child: Super {
                let b: String
            }
            """,
            expandedSource: """
            class Child: Super {
                let b: String

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.b = try container.decode(String.self, forKey: .b)
                    try super.init(from: decoder)
                }

                override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.b, forKey: .b)
                }
            }

            extension Child {

                enum CodingKeys: CodingKey {
                    case b
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    func testFinalOverrideIsRequired() {
        assertMacroExpansion(
            """
            @codable
            final class Child: Super {
                let b: String
            }
            """,
            expandedSource: """
            final class Child: Super {
                let b: String

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.b = try container.decode(String.self, forKey: .b)
                    try super.init(from: decoder)
                }

                override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.b, forKey: .b)
                }
            }

            extension Child {

                enum CodingKeys: CodingKey {
                    case b
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    func testPostDecodeActionRunsAfterTheSuperclassIsInitialized() {
        assertMacroExpansion(
            """
            @codable
            class Child: Super {
                let b: String

                func postDecodeAction() throws {
                }
            }
            """,
            expandedSource: """
            class Child: Super {
                let b: String

                func postDecodeAction() throws {
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.b = try container.decode(String.self, forKey: .b)
                    try super.init(from: decoder)
                    try self.postDecodeAction()
                }

                override func encode(to encoder: Encoder) throws {
                    try super.encode(to: encoder)
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.b, forKey: .b)
                }
            }

            extension Child {

                enum CodingKeys: CodingKey {
                    case b
                }
            }
            """,
            macroSpecs: conformedMacros
        )
    }
    
    func testStaticPostDecodeAction() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                var name: String

                static func postDecodeAction() {
                }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String

                static func postDecodeAction() {
                }
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    Self.postDecodeAction()
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    // MARK: - Access Control
    
    func testPublicStruct() {
        assertMacroExpansion(
            """
            @codable
            public struct Cat {
                public var name: String
            }
            """,
            expandedSource: """
            public struct Cat {
                public var name: String
            }

            extension Cat: Codable {

                public enum CodingKeys: CodingKey {
                    case name
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testPackageStruct() {
        assertMacroExpansion(
            """
            @codable
            package struct Cat {
                var name: String
            }
            """,
            expandedSource: """
            package struct Cat {
                var name: String
            }

            extension Cat: Codable {

                package enum CodingKeys: CodingKey {
                    case name
                }

                package init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                package func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testOpenClassOnlyOpensWhatCanBeOverridden() {
        // Neither an initializer that is `required`, nor an enum, can be `open`.
        assertMacroExpansion(
            """
            @codable
            open class Cat {
                public var name: String
            }
            """,
            expandedSource: """
            open class Cat {
                public var name: String

                public required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                open func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }

            extension Cat: Codable {

                public enum CodingKeys: CodingKey {
                    case name
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    // MARK: - Options
    
    func testCannotInferType() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                var name = function()

            }
            """,
            expandedSource: """
            struct Cat {

                var name = function()

            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Type of `name` cannot be inferred, please declare explicitly",
                    line: 4,
                    column: 5,
                    notes: [
                        NoteSpec(message: "Type cannot be inferred from referring to `function`", line: 4, column: 9)
                    ],
                    fixIts: [
                        FixItSpec(message: "Declare Type for `name`")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testTransient() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                @transient
                var name: String = ""

            }
            """,
            expandedSource: """
            struct Cat {
                var name: String = ""

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                }

                init(from decoder: Decoder) throws {
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testOptionIgnored() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                @encodeOptions(.ignored)
                var name: String = ""

            }
            """,
            expandedSource: """
            struct Cat {
                var name: String = ""

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                }

                init(from decoder: Decoder) throws {
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testOptionIfPresent() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                @encodeOptions(.encodeIfPresent)
                let name: String?

            }
            """,
            expandedSource: """
            struct Cat {
                let name: String?

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testOptionalsAreDecodedIfPresent() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                var a: String?
                var b: Optional<Int>
                var c: Swift.Optional<Bool>
                var d: Double!
                var e: [String]?
            }
            """,
            expandedSource: """
            struct Cat {
                var a: String?
                var b: Optional<Int>
                var c: Swift.Optional<Bool>
                var d: Double!
                var e: [String]?
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case a
                    case b
                    case c
                    case d
                    case e
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.a = try container.decodeIfPresent(String.self, forKey: .a)
                    self.b = try container.decodeIfPresent(Int.self, forKey: .b)
                    self.c = try container.decodeIfPresent(Bool.self, forKey: .c)
                    self.d = try container.decodeIfPresent(Double.self, forKey: .d)
                    self.e = try container.decodeIfPresent([String].self, forKey: .e)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.a, forKey: .a)
                    try container.encode(self.b, forKey: .b)
                    try container.encode(self.c, forKey: .c)
                    try container.encode(self.d, forKey: .d)
                    try container.encode(self.e, forKey: .e)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testOptionNonDefault() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                @encodeOptions(.encodeIfNoneDefault)
                var name: String? = nil

            }
            """,
            expandedSource: """
            struct Cat {
                var name: String? = nil

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? nil
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if self.name != nil {
                        try container.encodeIfPresent(self.name, forKey: .name)
                    }
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testNonDefaultOfNonOptional() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfNoneDefault)
                var age: Int = 0 // years
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0 // years
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case age
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if self.age != 0 {
                        try container.encodeIfPresent(self.age, forKey: .age)
                    }
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    func testTrailingCommentsAreNotCopiedIntoTheDecoder() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                var name: String // the name
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String // the name
            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                    case name
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
            macroSpecs: testMacros
        )
    }
    
    // MARK: - Diagnostics
    
    func testOptionRemoveMacro() async throws {
        assertMacroExpansion(
            """
            @codable
            struct Cat {

                @encodeOptions(.encodeIfNoneDefault)
                let name: String? = nil

            }
            """,
            expandedSource: """
            struct Cat {
                let name: String? = nil

            }

            extension Cat: Codable {

                enum CodingKeys: CodingKey {
                }

                init(from decoder: Decoder) throws {
                }

                func encode(to encoder: Encoder) throws {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@encodeOptions cannot be applied to a constant that cannot be changed",
                    line: 4,
                    column: 5,
                    fixIts: [
                        FixItSpec(message: "Remove @encodeOptions")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testEncodeIfPresentOfNonOptionalIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfPresent)
                var age: Int = 0
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`encodeIfPresent` can only be applied to optional values.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Remove @encodeOptions")
                    ]
                )
            ],
            macroSpecs: testMacros,
            fixedSource: """
            @codable
            struct Cat {
                var age: Int = 0
            }
            """
        )
    }
    
    func testEncodeIfPresentOfNonOptionalAmongOtherOptionsIsDiagnosed() {
        // The first of several options used to crash the plugin when it was removed.
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfPresent, .encodeIfNoneDefault)
                var age: Int = 0
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`encodeIfPresent` can only be applied to optional values.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Remove the `encodeIfPresent` option")
                    ]
                )
            ],
            macroSpecs: testMacros,
            fixedSource: """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfNoneDefault)
                var age: Int = 0
            }
            """
        )
    }
    
    func testLastOfSeveralOptionsIsRemoved() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfNoneDefault, .encodeIfPresent)
                var age: Int = 0
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "`encodeIfPresent` can only be applied to optional values.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Remove the `encodeIfPresent` option")
                    ]
                )
            ],
            macroSpecs: testMacros,
            fixedSource: """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfNoneDefault)
                var age: Int = 0
            }
            """
        )
    }
    
    func testEncodeIfNoneDefaultWithoutDefaultValueIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(.encodeIfNoneDefault)
                var age: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "A default value must be provided for `encodeIfNoneDefault` option.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Provide a default value")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testTransientWithoutDefaultValueIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @transient
                var age: Int
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "A default value must be provided for transient values.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Provide a default value")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testEveryProblemIsReportedOnce() {
        assertMacroExpansion(
            """
            @codable
            class Cat {
                @transient
                var age: Int

                @encodeOptions(.encodeIfNoneDefault)
                var name: String
            }
            """,
            expandedSource: """
            class Cat {
                var age: Int
                var name: String
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "A default value must be provided for transient values.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Provide a default value")
                    ]
                ),
                DiagnosticSpec(
                    message: "A default value must be provided for `encodeIfNoneDefault` option.",
                    line: 7,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Provide a default value")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testAsyncPostDecodeActionIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                var name: String

                func postDecodeAction() async {
                }
            }
            """,
            expandedSource: """
            struct Cat {
                var name: String

                func postDecodeAction() async {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "function `postDecodeAction` cannot be async", line: 5, column: 5)
            ],
            macroSpecs: testMacros
        )
    }
    
    func testUnsupportedDeclarationIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
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
                    message: "@codable should only be applied to `struct` or `class`",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @codable")
                    ]
                )
            ],
            macroSpecs: testMacros
        )
    }
    
    func testNonLiteralOptionIsDiagnosed() {
        assertMacroExpansion(
            """
            @codable
            struct Cat {
                @encodeOptions(option)
                var age: Int = 0
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Expected one of `.ignored`, `.encodeIfPresent`, `.encodeIfNoneDefault`", line: 3, column: 20)
            ],
            macroSpecs: testMacros
        )
    }
    
    func testOptionsOutsideOfCodableAreIgnoredWithAWarning() {
        assertMacroExpansion(
            """
            struct Cat {
                @transient
                var age: Int = 0

                @encodeOptions(.encodeIfPresent)
                var name: String? = nil
            }
            """,
            expandedSource: """
            struct Cat {
                var age: Int = 0
                var name: String? = nil
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@transient is ignored outside of a type annotated with @codable", line: 2, column: 5, severity: .warning),
                DiagnosticSpec(message: "@encodeOptions is ignored outside of a type annotated with @codable", line: 5, column: 5, severity: .warning)
            ],
            macroSpecs: testMacros
        )
    }
    
    // MARK: - Compiled Usage
    
    // Unlike the expansion tests, these let the compiler expand the macros, and compile the result.
    
    @codable
    struct Profile {
        var name: String
        var nickname: String?
        @encodeOptions(.encodeIfPresent) var email: String?
        @encodeOptions(.encodeIfNoneDefault) var score: Int = 0
        @transient var cache: [String: Int] = [:]
    }
    
    func testStructKeepsItsMemberwiseInitializer() {
        let profile = Profile(name: "a", score: 3)
        XCTAssertEqual(profile.name, "a")
        XCTAssertEqual(profile.score, 3)
    }
    
    func testOptionalsAreDecodedWhenTheirKeysAreMissing() throws {
        let profile = try JSONDecoder().decode(Profile.self, from: Data(#"{"name": "a"}"#.utf8))
        XCTAssertEqual(profile.name, "a")
        XCTAssertNil(profile.nickname)
        XCTAssertNil(profile.email)
        XCTAssertEqual(profile.score, 0)
        
        let explicit = try JSONDecoder().decode(Profile.self, from: Data(#"{"name": "a", "nickname": null, "email": "a@b.c", "score": 2}"#.utf8))
        XCTAssertNil(explicit.nickname)
        XCTAssertEqual(explicit.email, "a@b.c")
        XCTAssertEqual(explicit.score, 2)
    }
    
    func testEncodeIfPresentLeavesTheKeysOut() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let bare = String(decoding: try encoder.encode(Profile(name: "a")), as: UTF8.self)
        XCTAssertEqual(bare, #"{"name":"a","nickname":null}"#)
        
        let full = String(decoding: try encoder.encode(Profile(name: "a", nickname: "b", email: "c", score: 4)), as: UTF8.self)
        XCTAssertEqual(full, #"{"email":"c","name":"a","nickname":"b","score":4}"#)
    }
    
    class Parent: Codable {
        var id = 0
    }
    
    @codable
    final class Child: Parent {
        var name = ""
        @transient var decodedCount = 0
        
        func postDecodeAction() {
            self.decodedCount += 1
        }
    }
    
    func testSubclassBuildsOnItsSuperclass() throws {
        let decoded = try JSONDecoder().decode(Child.self, from: Data(#"{"id": 7, "name": "b"}"#.utf8))
        XCTAssertEqual(decoded.id, 7)
        XCTAssertEqual(decoded.name, "b")
        XCTAssertEqual(decoded.decodedCount, 1)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        XCTAssertEqual(String(decoding: try encoder.encode(decoded), as: UTF8.self), #"{"id":7,"name":"b"}"#)
    }
    
    func testAccessControlCompiles() throws {
        XCTAssertEqual(try JSONDecoder().decode(CompiledOpen.self, from: Data(#"{"a": 2}"#.utf8)).a, 2)
        XCTAssertEqual(try JSONDecoder().decode(CompiledPublic.self, from: Data(#"{"a": 3}"#.utf8)).a, 3)
        XCTAssertEqual(try JSONDecoder().decode(CompiledPackage.self, from: Data(#"{"a": 4}"#.utf8)).a, 4)
        XCTAssertEqual(try JSONDecoder().decode(CompiledQualified.self, from: Data(#"{"id": 1, "a": 5}"#.utf8)).a, 5)
        XCTAssertEqual(try JSONDecoder().decode(CompiledPartial.self, from: Data(#"{"a": 6}"#.utf8)).a, 6)
        XCTAssertEqual(try JSONDecoder().decode(CompiledGeneric<Int>.self, from: Data(#"{"value": 7}"#.utf8)).value, 7)
    }
    
}

@codable
open class CompiledOpen {
    public var a = 1
    public init() { }
}

@codable
public final class CompiledPublic {
    public var a = 1
    public init() { }
}

@codable
package struct CompiledPackage {
    var a: Int
}

@MacroCollection.codable(.override)
final class CompiledQualified: CodableTests.Parent {
    var a = 1
}

@codable
struct CompiledPartial: Decodable {
    var a: Int
}

@codable
struct CompiledGeneric<Value: Codable> {
    var value: Value
}

#endif
