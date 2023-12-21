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
///
/// ## Transient values
/// To ignore value explicitly, use the ``transient()`` macro.
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
/// In the generated `CodingKeys`, the `transient()` annotated property `age` is ignored.
/// ```swift
/// enum CodingKeys: CodingKey {
///     case name
/// }
/// ```
///
/// The other generated codes are updated according.
@attached(extension, names: named(encode(to:)), named(CodingKeys), conformances: Codable)
@attached(member, names: named(init(from:)))
public macro codable() = #externalMacro(module: "MacrosDefinitions", type: "codable")

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
public macro memberwiseInitializable() = #externalMacro(module: "MacrosDefinitions", type: "memberwiseInitializable")

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
public macro transient() = #externalMacro(module: "MacrosDefinitions", type: "transient")

/// Creates an url with compile-time validation
///
/// This macro would produce compile errors if an url cannot be produced using give string.
/// ```swift
/// #url("cat")
/// // error: The given string is not an url.
/// ```
@freestanding(expression)
public macro url(_ string: StaticString) -> URL = #externalMacro(module: "MacrosDefinitions", type: "url")

/// Creates a system-defined symbol with compile-time validation.
///
/// This macro would produce compile errors if the symbol is not defined.
/// ```swift
/// Image(systemName: #symbol("macro"))
/// // error: No such symbol `macro`.
/// ```
@freestanding(expression)
public macro symbol(_ name: StaticString) -> String = #externalMacro(module: "MacrosDefinitions", type: "symbol")

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
public macro accessingAssociatedValues() = #externalMacro(module: "MacrosDefinitions", type: "accessingAssociatedValues")


/// Declare a `class` to be ``DataProvider``.
///
/// Use this macro to declare a class to be ``DataProvider``
/// ```swift
/// @Observable
/// @dataProviding
/// final class ModelProvider { ... }
/// ```
///
/// The models are `codable` by default, you can override the coding of certain properties using the ``transient()`` macro.
///
/// Then, in your `@main App`, attach the ``provided(by:)`` macro.
/// ```swift
/// @provided(by: [ModelProvider.self])
/// struct testApp: App { ... }
/// ```
///
/// Use the `environment` view modifiers to store this provider in the environment
/// ```swift
/// WindowGroup {
///     ContentView()
///         .environment(modelProvider)
/// }
/// ```
///
/// which can be access by the children view by calling `@Enviroment`.
/// ```swift
/// @Enviroment(ModelProvider.self) private var modelProvider
/// ```
@attached(extension, names: named(encode(to:)), named(CodingKeys), named(storageItem), named(save()), conformances: DataProvider)
@attached(member, names: named(init(from:)), named(init), named(instance))
public macro dataProviding() = #externalMacro(module: "MacrosDefinitions", type: "dataProviding")

/// Attach this macro to the `@main App` to use the `DataProvider`s declared.
///
/// Attach the ``provided(by:)`` macro.
/// ```swift
/// @main
/// @provided(by: [ModelProvider.self])
/// struct testApp: App { ... }
/// ```
///
/// Use the `environment` view modifiers to store this provider in the environment
/// ```swift
/// WindowGroup {
///     ContentView()
///         .environment(modelProvider)
/// }
/// ```
///
/// which can be access by the children view by calling `@Enviroment`.
/// ```swift
/// @Enviroment(ModelProvider.self) private var modelProvider
/// ```
///
/// The providers can be declared using the ``dataProviding()`` macro.
/// ```swift
/// @dataProviding
/// final class ModelProvider { ... }
/// ```
@attached(member, names: named(ApplicationDelegate), arbitrary)
public macro provided(by providers: [any DataProvider.Type]) = #externalMacro(module: "MacrosDefinitions", type: "providedBy")
