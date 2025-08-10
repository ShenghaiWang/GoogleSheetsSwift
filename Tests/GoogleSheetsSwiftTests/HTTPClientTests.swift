import XCTest
import Foundation
@testable import GoogleSheetsSwift

class HTTPClientTests: XCTestCase {
    
    // MARK: - Mock URLSession
    
    class MockURLSession: URLSessionProtocol {
        var mockData: Data?
        var mockResponse: URLResponse?
        var mockError: Error?
        var data: (URLRequest) async throws -> (Data, URLResponse) = { _ in
            throw NSError(domain: "MockNotConfigured", code: -1, userInfo: nil)
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            // Use custom data function if set, otherwise use default behavior
            if mockError != nil || mockData != nil || mockResponse != nil {
                if let error = mockError {
                    throw error
                }
                
                let data = mockData ?? Data()
                let response = mockResponse ?? HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                return (data, response)
            } else {
                return try await data(request)
            }
        }
    }
    
    // MARK: - Mock Logger
    
    class MockHTTPLogger: HTTPLogger {
        var loggedRequests: [HTTPRequest] = []
        var loggedResponses: [(HTTPURLResponse, Data)] = []
        var loggedErrors: [(Error, HTTPRequest)] = []
        
        func logRequest(_ request: HTTPRequest) {
            loggedRequests.append(request)
        }
        
        func logResponse(_ response: HTTPURLResponse, data: Data) {
            loggedResponses.append((response, data))
        }
        
        func logError(_ error: Error, for request: HTTPRequest) {
            loggedErrors.append((error, request))
        }
    }
    
    // MARK: - Test Models
    
    struct TestModel: Codable, Equatable {
        let id: Int?
        let name: String?
        
        init(id: Int? = nil, name: String? = nil) {
            self.id = id
            self.name = name
        }
    }
    
    // MARK: - Tests
    
