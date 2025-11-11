//
//  CodableOptions.swift
//  MacroCollection
//
//  Created by Vaida on 2025-11-12.
//


/// Options for `@codable`.
public struct CodableOptions: OptionSet, Sendable {
    
    public var rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    /// Specifies that implementation should override conformance to `Codable` by superclass.
    ///
    /// If the declaration is not a class, this option is ignored.
    public static let `override` = CodableOptions(rawValue: 1 << 0)
    
}
