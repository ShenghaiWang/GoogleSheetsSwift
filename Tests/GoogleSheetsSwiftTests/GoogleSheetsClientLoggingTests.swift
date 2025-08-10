import XCTest
@testable import GoogleSheetsSwift
import Foundation

final class GoogleSheetsClientLoggingTests: XCTestCase {
    
    func testClientInitializationWithLogger() {
        let mockLogger = MockGoogleSheetsLogger()
        let mockTokenManager = MockOAuth2TokenManager()
        
        let client = GoogleSheetsClient(
            tokenManager: mockTokenManager,
            logger: mockLogger
        )
        
        XCTAssertNotNil(client.getLogger())
        XCTAssertEqual(mockLogger.loggedMessages.count, 1)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("GoogleSheetsClient initialized with OAuth2 authentication"))
    }
    
    func testClientInitializationWithAPIKeyAndLogger() {
        let mockLogger = MockGoogleSheetsLogger()
        
        let client = GoogleSheetsClient(
            apiKey: "test-api-key",
            logger: mockLogger
        )
        
        XCTAssertNotNil(client.getLogger())
        XCTAssertEqual(mockLogger.loggedMessages.count, 1)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("GoogleSheetsClient initialized with API key authentication"))
    }
    
    func testClientWithoutLogger() {
        let mockTokenManager = MockOAuth2TokenManager()
        
        let client = GoogleSheetsClient(tokenManager: mockTokenManager)
        
        XCTAssertNil(client.getLogger())
    }
    
    func testSetLogger() {
        let mockTokenManager = MockOAuth2TokenManager()
        let client = GoogleSheetsClient(tokenManager: mockTokenManager)
        
        XCTAssertNil(client.getLogger())
        
        let mockLogger = MockGoogleSheetsLogger()
        client.setLogger(mockLogger)
        
        XCTAssertNotNil(client.getLogger())
        XCTAssertEqual(mockLogger.loggedMessages.count, 1)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("Logger configured for GoogleSheetsClient"))
    }
    
    func testDebugMode() {
        let mockTokenManager = MockOAuth2TokenManager()
        let client = GoogleSheetsClient(tokenManager: mockTokenManager)
        
        XCTAssertFalse(client.isDebugModeEnabled())
        
        client.setDebugMode(true)
        XCTAssertTrue(client.isDebugModeEnabled())
        XCTAssertNotNil(client.getLogger())
        
        client.setDebugMode(false)
        // Logger should still exist but debug mode info should be logged
        XCTAssertNotNil(client.getLogger())
    }
    
    func testReadRangeWithLogging() async throws {
        let mockLogger = MockGoogleSheetsLogger()
        let mockHTTPClient = MockHTTPClient()
        let mockTokenManager = MockOAuth2TokenManager()
        
        // Set up mock response
        let valueRange = ValueRange(
            range: "A1:B2",
            majorDimension: .rows,
            values: [["A1", "B1"], ["A2", "B2"]]
        )
        mockHTTPClient.mockResponse(for: "values/A1", response: valueRange)
        
        let client = GoogleSheetsClient(
            tokenManager: mockTokenManager,
            httpClient: mockHTTPClient,
            logger: mockLogger
        )
        
        // Clear initialization log
        mockLogger.reset()
        
        let result = try await client.readRange("test-spreadsheet-id", range: "A1:B2")
        
        XCTAssertEqual(result.range, "A1:B2")
        
        // Verify logging occurred
        XCTAssertGreaterThanOrEqual(mockLogger.loggedMessages.count, 2)
        
        // Should have request start and complete logs
        let startLogs = mockLogger.loggedMessages.filter { $0.message.contains("Starting request") }
        let completeLogs = mockLogger.loggedMessages.filter { $0.message.contains("Request completed") }
        
        XCTAssertEqual(startLogs.count, 1)
        XCTAssertEqual(completeLogs.count, 1)
        
        // Verify metadata contains expected information
        if let startLog = startLogs.first,
           let metadata = startLog.metadata {
            XCTAssertEqual(metadata["operation"] as? String, "readRange")
            XCTAssertEqual(metadata["spreadsheetId"] as? String, "test-spreadsheet-id")
            XCTAssertEqual(metadata["range"] as? String, "A1:B2")
        }
    }
    
    func testReadRangeWithError() async throws {
        let mockLogger = MockGoogleSheetsLogger()
        let mockHTTPClient = MockHTTPClient()
        let mockTokenManager = MockOAuth2TokenManager()
        
        // Set up mock error
        mockHTTPClient.mockError(for: "values/A1", error: GoogleSheetsError.invalidRange("Invalid range"))
        
        let client = GoogleSheetsClient(
            tokenManager: mockTokenManager,
            httpClient: mockHTTPClient,
            logger: mockLogger
        )
        
        // Clear initialization log
        mockLogger.reset()
        
        do {
            _ = try await client.readRange("test-spreadsheet-id", range: "A1:B2")
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
        }
        
        // Verify error logging occurred
        let startLogs = mockLogger.loggedMessages.filter { $0.message.contains("Starting request") }
        let failureLogs = mockLogger.loggedMessages.filter { $0.message.contains("Request failed") }
        
        XCTAssertEqual(startLogs.count, 1)
        XCTAssertEqual(failureLogs.count, 1)
        
        // Verify error metadata
        if let failureLog = failureLogs.first,
           let metadata = failureLog.metadata {
            XCTAssertEqual(metadata["operation"] as? String, "readRange")
            XCTAssertNotNil(metadata["error"])
        }
    }
    
    func testLoggingHTTPClientAdapter() {
        let mockLogger = MockGoogleSheetsLogger()
        let adapter = LoggingHTTPClientAdapter(logger: mockLogger)
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://sheets.googleapis.com/v4/spreadsheets/test/values/A1:B2")!,
            headers: ["Authorization": "Bearer token"]
        )
        
        let response = HTTPURLResponse(
            url: request.url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        adapter.logRequest(request)
        adapter.logResponse(response, data: "{}".data(using: .utf8)!)
        
        XCTAssertEqual(mockLogger.loggedMessages.count, 2)
        XCTAssertEqual(mockLogger.loggedMessages[0].level, .debug)
        XCTAssertEqual(mockLogger.loggedMessages[1].level, .debug)
        XCTAssertTrue(mockLogger.loggedMessages[0].message.contains("HTTP Request"))
        XCTAssertTrue(mockLogger.loggedMessages[1].message.contains("HTTP Response"))
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