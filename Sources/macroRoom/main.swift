import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax

let syntax: DeclSyntax =
    """
    func encode(to encoder: Encoder) throws
    """

//let a = Optional(3)
//let a = Optional<Int>(3)
//let a = Model()

dump(syntax)
