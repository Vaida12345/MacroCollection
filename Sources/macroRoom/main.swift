import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax =
    """
    self.init(a: a, b: b, c: c)
    """

dump(syntax)
