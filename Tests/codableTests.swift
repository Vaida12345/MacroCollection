//
//  basicCodable.swift
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
    "codable": codable.self,
    "encodeOptions": encodeOptions.self,
    "transient": transient.self
]


final class CodableTests: XCTestCase {
    
    func testFoundation() async throws {
        assertMacroExpansion(
             """
            @codable
            final class Cat {
            
                let name: String
            
                func postDecodeAction() throws {
            
                }
            
                init(name: String) {
                    self.name = name
                }
            }
            """,
             expandedSource: """
            final class Cat {
            
                let name: String
            
                func postDecodeAction() throws {
            
                }
            
                init(name: String) {
                    self.name = name
                }
            
                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decode(String.self, forKey: .name)
                    try self.postDecodeAction()
                }
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                    case name
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
            }
            """,
             macros: testMacros
        )
    }
    
    func testNothingToEncode() async throws {
        assertMacroExpansion(
             """
            @codable
            final class Cat {
            
                let name: String = ""
            
            }
            """,
             expandedSource: """
            final class Cat {
            
                let name: String = ""
            
                required init(from decoder: Decoder) throws {
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                }
            
                func encode(to encoder: Encoder) throws {
                }
            }
            """,
             macros: testMacros
        )
    }
    
    func testCannotInferType() async throws {
        assertMacroExpansion(
             """
            @codable
            final class Cat {
            
                var name = function()
            
            }
            """,
             expandedSource: """
            final class Cat {
            
                var name = function()
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                    case name
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.name, forKey: .name)
                }
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
             macros: testMacros
        )
    }
    
    func testTransient() async throws {
        assertMacroExpansion(
             """
            @codable
            final class Cat {
            
                @transient
                var name: String = ""
            
            }
            """,
             expandedSource: """
            final class Cat {
                var name: String = ""
            
                required init(from decoder: Decoder) throws {
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                }
            
                func encode(to encoder: Encoder) throws {
                }
            }
            """,
             macros: testMacros
        )
    }
    
    func testOptionIgnored() async throws {
        assertMacroExpansion(
             """
            @codable
            final class Cat {
            
                @encodeOptions(.ignored)
                var name: String = ""
            
            }
            """,
             expandedSource: """
            final class Cat {
                var name: String = ""
            
                required init(from decoder: Decoder) throws {
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                }
            
                func encode(to encoder: Encoder) throws {
                }
            }
            """,
             macros: testMacros
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
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decodeIfPresent(String?.self, forKey: .name)
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                    case name
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encodeIfPresent(self.name, forKey: .name)
                }
            }
            """,
             macros: testMacros
        )
    }
    
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
            
                init(from decoder: Decoder) throws {
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
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
             macros: testMacros
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
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.name = try container.decodeIfPresent(String? .self, forKey: .name) ?? nil
                }
            
            }
            
            extension Cat: Codable {
            
                enum CodingKeys: CodingKey {
                    case name
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if self.name != nil {
                        try container.encodeIfPresent(self.name, forKey: .name)
                    }
                }
            }
            """,
             macros: testMacros
        )
    }
}

#endif
