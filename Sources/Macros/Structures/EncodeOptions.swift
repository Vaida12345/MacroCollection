//
//  EncodeOptions.swift
//  
//
//  Created by Vaida on 2024/3/6.
//


import Foundation


/// An option used within ``StratumMacros/encodeOptions(_:)``
public enum AttributeEncodeOptions {
    
    /// Ignore the property.
    ///
    /// This is the same as ``StratumMacros/encodeOptions(_:)``
    ///
    /// ### Usage
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
    case ignored
    
    /// Encode and decode the property only when present.
    ///
    /// This option is set to `Optional` properties. When annotated, the encoder would only attempt to encode when the value is non-`nil`, and the same for decoders.
    ///
    /// ### Usage
    /// This macro must be used within the ``codable()`` annotated class.
    /// ```swift
    /// @codable
    /// class Cat {
    ///     @encodeOptions(.encodeIfPresent)
    ///     let age: Int?
    /// }
    /// ```
    ///
    /// In the generated `encode(to:)` and `init(from:)`. Such value will only be encoded / decoded when the value is not nil.
    /// ```swift
    /// try container.encodeIfPresent(self.age, forKey: .age)
    /// ```
    case encodeIfPresent
    
    /// Encode and decode the property only when it is not the default value.
    ///
    /// When annotated, the encoder would only attempt to encode when the value is different from the default value, measured by `==`, and the same for decoders.
    ///
    /// - Bug: Annotate this on a non-`Equitable` property will cause failure of complication.
    ///
    /// ### Usage
    /// This macro must be used within the ``codable()`` annotated class.
    /// ```swift
    /// @codable
    /// class Cat {
    ///     @encodeOptions(.encodeIfNoneDefault)
    ///     var age: Int = 0
    /// }
    /// ```
    ///
    /// In the generated `encode(to:)` and `init(from:)`. Such value will only be encoded / decoded when the value is not default.
    /// ```swift
    /// if self.age != 0 {
    ///     try container.encodeIfPresent(self.age, forKey: .age)
    /// }
    /// ```
    case encodeIfNoneDefault
    
}
