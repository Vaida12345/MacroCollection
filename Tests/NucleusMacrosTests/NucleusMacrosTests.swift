import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax
@testable
import NucleusMacrosDefinitions

let testMacros: [String: Macro.Type] = [
    "Codable": Codable.self,
    "memberwiseInitializable": memberwiseInitializable.self
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @memberwiseInitializable
            class Model {
            
                let a: String
            
                var b = Int()
            
                let c: String?
            
                static let e: String
            
            }
            """,
            expandedSource: """
            struct Model {
            
                let a: String
            
                let b = Int()
            
                let c: String?
            
                static let e: String
            
            }
            
            extension Model: Codable {
            
                enum CodingKeys: CodingKey {
                    case a
                    case c
                }
            
                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.a, forKey: .a)
                    try container.encodeIfPresent(self.c, forKey: .c)
                }
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.a = try container.decode(forKey: .a)
                    self.c = try container.decodeIfPresent(forKey: .c)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testExtensions() throws {
        let syntax: DeclSyntax =
    """
    let a = Optional<Int>(3)
    """
        
        //
        //let a = Optional<Int>(3)
        //let a = Model()
        
        dump(syntax)
        try print(syntax.as(VariableDeclSyntax.self)?.bindings.first?.inferredType.isOptional)
    }
}



//- FunctionTypeSyntax
//├─leftParen: leftParen
//├─parameters: TupleTypeElementListSyntax
//├─rightParen: rightParen
//╰─returnClause: ReturnClauseSyntax
//  ├─arrow: arrow
//  ╰─type: IdentifierTypeSyntax
//     ╰─name: identifier("Void")
