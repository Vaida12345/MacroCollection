
import StratumMacros
import Foundation
import SwiftUI


@codable
struct Model {
    
    @encodeOptions(.encodeIfNoneDefault, .encodeIfPresent)
    var property1: Int? = 2
    
    var property2: Int? = 2
    
    @encodeOptions(.encodeIfNoneDefault)
    var property3: Int = 2
    
}
