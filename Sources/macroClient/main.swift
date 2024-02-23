
import StratumMacros
import Foundation
import SwiftUI


@available(macOS 14.0, iOS 17, *)
struct RequestTokenView: View {
    
    #environment(\.dismiss)
    #environment(ModelProvider.self)
    
    var body: some View {
        EmptyView()
    }
}


@available(macOS 14.0, iOS 17, *)
@dataProviding
@Observable
final class ModelProvider {
    
}
