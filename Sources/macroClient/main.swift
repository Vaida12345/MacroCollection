
import NucleusMacros

@codable
public struct Model {
    
    let a: String
    
    let b = Int()
    
    @transient
    var c: Int = Int()
    
}
