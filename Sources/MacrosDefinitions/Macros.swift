import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
    var providingMacros: [Macro.Type] {
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, *) {
            [
                codable.self,
                memberwiseInitializable.self,
                transient.self,
                url.self,
                symbol.self,
                accessingAssociatedValues.self,
                AttributeDeclMacro.self,
                encodeOptions.self,
                encrypt.self,
                varyArgumentType.self
            ]
        } else {
            [
                codable.self,
                memberwiseInitializable.self,
                transient.self,
                symbol.self,
                accessingAssociatedValues.self,
                AttributeDeclMacro.self,
                encodeOptions.self,
                encrypt.self,
                varyArgumentType.self
            ]
        }
    }
}
