#if DEBUG
import Foundation

class Logger {
    enum Level {
        case debug
        case info
        case error
        
        var consolePrefix: String {
            switch self {
            case .debug:
                return "[InnernetConsole DEBUG]"
            case .info:
                return "[InnernetConsole INFO]"
            case .error:
                return "[InnernetConsole ERROR]"
            }
        }
    }
    
    static let shared = Logger()
    var isEnabled = false
    
    func log(_ message: String, level: Level) {
        if isEnabled {
            print("\(level.consolePrefix): \(message)")
        }
    }
}

extension Logger {
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
}

#endif
