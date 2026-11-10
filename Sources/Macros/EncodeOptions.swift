//
//  EncodeOptions.swift
//  
//
//  Created by Vaida on 2024/3/6.
//


import Foundation


/// An option used within ``MacroCollection/encodeOptions(_:)``
public enum AttributeEncodeOptions {
    
    /// Ignore the property.
    ///
    /// This is the same as ``MacroCollection/transient()``
    ///
    /// ### Usage
    /// This macro must be used within the ``codable(_:)`` annotated class.
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
    
    /// Encode the property only when present.
    ///
    /// This option can only be applied to `Optional` properties. When annotated, the encoder leaves the key out if the value is `nil`, instead of writing `null`.
    ///
    /// Decoding does not depend on this option: an optional property is always decoded using `decodeIfPresent`, hence its key may be missing.
    ///
    /// ### Usage
    /// This macro must be used within the ``codable(_:)`` annotated class.
    /// ```swift
    /// @codable
    /// class Cat {
    ///     @encodeOptions(.encodeIfPresent)
    ///     let age: Int?
    /// }
    /// ```
    ///
    /// In the generated `encode(to:)`. Such value will only be encoded when the value is not nil.
    /// ```swift
    /// try container.encodeIfPresent(self.age, forKey: .age)
    /// ```
    case encodeIfPresent
    
    /// Encode and decode the property only when it is not the default value.
    ///
    /// When annotated, the encoder would only attempt to encode when the value is different from the default value, measured by `==`, and the same for decoders.
    ///
    /// - Bug: Annotating this on a non-`Equatable` property will cause failure of compilation.
    ///
    /// ### Usage
    /// This macro must be used within the ``codable(_:)`` annotated class.
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
