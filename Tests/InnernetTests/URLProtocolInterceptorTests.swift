import XCTest
@testable import Innernet
import InnernetBase

final class URLProtocolInterceptorTests: XCTestCase {
        
    var session: URLSession!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = URLSessionConfiguration.default
        config.protocolClasses = [Innernet.InterceptProtocol.self]
        session = URLSession(configuration: config)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        Innernet.unregisterAll()
        session = nil
        MockURLProtocol.reset()
    }
    
    func test_Registration_WillReturnIntercept() {
        let expect = expectation(description: "test_Registration_WillReturnIntercept")
        Innernet.intercept(.get, canIntercept: { _ in
            return true
        }, onRequest: { _, completion in
            expect.fulfill()
        })
        var req = URLRequest(url: URL(string: "https://apple.com")!)
        req.httpMethod = "GET"
        session.dataTask(with: req).resume()
        wait(for: [expect], timeout: 0.1)
    }

    func test_intercept_PreventsRequestsFromHittingNetwork() {

        let config = URLSessionConfiguration.default
        config.protocolClasses = [Innernet.InterceptProtocol.self, MockURLProtocol.self]
        session = URLSession(configuration: config)

        let expect = expectation(description: "test_intercept_PreventsRequestsFromHittingNetwork")
        expect.isInverted = true

        Innernet.intercept(.get, canIntercept: { _ in
            return true
        }, onRequest: { _, completion in
            completion(.mock(status: 200, data: nil, headers: nil, httpVersion: nil))
        })
        let reqID = UUID().uuidString
        MockURLProtocol.onStart = { id in
            if id == reqID {
                expect.fulfill()
            }
        }
        var req = URLRequest(url: URL(string: "https://apple.com")!)
        req.httpMethod = "GET"
        req.addTestID(reqID)
        session.dataTask(with: req).resume()
        wait(for: [expect], timeout: 0.1)
    }

    // MARK: Passthroughs

    func test_RequestReturnsError_When_NoMatchingIntercept_And_PassthroughsDisabled() {
        URLProtocolInterceptor.allowsPassthroughRequests = false
        let config = URLSessionConfiguration.default
        config.protocolClasses = [Innernet.InterceptProtocol.self, MockURLProtocol.self]
        session = URLSession(configuration: config)

        let invalidExpect = expectation(description: "test_RequestReturnsErorr_When_NoMatchingIntercept_And_PassthroughsDisabled")
        invalidExpect.isInverted = true

        let reqID = UUID().uuidString
        MockURLProtocol.onStart = { id in
            if id == reqID {
                invalidExpect.fulfill()
            }
        }

        let expect = expectation(description: "test_RequestReturnsErorr_When_NoMatchingIntercept_And_PassthroughsDisabled 2")
        var req = URLRequest(url: URL(string: "https://apple.com")!)
        req.httpMethod = "GET"
        req.addTestID(reqID)
        session.dataTask(with: req) { _, _, error in
            XCTAssert(error.debugDescription.contains("Request was blocked"))
            expect.fulfill()
        }.resume()
        wait(for: [invalidExpect, expect], timeout: 0.1)
    }

    func test_RequestHitsNetwork_When_NoMatchingIntercept_And_PassthroughsEnabled() {
        URLProtocolInterceptor.allowsPassthroughRequests = true
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)

        let expect = expectation(description: "test_RequestHitsNetwork_When_NoMatchingIntercept_And_PassthroughsEnabled")
        var req = URLRequest(url: URL(string: "https://apple.com")!)
        req.httpMethod = "GET"
        let expected = "test"
        let body = expected.data(using: .utf8)!
        MockURLProtocol.responseData = body
        let id = UUID().uuidString
        req.addTestID(id)

        session.dataTask(with: req) { data, _, _ in
            guard let data = data else {
                XCTFail("Expected to get data response")
                return
            }
            let value = String(data: data, encoding: .utf8)
            XCTAssertEqual(value, expected)
            expect.fulfill()
        }.resume()
        wait(for: [expect], timeout: 0.1)
    }

    // MARK: Timeouts

    func test_RequestTimesOut_When_InterceptTakesTooLong() {
        Innernet.timeoutThreshold = 0.1
        let expect = expectation(description: "test_RequestTimesOut_When_InterceptTakesTooLong")
        Innernet.intercept(.get, canIntercept: { _ in
            return true
        }, onRequest: { _, completion in
            // never completes
        })
        var req = URLRequest(url: URL(string: "https://apple.com")!)
        req.httpMethod = "GET"
        session.dataTask(with: req) { _, _, error in
            XCTAssertNotNil(error)
            XCTAssert(error.debugDescription.contains("Request forced to timeout"))
            expect.fulfill()
        }.resume()
        wait(for: [expect], timeout: 0.3)
    }
}

extension URLRequest {
    mutating
    func addTestID(_ id: String) {
        self.addValue(id, forHTTPHeaderField: "TestHeaderID")
    }
    
    var testID: String? {
        return self.value(forHTTPHeaderField: "TestHeaderID")
    }
}

private let HandledKey = "RequestHandledKey"
class MockURLProtocol: URLProtocol {
    
    static var onStart: ((String) -> Void)?
    static var responseData: Data?
    
    static func reset() {
        onStart = nil
        responseData = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: HandledKey, in: request) != nil {
          return false
        }
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let newRequest = ((request as NSURLRequest).mutableCopy() as! NSMutableURLRequest)
        URLProtocol.setProperty(true, forKey: HandledKey, in: newRequest)
        let id = request.testID ?? ""
        MockURLProtocol.onStart?(id)
        if let data = MockURLProtocol.responseData {
            self.client?.urlProtocol(self, didLoad: data)
        }
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
}

