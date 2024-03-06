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
            struct Model {
            
            var property: Int
            
            
            /// `CustomCodable` protocol requirement.
            ///
            /// Within this function, encode the properties that need *special care*. The properties not defined will be encoded according to its attributes, such as ``encodeOptions(:_)``.
            ///
            /// - Note: A key not present here does not mean not encoded.
            func _encode(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
            try container.encode(true, forKey: .property)
            }
            
            /// `CustomCodable` protocol requirement.
            ///
            /// Within this function, decode the properties that need *special care*. The properties not defined will be decode according to its attributes, such as ``encodeOptions(:_)``.
            ///
            /// - Returns: Always return `nil` to enable partial initializations.
            ///
            /// - Note: A key not present here does not mean not being decoded.
            init?(_from container: inout KeyedDecodingContainer<CodingKeys>) throws {
            let _: Int = try container.decode(forKey: .property)
            self.property = 1
            
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
