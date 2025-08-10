import XCTest
@testable import GoogleSheetsSwift

final class SpreadsheetsServiceTests: XCTestCase {
    var service: SpreadsheetsService!
    fileprivate var mockHTTPClient: SpreadsheetsServiceMockHTTPClient!
    fileprivate var mockTokenManager: SpreadsheetsServiceMockOAuth2TokenManager!
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = SpreadsheetsServiceMockHTTPClient()
        mockTokenManager = SpreadsheetsServiceMockOAuth2TokenManager()
        service = SpreadsheetsService(httpClient: mockHTTPClient, tokenManager: mockTokenManager)
    }
    
    override func tearDown() {
        service = nil
        mockHTTPClient = nil
        mockTokenManager = nil
        super.tearDown()
    }
    
    // MARK: - Create Tests
    
    func testCreateSpreadsheet_Success() async throws {
        // Given
        let request = SpreadsheetCreateRequest(
            properties: SpreadsheetProperties(title: "Test Spreadsheet")
        )
        
        let expectedSpreadsheet = Spreadsheet(
            spreadsheetId: "test-id-123",
            properties: SpreadsheetProperties(title: "Test Spreadsheet"),
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/test-id-123"
        )
        
        mockHTTPClient.mockResponse = expectedSpreadsheet
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.create(request)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, "test-id-123")
        XCTAssertEqual(result.properties?.title, "Test Spreadsheet")
        XCTAssertEqual(result.spreadsheetUrl, "https://docs.google.com/spreadsheets/d/test-id-123")
        
        // Verify request details
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .POST)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.path.contains("/spreadsheets") == true)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer valid-token")
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Content-Type"], "application/json")
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
    }
    
    func testCreateSpreadsheet_AuthenticationFailure() async throws {
        // Given
        let request = SpreadsheetCreateRequest(
            properties: SpreadsheetProperties(title: "Test Spreadsheet")
        )
        
        mockTokenManager.shouldFail = true
        
        // When/Then
        do {
            _ = try await service.create(request)
            XCTFail("Expected authentication error")
        } catch let error as GoogleSheetsError {
            if case .authenticationFailed = error {
                // Expected
            } else {
                XCTFail("Expected authentication failed error, got \(error)")
            }
        }
    }
    
    func testCreateSpreadsheet_NetworkError() async throws {
        // Given
        let request = SpreadsheetCreateRequest(
            properties: SpreadsheetProperties(title: "Test Spreadsheet")
        )
        
        mockHTTPClient.shouldFail = true
        mockHTTPClient.mockError = URLError(.notConnectedToInternet)
        mockTokenManager.mockToken = "valid-token"
        
        // When/Then
        do {
            _ = try await service.create(request)
            XCTFail("Expected network error")
        } catch let error as GoogleSheetsError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected network error, got \(error)")
            }
        }
    }
    
    // MARK: - Get Tests
    
    func testGetSpreadsheet_Success() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let expectedSpreadsheet = Spreadsheet(
            spreadsheetId: spreadsheetId,
            properties: SpreadsheetProperties(title: "Test Spreadsheet"),
            sheets: [Sheet(properties: SheetProperties(title: "Sheet1"))]
        )
        
        mockHTTPClient.mockResponse = expectedSpreadsheet
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.get(spreadsheetId: spreadsheetId)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.properties?.title, "Test Spreadsheet")
        XCTAssertEqual(result.sheets?.count, 1)
        
        // Verify request details
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .GET)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.path.contains("/spreadsheets/\(spreadsheetId)") == true)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer valid-token")
    }
    
    func testGetSpreadsheet_WithRanges() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let ranges = ["Sheet1!A1:B2", "Sheet2!C1:D2"]
        let expectedSpreadsheet = Spreadsheet(spreadsheetId: spreadsheetId)
        
        mockHTTPClient.mockResponse = expectedSpreadsheet
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.get(spreadsheetId: spreadsheetId, ranges: ranges)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters
        let url = mockHTTPClient.lastRequest?.url
        XCTAssertTrue(url?.query?.contains("ranges=") == true)
        XCTAssertTrue(url?.query?.contains("Sheet1") == true)
        XCTAssertTrue(url?.query?.contains("Sheet2") == true)
    }
    
    func testGetSpreadsheet_WithIncludeGridData() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let expectedSpreadsheet = Spreadsheet(spreadsheetId: spreadsheetId)
        
        mockHTTPClient.mockResponse = expectedSpreadsheet
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.get(spreadsheetId: spreadsheetId, includeGridData: true)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters
        let url = mockHTTPClient.lastRequest?.url
        XCTAssertTrue(url?.query?.contains("includeGridData=true") == true)
    }
    
    func testGetSpreadsheet_WithFields() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let fields = "properties.title,sheets.properties"
        let expectedSpreadsheet = Spreadsheet(spreadsheetId: spreadsheetId)
        
        mockHTTPClient.mockResponse = expectedSpreadsheet
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.get(spreadsheetId: spreadsheetId, fields: fields)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters
        let url = mockHTTPClient.lastRequest?.url
        XCTAssertTrue(url?.query?.contains("fields=") == true)
        XCTAssertTrue(url?.query?.contains("properties.title") == true)
        XCTAssertTrue(url?.query?.contains("sheets.properties") == true)
    }
    
    func testGetSpreadsheet_EmptySpreadsheetId() async throws {
        // When/Then
        do {
            _ = try await service.get(spreadsheetId: "")
            XCTFail("Expected invalid spreadsheet ID error")
        } catch let error as GoogleSheetsError {
            if case .invalidSpreadsheetId(let message) = error {
                XCTAssertEqual(message, "Spreadsheet ID cannot be empty")
            } else {
                XCTFail("Expected invalid spreadsheet ID error, got \(error)")
            }
        }
    }
    
    // MARK: - BatchUpdate Tests
    
    func testBatchUpdate_Success() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let requests = [BatchUpdateRequest()]
        let expectedResponse = BatchUpdateSpreadsheetResponse(
            spreadsheetId: spreadsheetId,
            replies: [Response()]
        )
        
        mockHTTPClient.mockResponse = expectedResponse
        mockTokenManager.mockToken = "valid-token"
        
        // When
        let result = try await service.batchUpdate(spreadsheetId: spreadsheetId, requests: requests)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.replies?.count, 1)
        
        // Verify request details
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .POST)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.path.contains("/spreadsheets/\(spreadsheetId):batchUpdate") == true)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer valid-token")
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
    }
    
    func testBatchUpdate_EmptySpreadsheetId() async throws {
        // Given
        let requests = [BatchUpdateRequest()]
        
        // When/Then
        do {
            _ = try await service.batchUpdate(spreadsheetId: "", requests: requests)
            XCTFail("Expected invalid spreadsheet ID error")
        } catch let error as GoogleSheetsError {
            if case .invalidSpreadsheetId(let message) = error {
                XCTAssertEqual(message, "Spreadsheet ID cannot be empty")
            } else {
                XCTFail("Expected invalid spreadsheet ID error, got \(error)")
            }
        }
    }
    
    func testBatchUpdate_EmptyRequests() async throws {
        // Given
        let spreadsheetId = "test-id-123"
        let requests: [BatchUpdateRequest] = []
        
        // When/Then
        do {
            _ = try await service.batchUpdate(spreadsheetId: spreadsheetId, requests: requests)
            XCTFail("Expected API error for empty requests")
        } catch let error as GoogleSheetsError {
            if case .apiError(let code, let message, _) = error {
                XCTAssertEqual(code, 400)
                XCTAssertEqual(message, "Batch update requests cannot be empty")
            } else {
                XCTFail("Expected API error, got \(error)")
            }
        }
    }
    
    // MARK: - Error Mapping Tests
    
    func testErrorMapping_URLError() async throws {
        // Given
        let request = SpreadsheetCreateRequest()
        mockHTTPClient.shouldFail = true
        mockHTTPClient.mockError = URLError(.timedOut)
        mockTokenManager.mockToken = "valid-token"
        
        // When/Then
        do {
            _ = try await service.create(request)
            XCTFail("Expected network error")
        } catch let error as GoogleSheetsError {
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected network error, got \(error)")
            }
        }
    }
    
    func testErrorMapping_GoogleSheetsError() async throws {
        // Given
        let request = SpreadsheetCreateRequest()
        let originalError = GoogleSheetsError.rateLimitExceeded(retryAfter: 60)
        mockHTTPClient.shouldFail = true
        mockHTTPClient.mockError = originalError
        mockTokenManager.mockToken = "valid-token"
        
        // When/Then
        do {
            _ = try await service.create(request)
            XCTFail("Expected rate limit error")
        } catch let error as GoogleSheetsError {
            if case .rateLimitExceeded(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 60)
            } else {
                XCTFail("Expected rate limit error, got \(error)")
            }
        }
    }
}

