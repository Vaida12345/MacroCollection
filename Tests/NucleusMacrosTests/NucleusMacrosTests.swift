import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax
@testable
import NucleusMacrosDefinitions

let testMacros: [String: Macro.Type] = [
    "codable": codable.self,
    "memberwiseInitializable": memberwiseInitializable.self,
    "transient": transient.self
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @memberwiseInitializable
            struct Model {
            
                let a: String
                
                @transient
                var c: String?
            
            }
            """,
            expandedSource: """
            class Model {
            
                let a: String
                
                var c: String?
            
            }
            
            extension Model: Codable {
            
                enum CodingKeys: CodingKey {
                    case a
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.a, forKey: .a)
                }
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.a = try container.decode(forKey: .a)
                }
            }
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
