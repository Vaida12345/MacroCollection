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
            let _key = buffer.bindMemory(to: (UInt64, UInt64, UInt64, UInt64).self).baseAddress!.pointee
            
            var _cipher = """
            var cipher = Data(capacity: \(cipher.count))\n
            """
            for byte in cipher {
                _cipher.append("cipher.append((\(byte) as UInt8))\n")
            }
            
            
            return """
            { () -> String in
                let key: (UInt64, UInt64, UInt64, UInt64) = \(raw: _key)
                \(raw: _cipher)
                return _encrypt_macro_decrypt(key: key, cipher: cipher)
            }()
            """
        }
    }
    
}
