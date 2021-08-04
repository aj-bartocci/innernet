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
}
#endif
