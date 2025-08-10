import Foundation
import XCTest
@testable import GoogleSheetsSwift

/// Helper methods for setting up test scenarios
public struct TestHelpers {
    
    // MARK: - Mock Setup Helpers
    
    /// Set up a mock HTTP client with common successful responses
    public static func setupSuccessfulMockHTTPClient() -> MockHTTPClient {
        let mockClient = MockHTTPClient()
        
        // Configure common successful responses
        // TODO: Add TestDataFixtures references once compilation issues are resolved
        
        return mockClient
    }
    
    /// Set up a mock HTTP client that simulates various error conditions
    public static func setupErrorMockHTTPClient() -> MockHTTPClient {
        let mockClient = MockHTTPClient()
        
        // Configure common error responses
        mockClient.mockAuthenticationError()
        mockClient.mockRateLimitError()
        mockClient.mockNetworkError()
        
        return mockClient
    }
    
    /// Set up an authenticated mock token manager
    public static func setupAuthenticatedMockTokenManager(accessToken: String = "test_access_token") -> MockOAuth2TokenManager {
        return MockOAuth2TokenManager.authenticated(accessToken: accessToken)
    }
    
    /// Set up an unauthenticated mock token manager
    public static func setupUnauthenticatedMockTokenManager() -> MockOAuth2TokenManager {
        return MockOAuth2TokenManager.unauthenticated()
    }
    
    // MARK: - Service Setup Helpers
    
    /// Create a SpreadsheetsService with mock dependencies
    public static func createMockSpreadsheetsService(
        httpClient: MockHTTPClient? = nil,
        tokenManager: MockOAuth2TokenManager? = nil
    ) -> (service: SpreadsheetsService, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        let mockHTTPClient = httpClient ?? setupSuccessfulMockHTTPClient()
        let mockTokenManager = tokenManager ?? setupAuthenticatedMockTokenManager()
        let service = SpreadsheetsService(httpClient: mockHTTPClient, tokenManager: mockTokenManager)
        
        return (service, mockHTTPClient, mockTokenManager)
    }
    
    /// Create a ValuesService with mock dependencies
    public static func createMockValuesService(
        httpClient: MockHTTPClient? = nil,
        tokenManager: MockOAuth2TokenManager? = nil
    ) -> (service: ValuesService, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        let mockHTTPClient = httpClient ?? setupSuccessfulMockHTTPClient()
        let mockTokenManager = tokenManager ?? setupAuthenticatedMockTokenManager()
        let service = ValuesService(httpClient: mockHTTPClient, tokenManager: mockTokenManager)
        
        return (service, mockHTTPClient, mockTokenManager)
    }
    
    /// Create a GoogleSheetsClient with mock dependencies
    public static func createMockGoogleSheetsClient(
        httpClient: MockHTTPClient? = nil,
        tokenManager: MockOAuth2TokenManager? = nil
    ) -> (client: GoogleSheetsClient, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        let mockHTTPClient = httpClient ?? setupSuccessfulMockHTTPClient()
        let mockTokenManager = tokenManager ?? setupAuthenticatedMockTokenManager()
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        
        return (client, mockHTTPClient, mockTokenManager)
    }
    
    // MARK: - Test Data Helpers
    
    /// Generate test spreadsheet ID
    public static func generateTestSpreadsheetId() -> String {
        return "test_spreadsheet_\(UUID().uuidString.prefix(8))"
    }
    
    /// Generate test range string
    public static func generateTestRange(sheet: String = "Sheet1", startRow: Int = 1, startCol: String = "A", endRow: Int = 2, endCol: String = "B") -> String {
        return "\(sheet)!\(startCol)\(startRow):\(endCol)\(endRow)"
    }
    
    /// Create test value range with random data
    public static func createTestValueRange(
        range: String? = nil,
        rows: Int = 2,
        columns: Int = 2,
        majorDimension: MajorDimension = .rows
    ) -> ValueRange {
        let testRange = range ?? generateTestRange(endRow: rows, endCol: columnLetter(for: columns))
        
        var values: [[AnyCodable]] = []
        for row in 1...rows {
            var rowValues: [AnyCodable] = []
            for col in 1...columns {
                rowValues.append(AnyCodable("TestData_R\(row)C\(col)"))
            }
            values.append(rowValues)
        }
        
        return ValueRange(
            range: testRange,
            majorDimension: majorDimension,
            values: values
        )
    }
    
    /// Convert column number to letter (1 = A, 26 = Z, 27 = AA, etc.)
    public static func columnLetter(for column: Int) -> String {
        var result = ""
        var num = column
        
        while num > 0 {
            num -= 1
            result = String(Character(UnicodeScalar(65 + (num % 26))!)) + result
            num /= 26
        }
        
        return result
    }
    
    // MARK: - Assertion Helpers
    
