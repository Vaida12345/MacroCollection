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
@testable import MacrosDefinitions

nonisolated(unsafe) fileprivate let testMacros: [String: any Macro.Type] = [
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
             func `as`<T>(_ property: EnumProperty<T>) -> T? {
                 switch property.root {
                 case .none:
                     if case .none = self {
                         return () as? T
                     }
                 case .car:
                     if case let .car(name, make) = self {
                         return (name, make) as? T
                     }
                 case .bus:
                     if case let .bus(length) = self {
                         return (length) as? T
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
             func `is`<T>(_ property: EnumProperty<T>) -> Bool {
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
             struct EnumProperty<T>: Sendable {
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
}
#endif
