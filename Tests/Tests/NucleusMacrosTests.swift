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
            final class Cat {
            
            func postDecodeAction() throws {
            
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
