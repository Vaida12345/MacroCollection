//
//  symbolTests.swift
//  MacroCollection
//
//  Created by Vaida on 2025-07-05.
//

import Testing
import MacroCollection

@Test func symbolTest() {
    #expect(#symbol("shippingbox") == "shippingbox")
}