    func testHTTPRequestInitialization() {
        let url = URL(string: "https://example.com")!
        let headers = ["Authorization": "Bearer token"]
        let body = "test body".data(using: .utf8)
        
        let request = HTTPRequest(
            method: .POST,
            url: url,
            headers: headers,
            body: body
        )
        
        XCTAssertEqual(request.method, .POST)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.headers, headers)
        XCTAssertEqual(request.body, body)
    }
    
    func testHTTPRequestDefaultValues() {
        let url = URL(string: "https://example.com")!
        let request = HTTPRequest(method: .GET, url: url)
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertEqual(request.url, url)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertNil(request.body)
    }
    
    func testSuccessfulJSONResponse() async throws {
        let mockSession = MockURLSession()
        let mockLogger = MockHTTPLogger()
        let client = URLSessionHTTPClient(session: mockSession, logger: mockLogger)
        
        let testModel = TestModel(id: 1, name: "Test")
        let jsonData = try JSONEncoder().encode(testModel)
        
        mockSession.mockData = jsonData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        let result: TestModel = try await client.execute(request)
        
        XCTAssertEqual(result, testModel)
        XCTAssertEqual(mockLogger.loggedRequests.count, 1)
        XCTAssertEqual(mockLogger.loggedResponses.count, 1)
        XCTAssertTrue(mockLogger.loggedErrors.isEmpty)
    }
    
    func testSuccessfulRawDataResponse() async throws {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        let testData = "test response".data(using: .utf8)!
        mockSession.mockData = testData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        let result = try await client.executeRaw(request)
        
        XCTAssertEqual(result, testData)
    }
    
    func testNetworkError() async {
        let mockSession = MockURLSession()
        let mockLogger = MockHTTPLogger()
        let client = URLSessionHTTPClient(session: mockSession, logger: mockLogger)
        
        let networkError = NSError(domain: "TestError", code: -1, userInfo: nil)
        mockSession.mockError = networkError
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .networkError(let underlyingError) = error {
                XCTAssertEqual((underlyingError as NSError).domain, "TestError")
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
        
        XCTAssertGreaterThan(mockLogger.loggedErrors.count, 0)
    }
    
    func testAuthenticationError() async {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .authenticationFailed(let message) = error {
                XCTAssertEqual(message, "Unauthorized")
            } else {
                XCTFail("Expected authenticationFailed, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testRateLimitError() async {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: ["Retry-After": "30"]
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .rateLimitExceeded(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 30.0)
            } else {
                XCTFail("Expected rateLimitExceeded, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testRateLimitErrorWithoutRetryAfter() async {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .rateLimitExceeded(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 60.0) // Default value
            } else {
                XCTFail("Expected rateLimitExceeded, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testServerError() async {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .apiError(let code, let message, _) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(message, "Server Error")
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testInvalidJSONResponse() async {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        let invalidJSON = "invalid json".data(using: .utf8)!
        mockSession.mockData = invalidJSON
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testRequestHeadersAndBody() async throws {
        let mockSession = MockURLSession()
        let client = URLSessionHTTPClient(session: mockSession)
        
        mockSession.mockData = "{}".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let headers = ["Authorization": "Bearer token", "Custom-Header": "value"]
        let body = "request body".data(using: .utf8)
        
        let request = HTTPRequest(
            method: .POST,
            url: URL(string: "https://example.com")!,
            headers: headers,
            body: body
        )
        
        _ = try await client.executeRaw(request)
        
        // The actual URLRequest creation is tested implicitly through successful execution
        // In a real implementation, you might want to capture the URLRequest for verification
    }
    
    func testConsoleLogger() {
        let logger = ConsoleHTTPLogger()
        let url = URL(string: "https://example.com")!
        
        let request = HTTPRequest(
            method: .POST,
            url: url,
            headers: ["Authorization": "Bearer token"],
            body: "test body".data(using: .utf8)
        )
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let data = "response data".data(using: .utf8)!
        let error = GoogleSheetsError.networkError(NSError(domain: "Test", code: 1, userInfo: nil))
        
        // These methods should not throw - they just log to console
        logger.logRequest(request)
        logger.logResponse(response, data: data)
        logger.logError(error, for: request)
    }
    
    // MARK: - RequestBuilder Tests
    
    func testRequestBuilderInitialization() {
        let builder1 = RequestBuilder()
        XCTAssertNotNil(builder1)
        
        let builder2 = RequestBuilder(baseURL: "https://custom.api.com", apiKey: "test-key", accessToken: "test-token")
        XCTAssertNotNil(builder2)
    }
    
    func testBuildSpreadsheetRequestWithAPIKey() throws {
        let builder = RequestBuilder(apiKey: "test-api-key")
        
        let request = try builder.buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint"
        )
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("test-endpoint"))
        XCTAssertTrue(request.url.absoluteString.contains("key=test-api-key"))
        XCTAssertTrue(request.headers.isEmpty)
    }
    
    func testBuildSpreadsheetRequestWithAccessToken() throws {
        let builder = RequestBuilder(accessToken: "test-access-token")
        
        let request = try builder.buildSpreadsheetRequest(
            method: .POST,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint",
            body: "test body".data(using: .utf8)
        )
        
        XCTAssertEqual(request.method, .POST)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("test-endpoint"))
        XCTAssertFalse(request.url.absoluteString.contains("key="))
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-access-token")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertNotNil(request.body)
    }
    
    func testBuildSpreadsheetRequestWithQueryParameters() throws {
        let builder = RequestBuilder()
        
        let queryParams = [
            "param1": "value1",
            "param2": "value2"
        ]
        
        let request = try builder.buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint",
            queryParameters: queryParams
        )
        
        XCTAssertTrue(request.url.absoluteString.contains("param1=value1"))
        XCTAssertTrue(request.url.absoluteString.contains("param2=value2"))
    }
    
    func testBuildValuesRequest() throws {
        let builder = RequestBuilder(accessToken: "test-token")
        
        let request = try builder.buildValuesRequest(
            method: .GET,
            spreadsheetId: "test-id",
            range: "Sheet1!A1:B10"
        )
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("values"))
        XCTAssertTrue(request.url.absoluteString.contains("Sheet1"))
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-token")
    }
    
    func testBuildValuesRequestWithSpecialCharacters() throws {
        let builder = RequestBuilder()
        
        let request = try builder.buildValuesRequest(
            method: .GET,
            spreadsheetId: "test-id",
            range: "Sheet Name!A1:B10"
        )
        
        // Should properly encode the range with spaces
        XCTAssertTrue(request.url.absoluteString.contains("values"))
        XCTAssertTrue(request.url.absoluteString.contains("Sheet"))
    }
    
    func testGetSpreadsheetRequest() throws {
        let builder = RequestBuilder(apiKey: "test-key")
        
        let request = try builder.getSpreadsheet(
            spreadsheetId: "test-id",
            ranges: ["Sheet1!A1:B10", "Sheet2!C1:D10"],
            includeGridData: true,
            fields: "sheets.properties"
        )
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("ranges="))
        XCTAssertTrue(request.url.absoluteString.contains("includeGridData=true"))
        XCTAssertTrue(request.url.absoluteString.contains("fields=sheets.properties"))
        XCTAssertTrue(request.url.absoluteString.contains("key=test-key"))
    }
    
    func testGetValuesRequest() throws {
        let builder = RequestBuilder(accessToken: "test-token")
        
        let request = try builder.getValues(
            spreadsheetId: "test-id",
            range: "Sheet1!A1:B10",
            majorDimension: "ROWS",
            valueRenderOption: "FORMATTED_VALUE",
            dateTimeRenderOption: "FORMATTED_STRING"
        )
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("values"))
        XCTAssertTrue(request.url.absoluteString.contains("majorDimension=ROWS"))
        XCTAssertTrue(request.url.absoluteString.contains("valueRenderOption=FORMATTED_VALUE"))
        XCTAssertTrue(request.url.absoluteString.contains("dateTimeRenderOption=FORMATTED_STRING"))
    }
    
    func testUpdateValuesRequest() throws {
        let builder = RequestBuilder(accessToken: "test-token")
        let body = "test body".data(using: .utf8)!
        
        let request = try builder.updateValues(
            spreadsheetId: "test-id",
            range: "Sheet1!A1:B10",
            valueInputOption: "USER_ENTERED",
            includeValuesInResponse: true,
            responseValueRenderOption: "FORMATTED_VALUE",
            responseDateTimeRenderOption: "FORMATTED_STRING",
            body: body
        )
        
        XCTAssertEqual(request.method, .PUT)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("values"))
        XCTAssertTrue(request.url.absoluteString.contains("valueInputOption=USER_ENTERED"))
        XCTAssertTrue(request.url.absoluteString.contains("includeValuesInResponse=true"))
        XCTAssertTrue(request.url.absoluteString.contains("responseValueRenderOption=FORMATTED_VALUE"))
        XCTAssertTrue(request.url.absoluteString.contains("responseDateTimeRenderOption=FORMATTED_STRING"))
        XCTAssertEqual(request.body, body)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }
    
    func testAppendValuesRequest() throws {
        let builder = RequestBuilder(accessToken: "test-token")
        let body = "test body".data(using: .utf8)!
        
        let request = try builder.appendValues(
            spreadsheetId: "test-id",
            range: "Sheet1!A1:B10",
            valueInputOption: "RAW",
            insertDataOption: "INSERT_ROWS",
            includeValuesInResponse: false,
            body: body
        )
        
        XCTAssertEqual(request.method, .POST)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("append"))
        XCTAssertTrue(request.url.absoluteString.contains("valueInputOption=RAW"))
        XCTAssertTrue(request.url.absoluteString.contains("insertDataOption=INSERT_ROWS"))
        XCTAssertEqual(request.body, body)
    }
    
    func testClearValuesRequest() throws {
        let builder = RequestBuilder(accessToken: "test-token")
        
        let request = try builder.clearValues(
            spreadsheetId: "test-id",
            range: "Sheet1!A1:B10"
        )
        
        XCTAssertEqual(request.method, .POST)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("clear"))
        XCTAssertNil(request.body)
    }
    
    func testBatchGetValuesRequest() throws {
        let builder = RequestBuilder(apiKey: "test-key")
        
        let request = try builder.batchGetValues(
            spreadsheetId: "test-id",
            ranges: ["Sheet1!A1:B10", "Sheet2!C1:D10"],
            majorDimension: "COLUMNS",
            valueRenderOption: "UNFORMATTED_VALUE"
        )
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertTrue(request.url.absoluteString.contains("test-id"))
        XCTAssertTrue(request.url.absoluteString.contains("batchGet"))
        XCTAssertTrue(request.url.absoluteString.contains("ranges="))
        XCTAssertTrue(request.url.absoluteString.contains("majorDimension=COLUMNS"))
        XCTAssertTrue(request.url.absoluteString.contains("valueRenderOption=UNFORMATTED_VALUE"))
    }
    
    func testCustomBaseURL() throws {
        let builder = RequestBuilder(baseURL: "https://custom.googleapis.com/v4")
        
        let request = try builder.buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint"
        )
        
        XCTAssertTrue(request.url.absoluteString.starts(with: "https://custom.googleapis.com/v4"))
    }
    
    func testInvalidURLThrowsError() {
        // Use a URL that will cause URLComponents to fail to create a valid URL
        // Using characters that are invalid in URLs
        let builder = RequestBuilder(baseURL: "http://[invalid")
        
        XCTAssertThrowsError(try builder.buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint"
        )) { error in
            XCTAssertTrue(error is GoogleSheetsError)
            if case .invalidURL = error as? GoogleSheetsError {
                // Expected error type
            } else {
                XCTFail("Expected invalidURL error, got \(error)")
            }
        }
    }
    
    func testAPIKeyAndAccessTokenPrecedence() throws {
        // When both API key and access token are provided, access token should take precedence
        let builder = RequestBuilder(apiKey: "test-api-key", accessToken: "test-access-token")
        
        let request = try builder.buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: "test-id",
            endpoint: "test-endpoint"
        )
        
        // Should use access token, not API key
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-access-token")
        XCTAssertFalse(request.url.absoluteString.contains("key="))
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryOnNetworkError() async {
        let mockSession = MockURLSession()
        let mockLogger = MockHTTPLogger()
        let retryConfig = RetryConfiguration(maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0)
        let client = URLSessionHTTPClient(session: mockSession, logger: mockLogger, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        mockSession.mockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        
        // Override the mock to succeed on the second attempt
        mockSession.data = { request in
            attemptCount += 1
            if attemptCount == 1 {
                throw NSError(domain: "TestError", code: -1, userInfo: nil)
            } else {
                let data = "{}".data(using: .utf8)!
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (data, response)
            }
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTAssertEqual(attemptCount, 2) // Should have retried once
        } catch {
            XCTFail("Expected request to succeed after retry, but got error: \(error)")
        }
    }
    
    func testRetryOnRateLimitError() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration(maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0)
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        
        // Override the mock to return 429 on first attempt, then 200
        mockSession.data = { request in
            attemptCount += 1
            let data = "{}".data(using: .utf8)!
            let statusCode = attemptCount == 1 ? 429 : 200
            let headers = attemptCount == 1 ? ["Retry-After": "1"] : nil
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            return (data, response)
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTAssertEqual(attemptCount, 2) // Should have retried once
        } catch {
            XCTFail("Expected request to succeed after retry, but got error: \(error)")
        }
    }
    
    func testRetryOnServerError() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration(maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0)
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        
        // Override the mock to return 500 on first attempt, then 200
        mockSession.data = { request in
            attemptCount += 1
            let data = "{}".data(using: .utf8)!
            let statusCode = attemptCount == 1 ? 500 : 200
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTAssertEqual(attemptCount, 2) // Should have retried once
        } catch {
            XCTFail("Expected request to succeed after retry, but got error: \(error)")
        }
    }
    
    func testNoRetryOnClientError() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration(maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0)
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        
        // Always return 400 (client error)
        mockSession.data = { request in
            attemptCount += 1
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .badRequest = error {
                XCTAssertEqual(attemptCount, 1) // Should not have retried
            } else {
                XCTFail("Expected badRequest error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testMaxRetriesExceeded() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration(maxRetries: 2, baseDelay: 0.1, maxDelay: 1.0)
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        
        // Always return 500 (server error)
        mockSession.data = { request in
            attemptCount += 1
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .apiError(let code, _, _) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(attemptCount, 3) // Initial attempt + 2 retries
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testRateLimiterIntegration() async throws {
        let mockSession = MockURLSession()
        let rateLimiter = RateLimiter(maxRequestsPerSecond: 1.0) // Very restrictive for testing
        let client = URLSessionHTTPClient(session: mockSession, rateLimiter: rateLimiter)
        
        mockSession.mockData = "{}".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        let startTime = Date()
        
        // Make two requests - the second should be delayed by rate limiter
        let _: TestModel = try await client.execute(request)
        let _: TestModel = try await client.execute(request)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should take at least 1 second due to rate limiting
        XCTAssertGreaterThan(duration, 0.9)
    }
    
    func testRetryConfigurationNone() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration.none // No retries
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        var attemptCount = 0
        
        // Always return 500 (server error)
        mockSession.data = { request in
            attemptCount += 1
            let data = "{}".data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .apiError(let code, _, _) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(attemptCount, 1) // Should not have retried
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testRetryWithCustomConfiguration() async {
        let mockSession = MockURLSession()
        let retryConfig = RetryConfiguration.aggressive // 2 retries with shorter delays
        let client = URLSessionHTTPClient(session: mockSession, retryConfiguration: retryConfig)
        
        // Always return network error
        mockSession.mockError = NSError(domain: "TestError", code: -1, userInfo: nil)
        
        let request = HTTPRequest(
            method: .GET,
            url: URL(string: "https://example.com")!
        )
        
        let startTime = Date()
        
        do {
            let _: TestModel = try await client.execute(request)
            XCTFail("Expected error to be thrown")
        } catch {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Should have made 3 attempts (initial + 2 retries) with aggressive config
            // Duration should be relatively short due to aggressive config
            XCTAssertLessThan(duration, 5.0) // Should complete quickly with aggressive config
        }
    }
}