#if DEBUG
import Foundation
import InnernetBase

extension NetworkError {
    var errorForResponse: Error {
        switch self {
        case .timeout:
            return NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        case .unreachable:
            return NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        case let .framework(error):
            return error
        case let .custom(error):
            return error
        }
    }
}

// Custom URLProtocols do not work when a custom session is created that does not contain
// the URLProtocol classes in the configuration.protocolClasses array

// this means this proxying will not work with Alamofire automatically, the Alamofire
// session will need to be setup in such a way that the protocolClasses are set

// Swizzling URLSession will also not work because Alamofire uses URLConnection under the hood?

private let HandledKey = "URLProtocolInterceptorHandledKey"

private extension DispatchQueue {
    static let intercept = DispatchQueue(label: "com.ajbartocci.Innernet.URLProtocolInterceptorQueue")
}

public class URLProtocolInterceptor: URLProtocol {
    
    static var allowsPassthroughRequests = false
    static var timeoutThreshold: Double = 15
    static let interceptor = RequestInterceptor()
    
    public override class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: HandledKey, in: request) != nil {
          return false
        }
        if interceptor.intercept(for: request) != nil {
            return true
        } else {
            if allowsPassthroughRequests {
                // allow it to go on to the network
                return false
            } else {
                // intercept it and return an error
                return true
            }
        }
    }
    
    public override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        if let intercept = URLProtocolInterceptor.interceptor.intercept(for: request) {
            handleIntercept(intercept, for: request)
        } else {
            if URLProtocolInterceptor.allowsPassthroughRequests {
                forwardOriginalRequest(request: request)
            } else {
                client?.urlProtocol(self, didFailWithError: NetworkError.framework(.blockedPassthrough).errorForResponse)
                didFinishRequest()
            }
        }
    }
    
    public override func stopLoading() {
        
    }
}

//extension URLProtocolInterceptor: NSURLConnectionDataDelegate {
//
//    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
//        receivedResponse(response)
//    }
//
//    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
//        receivedData(data)
//    }
//
//    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
//        didFinishRequest()
//    }
//
//    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
//        receivedError(error)
//    }
//}

private extension URLProtocolInterceptor {
    func receivedResponse(_ response: URLResponse) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    
    func receivedData(_ data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
    
    func receivedError(_ error: Error) {
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    func didFinishRequest() {
        client?.urlProtocolDidFinishLoading(self)
    }
    
    func handleIntercept(_ intercept: Intercept, for request: URLRequest) {
        let newRequest = ((request as NSURLRequest).mutableCopy() as! NSMutableURLRequest)
        URLProtocol.setProperty(true, forKey: HandledKey, in: newRequest)
        
        var didFinish = false
        DispatchQueue.intercept.asyncAfter(deadline: .now() + URLProtocolInterceptor.timeoutThreshold) {
            guard didFinish == false else {
                return
            }
            didFinish = true
            self.receivedError(NetworkError.framework(.interceptTimeout).errorForResponse)
            self.didFinishRequest()
        }
        
        intercept.onRequest(request, { response in
            DispatchQueue.intercept.async {
                guard didFinish == false else {
                    return
                }
                didFinish = true
                switch response {
                case let .mock(status: status, data: data, headers: headers, httpVersion: httpVersion):
                    if let data = data {
                        self.receivedData(data)
                    }
                    let url = request.url ?? URL(string: "https://localhost:8000/innernets-default")!
                    let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: httpVersion, headerFields: headers)!
                    self.receivedResponse(response)
                    self.didFinishRequest()
                case let .networkError(networkError):
                    self.receivedError(networkError.errorForResponse)
                    self.didFinishRequest()
                }
            }
        })
    }
    
    
    
    func forwardOriginalRequest(request: URLRequest) {
        let newRequest = ((request as NSURLRequest).mutableCopy() as! NSMutableURLRequest)
        URLProtocol.setProperty(true, forKey: HandledKey, in: newRequest)
        
        URLSession.shared.dataTask(with: newRequest as URLRequest) { [weak self] data, response, error in
            if let data = data, let response = response {
                self?.receivedData(data)
                self?.receivedResponse(response)
                self?.didFinishRequest()
            } else {
                if let response = response {
                    self?.receivedResponse(response)
                }
                self?.receivedError(error!)
                self?.didFinishRequest()
            }
        }.resume()
    }
}
#endif