    /// Assert that a request was made with expected parameters
    public static func assertRequest(
        _ request: HTTPRequest?,
        method: HTTPMethod,
        containsPath: String,
        containsQuery: String? = nil,
        hasAuthHeader: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(request, "Request should not be nil", file: file, line: line)
        guard let request = request else { return }
        
        XCTAssertEqual(request.method, method, "HTTP method should match", file: file, line: line)
        XCTAssertTrue(request.url.path.contains(containsPath), "URL path should contain '\(containsPath)'", file: file, line: line)
        
        if let containsQuery = containsQuery {
            XCTAssertTrue(request.url.query?.contains(containsQuery) == true, "URL query should contain '\(containsQuery)'", file: file, line: line)
        }
        
        if hasAuthHeader {
            XCTAssertTrue(request.headers["Authorization"]?.starts(with: "Bearer ") == true, "Should have Bearer authorization header", file: file, line: line)
        }
    }
    
    /// Assert that an error is of expected type
    public static func assertError<T: Error>(
        _ error: Error,
        isType expectedType: T.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(error is T, "Error should be of type \(expectedType)", file: file, line: line)
    }
    
    /// Assert that a GoogleSheetsError is of expected case
    public static func assertGoogleSheetsError(
        _ error: Error,
        isCase expectedCase: GoogleSheetsError,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let gsError = error as? GoogleSheetsError else {
            XCTFail("Error should be GoogleSheetsError", file: file, line: line)
            return
        }
        
        switch (gsError, expectedCase) {
        case (.authenticationFailed, .authenticationFailed),
             (.tokenExpired, .tokenExpired),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.quotaExceeded, .quotaExceeded),
             (.networkError, .networkError),
             (.invalidSpreadsheetId, .invalidSpreadsheetId),
             (.invalidRange, .invalidRange),
             (.invalidResponse, .invalidResponse),
             (.decodingError, .decodingError),
             (.badRequest, .badRequest),
             (.accessDenied, .accessDenied),
             (.notFound, .notFound),
             (.apiError, .apiError):
            // Cases match
            break
        default:
            XCTFail("GoogleSheetsError case should match expected case", file: file, line: line)
        }
    }
    
    // MARK: - Async Test Helpers
    
    /// Execute an async test with timeout
    public static func executeAsyncTest<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            guard let result = try await group.next() else {
                throw TestError.noResult
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Execute an async test expecting it to throw an error
    public static func executeAsyncTestExpectingError<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> Error? {
        do {
            _ = try await executeAsyncTest(timeout: timeout, operation: operation, file: file, line: line)
            XCTFail("Expected operation to throw an error", file: file, line: line)
            return nil
        } catch {
            return error
        }
    }
    
    // MARK: - Performance Test Helpers
    
    /// Measure the performance of an async operation
    public static func measureAsyncPerformance<T>(
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        return (result, duration)
    }
    
    // MARK: - JSON Helpers
    
    /// Parse JSON string to Data
    public static func jsonData(from string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw TestError.invalidJSON
        }
        return data
    }
    
    /// Decode JSON string to object
    public static func decodeJSON<T: Codable>(_ string: String, as type: T.Type) throws -> T {
        let data = try jsonData(from: string)
        return try JSONDecoder().decode(type, from: data)
    }
    
    /// Encode object to JSON string
    public static func encodeJSON<T: Codable>(_ object: T) throws -> String {
        let data = try JSONEncoder().encode(object)
        guard let string = String(data: data, encoding: .utf8) else {
            throw TestError.encodingFailed
        }
        return string
    }
}

// MARK: - Test Errors

public enum TestError: Error, LocalizedError {
    case timeout
    case noResult
    case invalidJSON
    case encodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Test operation timed out"
        case .noResult:
            return "Test operation returned no result"
        case .invalidJSON:
            return "Invalid JSON string"
        case .encodingFailed:
            return "Failed to encode object to JSON"
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    /// Convenience method to create mock services
    public func createMockSpreadsheetsService() -> (service: SpreadsheetsService, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        return TestHelpers.createMockSpreadsheetsService()
    }
    
    public func createMockValuesService() -> (service: ValuesService, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        return TestHelpers.createMockValuesService()
    }
    
    public func createMockGoogleSheetsClient() -> (client: GoogleSheetsClient, httpClient: MockHTTPClient, tokenManager: MockOAuth2TokenManager) {
        return TestHelpers.createMockGoogleSheetsClient()
    }
    
    /// Convenience method to assert async operations
    public func assertAsyncOperation<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        return try await TestHelpers.executeAsyncTest(timeout: timeout, operation: operation, file: file, line: line)
    }
    
    /// Convenience method to assert async operations throw errors
    public func assertAsyncThrows<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> Error? {
        return await TestHelpers.executeAsyncTestExpectingError(timeout: timeout, operation: operation, file: file, line: line)
    }
}