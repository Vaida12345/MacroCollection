//
//  NucleusMacros.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation


/// Generates the methods required by `Codable` for the stored properties.
@attached(extension, names: named(encode(to:)), named(CodingKeys), conformances: Codable)
@attached(member, names: named(init(from:)))
public macro codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "codable")

/// Generates an initializer including all the stored properties. if it is possible, an `init()` will also be synthesized.
@attached(member, names: named(init))
public macro memberwiseInitializable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "memberwiseInitializable")

/// Tells `@codable` macro not to persist the annotated property.
@attached(peer)
public macro transient() = #externalMacro(module: "NucleusMacrosDefinitions", type: "transient")

/// Creates an url with compile-time validation
@freestanding(expression)
public macro url(_ string: StaticString) -> URL = #externalMacro(module: "NucleusMacrosDefinitions", type: "url")

/// Creates a system-defined symbol with compile-time validation
@available(macOS 11.0, iOS 15, watchOS 7, *)
@freestanding(expression)
public macro symbol(systemName: StaticString) -> String = #externalMacro(module: "NucleusMacrosDefinitions", type: "symbol")

/// Generates methods for retrieving associated values and determining cases.
@attached(extension, names: named(as(_:)), named(is(_:)), named(EnumProperty))
public macro accessingAssociatedValues() = #externalMacro(module: "NucleusMacrosDefinitions", type: "accessingAssociatedValues")
