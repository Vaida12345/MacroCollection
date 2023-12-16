// The Swift Programming Language
// https://docs.swift.org/swift-book


/// Generates the methods required by `Codable` for the stored properties.
@attached(extension, names: named(init(from:)), named(encode(to:)), named(CodingKeys), arbitrary, conformances: Codable)
public macro Codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "Codable")

/// Generates an initializer including all the stored properties.
@attached(member, names: named(init))
public macro memberwiseInitializable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "memberwiseInitializable")
