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
            struct App: App {
            
                @State private var model = Model()
            
                var body: some View {
                    ContentView()
                        .foregroudStyle(.black)
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
