//
//  associatedTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-06-27.
//

#if os(macOS)
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Testing
@testable import MacrosDefinitions
@testable import MacroCollection

fileprivate let testMacros: [String: any Macro.Type] = [
    "accessingAssociatedValues": accessingAssociatedValues.self,
]


final class AssociatedTests: XCTestCase {
    
    func testFoundation() async throws {
        let source = """
         @accessingAssociatedValues
         public enum Model {
             case none
             case car(name: String, make: String)
             case bus(length: Int)
             case bus2(Int)
             case bus3(Int, Int)
         }
         """
        
        let expected = """
         public enum Model {
             case none
             case car(name: String, make: String)
             case bus(length: Int)
             case bus2(Int)
             case bus3(Int, Int)
         
             /// Returns the value associated with `property`, if the case matches.
             ///
             /// This method can be considered as an alternative to `if case let`.
             ///
             /// ```swift
             /// @accessingAssociatedValues
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
             /// If there isn't any value associated with `property`, this function would always return `Void`.
             ///
             /// - SeeAlso: If you are not interested in the value associated with `property`, see ``is(_:)``.
             public func `as`<T>(_ property: EnumProperty<T>) -> T? {
                 switch property.root {
                 case .none:
                     if case .none = self {
                         return () as? T
                     }
                 case .car:
                     if case let .car(v0, v1) = self {
                         return (v0, v1) as? T
                     }
                 case .bus:
                     if case let .bus(v0) = self {
                         return (v0) as? T
                     }
                 case .bus2:
                     if case let .bus2(v0) = self {
                         return (v0) as? T
                     }
                 case .bus3:
                     if case let .bus3(v0, v1) = self {
                         return (v0, v1) as? T
                     }
                 }
                 return nil
             }
         
             /// Returns whether the given case matches `property`.
             ///
             /// This method can be considered as an alternative to `if case`.
             ///
             /// ```swift
             /// @accessingAssociatedValues
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
             public func `is`<T>(_ property: EnumProperty<T>) -> Bool {
                 switch property.root {
                 case .none:
                     if case .none = self {
                         return true
                     }
                 case .car:
                     if case .car = self {
                         return true
                     }
                 case .bus:
                     if case .bus = self {
                         return true
                     }
                 case .bus2:
                     if case .bus2 = self {
                         return true
                     }
                 case .bus3:
                     if case .bus3 = self {
                         return true
                     }
                 }
                 return false
             }
         
             /// Auto generated type to access properties for ``Model``.
             ///
             /// You can use the static properties to retrieve enum cases.
             public struct EnumProperty<T>: Sendable {
                 /// The cases used as an identifier to the property.
                 fileprivate enum __Case: Sendable {
                     case none, car, bus, bus2, bus3
                 }
                 /// The property identifier.
                 fileprivate let root: __Case
         
                 fileprivate init(root: __Case) {
                     self.root = root
                 }
                 /// Indicates the value of ``Model/none``
                 public static var none: EnumProperty<Void> {
                     EnumProperty<Void>(root: .none)
                 }
                 /// Indicates the value of ``Model/car(name:make:)``
                 public static var car: EnumProperty<(name: String, make: String)> {
                     EnumProperty<(name: String, make: String)>(root: .car)
                 }
                 /// Indicates the value of ``Model/bus(length:)``
                 public static var bus: EnumProperty<Int> {
                     EnumProperty<Int>(root: .bus)
                 }
                 /// Indicates the value of ``Model/bus2(_:)``
                 public static var bus2: EnumProperty<Int> {
                     EnumProperty<Int>(root: .bus2)
                 }
                 /// Indicates the value of ``Model/bus3(_:_:)``
                 public static var bus3: EnumProperty<(Int, Int)> {
                     EnumProperty<(Int, Int)>(root: .bus3)
                 }
             }
         }
         """
        
        assertMacroExpansion(source, expandedSource: expected, macros: testMacros)
    }
    
    
    func testEnumWithoutCasesIsDiagnosed() {
        assertMacroExpansion(
            """
            @accessingAssociatedValues
            enum Model {
            }
            """,
            expandedSource: """
            enum Model {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@accessingAssociatedValues found no case to generate the accessors for",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @accessingAssociatedValues")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    func testUnsupportedDeclarationIsDiagnosed() {
        assertMacroExpansion(
            """
            @accessingAssociatedValues
            struct Model {
            }
            """,
            expandedSource: """
            struct Model {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@accessingAssociatedValues should only be applied to `enum`",
                    line: 1,
                    column: 1,
                    fixIts: [
                        FixItSpec(message: "Remove @accessingAssociatedValues")
                    ]
                )
            ],
            macros: testMacros
        )
    }
    
    // MARK: - Compiled Usage
    
    // Unlike the expansion tests, these let the compiler expand the macros, and compile the result.
    
    @accessingAssociatedValues
    enum Model {
        case a
        case b(Int)
        case c
    }
    
    func testIs() {
        let model = Model.c
        #expect(!model.is(.a))
        #expect(!model.is(.b))
        #expect(model.is(.c))
    }
    
    @accessingAssociatedValues
    enum Shape {
        case plain
        case unlabeled(_ value: Int)
        case mixed(Int, _ name: String)
        case labeled(default: Int)
        case labeledTuple(`default`: Int, other: String)
        case `default`
    }
    
    func testLabelsThatCannotNameAVariable() {
        #expect(Shape.plain.as(.plain) != nil)
        #expect(Shape.unlabeled(1).as(.unlabeled) == 1)
        #expect(Shape.unlabeled(1).as(.plain) == nil)
        #expect(Shape.mixed(2, "b").as(.mixed)?.0 == 2)
        #expect(Shape.mixed(2, "b").as(.mixed)?.1 == "b")
        #expect(Shape.labeled(default: 3).as(.labeled) == 3)
        #expect(Shape.labeledTuple(default: 4, other: "d").as(.labeledTuple)?.other == "d")
        #expect(Shape.default.is(.default))
        #expect(!Shape.plain.is(.default))
    }
    
    func testAccessControlAndGenericsCompile() {
        #expect(PublicShape.a(1).as(.a) == 1)
        #expect(PackageShape.a(2).as(.a) == 2)
        #expect(PackageShape.b.is(.b))
        #expect(GenericShape.some("s").as(.some) == "s")
        #expect(GenericShape<Int>.none.is(.none))
    }
    
}

@accessingAssociatedValues
public enum PublicShape {
    case a(Int)
    case b
}

@accessingAssociatedValues
package enum PackageShape {
    case a(Int)
    case b
}

@accessingAssociatedValues
enum GenericShape<Wrapped> {
    case some(Wrapped)
    case none
}
#endif
