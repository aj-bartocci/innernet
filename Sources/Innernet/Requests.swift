//
//  File.swift
//  
//
//  Created by AJ Bartocci on 11/24/21.
//

import Foundation

struct Request { }

extension Request {
    typealias Intercepts = Network.Request<[ConsoleManager.ConsoleIntercept]>
}
