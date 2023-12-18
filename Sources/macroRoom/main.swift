import SwiftSyntaxMacros
import SwiftSyntax

let syntax: ExprSyntax =
    """
    #if foo
    { a + b }
    #endif
    """

dump(syntax)
