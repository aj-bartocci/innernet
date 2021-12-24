#if DEBUG
import Foundation

// TODO: make it so the user can set the port
// - Innernet client will have it as an option that is passed on startup
// - Innernet console will have settings page where it can be set
struct Constant {
    struct Network {
        static let consoleBaseUrlString = "http://localhost:5069"
        static let consoleBaseUrl = URL(string: consoleBaseUrlString)!
    }
}
#endif
