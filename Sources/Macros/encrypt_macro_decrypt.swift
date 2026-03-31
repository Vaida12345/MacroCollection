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
public func _encrypt_macro_decrypt(key: (UInt64, UInt64, UInt64, UInt64), cipher: [UInt64], cipherCount: Int) -> String {
    return withUnsafeBytes(of: key) { buffer in
        let keyBuffer = buffer.bindMemory(to: UInt8.self)
        return cipher.withUnsafeBytes { cipherBuffer in
            let _cipher = cipherBuffer.bindMemory(to: UInt8.self)[0..<cipherCount]
            
            let key = SymmetricKey(data: UnsafeBufferPointer(start: keyBuffer.baseAddress!, count: 32))
            let sealedBox = try! AES.GCM.SealedBox(combined: _cipher)
            let data = try! AES.GCM.open(sealedBox, using: key)
            return String(data: data, encoding: .utf8)!
        }
    }
}
