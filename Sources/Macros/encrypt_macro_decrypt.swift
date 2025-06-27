//
//  _encrypt_macro_decrypt.swift
//
//
//  Created by Vaida on 5/18/24.
//

import Foundation
import CryptoKit


/// Helper function of `#encrypt` macro.
@inlinable
public func _encrypt_macro_decrypt(key: (UInt64, UInt64, UInt64, UInt64), cipher: Data) -> String {
    var key = key
    
    return withUnsafeMutablePointer(to: &key) { buffer in
        buffer.withMemoryRebound(to: UInt8.self, capacity: 32) { pointer in
            let key = SymmetricKey(data: UnsafeMutableBufferPointer(start: pointer, count: 32))
            let sealedBox = try! AES.GCM.SealedBox(combined: cipher)
            let data = try! AES.GCM.open(sealedBox, using: key)
            return String(data: data, encoding: .utf8)!
        }
    }
}
