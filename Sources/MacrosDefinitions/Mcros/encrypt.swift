//
//  encrypt.swift
//
//
//  Created by Vaida on 5/18/24.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros
import CryptoKit


public enum encrypt: ExpressionMacro {
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.arguments.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let segment)? = segments.first
        else {
            fatalError("Compiler Bug: The passed argument is not static string")
        }
        
        let plainText = segment.content.text
        let key = SymmetricKey(size: .bits256)
        
        let cipher = try AES.GCM.seal(plainText.data(using: .utf8)!, using: key).combined!
        
        return key.withUnsafeBytes { buffer in
            let _key = buffer.bindMemory(to: UInt64.self)
            
            func hexEscape(_ word: UInt64) -> String {
                "0x" + String(format: "%016llX", word)
            }
            
            let cipherCount = cipher.count
            let remainder = cipher.count % 8
            let padding = remainder == 0 ? 0 : 8 - remainder
            let paddedCipher = cipher + [UInt8](repeating: 0, count: padding)
            
            return paddedCipher.withUnsafeBytes { cipherBuffer in
                let _cipher = cipherBuffer.bindMemory(to: UInt64.self)
                
                return "_encrypt_macro_decrypt(key: (\(raw: _key.map(hexEscape).joined(separator: ","))), cipher: [\(raw: _cipher.map(hexEscape).joined(separator: ","))], cipherCount: \(raw: cipherCount))"
            }
        }
    }
    
}
