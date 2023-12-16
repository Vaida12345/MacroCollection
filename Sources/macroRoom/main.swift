import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax =
    """
    let a = Int()
    """

dump(syntax)
