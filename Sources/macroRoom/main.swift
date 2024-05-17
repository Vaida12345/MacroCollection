import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
struct Model {

    static func postDecodeAction() async throws {
        
    }

}
"""

// Auto generate coding keys

dump(syntax)
