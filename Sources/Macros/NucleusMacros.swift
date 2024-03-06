//
//  NucleusMacros.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation


/// Generates the methods required by `Codable` for the stored properties with customizations.
///
/// Use this macro only when you need customizations on how the values should be encoded and decoded that ``AttributeEncodeOptions`` cannot achieve. Otherwise, ``codable()`` would be a better choice.
///
/// This macro comes with two requirements: `_encoded(to:)` and `init(_from:)`. Any **key** used within these methods would indicate that you will handle the coding of the represented properties yourself. The properties for the keys not observed here will be coded automatically.
///
/// The macros of ``transient()`` and ``encodeOptions(_:)`` can be used to control the auto generated coding behaviors.
///
/// ### Usage
///
/// Apply this macro to a class to generate memberwise codable conformances.
///
/// ```swift
/// @customCodable
/// struct Model {
///     var specialProperty: Int
///     var normalProperty: String
/// }
/// ```
///
/// Within the protocol requirements, define your special properties. Any properties not defined here will be automatically handled.
/// ```swift
/// private func _encode(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
///     try container.encode(self.specialProperty.byteSwapped, forKey: .specialProperty)
/// }
///
/// private init?(_from container: inout KeyedDecodingContainer<CodingKeys>) throws {
///     self.specialProperty = try container.decode(Int.self, forKey: .specialProperty).byteSwapped
///
///     return nil // Protocol requirement: enabling partial initialization
/// }
/// ```
///
/// The generated encoding and decoding functions will copy your customized function, with the auto generated ones.
/// ```swift
/// func encode(to encoder: Encoder) throws {
///     var container = encoder.container(keyedBy: CodingKeys.self)
///     try container.encode(self.normalProperty, forKey: .normalProperty)
///     try container.encode(self.specialProperty.byteSwapped, forKey: .specialProperty)
/// }
///
/// init(from decoder: Decoder) throws {
///     let container = try decoder.container(keyedBy: CodingKeys.self)
///     self.normalProperty = try container.decode(forKey: .normalProperty)
///     self.specialProperty = try container.decode(Int.self, forKey: .specialProperty).byteSwapped
/// }
/// ```
///
/// ## Topics
///
/// ### Controlling Encode
/// - ``transient()``
/// - ``encodeOptions(_:)``
@attached(extension, conformances: Codable, names: named(encode(to:)), named(CodingKeys))
@attached(member, names: named(init))
public macro customCodable() = #externalMacro(module: "MacrosDefinitions", type: "customCodable")


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
///
/// ## Topics
///
/// ### Controlling Encode
/// - ``transient()``
/// - ``encodeOptions(_:)``
///
/// ### More Customizations
/// - ``customCodable()``
@attached(extension, conformances: Codable, names: named(encode(to:)), named(CodingKeys))
@attached(member, names: named(init))
public macro codable() = #externalMacro(module: "MacrosDefinitions", type: "codable")


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


/// Tells `@codable` macro the additional options for coding.
///
/// This macro must be used within the ``codable()`` annotated class.
/// ```swift
/// @codable
/// class Cat {
///     let name: String
///
///     @encodeOptions(.ignored)
///     let age: Int
/// }
/// ```
///
/// In the generated `CodingKeys`, the ignored property `age` is not shown.
/// ```swift
/// enum CodingKeys: CodingKey {
///     case name
/// }
/// ```
///
/// The other generated codes are updated according.
///
/// ## Topics
/// ### Controlling Coding
/// - ``AttributeEncodeOptions``
@attached(peer)
public macro encodeOptions(_ options: AttributeEncodeOptions...) = #externalMacro(module: "MacrosDefinitions", type: "encodeOptions")


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
/// @provided(by: ModelProvider.self)
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
/// > Tip:
/// > You could also use the ``environment(_:)-9r4s2`` macro.
/// > ```swift
/// > #environment(ModelProvider.self)
/// > ```
///
/// ## Macro Expansion
/// The `ModelProvider` declared above will be expanded to
///
/// ```swift
/// final class ModelProvider {
///     static var instance: Model
/// }
///
/// extension ModelProvider: Codable { ... }
/// ```
///
/// The `instance` can be used to refer to this singleton, on mutation of this value, views will be updated automatically.
///
/// ## Topics
///
/// ### Macros
///
///- ``provided(by:)``
///- ``environment(_:)-9r4s2``
///
/// ### Protocols
///
/// - ``DataProvider``
@attached(extension, conformances: DataProvider, Codable, names: named(encode(to:)), named(CodingKeys), named(storageItem), named(save()))
@attached(member, names: named(init(from:)), named(init), named(instance))
public macro dataProviding() = #externalMacro(module: "MacrosDefinitions", type: "dataProviding")


/// Attach this macro to the `@main App` to use the `DataProvider`s declared.
///
/// Attach the ``provided(by:)`` macro.
/// ```swift
/// @main
/// @provided(by: ModelProvider.self)
/// struct testApp: App { ... }
/// ```
///
/// Use the `environment` view modifiers to store this provider in the environment. The name is the same as the class, with the leading character being lowercased.
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
/// > Tip:
/// > You could also use the ``environment(_:)-9r4s2`` macro.
/// > ```swift
/// > #environment(ModelProvider.self)
/// > ```
///
/// The providers can be declared using the ``dataProviding()`` macro.
/// ```swift
/// @dataProviding
/// final class ModelProvider { ... }
/// ```
///
/// ## Macro Expansion
/// The `testApp` declared above will be expanded to
///
/// ```swift
/// @State var modelProvider = ModelProvider.instance
/// @ApplicationDelegateAdaptor var applicationDelegate
/// ```
/// - term modelProvider: The `modelProvider`, which is the class name with leading character lowercased, can be passed around in the environment.
/// - term applicationDelegate: A simple application delegate, which is defined to save the `modelProvider` when application closes. On macOS, it will also tell the system to close the application after the last window closed.
///
/// - bug: Will fail to compile if the user defines its own `applicationDelegate`.
@attached(member, names: named(ApplicationDelegate), arbitrary)
public macro provided<each Value>(by providers: repeat (each Value).Type) = #externalMacro(module: "MacrosDefinitions", type: "providedBy") where repeat each Value: DataProvider


#if canImport(SwiftUI)
import SwiftUI

/// *syntax sugar* for defining swiftUI `@Environment`.
///
/// > Example:
/// > ```swift
/// > #environment(\.dismiss)
/// > ```
/// > would translate to
/// > ```swift
/// > @Environment(\.dismiss) private var dismiss
/// > ```
@freestanding(declaration, names: arbitrary)
public macro environment<each Value>(_ contents: repeat KeyPath<EnvironmentValues, each Value>) = #externalMacro(module: "MacrosDefinitions", type: "environment")


/// *syntax sugar* for defining swiftUI `@Environment`.
///
/// > Example:
/// > ```swift
/// > #environment(ModelProvider.self)
/// > ```
/// > would translate to
/// > ```swift
/// > @Environment(ModelProvider.self) private var modelProvider
/// > ```
@freestanding(declaration, names: arbitrary)
public macro environment<each Value>(_ contents: repeat (each Value).Type) = #externalMacro(module: "MacrosDefinitions", type: "environment") where repeat each Value: DataProvider
#endif
