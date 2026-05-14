
import Foundation
import SwiftUI
import MacroCollection


@accessingAssociatedValues
enum Model {
    case a
    case b(Int)
    case c(String, Int)
    case d(a: String)
    case e(a: String, b: Int)
    case f(String, b: Int)
}
