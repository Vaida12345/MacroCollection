
import StratumMacros
import Foundation
import SwiftUI


//@customCodable
//struct Cat {
//    
//    @encodeOptions(.encodeIfNoneDefault)
//    var age: Int = 0
//}


@available(macOS 14.0, *)
@dataProviding
@customCodable
@Observable
final class Model {
    
    /// `CustomCodable` protocol requirement.
    ///
    /// Within this function, encode the properties that need *special care*. The properties not defined will be encoded according to its attributes, such as ``encodeOptions(:_)``.
    ///
    /// - Note: A key not present here does not mean not encoded.
    private func _encode(to container: inout KeyedEncodingContainer<CodingKeys>) throws { 
        
    }
    
    /// `CustomCodable` protocol requirement.
    ///
    /// Within this function, decode the properties that need *special care*. The properties not defined will be decode according to its attributes, such as ``encodeOptions(:_)``.
    ///
    /// - Returns: Always return `nil` to enable partial initializations.
    ///
    /// - Note: A key not present here does not mean not being decoded.
    private init?(_from container: inout KeyedDecodingContainer<CodingKeys>) throws {
        
        return nil // Protocol requirement: enabling partial initialization
    }
    
}


@available(macOS 14.0, *)
@provided(by: Model.self)
struct MainApp: App {
    
    var body: some Scene {
        WindowGroup {
            
        }
    }
    
    
}
