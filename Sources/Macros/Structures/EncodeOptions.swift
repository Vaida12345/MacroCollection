//
//  EncodeOptions.swift
//  
//
//  Created by Vaida on 2024/3/6.
//


import Foundation


/// An option used within ``encodeOptions(:_)``
public enum AttributeEncodeOptions {
    
    /// Ignore the property.
    ///
    /// This is the same as ``encodeOptions()``
    case ignored
    
    /// Encode and decode the property only when present.
    ///
    /// This option is set to `Optional` properties. When annotated, the encoder would only attempt to encode when the value is non-`nil`, and the same for decoders.
    case encodeIfPresent
    
    /// Encode and decode the property only when it is not the default value.
    ///
    /// When annotated, the encoder would only attempt to encode when the value is different from the default value, measured by `==`, and the same for decoders.
    ///
    /// - Bug: Annotate this on a non-`Equitable` property will cause failure of complication.
    case encodeIfNoneDefault
    
}
