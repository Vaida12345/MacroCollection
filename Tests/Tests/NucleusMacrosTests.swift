#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax
@testable
import MacrosDefinitions

let testMacros: [String: Macro.Type] = [
    "codable": codable.self,
    "memberwiseInitializable": memberwiseInitializable.self,
    "transient": transient.self,
    "url": url.self,
    "symbol": symbol.self,
    "accessingAssociatedValues": accessingAssociatedValues.self,
    "dataProviding": dataProviding.self,
    "environment": environment.self,
    "customCodable": customCodable.self
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @customCodable
            final class Cat: Codable {
            
            /// `CustomCodable` protocol requirement.
            ///
            /// Within this function, encode the properties that need *special care*. The properties not defined will be encoded according to its attributes, such as ``encodeOptions(:_)``.
            ///
            /// - Note: A key not present here does not mean not encoded.
            private func _encode(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
            
            }
            
            /// `CustomCodable` protocol requirement.
            ///
            /// Within this function, decode the properties that need *special care*. The properties not defined will be decode according to its attributes, such as ``encodeOptions(:_)``.
            ///
            /// - Returns: Always return `nil` to enable partial initializations.
            ///
            /// - Note: A key not present here does not mean not being decoded.
            private init?(_from container: inout KeyedDecodingContainer<CodingKeys>) throws {
            
            return nil // Protocol requirement: enabling partial initialization
            }
            
            }
            """,
             expandedSource: """
            """,
             macros: testMacros
        )
    }
}
#endif
