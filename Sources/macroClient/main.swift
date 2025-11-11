
import Foundation
import SwiftUI
import MacroCollection


@codable()
class Super: Codable {
    
    let a: String
    
    init(a: String) {
        self.a = a
    }
    
}


@codable(.override)
class Child: Super {
    
    let b: String
    
    
    init(a: String, b: String) {
        self.b = b
        super.init(a: a)
    }
    
}


print(Super.CodingKeys.a)
print(Child.CodingKeys.b)
