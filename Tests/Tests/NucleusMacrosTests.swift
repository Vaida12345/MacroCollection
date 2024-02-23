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
    "environment": environment.self
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            struct RequestTokenView: View {
            
                @Binding var phase: WelcomeView.Phase
                
                #environment(\\.dismiss)
                #environment(ModelProvider.self)
            }
            """,
             expandedSource: """
             struct RequestTokenView: View {
            
                @Binding var phase: WelcomeView.Phase
                
                @Environment(\\.dismiss) private var dismiss
                @Environment(ModelProvider.self) private var modelProvider
            }
            """,
             macros: testMacros
        )
    }
}
#endif
