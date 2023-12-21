import SwiftSyntaxMacros
import SwiftSyntax
import UIKit

let syntax: DeclSyntax = """
@provided(by: [Model.self])
struct App: App {

    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) private var applicationDelegate

    var body: some View {
        ContentView()
            .foregroudStyle(.black)
    }
}
"""

dump(syntax)

