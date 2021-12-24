#if DEBUG
import Foundation

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
    
    struct LoggedRequest: Codable {
        let statusCode: Int
        let method: String
        let url: String
        let reqHeaders: [String: String]?
        let reqBody: Data?
        let resBody: Data?
        let resHeaders: [String: String]?
        let wasIntercepted: Bool
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
    
    init() { }
    
    func loadIntercepts(completion: @escaping (Result<Network.Response<[ConsoleIntercept]>, Error>) -> Void) {
        isLoadingIntercepts = true
        let url = Constant.Network.consoleBaseUrl.appendingPathComponent("intercept")
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
        let url = Constant.Network.consoleBaseUrl.appendingPathComponent("intercept/\(intercept.id)/response")
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
    
    func logRequest(
        _ request: URLRequest,
        resData: Data?,
        response: URLResponse?,
        error: Error?,
        wasIntercepted: Bool,
        completion: (() -> Void)? = nil
    ) {
        let response = response as? HTTPURLResponse
        let payload = LoggedRequest(
            statusCode: response?.statusCode ?? -1,
            method: request.httpMethod ?? "???",
            url: request.url?.absoluteString ?? "???",
            reqHeaders: request.allHTTPHeaderFields,
            reqBody: request.httpBody,
            resBody: resData,
            resHeaders: response?.allHeaderFields as? [String: String],
            wasIntercepted: wasIntercepted
        )
        let req = Request.LogRequest(payload)
        Network.shared.send(request: req) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                Logger.shared.error(error.localizedDescription)
            }
            completion?()
        }
    }
}
#endif
