#if DEBUG
import Foundation

protocol RequestRepresentable {
    associatedtype Payload
    var request: URLRequest { get }
}

class Network {
    
    struct Request<Payload>: RequestRepresentable {
        let request: URLRequest
    }
    
    struct Response<Payload: Decodable> {
        let payload: Payload
        let response: HTTPURLResponse
    }
    
    struct EmptyPayload: Codable { }
    
    static let shared = Network()
    init() { }
    
    func send<Request: RequestRepresentable>(
        request: Request,
        decoder: JSONDecoder = JSONDecoder(),
        completion: @escaping (Result<Response<Request.Payload>, Error>) -> Void
    ) {
        send(request: request.request) { result in
            switch result {
            case .success(let response):
                do {
                    let payload = try decoder.decode(Request.Payload.self, from: response.payload)
                    completion(.success(Response(payload: payload, response: response.response)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func send(
        request: URLRequest,
        completion: @escaping (Result<Response<Data>, Error>) -> Void
    ) {
        let req = ((request as NSURLRequest).mutableCopy() as! NSMutableURLRequest)
        URLProtocol.setProperty(true, forKey: HandledKey, in: req)
        send(request: request) { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(.failure(error!))
                return
            }
            completion(.success(Response(payload: data, response: response)))
        }
    }
    
    func send(
        request: URLRequest,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        let req = ((request as NSURLRequest).mutableCopy() as! NSMutableURLRequest)
        URLProtocol.setProperty(true, forKey: HandledKey, in: req)
        URLSession.shared.dataTask(with: req as URLRequest, completionHandler: completion).resume()
    }
}
#endif
