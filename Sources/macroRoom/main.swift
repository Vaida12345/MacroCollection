import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
@provided(by: Model.self, Model2.self)
struct Model {
}
"""

// Auto generate coding keys

dump(syntax)
