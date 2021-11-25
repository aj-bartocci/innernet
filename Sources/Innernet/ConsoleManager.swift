//
//  File.swift
//  
//
//  Created by AJ Bartocci on 11/24/21.
//

import Foundation

// TODO: make it so the user can set the port
// - Innernet client will have it as an option that is passed on startup
// - Innernet console will have settings page where it can be set
private let consoleBaseUrlString = "http://localhost:5069"
private let consoleBaseUrl = URL(string: consoleBaseUrlString)!

class ConsoleManager {
    
    enum ConsolError: Error {
        case consoleNotAvailable
        case consoleDecodingFailed
    }
    
    struct ConsoleIntercept: Codable {
        let id: String
        let method: String
        let matchURL: String
        let delay: Double
    }
    
    // TODO: allow console configured networking errors
//    struct ConsoleMockError: Codable {
//        enum ErrorType: Codable {
//            case timeout
//            case serverUnreachable
//            // etc
//        }
//        // just in case the mock collides with this
//        let innernetConsoleKey: Bool
//        let type: ErrorType
//    }
    
    private var didAttemptToLoadIntercepts = false
    private var intecepts = [ConsoleIntercept]()
    private let decoder = JSONDecoder()
    private (set) var isLoadingIntercepts = false {
        didSet {
            if isLoadingIntercepts == false {
                self.interceptsLoadingCompletions.forEach({ $0() })
                self.interceptsLoadingCompletions = []
            }
        }
    }
    var interceptsLoadingCompletions = [() -> Void]()
    static let shared = ConsoleManager()
    
    private init() { }
    
    func loadIntercepts(completion: @escaping (Result<Network.Response<[ConsoleIntercept]>, Error>) -> Void) {
        isLoadingIntercepts = true
        let url = consoleBaseUrl.appendingPathComponent("intercept")
        Network.shared.send(
            request: Request.Intercepts(request: URLRequest(url: url)),
            completion: { [weak self] result in
                DispatchQueue.intercept.async {
                    completion(result)
                    self?.isLoadingIntercepts = false
                }
            }
        )
    }
    
    func loadMockInfoFor(
        intercept: ConsoleIntercept,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        let url = consoleBaseUrl.appendingPathComponent("intercept/\(intercept.id)/response")
        Network.shared.send(request: URLRequest(url: url), completion: completion)
    }
    
    func onInterceptsFinishedLoading(completion: @escaping () -> Void) {
        DispatchQueue.intercept.async {
            guard self.isLoadingIntercepts == true else {
                completion()
                return
            }
            self.interceptsLoadingCompletions.append(completion)
        }
    }
}
