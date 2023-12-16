// The Swift Programming Language
// https://docs.swift.org/swift-book


/// Generates the methods required by `Codable` for the stored properties.
@attached(extension, names: named(encode(to:)), named(CodingKeys), conformances: Codable)
@attached(member, names: named(init(from:)))
public macro codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "codable")

/// Generates an initializer including all the stored properties. if it is possible, an `init { }` will also be synthesized.
@attached(member, names: named(init))
public macro memberwiseInitializable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "memberwiseInitializable")

/// Tells `@codable` macro not to persist the annotated property.
@attached(peer)
public macro transient() = #externalMacro(module: "NucleusMacrosDefinitions", type: "transient")
