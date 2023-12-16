import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax

let syntax: DeclSyntax =
    """
    let a, b: Int = 3
    """

dump(syntax)
