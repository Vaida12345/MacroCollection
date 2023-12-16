import SwiftSyntaxMacros
import XCTest
import SwiftSyntax

let syntax: DeclSyntax =
    """
    @transient
    let a, b: Int = 3
    """

dump(syntax)
print(syntax.as(VariableDeclSyntax.self)?.attributes.contains(where: { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "transient" }))
