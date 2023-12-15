// The Swift Programming Language
// https://docs.swift.org/swift-book


@attached(extension, names: named(init(from:)), named(encode(to:)), named(CodingKeys), arbitrary, conformances: Codable)
public macro Codable() = #externalMacro(module: "NucleusMacrosDefinitions", type: "Codable")
