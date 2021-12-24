//
//  RequestAPITests.swift
//  
//
//  Created by AJ Bartocci on 12/21/21.
//

import XCTest

@testable import Innernet

struct GetLoggedRequests: RequestRepresentable {
    typealias Payload = [RequestInfo]
    let request: URLRequest = {
        let url = Constant.Network.consoleBaseUrl.appendingPathComponent("request")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        return req
    }()
    
    struct RequestInfo: Decodable {
        let id: String
        let method: String
        let url: String
        let statusCode: Int
        let wasIntercepted: Bool
        let timestamp: String

        let reqHeaders: [String: String]?
        // since this is for the console client we stringify everything
        // since it could be json, xml, etc
        let reqBody: String?
        let resHeaders: [String: String]?
        let resBody: String?
    }
}

extension Network {
    func getLoggedRequests(completion: @escaping (Result<Response<GetLoggedRequests.Payload>, Error>) -> Void) {
        Network.shared.send(request: GetLoggedRequests(), completion: completion)
    }
}

/**
 In order for these tests to work the InnernetConsole server must be running
 */
class RequestAPITests: XCTestCase {
    
    var sut: ConsoleManager!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = ConsoleManager()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }
    
    private func getLoggedRequestsAfterLogging(
        req: URLRequest,
        response: HTTPURLResponse,
        resData: Data? = nil,
        error: Error? = nil,
        wasIntercepted: Bool = false,
        completion: @escaping (Result<Network.Response<GetLoggedRequests.Payload>, Error>) -> Void
    ) {
        sut.logRequest(req, resData: resData, response: response, error: error, wasIntercepted: wasIntercepted) {
            Network.shared.getLoggedRequests(completion: completion)
        }
    }
    
    // MARK: Server generated info
    func test_SentRequestInfo_Returns_SentRequestInfo_Id() {
        let url = URL(string: "https://test.com/id")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.id)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_Returns_SentRequestInfo_Timestamp() {
        let url = URL(string: "https://test.com/timestamp")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let statusCode = 200
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.timestamp)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    // MARK: Request Info
    
    func test_SentRequestInfo_Returns_SentRequestInfo_URL() {
        let url = URL(string: "https://test.com/url")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.url)
                XCTAssertEqual(payload.first?.url, req.url?.absoluteString)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_Returns_SentRequestInfo_Method() {
        let url = URL(string: "https://test.com/method")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.method)
                XCTAssertEqual(payload.first?.method, req.httpMethod)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }

    func test_SentRequestInfo_Returns_SentRequestInfo_ReqHeaders() {
        let url = URL(string: "https://test.com/req-headers")!
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        let headers: [String: String] = [
            "foo": "bar",
            "baz": "buzz"
        ]
        req.allHTTPHeaderFields = headers
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!

        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.reqHeaders)
                XCTAssertEqual(payload.first?.reqHeaders, headers)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    // MARK: Response Body
    
    func test_SentRequestInfo_WithoutReqBody_DoesNot_Return_ReqBody() {
        let url = URL(string: "https://test.com/null-req-body")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!

        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNil(payload.first?.reqBody)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_WithJSONReqBody_Returns_ReqBody() {
        let url = URL(string: "https://test.com/json-req-body")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil)!
        let bodyPayload = ["hello": "world"]
        let data = try! JSONSerialization.data(withJSONObject: bodyPayload, options: [])
        req.httpBody = data
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.reqBody)
                guard let dataStr = payload.first?.reqBody else {
                    return
                }
                print("dataStr = \(dataStr)")
                do {
                    let obj = try JSONSerialization.jsonObject(with: Data(base64Encoded: dataStr)!, options: [])
                    guard let objDict = obj as? [String: String] else {
                        return
                    }
                    XCTAssertEqual(bodyPayload, objDict)
                    expect.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    // TODO: Test XML req body
    
    // MARK: Response Info
    
    func test_SentRequestInfo_Returns_SentRequestInfo_WasIntercepted() {
        let url = URL(string: "https://test.com/was-intercepted")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let statusCode = 200
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let wasIntercepted = true
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response, wasIntercepted: wasIntercepted) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.wasIntercepted)
                XCTAssertEqual(payload.first?.wasIntercepted, wasIntercepted)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_Returns_SentRequestInfo_Status() {
        let url = URL(string: "https://test.com/status")!
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        let statusCode = 400
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.statusCode)
                XCTAssertEqual(payload.first?.statusCode, statusCode)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_Returns_SentRequestInfo_ResHeaders() {
        let url = URL(string: "https://test.com/res-headers")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let headers: [String: String] = [
            "foo": "bar!",
            "baz": "buzz!"
        ]
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headers)!
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.resHeaders)
                XCTAssertEqual(payload.first?.resHeaders, headers)
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_SentRequestInfo_WithJSONResBody_Returns_ResBody() {
        let url = URL(string: "https://test.com/json-res-body")!
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let response = HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        let bodyPayload = [
            "hello": "world",
            "foo": "bar"
        ]
        let data = try! JSONSerialization.data(withJSONObject: bodyPayload, options: [])
        
        let expect = expectationForCurrentFunction()
        getLoggedRequestsAfterLogging(req: req, response: response, resData: data) { result in
            switch result {
            case .success(let response):
                let payload = response.payload
                XCTAssertNotNil(payload.first?.resBody)
                guard let dataStr = payload.first?.resBody else {
                    return
                }
                print("dataStr = \(dataStr)")
                do {
                    let obj = try JSONSerialization.jsonObject(with: Data(base64Encoded: dataStr)!, options: [])
                    guard let objDict = obj as? [String: String] else {
                        return
                    }
                    XCTAssertEqual(bodyPayload, objDict)
                    expect.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expect], timeout: 1.0)
    }
    
    // TODO: Test XML res body
    
//    struct TestGet: RequestRepresentable {
//        let request: URLRequest = URLRequest(url: Constant.Network.consoleBaseUrl.appendingPathComponent("/request/test-buffer"))
//
//        struct Payload: Codable {
//            let foo: String
//        }
//    }
//    func test_foo() {
//        let expect = expectationForCurrentFunction()
//        Network.shared.send(request: TestGet()) { result in
//            switch result {
//            case .success(let response):
//                print("foo = \(response.payload.foo)")
//                expect.fulfill()
//            case .failure(let error):
//                XCTFail(error.localizedDescription)
//            }
//        }
//        wait(for: [expect], timeout: 1.0)
//    }
}
