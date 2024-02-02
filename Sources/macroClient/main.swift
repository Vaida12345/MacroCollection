
import StratumMacros
import Foundation
import SwiftUI


@available(macOS 14.0, *)
@available(iOS 17.0, *)
@provided(by: [Model.self])
struct testApp: App {
    
    var body: some Scene {
        WindowGroup {
            Text("")
        }
    }
}

@available(iOS 17.0, *)
@available(macOS 14.0, *)
@dataProviding
@Observable
final class Model {
    
}