// MARK: - Mock Implementations

fileprivate class SpreadsheetsServiceMockHTTPClient: HTTPClient {
    var mockResponse: Any?
    var mockError: Error?
    var shouldFail = false
    var lastRequest: HTTPRequest?
    
    func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
        lastRequest = request
        
        if shouldFail {
            if let error = mockError {
                throw error
            }
            throw GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
        }
        
        guard let response = mockResponse as? T else {
            throw GoogleSheetsError.invalidResponse("No mock response configured")
        }
        
        return response
    }
    
    func executeRaw(_ request: HTTPRequest) async throws -> Data {
        lastRequest = request
        
        if shouldFail {
            if let error = mockError {
                throw error
            }
            throw GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
        }
        
        return Data()
    }
}

fileprivate class SpreadsheetsServiceMockOAuth2TokenManager: OAuth2TokenManager {
    var mockToken = "mock-token"
    var shouldFail = false
    var isAuthenticated = true
    
    func getAccessToken() async throws -> String {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock authentication failure")
        }
        return mockToken
    }
    
    func refreshToken() async throws -> String {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock refresh failure")
        }
        return mockToken
    }
    
    func authenticate(scopes: [String]) async throws -> AuthResult {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock authentication failure")
        }
        return AuthResult(accessToken: mockToken, refreshToken: "mock-refresh-token", expiresIn: 3600)
    }
    
    func clearTokens() async throws {
        // Mock implementation - do nothing
    }
}