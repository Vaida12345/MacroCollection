import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct NucleusMacrosPlugin: CompilerPlugin {
    var providingMacros: [Macro.Type] {
        var macros: [Macro.Type] = [
            codable.self,
            memberwiseInitializable.self,
            transient.self,
            url.self,
            accessingAssociatedValues.self,
        ]
        
        if #available(macOS 11.0, iOS 15, watchOS 7, *) {
            macros.append(symbol.self)
        }
        
        return macros
    }
}
