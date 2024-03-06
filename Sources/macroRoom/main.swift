import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
@customCodable
struct Model {

//    var property: Int
    
    func encode(to container: KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(self.property, to: .property)
    }

//    init?(from container: KeyedDecodingContainer<CodingKeys>) throws {
//        self.property = try container.decode(.container)
//
//        return nil
//    }

}
"""

// Auto generate coding keys

dump(syntax)
