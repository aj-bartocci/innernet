#if DEBUG
import Foundation

struct Request { }

extension Request {
    typealias Intercepts = Network.Request<[ConsoleManager.ConsoleIntercept]>
    struct LogRequest: RequestRepresentable {
        typealias Payload = Network.EmptyPayload
        let request: URLRequest
        
        init(_ payload: ConsoleManager.LoggedRequest) {
            let url = Constant.Network.consoleBaseUrl.appendingPathComponent("request")
            let data = try! JSONEncoder().encode(payload)
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setBody(data)
            request.setMethod(.post)
            self.request = request
        }
    }
}
#endif
