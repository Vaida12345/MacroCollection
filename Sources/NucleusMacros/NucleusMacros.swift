//
//  NucleusMacros.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation


/// Generates the methods required by `Codable` for the stored properties.
///
/// Apply this macro to a class to generate memberwise codable conformances.
/// ```swift
/// @codable
/// class Cat {
///     let name: String = "cat"
///     let age: Int
/// }
/// ```
///
/// This above macro would expand to the following:
/// ```swift
/// enum CodingKeys: CodingKey { ... }
/// func encode(to encoder: Encoder) throws { ... }
/// required init(from decoder: Decoder) throws { ... }
/// ```
///
/// Please note that any non-assignable values are ignored.
@attached(extension, names: named(encode(to:)), named(CodingKeys), conformances: Codable)
@attached(member, names: named(init(from:)))
public macro codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "codable")

/// Generates an initializer including all the stored properties. if it is possible, an `init()` will also be synthesized.
///
/// Apply this macro to a class to generate memberwise initializers.
/// ```swift
/// @memberwiseInitializable
/// class Cat {
///     let name: String = "cat"
///     let age: Int
/// }
/// ```
///
/// Any non-assignable values are ignored.
/// ```swift
/// init(age: Int) {
///     self.age = age
/// }
/// ```
///
/// Sometimes, type cannot be interfered, such as the ones assigned by calling functions. In this case, an error will be emitted asking to declare type explicitly.
@attached(member, names: named(init))
public macro memberwiseInitializable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "memberwiseInitializable")

/// Tells `@codable` macro not to persist the annotated property.
///
/// This macro must be used within the ``codable()`` annotated class.
/// ```swift
/// @codable
/// class Cat {
///     let name: String
///
///     @transient
///     let age: Int
/// }
/// ```
///
/// In the generated `CodingKeys`, the ``transient()`` annotated property `age` is ignored.
/// ```swift
/// enum CodingKeys: CodingKey {
///     case name
/// }
/// ```
///
/// The other generated codes are updated according.
@attached(peer)
public macro transient() = #externalMacro(module: "NucleusMacrosDefinitions", type: "transient")

/// Creates an url with compile-time validation
///
/// This macro would produce compile errors if an url cannot be produced using give string.
/// ```swift
/// #url("cat")
/// // error: The given string is not an url.
/// ```
@freestanding(expression)
public macro url(_ string: StaticString) -> URL = #externalMacro(module: "NucleusMacrosDefinitions", type: "url")

/// Creates a system-defined symbol with compile-time validation.
///
/// This macro would produce compile errors if the symbol is not defined.
/// ```swift
/// Image(systemName: #symbol("macro"))
/// // error: No such symbol `macro`.
/// ```
@available(macOS 11.0, iOS 15, watchOS 7, *)
@freestanding(expression)
public macro symbol(systemName: StaticString) -> String = #externalMacro(module: "NucleusMacrosDefinitions", type: "symbol")

/// Generates methods for retrieving associated values and determining cases.
///
/// Use this macro to generate the `as(_:)` and `is(_:)` methods.
///
/// ```swift
/// @accessingAssociatedValues
/// enum Model {
///     case car(name: String)
///     case bus(length: Int)
/// }
/// ```
///
/// You can access the associated values and determine the cases using `as(:_)` and `is(_:)`.
///
/// ```swift
/// let shortBus: Model = .bus(length: 10)
/// shortBus.as(.bus) // Optional(10)
/// shortBus.is(.car) // false
/// ```
///
/// The `as(_:)` would returns the associated value if the case matches and there is any, while `is(_:)` would return a `Bool` determining whether the case matches.
@attached(extension, names: named(as(_:)), named(is(_:)), named(EnumProperty))
public macro accessingAssociatedValues() = #externalMacro(module: "NucleusMacrosDefinitions", type: "accessingAssociatedValues")
