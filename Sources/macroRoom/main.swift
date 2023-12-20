import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
class Model : Codable, Identifiable {}
"""

print(syntax.debugDescription(includeTrivia: true))
