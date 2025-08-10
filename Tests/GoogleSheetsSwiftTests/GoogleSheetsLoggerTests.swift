import XCTest
@testable import GoogleSheetsSwift
import Foundation

final class GoogleSheetsLoggerTests: XCTestCase {
    
    // MARK: - LogLevel Tests
    
    func testLogLevelComparison() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        
        XCTAssertFalse(LogLevel.error < LogLevel.debug)
        XCTAssertFalse(LogLevel.warning < LogLevel.info)
    }
    
    func testLogLevelDescription() {
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
    }
    
    func testLogLevelEmoji() {
        XCTAssertEqual(LogLevel.debug.emoji, "🔍")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(LogLevel.error.emoji, "❌")
    }
    
    // MARK: - ConsoleGoogleSheetsLogger Tests
    
    func testConsoleLoggerMinimumLevel() {
        let logger = ConsoleGoogleSheetsLogger(minimumLevel: .warning)
        
        XCTAssertFalse(logger.isEnabled(for: .debug))
        XCTAssertFalse(logger.isEnabled(for: .info))
        XCTAssertTrue(logger.isEnabled(for: .warning))
        XCTAssertTrue(logger.isEnabled(for: .error))
    }
    
    func testConsoleLoggerDefaultLevel() {
        let logger = ConsoleGoogleSheetsLogger()
        
        XCTAssertFalse(logger.isEnabled(for: .debug))
        XCTAssertTrue(logger.isEnabled(for: .info))
        XCTAssertTrue(logger.isEnabled(for: .warning))
        XCTAssertTrue(logger.isEnabled(for: .error))
    }
    
    func testConsoleLoggerLogging() {
        let logger = ConsoleGoogleSheetsLogger(minimumLevel: .debug)
        
        // These should not crash and should be enabled
        XCTAssertTrue(logger.isEnabled(for: .debug))
        logger.log(level: .debug, message: "Debug message", metadata: nil)
        logger.log(level: .info, message: "Info message", metadata: ["key": "value"])
        logger.log(level: .warning, message: "Warning message", metadata: nil)
        logger.log(level: .error, message: "Error message", metadata: ["error": "test"])
    }
    
    // MARK: - SilentGoogleSheetsLogger Tests
    
    func testSilentLogger() {
        let logger = SilentGoogleSheetsLogger()
        
        XCTAssertFalse(logger.isEnabled(for: .debug))
        XCTAssertFalse(logger.isEnabled(for: .info))
        XCTAssertFalse(logger.isEnabled(for: .warning))
        XCTAssertFalse(logger.isEnabled(for: .error))
        
        // These should not crash
        logger.log(level: .debug, message: "Debug message", metadata: nil)
        logger.log(level: .error, message: "Error message", metadata: ["key": "value"])
    }
    
    // MARK: - FileGoogleSheetsLogger Tests
    
    func testFileLogger() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let logFileURL = tempDir.appendingPathComponent("test_log_\(UUID().uuidString).log")
        
        // Ensure file doesn't exist initially
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            try FileManager.default.removeItem(at: logFileURL)
        }
        
        guard let logger = FileGoogleSheetsLogger(fileURL: logFileURL, minimumLevel: .debug) else {
            XCTFail("Failed to create file logger")
            return
        }
        
        XCTAssertTrue(logger.isEnabled(for: .debug))
        XCTAssertTrue(logger.isEnabled(for: .info))
        XCTAssertTrue(logger.isEnabled(for: .warning))
        XCTAssertTrue(logger.isEnabled(for: .error))
        
        // Log some messages
        logger.log(level: .info, message: "Test message", metadata: nil)
        logger.log(level: .warning, message: "Warning message", metadata: ["key": "value"])
        
        // Verify file was created and contains content
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFileURL.path))
        
        let logContent = try String(contentsOf: logFileURL)
        XCTAssertTrue(logContent.contains("Test message"))
        XCTAssertTrue(logContent.contains("Warning message"))
        XCTAssertTrue(logContent.contains("key: value"))
        
        // Clean up
        try FileManager.default.removeItem(at: logFileURL)
    }
    
    func testFileLoggerWithInvalidPath() {
        let invalidURL = URL(fileURLWithPath: "/invalid/path/that/does/not/exist/test.log")
        let logger = FileGoogleSheetsLogger(fileURL: invalidURL)
        
        XCTAssertNil(logger, "Logger should be nil for invalid file path")
    }
    
    // MARK: - CompositeGoogleSheetsLogger Tests
    
    func testCompositeLogger() {
        let consoleLogger = ConsoleGoogleSheetsLogger(minimumLevel: .info)
        let silentLogger = SilentGoogleSheetsLogger()
        
        let compositeLogger = CompositeGoogleSheetsLogger(loggers: [consoleLogger, silentLogger])
        
        // Should be enabled if any child logger is enabled
        XCTAssertFalse(compositeLogger.isEnabled(for: .debug)) // Neither enabled
        XCTAssertTrue(compositeLogger.isEnabled(for: .info))   // Console enabled
        XCTAssertTrue(compositeLogger.isEnabled(for: .warning)) // Console enabled
        XCTAssertTrue(compositeLogger.isEnabled(for: .error))   // Console enabled
        
        // Should not crash
        compositeLogger.log(level: .info, message: "Test message", metadata: ["key": "value"])
    }
    
    func testCompositeLoggerWithNoLoggers() {
        let compositeLogger = CompositeGoogleSheetsLogger(loggers: [])
        
        XCTAssertFalse(compositeLogger.isEnabled(for: .debug))
        XCTAssertFalse(compositeLogger.isEnabled(for: .info))
        XCTAssertFalse(compositeLogger.isEnabled(for: .warning))
        XCTAssertFalse(compositeLogger.isEnabled(for: .error))
        
        // Should not crash
        compositeLogger.log(level: .info, message: "Test message", metadata: nil)
    }
    
    // MARK: - LoggingContext Tests
    
    func testLoggingContext() {
        let startTime = Date()
        let context = LoggingContext(
            requestId: "test-123",
            operation: "readRange",
            spreadsheetId: "sheet-456",
            range: "A1:B10",
            startTime: startTime
        )
        
        XCTAssertEqual(context.requestId, "test-123")
        XCTAssertEqual(context.operation, "readRange")
        XCTAssertEqual(context.spreadsheetId, "sheet-456")
        XCTAssertEqual(context.range, "A1:B10")
        XCTAssertEqual(context.startTime, startTime)
        
        let metadata = context.toMetadata()
        XCTAssertEqual(metadata["requestId"] as? String, "test-123")
        XCTAssertEqual(metadata["operation"] as? String, "readRange")
        XCTAssertEqual(metadata["spreadsheetId"] as? String, "sheet-456")
        XCTAssertEqual(metadata["range"] as? String, "A1:B10")
        XCTAssertNotNil(metadata["startTime"])
    }
    
    func testLoggingContextWithDefaults() {
        let context = LoggingContext(operation: "testOperation")
        
        XCTAssertFalse(context.requestId.isEmpty)
        XCTAssertEqual(context.operation, "testOperation")
        XCTAssertNil(context.spreadsheetId)
        XCTAssertNil(context.range)
        
        let duration = context.duration()
        XCTAssertGreaterThanOrEqual(duration, 0)
    }
    
    func testLoggingContextDuration() {
        let startTime = Date()
        let context = LoggingContext(operation: "test", startTime: startTime)
        
        // Wait a small amount
        Thread.sleep(forTimeInterval: 0.01)
        
        let endTime = Date()
        let duration = context.duration(to: endTime)
        
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 1.0) // Should be less than 1 second
    }
    
    // MARK: - Logger Extension Tests
    
    func testLoggerExtensionMethods() {
        let mockLogger = MockGoogleSheetsLogger()
        
        mockLogger.debug("Debug message")
        mockLogger.info("Info message")
        mockLogger.warning("Warning message")
        mockLogger.error("Error message")
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 4)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .debug)
        XCTAssertEqual(mockLogger.loggedMessages[1].level, .info)
        XCTAssertEqual(mockLogger.loggedMessages[2].level, .warning)
        XCTAssertEqual(mockLogger.loggedMessages[3].level, .error)
    }
    
    func testLoggerRequestLogging() {
        let mockLogger = MockGoogleSheetsLogger()
        let context = LoggingContext(operation: "test")
        
        mockLogger.logRequestStart(context)
        mockLogger.logRequestComplete(context)
        mockLogger.logRequestFailure(context, error: GoogleSheetsError.invalidRange("test"))
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 3)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("Starting request"))
        XCTAssertTrue(mockLogger.loggedMessages[1].message.contains("Request completed"))
        XCTAssertTrue(mockLogger.loggedMessages[2].message.contains("Request failed"))
    }
    
    func testLoggerHTTPLogging() {
        let mockLogger = MockGoogleSheetsLogger()
        let context = LoggingContext(operation: "test")
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!,
            headers: ["Authorization": "Bearer token"],
            body: nil
        )
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        mockLogger.logHTTPRequest(request, context: context)
        mockLogger.logHTTPResponse(response, data: Data(), context: context)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 2)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("HTTP Request"))
        XCTAssertTrue(mockLogger.loggedMessages[1].message.contains("HTTP Response"))
    }
    
    func testLoggerAuthenticationLogging() {
        let mockLogger = MockGoogleSheetsLogger()
        
        mockLogger.logAuthentication("Login successful", success: true)
        mockLogger.logAuthentication("Login failed", success: false)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 2)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .info)
        XCTAssertEqual(mockLogger.loggedMessages[1].level, .warning)
    }
    
    func testLoggerRateLimitLogging() {
        let mockLogger = MockGoogleSheetsLogger()
        
        mockLogger.logRateLimit("Rate limit hit", retryAfter: 60.0)
        mockLogger.logRateLimit("Rate limit hit", retryAfter: nil)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 2)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .warning)
        XCTAssertEqual(mockLogger.loggedMessages[1].level, .warning)
    }
    
    func testLoggerRetryLogging() {
        let mockLogger = MockGoogleSheetsLogger()
        let error = GoogleSheetsError.networkError(URLError(.timedOut))
        
        mockLogger.logRetry(attempt: 2, maxAttempts: 3, delay: 1.5, error: error)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 1)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .warning)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("Retry attempt 2/3"))
    }
    
    // MARK: - LoggingHTTPClientAdapter Tests
    
    func testLoggingHTTPClientAdapter() {
        let mockLogger = MockGoogleSheetsLogger()
        let adapter = LoggingHTTPClientAdapter(logger: mockLogger)
        
        let request = HTTPRequest(
            method: .POST,
            url: URL(string: "https://example.com")!,
            headers: ["Content-Type": "application/json"],
            body: "test body".data(using: .utf8)
        )
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let error = GoogleSheetsError.networkError(URLError(.timedOut))
        
        adapter.logRequest(request)
        adapter.logResponse(response, data: "response body".data(using: .utf8)!)
        adapter.logError(error, for: request)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 3)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .debug)
        XCTAssertEqual(mockLogger.loggedMessages[1].level, .debug)
        XCTAssertEqual(mockLogger.loggedMessages[2].level, .error)
    }
    
    func testLoggingHTTPClientAdapterWithDisabledDebug() {
        let mockLogger = MockGoogleSheetsLogger(enabledLevels: [.info, .warning, .error])
        let adapter = LoggingHTTPClientAdapter(logger: mockLogger)
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        adapter.logRequest(request)
        adapter.logResponse(response, data: Data())
        
        // Should not log debug messages when debug is disabled
        XCTAssertEqual(mockLogger.loggedMessages.count, 0)
        
        // But should log errors
        let error = GoogleSheetsError.networkError(URLError(.timedOut))
        adapter.logError(error, for: request)
        XCTAssertEqual(mockLogger.loggedMessages.count, 1)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .error)
    }
}

// MARK: - Mock Logger for Testing

private class MockGoogleSheetsLogger: GoogleSheetsLogger {
    struct LoggedMessage {
        let level: LogLevel
        let message: String
        let metadata: [String: Any]?
    }
    
    private let enabledLevels: Set<LogLevel>
    private(set) var loggedMessages: [LoggedMessage] = []
    
    init(enabledLevels: Set<LogLevel> = Set(LogLevel.allCases)) {
        self.enabledLevels = enabledLevels
    }
    
    func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        loggedMessages.append(LoggedMessage(level: level, message: message, metadata: metadata))
    }
    
    func isEnabled(for level: LogLevel) -> Bool {
        return enabledLevels.contains(level)
    }
    
    func reset() {
        loggedMessages.removeAll()
    }
}