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
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @dataProviding
            class Model {
            
                var a: String
                
                @transient
                var b: String
                
            }
            """,
             expandedSource: """
            
            """,
             macros: testMacros
        )
    }
}
#endif
