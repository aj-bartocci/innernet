//
//  File.swift
//  
//
//  Created by AJ Bartocci on 12/22/21.
//

import XCTest

extension XCTestCase {
    func expectationForCurrentFunction(functionName: String = #function, id: String = "") -> XCTestExpectation {
        return expectation(description: functionName + id)
    }
}
