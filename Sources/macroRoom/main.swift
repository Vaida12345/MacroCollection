import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
@encodeOptions(.ignored, .encodeIfNoneDefault, .encodeIfPresent)
var property: Int = call()
"""

dump(syntax)

