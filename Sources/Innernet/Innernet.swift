#if DEBUG
import Foundation
import InnernetBase

public class Innernet {
    public typealias InterceptProtocol = URLProtocolInterceptor
    
    public static var allowsPassthroughRequests = false {
        didSet {
            URLProtocolInterceptor.allowsPassthroughRequests = allowsPassthroughRequests
        }
    }
    
    public static var timeoutThreshold: Double = 15 {
        didSet {
            URLProtocolInterceptor.timeoutThreshold = timeoutThreshold
        }
    }
    
    /// Enable or disable communication with external console. Defaults to false.
    static var enableExternalConsoleIntercepts: Bool = false
    
    /// Enable or disable logging. Defaults to false.
    static var enableLogs: Bool {
        get {
            return Logger.shared.isEnabled
        }
        set {
            Logger.shared.isEnabled = newValue
        }
    }
}

public extension Innernet {
    
    /**
     Intercept function used for simple request matching. The request will match against the URL path and HTTPMethod. If more complex matching is needed use the **intercept(_ method: HTTPMethod, canIntercept: @escaping (URLRequest) -> Bool, onRequest: @escaping (URLRequest, @escaping (ResponseStrategy) -> Void) -> Void)** instead
     */
    static func intercept(
        _ method: RequestInterceptor.HTTPMethod,
        matching url: String,
        onRequest: @escaping (URLRequest, @escaping (ResponseStrategy) -> Void) -> Void
    ) {
        URLProtocolInterceptor.interceptor.register(
            method,
            matching: url,
            onRequest: onRequest
        )
    }
    
    /**
     The function that all intercepts go through. This can be used to do more complex intercept matching like checking against request headers, body, etc.
     */
    static func intercept(
        _ method: RequestInterceptor.HTTPMethod,
        canIntercept: @escaping (URLRequest) -> Bool,
        onRequest: @escaping (URLRequest, @escaping (ResponseStrategy) -> Void) -> Void
    ) {
        URLProtocolInterceptor.interceptor.register(
            method,
            canIntercept: canIntercept,
            onRequest: onRequest
        )
    }
    
    static func unregisterAll() {
        URLProtocolInterceptor.interceptor.unregisterAll()
    }
    
    /// Enable  communication with external console. Defaults to false.
    static func enableExternalConsole() {
        Self.enableExternalConsoleIntercepts = true
        ConsoleManager.shared.loadIntercepts { result in
            handleConsoleInterceptResponse(result: result)
        }
    }
    
    static func disableExternalConsole() {
        Self.enableExternalConsoleIntercepts = false
    }
    
    /// Enable logging. Defaults to false.
    static func enableLogging() {
        Self.enableLogs = true
    }
    
    static func disableLogging() {
        Self.enableLogs = false
    }
}

private extension Innernet {
    
    static func handleConsoleInterceptResponse(result: Result<Network.Response<[ConsoleManager.ConsoleIntercept]>, Error>) {
        switch result {
        case .success(let response):
            handleConsoleIntercepts(response.payload)
        case .failure(let error):
            handleConsoleError(error)
        }
    }
    
    static func handleConsoleIntercepts(_ intercepts: [ConsoleManager.ConsoleIntercept]) {
        intercepts.forEach { intercept in
            registerExternalIntercept(
                RequestInterceptor.HTTPMethod.custom(intercept.method),
                matching: intercept.matchURL,
                onRequest: { _, completion in
                    // hit the localhost to get the payload info for mock
                    ConsoleManager.shared.loadMockInfoFor(
                        intercept: intercept,
                        completion: { data, response, error in
                            // TODO: try to decode the data as some predefined console object
                            // so that network timeouts and stuff can be sent instead of simply
                            // the mocked response
                            completion(.redirected(data: data, response: response, error: error))
                        }
                    )
                }
            )
        }
    }
    
    static func handleConsoleError(_ error: Error) {
        Logger.shared.error(error.localizedDescription)
    }
    
    static func registerExternalIntercept(
        _ method: RequestInterceptor.HTTPMethod,
        matching url: String,
        onRequest: @escaping (URLRequest, @escaping (ResponseStrategy) -> Void) -> Void
    ) {
        URLProtocolInterceptor.interceptor.register(
            method,
            canIntercept: { req in
                if Self.enableExternalConsoleIntercepts == false {
                    return false
                }
                return RequestInterceptor.defaultMatching(for: req, matching: url)
            },
            onRequest: onRequest
        )
    }
}
#endif
