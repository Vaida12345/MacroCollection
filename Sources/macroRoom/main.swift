import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
let id = UUID()
"""

// Auto generate coding keys

dump(syntax)
