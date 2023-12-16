import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax

let syntax: DeclSyntax =
    """
    internal init(a: Int, b: Int = 3) {
        self.a = a
        self.b = b
    }
    """

//let a = Optional(3)
//let a = Optional<Int>(3)
//let a = Model()

dump(syntax)

struct Model {
    
    let a: Int
    
    var b = 3
    
    internal init(a: Int, b: Int = 3) {
        self.a = a
        self.b = b
    }
    
}
