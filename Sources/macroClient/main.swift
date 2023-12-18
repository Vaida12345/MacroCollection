
import NucleusMacros
import Foundation
import AVFoundation


@accessingAssociatedValues
public enum Model: Codable {
    
    case a(model: String)
    
    case b
    
    
}


let model = Model.a(model: "12345")
if let value = model.as(.b) {
    print(value)
}
