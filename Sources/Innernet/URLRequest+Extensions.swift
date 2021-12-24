#if DEBUG
import Foundation
import InnernetBase

extension URLRequest {
    
    mutating
    func setMethod(_ method: RequestInterceptor.HTTPMethod) {
        self.httpMethod = method.rawValue
    }
    
    mutating
    func setBody(_ data: Data) {
        self.httpBody = data
    }
}
#endif
