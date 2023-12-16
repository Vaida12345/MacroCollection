// The Swift Programming Language
// https://docs.swift.org/swift-book


/// Generates the methods required by `Codable` for the stored properties.
@attached(extension, names: named(init(from:)), named(encode(to:)), named(CodingKeys), conformances: Codable)
public macro codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "codable")

/// Generates an initializer including all the stored properties.
@attached(member, names: named(init))
public macro memberwiseInitializable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "memberwiseInitializable")

/// Tells `@codable` macro not to persist the annotated property.
@attached(peer)
public macro transient() = #externalMacro(module: "NucleusMacrosDefinitions", type: "transient")
