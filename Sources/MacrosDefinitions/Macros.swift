import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct NucleusMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        codable.self,
        memberwiseInitializable.self,
        transient.self,
        url.self,
        symbol.self,
        accessingAssociatedValues.self,
        environment.self,
        encodeOptions.self,
        encrypt.self
    ]
}
