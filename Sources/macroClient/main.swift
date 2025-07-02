
import Foundation
import SwiftUI
import MacroCollection

@accessingAssociatedValues
public enum Model {
    case none
    case car(name: String, make: String)
    case bus(length: Int)
    case bus2(Int)
    case bus3(Int, Int)
}
