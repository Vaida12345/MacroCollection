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
            @codable
            @customCodable
            struct Cat {
            
            @encodeOptions(.encodeIfNoneDefault)
            var age: Int = 0
            }

            """,
             expandedSource: """
            """,
             macros: testMacros
        )
    }
}
#endif
