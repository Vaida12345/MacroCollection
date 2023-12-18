#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SwiftSyntax
@testable
import NucleusMacrosDefinitions

let testMacros: [String: Macro.Type] = [
    "codable": codable.self,
    "memberwiseInitializable": memberwiseInitializable.self,
    "transient": transient.self,
    "url": url.self,
    "symbol": symbol.self,
    "accessingAssociatedValues": accessingAssociatedValues.self,
]

final class NucleusMacrosTests: XCTestCase {
    func testMacro() throws {
        assertMacroExpansion(
             """
            @accessingAssociatedValues
            enum Model: Codable {
            
            case a(model: String)
            
            case b
            
            }
            """,
            expandedSource: """
            enum Model: Codable {
            
            case a(model: String)
            
            case b
            
            }
            
            extension Model {
            /// Returns the value associated with `property`, if the case matches.
            ///
            /// This method can be considered as an alternative to `if case let`.
            ///
            /// ```swift
            /// enum Model {
            ///     case car(name: String)
            ///     case bus(length: Int)
            /// }
            ///
            /// let shortBus: Model = .bus(length: 10)
            /// shortBus.as(.bus) // 10
            /// shortBus.as(.car) // nil
            /// ```
            ///
            /// The *casting* is considered successful if the case matches `property`, and returns the value associated with it.
            ///
            /// If there isn't any value associated with `property`, this function would always return `nil`.
            ///
            /// - SeeAlso: If you are not interested in the value associated with `property`, see ``as(_:)``.
            func `as`<T>(_ property: Property<T>) -> T? {
            switch property.root {
            case .a: if case let .a(model) = self { return model as? T }
            case .b: if case .b = self { return nil }
            }
            
            return nil
            }
            
            /// Returns whether the given case matches `property`.
            ///
            /// This method can be considered as an alternative to `if case`.
            ///
            /// ```swift
            /// enum Model {
            ///     case car(name: String)
            ///     case bus(length: Int)
            /// }
            ///
            /// let shortBus: Model = .bus(length: 10)
            /// shortBus.is(.bus) // true
            /// shortBus.is(.car) // false
            /// ```
            ///
            /// - SeeAlso: If you want to retrieve the value associated with `property`, see ``as(_:)``.
            func `is`<T>(_ property: Property<T>) -> Bool {
            switch property.root {
            case .a: if case .a = self { return true }
            case .b: if case .b = self { return true }
            }
            
            return false
            }
            
            /// Auto generated type to access properties for ``Model``.
            ///
            /// - Important: Please do not interact with this structure directly.
            struct Property<T> {
            
            /// The cases used as an identifier to the property.
            fileprivate enum __Case {
            case a, b
            }
            
            /// The property identifier.
            fileprivate let root: __Case
            
            fileprivate init(root: __Case) {
            self.root = root
            }
            
            /// Indicates the value of ``Model/a(model:)``
            static var a: Property<String> { Property<String>(root: .a) }
            
            /// Indicates the value of ``Model/b``
            static var b: Property<Never> { Property<Never>(root: .b) }
            }
            
            }
            }
            """,
            macros: testMacros
        )
    }
    
//    func testExtensions() throws {
//        let syntax: DeclSyntax =
//    """
//    let a = Optional<Int>(3)
//    """
//        
//        //
//        //let a = Optional<Int>(3)
//        //let a = Model()
//        
//        dump(syntax)
//        try print(syntax.as(VariableDeclSyntax.self)?.bindings.first?.inferredType.isOptional)
//    }
}



//- FunctionTypeSyntax
//├─leftParen: leftParen
//├─parameters: TupleTypeElementListSyntax
//├─rightParen: rightParen
//╰─returnClause: ReturnClauseSyntax
//  ├─arrow: arrow
//  ╰─type: IdentifierTypeSyntax
//     ╰─name: identifier("Void")
#endif
