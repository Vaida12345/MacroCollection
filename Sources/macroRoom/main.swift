import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
@customCodable
@codable
struct Model {
}
"""

// Auto generate coding keys

dump(syntax)
