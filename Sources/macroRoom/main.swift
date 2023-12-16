import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax =
    """
    public final let a, b: Int = 3
    """

dump(syntax)
