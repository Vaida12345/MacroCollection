#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax
@testable
import NucleusMacrosDefinitions

let testMacros: [String: Macro.Type] = [
    "codable": codable.self,
    "memberwiseInitializable": memberwiseInitializable.self,
    "transient": transient.self,
    "url": url.self,
    "symbol": symbol.self,
    "accessingAssociatedValues": accessingAssociatedValues.self,
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @codable
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
    
//    func testExtensions() throws {
//        let syntax: DeclSyntax =
//    """
//    let a = Optional<Int>(3)
//    """
//        
//        //
//        //let a = Optional<Int>(3)
//        //let a = Model()
//        
//        dump(syntax)
//        try print(syntax.as(VariableDeclSyntax.self)?.bindings.first?.inferredType.isOptional)
//    }
}



//- FunctionTypeSyntax
//├─leftParen: leftParen
//├─parameters: TupleTypeElementListSyntax
//├─rightParen: rightParen
//╰─returnClause: ReturnClauseSyntax
//  ├─arrow: arrow
//  ╰─type: IdentifierTypeSyntax
//     ╰─name: identifier("Void")
#endif
