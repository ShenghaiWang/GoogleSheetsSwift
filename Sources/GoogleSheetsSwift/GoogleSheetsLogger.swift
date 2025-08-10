import Foundation

/// Log levels for Google Sheets SDK operations
public enum LogLevel: Int, CaseIterable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
    
    public var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

/// Protocol for pluggable logging in Google Sheets SDK
public protocol GoogleSheetsLogger {
    /// Log a message with the specified level and metadata
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The log message
    ///   - metadata: Optional metadata dictionary
    func log(level: LogLevel, message: String, metadata: [String: Any]?)
    
    /// Check if logging is enabled for the specified level
    /// - Parameter level: The log level to check
    /// - Returns: true if logging is enabled for this level
    func isEnabled(for level: LogLevel) -> Bool
}

/// Default console logger implementation
public class ConsoleGoogleSheetsLogger: GoogleSheetsLogger {
    private let minimumLevel: LogLevel
    private let includeTimestamp: Bool
    private let includeMetadata: Bool
    private let dateFormatter: DateFormatter
    
    public init(
        minimumLevel: LogLevel = .info,
        includeTimestamp: Bool = true,
        includeMetadata: Bool = true
    ) {
        self.minimumLevel = minimumLevel
        self.includeTimestamp = includeTimestamp
        self.includeMetadata = includeMetadata
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        guard isEnabled(for: level) else { return }
        
        var logMessage = ""
        
        // Add timestamp if enabled
        if includeTimestamp {
            logMessage += "[\(dateFormatter.string(from: Date()))] "
        }
        
        // Add level with emoji
        logMessage += "\(level.emoji) [\(level.description)] "
        
        // Add the main message
        logMessage += message
        
        // Add metadata if present and enabled
        if includeMetadata, let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | \(metadataString)"
        }
        
        print(logMessage)
    }
    
    public func isEnabled(for level: LogLevel) -> Bool {
        return level >= minimumLevel
    }
}

/// Silent logger that doesn't output anything
public class SilentGoogleSheetsLogger: GoogleSheetsLogger {
    public init() {}
    
    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        // Do nothing
    }
    
    public func isEnabled(for level: LogLevel) -> Bool {
        return false
    }
}

/// File-based logger implementation
public class FileGoogleSheetsLogger: GoogleSheetsLogger {
    private let fileURL: URL
    private let minimumLevel: LogLevel
    private let includeTimestamp: Bool
    private let includeMetadata: Bool
    private let dateFormatter: DateFormatter
    private let fileHandle: FileHandle?
    
    public init?(
        fileURL: URL,
        minimumLevel: LogLevel = .info,
        includeTimestamp: Bool = true,
        includeMetadata: Bool = true
    ) {
        self.fileURL = fileURL
        self.minimumLevel = minimumLevel
        self.includeTimestamp = includeTimestamp
        self.includeMetadata = includeMetadata
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        // Open file handle for writing
        self.fileHandle = try? FileHandle(forWritingTo: fileURL)
        
        if fileHandle == nil {
            return nil
        }
        
        // Seek to end of file
        fileHandle?.seekToEndOfFile()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        guard isEnabled(for: level), let fileHandle = fileHandle else { return }
        
        var logMessage = ""
        
        // Add timestamp if enabled
        if includeTimestamp {
            logMessage += "[\(dateFormatter.string(from: Date()))] "
        }
        
        // Add level
        logMessage += "[\(level.description)] "
        
        // Add the main message
        logMessage += message
        
        // Add metadata if present and enabled
        if includeMetadata, let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | \(metadataString)"
        }
        
        logMessage += "\n"
        
        if let data = logMessage.data(using: .utf8) {
            fileHandle.write(data)
        }
    }
    
    public func isEnabled(for level: LogLevel) -> Bool {
        return level >= minimumLevel
    }
}

/// Composite logger that forwards to multiple loggers
public class CompositeGoogleSheetsLogger: GoogleSheetsLogger {
    private let loggers: [GoogleSheetsLogger]
    
    public init(loggers: [GoogleSheetsLogger]) {
        self.loggers = loggers
    }
    
    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        for logger in loggers {
            logger.log(level: level, message: message, metadata: metadata)
        }
    }
    
    public func isEnabled(for level: LogLevel) -> Bool {
        return loggers.contains { $0.isEnabled(for: level) }
    }
}

/// Logging context for request/response tracking
public struct LoggingContext {
    public let requestId: String
    public let operation: String
    public let spreadsheetId: String?
    public let range: String?
    public let startTime: Date
    
    public init(
        requestId: String = UUID().uuidString,
        operation: String,
        spreadsheetId: String? = nil,
        range: String? = nil,
        startTime: Date = Date()
    ) {
        self.requestId = requestId
        self.operation = operation
        self.spreadsheetId = spreadsheetId
        self.range = range
        self.startTime = startTime
    }
    
    public func toMetadata() -> [String: Any] {
        var metadata: [String: Any] = [
            "requestId": requestId,
            "operation": operation,
            "startTime": ISO8601DateFormatter().string(from: startTime)
        ]
        
        if let spreadsheetId = spreadsheetId {
            metadata["spreadsheetId"] = spreadsheetId
        }
        
        if let range = range {
            metadata["range"] = range
        }
        
        return metadata
    }
    
