//
//  Codable Ex.swift
//  NucleusMacros
//
//  Created by Vaida on 2023/12/15.
//

import Foundation

extension KeyedDecodingContainer {
    
    /// Decodes a value for the given key.
    ///
    /// The returning type is inferred. You can make it explicit by calling the original `decode` method.
    ///
    /// - Returns: A value of the requested type, if present for the given key and convertible to the requested type.
    public func decode<T>(forKey key: KeyedDecodingContainer<K>.Key) throws -> T where T: Decodable {
        try self.decode(T.self, forKey: key)
    }
    
    /// Decodes a value of the given type for the given key, if present.
    ///
    /// The returning type is inferred. You can make it explicit by calling the original `decode` method.
    ///
    /// - Returns: A decoded value of the requested type, or nil if the Decoder does not have an entry associated with the given key, or if the value is a null value.
    public func decodeIfPresent<T>(forKey key: KeyedDecodingContainer<K>.Key) throws -> T? where T: Decodable {
        try self.decodeIfPresent(T.self, forKey: key)
    }
    
}
