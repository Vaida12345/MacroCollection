//
//  Macros.swift
//
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
///
/// ## Additional Options
///
/// There are a few other options that can be accessed using ``encodeOptions(_:)``. For a list of options, see ``AttributeEncodeOptions``.
///
/// A backdoor was made for function with signature `static? func postDecodeAction() throws?`. Such function will be appended to the end of generated decode implementation if present.
///
/// ## Topics
///
/// ### Controlling Encode
/// - ``transient()``
/// - ``encodeOptions(_:)``
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


/// Tells `@codable` macro the additional options for encoding and decoding.
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


/// Encrypt the sensitive `string` in the build product.
///
/// Instead of storing the string, this macro would store the cipher text and decryption key in binary. Hence making it harder for users to find the sensitive info from the build product.
///
/// In this implementation, `AES.GCM` cipher is used.
///
/// ## Example
///
/// ``` swift
/// #encrypt("hello world")
/// ```
///
/// Would expand to
///
/// ```swift
/// { () -> String in
///     let key: (UInt64, UInt64, UInt64, UInt64) = ...
///     var cipher = Data(capacity: 39)
///     cipher.append((191 as UInt8))
///     cipher.append((114 as UInt8))
///     ...
///
///     return // decrypted string
/// }()
/// ```
///
/// The `key` and `cipher` are different for each build, and these implementation details are completely hidden under the hood, users can treat `#encrypt("hello world")` as `"hello world"`.
@freestanding(expression)
public macro encrypt(_ string: StaticString) -> String = #externalMacro(module: "MacrosDefinitions", type: "encrypt")


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
@attached(member, names: named(as(_:)), named(is(_:)), named(EnumProperty))
public macro accessingAssociatedValues() = #externalMacro(module: "MacrosDefinitions", type: "accessingAssociatedValues")


#if canImport(SwiftUI)
import SwiftUI

/// *syntax sugar* for defining swiftUI `@Environment`.
///
/// > Example:
/// > ```swift
/// > #environment(\.dismiss)
/// > ```
/// > would expand to
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
/// > would expand to
/// > ```swift
/// > @Environment(ModelProvider.self) private var modelProvider
/// > ```
@freestanding(declaration, names: arbitrary)
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
public macro environment<each Value>(_ contents: repeat (each Value).Type) = #externalMacro(module: "MacrosDefinitions", type: "environment") where repeat each Value: Observable
#endif
