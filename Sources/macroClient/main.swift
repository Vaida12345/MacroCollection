
import StratumMacros
import Foundation
import SwiftUI


print(#encrypt("hello world"))


@dataProviding
final class Model: ObservableObject {
    
}

@provided(by: Model.self)
struct Main: App {
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
    
}
