
import StratumMacros
import Foundation
import SwiftUI


@codable
struct Cat {
    
    @encodeOptions(.encodeIfNoneDefault)
    var age: Int = 0
}
