import SwiftSyntaxMacros
import SwiftSyntax

let syntax: DeclSyntax = """
struct App: App {

    @State private var model = Model()

    var body: some View {
        ContentView()
            .foregroudStyle(.black)
            .provided(by: [Provider.self])
    }
}
"""

dump(syntax)
