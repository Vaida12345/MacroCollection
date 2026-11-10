import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    var providingMacros: [Macro.Type] {
        var macros: [Macro.Type] = [
            codable.self,
            memberwiseInitializable.self,
            transient.self,
            symbol.self,
            accessingAssociatedValues.self,
            encodeOptions.self,
            encrypt.self,
            varyArgumentType.self
        ]
        
        #if canImport(SwiftUI)
        macros.append(AttributeDeclMacro.self)
        #endif
        
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
            macros.append(url.self)
        }
        
        return macros
    }
}