    public func duration(to endTime: Date = Date()) -> TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

/// Extension for convenient logging methods
extension GoogleSheetsLogger {
    /// Log a debug message
    public func debug(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .debug, message: message, metadata: metadata)
    }
    
    /// Log an info message
    public func info(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .info, message: message, metadata: metadata)
    }
    
    /// Log a warning message
    public func warning(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .warning, message: message, metadata: metadata)
    }
    
    /// Log an error message
    public func error(_ message: String, metadata: [String: Any]? = nil) {
        log(level: .error, message: message, metadata: metadata)
    }
    
    /// Log request start
    public func logRequestStart(_ context: LoggingContext) {
        debug("Starting request", metadata: context.toMetadata())
    }
    
    /// Log request completion
    public func logRequestComplete(_ context: LoggingContext, duration: TimeInterval? = nil) {
        let actualDuration = duration ?? context.duration()
        var metadata = context.toMetadata()
        metadata["duration"] = String(format: "%.3f", actualDuration)
        
        info("Request completed", metadata: metadata)
    }
    
    /// Log request failure
    public func logRequestFailure(_ context: LoggingContext, error: Error, duration: TimeInterval? = nil) {
        let actualDuration = duration ?? context.duration()
        var metadata = context.toMetadata()
        metadata["duration"] = String(format: "%.3f", actualDuration)
        metadata["error"] = String(describing: error)
        
        self.error("Request failed", metadata: metadata)
    }
    
    /// Log HTTP request details
    public func logHTTPRequest(_ request: HTTPRequest, context: LoggingContext) {
        guard isEnabled(for: .debug) else { return }
        
        var metadata = context.toMetadata()
        metadata["method"] = request.method.rawValue
        metadata["url"] = request.url.absoluteString
        metadata["headers"] = request.headers
        
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            metadata["body"] = bodyString
        }
        
        debug("HTTP Request", metadata: metadata)
    }
    
    /// Log HTTP response details
    public func logHTTPResponse(_ response: HTTPURLResponse, data: Data, context: LoggingContext) {
        guard isEnabled(for: .debug) else { return }
        
        var metadata = context.toMetadata()
        metadata["statusCode"] = response.statusCode
        metadata["responseHeaders"] = response.allHeaderFields
        
        if let responseString = String(data: data, encoding: .utf8) {
            metadata["responseBody"] = responseString
        }
        
        debug("HTTP Response", metadata: metadata)
    }
    
    /// Log authentication events
    public func logAuthentication(_ message: String, success: Bool, metadata: [String: Any]? = nil) {
        var authMetadata = metadata ?? [:]
        authMetadata["authSuccess"] = success
        
        if success {
            info("Authentication: \(message)", metadata: authMetadata)
        } else {
            warning("Authentication: \(message)", metadata: authMetadata)
        }
    }
    
    /// Log rate limiting events
    public func logRateLimit(_ message: String, retryAfter: TimeInterval?, metadata: [String: Any]? = nil) {
        var rateLimitMetadata = metadata ?? [:]
        if let retryAfter = retryAfter {
            rateLimitMetadata["retryAfter"] = retryAfter
        }
        
        warning("Rate Limit: \(message)", metadata: rateLimitMetadata)
    }
    
    /// Log retry attempts
    public func logRetry(attempt: Int, maxAttempts: Int, delay: TimeInterval, error: Error, metadata: [String: Any]? = nil) {
        var retryMetadata = metadata ?? [:]
        retryMetadata["attempt"] = attempt
        retryMetadata["maxAttempts"] = maxAttempts
        retryMetadata["delay"] = delay
        retryMetadata["error"] = String(describing: error)
        
        warning("Retry attempt \(attempt)/\(maxAttempts)", metadata: retryMetadata)
    }
}

/// Adapter to bridge GoogleSheetsLogger with HTTPLogger protocol
public class LoggingHTTPClientAdapter: HTTPLogger {
    private let logger: GoogleSheetsLogger
    
    public init(logger: GoogleSheetsLogger) {
        self.logger = logger
    }
    
    public func logRequest(_ request: HTTPRequest) {
        guard logger.isEnabled(for: .debug) else { return }
        
        var metadata: [String: Any] = [
            "method": request.method.rawValue,
            "url": request.url.absoluteString,
            "headers": request.headers
        ]
        
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            metadata["body"] = bodyString
        }
        
        logger.debug("HTTP Request", metadata: metadata)
    }
    
    public func logResponse(_ response: HTTPURLResponse, data: Data) {
        guard logger.isEnabled(for: .debug) else { return }
        
        var metadata: [String: Any] = [
            "statusCode": response.statusCode,
            "url": response.url?.absoluteString ?? "unknown",
            "headers": response.allHeaderFields
        ]
        
        if let responseString = String(data: data, encoding: .utf8) {
            metadata["responseBody"] = responseString
        }
        
        logger.debug("HTTP Response", metadata: metadata)
    }
    
    public func logError(_ error: Error, for request: HTTPRequest) {
        let metadata: [String: Any] = [
            "method": request.method.rawValue,
            "url": request.url.absoluteString,
            "error": String(describing: error)
        ]
        
        logger.error("HTTP Error", metadata: metadata)
    }
}