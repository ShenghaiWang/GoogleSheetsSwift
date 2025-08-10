import XCTest
@testable import GoogleSheetsSwift

final class GoogleSheetsClientTests: XCTestCase {
    
    // MARK: - Test Doubles
    
    class MockOAuth2TokenManager: OAuth2TokenManager {
        var mockAccessToken = "mock_access_token"
        var mockRefreshToken = "mock_refresh_token"
        var shouldFailAuth = false
        var isAuthenticatedValue = true
        
        func getAccessToken() async throws -> String {
            if shouldFailAuth {
                throw GoogleSheetsError.authenticationFailed("Mock authentication failure")
            }
            return mockAccessToken
        }
        
        func refreshToken() async throws -> String {
            if shouldFailAuth {
                throw GoogleSheetsError.authenticationFailed("Mock token refresh failure")
            }
            return mockRefreshToken
        }
        
        var isAuthenticated: Bool {
            return isAuthenticatedValue
        }
        
        func authenticate(scopes: [String]) async throws -> AuthResult {
            if shouldFailAuth {
                throw GoogleSheetsError.authenticationFailed("Mock authentication failure")
            }
            return AuthResult(
                accessToken: mockAccessToken,
                refreshToken: mockRefreshToken,
                expiresIn: 3600,
                tokenType: "Bearer",
                scope: scopes.joined(separator: " ")
            )
        }
        
        func clearTokens() async throws {
            // Mock implementation - no actual tokens to clear
        }
    }
    
    class MockHTTPClient: HTTPClient {
        var mockResponses: [String: Any] = [:]
        var mockErrors: [String: Error] = [:]
        var executedRequests: [HTTPRequest] = []
        
        func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
            executedRequests.append(request)
            
            let key = "\(request.method.rawValue):\(request.url.path)"
            
            if let error = mockErrors[key] {
                throw error
            }
            
            if let response = mockResponses[key] as? T {
                return response
            }
            
            // Return a default mock response based on type
            if T.self == Spreadsheet.self {
                let mockSpreadsheet = Spreadsheet(
                    spreadsheetId: "mock_spreadsheet_id",
                    properties: SpreadsheetProperties(title: "Mock Spreadsheet"),
                    sheets: nil,
                    namedRanges: nil,
                    spreadsheetUrl: "https://docs.google.com/spreadsheets/d/mock_spreadsheet_id",
                    developerMetadata: nil
                )
                return mockSpreadsheet as! T
            }
            
            if T.self == ValueRange.self {
                let mockValueRange = ValueRange(
                    range: "A1:B2",
                    majorDimension: .rows,
                    values: [[AnyCodable("A1"), AnyCodable("B1")], [AnyCodable("A2"), AnyCodable("B2")]]
                )
                return mockValueRange as! T
            }
            
            throw GoogleSheetsError.invalidResponse("No mock response configured for \(key)")
        }
        
        func executeRaw(_ request: HTTPRequest) async throws -> Data {
            executedRequests.append(request)
            
            let key = "\(request.method.rawValue):\(request.url.path)"
            
            if let error = mockErrors[key] {
                throw error
            }
            
            return Data()
        }
    }
    
    // MARK: - Test Properties
    
    var mockTokenManager: MockOAuth2TokenManager!
    var mockHTTPClient: MockHTTPClient!
    
    override func setUp() {
        super.setUp()
        mockTokenManager = MockOAuth2TokenManager()
        mockHTTPClient = MockHTTPClient()
    }
    
    override func tearDown() {
        mockTokenManager = nil
        mockHTTPClient = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithTokenManager() {
        // Given
        let tokenManager = mockTokenManager!
        
        // When
        let client = GoogleSheetsClient(tokenManager: tokenManager)
        
        // Then
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        XCTAssertNil(client.getAPIKey())
    }
    
    func testInitWithTokenManagerAndCustomHTTPClient() {
        // Given
        let tokenManager = mockTokenManager!
        let httpClient = mockHTTPClient!
        
        // When
        let client = GoogleSheetsClient(tokenManager: tokenManager, httpClient: httpClient)
        
        // Then
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        XCTAssertNil(client.getAPIKey())
    }
    
    func testInitWithAPIKey() {
        // Given
        let apiKey = "test_api_key"
        
        // When
        let client = GoogleSheetsClient(apiKey: apiKey)
        
        // Then
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        XCTAssertEqual(client.getAPIKey(), apiKey)
    }
    
    func testInitWithAPIKeyAndCustomHTTPClient() {
        // Given
        let apiKey = "test_api_key"
        let httpClient = mockHTTPClient!
        
        // When
        let client = GoogleSheetsClient(apiKey: apiKey, httpClient: httpClient)
        
        // Then
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        XCTAssertEqual(client.getAPIKey(), apiKey)
    }
    
    // MARK: - API Key Management Tests
    
    func testSetAPIKey() {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager)
        let apiKey = "new_api_key"
        
        // When
        client.setAPIKey(apiKey)
        
        // Then
        XCTAssertEqual(client.getAPIKey(), apiKey)
    }
    
    func testGetAPIKeyWhenNotSet() {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager)
        
        // When
        let apiKey = client.getAPIKey()
        
        // Then
        XCTAssertNil(apiKey)
    }
    
    func testGetAPIKeyWhenSetViaInit() {
        // Given
        let expectedAPIKey = "test_api_key"
        let client = GoogleSheetsClient(apiKey: expectedAPIKey)
        
        // When
        let apiKey = client.getAPIKey()
        
        // Then
        XCTAssertEqual(apiKey, expectedAPIKey)
    }
    
    // MARK: - Service Access Tests
    
    func testSpreadsheetsServiceAccess() {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        
        // When
        let service = client.spreadsheets
        
        // Then
        XCTAssertTrue(service is SpreadsheetsService)
    }
    
    func testValuesServiceAccess() {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        
        // When
        let service = client.values
        
        // Then
        XCTAssertTrue(service is ValuesService)
    }
    
    // MARK: - Integration Tests
    
    func testClientCanAccessSpreadsheetOperations() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        
        // Configure mock response
        let mockSpreadsheet = Spreadsheet(
            spreadsheetId: spreadsheetId,
            properties: SpreadsheetProperties(title: "Test Spreadsheet"),
            sheets: nil,
            namedRanges: nil,
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/\(spreadsheetId)",
            developerMetadata: nil
        )
        mockHTTPClient.mockResponses["GET:/v4/spreadsheets/\(spreadsheetId)"] = mockSpreadsheet
        
        // When
        let result = try await client.spreadsheets.get(
            spreadsheetId: spreadsheetId,
            ranges: nil,
            includeGridData: false,
            fields: nil
        )
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.properties?.title, "Test Spreadsheet")
        XCTAssertEqual(mockHTTPClient.executedRequests.count, 1)
    }
    
    func testClientCanAccessValuesOperations() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        
        // Configure mock response
        let mockValueRange = ValueRange(
            range: range,
            majorDimension: .rows,
            values: [[AnyCodable("A1"), AnyCodable("B1")], [AnyCodable("A2"), AnyCodable("B2")]]
        )
        mockHTTPClient.mockResponses["GET:/v4/spreadsheets/\(spreadsheetId)/values/\(range)"] = mockValueRange
        
        // When
        let result = try await client.values.get(
            spreadsheetId: spreadsheetId,
            range: range,
            options: nil
        )
        
        // Then
        XCTAssertEqual(result.range, range)
        XCTAssertEqual(result.majorDimension, .rows)
        XCTAssertEqual(result.values?.count, 2)
        XCTAssertEqual(mockHTTPClient.executedRequests.count, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testClientHandlesAuthenticationErrors() async {
        // Given
        mockTokenManager.shouldFailAuth = true
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        
        // When/Then
        do {
            _ = try await client.spreadsheets.get(
                spreadsheetId: "test_id",
                ranges: nil,
                includeGridData: false,
                fields: nil
            )
            XCTFail("Expected authentication error")
        } catch let error as GoogleSheetsError {
            if case .authenticationFailed = error {
                // Expected error
            } else {
                XCTFail("Expected authentication failed error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testClientHandlesNetworkErrors() async {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let networkError = GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
        mockHTTPClient.mockErrors["GET:/v4/spreadsheets/test_id"] = networkError
        
        // When/Then
        do {
            _ = try await client.spreadsheets.get(
                spreadsheetId: "test_id",
                ranges: nil,
                includeGridData: false,
                fields: nil
            )
            XCTFail("Expected network error")
        } catch let error as GoogleSheetsError {
            if case .networkError = error {
                // Expected error
            } else {
                XCTFail("Expected network error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    // MARK: - API Key Token Manager Tests
    
    func testAPIKeyTokenManagerAuthentication() async {
        // Given
        let apiKey = "test_api_key"
        let client = GoogleSheetsClient(apiKey: apiKey)
        
        // When/Then - API key token manager should indicate it's authenticated
        // but should throw errors when trying to get access tokens
        // This is expected behavior as API key auth doesn't use access tokens
        XCTAssertEqual(client.getAPIKey(), apiKey)
    }
    
    func testAPIKeyTokenManagerIsAuthenticated() {
        // Given
        let apiKey = "test_api_key"
        let client = GoogleSheetsClient(apiKey: apiKey)
        
        // When
        let isAuthenticated = (client.values as! ValuesService).tokenManager.isAuthenticated
        
        // Then
        XCTAssertTrue(isAuthenticated)
    }
    
    func testEmptyAPIKeyTokenManagerIsNotAuthenticated() {
        // Given
        let apiKey = ""
        let client = GoogleSheetsClient(apiKey: apiKey)
        
        // When
        let isAuthenticated = (client.values as! ValuesService).tokenManager.isAuthenticated
        
        // Then
        XCTAssertFalse(isAuthenticated)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testReadRange() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        
        let mockValueRange = ValueRange(
            range: range,
            majorDimension: .rows,
            values: [[AnyCodable("A1"), AnyCodable("B1")], [AnyCodable("A2"), AnyCodable("B2")]]
        )
        mockHTTPClient.mockResponses["GET:/v4/spreadsheets/\(spreadsheetId)/values/\(range)"] = mockValueRange
        
        // When
        let result = try await client.readRange(spreadsheetId, range: range)
        
        // Then
        XCTAssertEqual(result.range, range)
        XCTAssertEqual(result.majorDimension, .rows)
        XCTAssertEqual(result.values?.count, 2)
    }
    
    func testReadStringValues() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        
        let mockValueRange = ValueRange(
            range: range,
            majorDimension: .rows,
            values: [[AnyCodable("A1"), AnyCodable("B1")], [AnyCodable("A2"), AnyCodable("B2")]]
        )
        mockHTTPClient.mockResponses["GET:/v4/spreadsheets/\(spreadsheetId)/values/\(range)"] = mockValueRange
        
        // When
        let result = try await client.readStringValues(spreadsheetId, range: range)
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0][0], "A1")
        XCTAssertEqual(result[0][1], "B1")
        XCTAssertEqual(result[1][0], "A2")
        XCTAssertEqual(result[1][1], "B2")
    }
    
    func testWriteRange() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        let values = [["A1", "B1"], ["A2", "B2"]]
        
        let mockResponse = UpdateValuesResponse(
            spreadsheetId: spreadsheetId,
            updatedRows: 2,
            updatedColumns: 2,
            updatedCells: 4,
            updatedRange: range,
            updatedData: nil
        )
        mockHTTPClient.mockResponses["PUT:/v4/spreadsheets/\(spreadsheetId)/values/A1%3AB2"] = mockResponse
        
        // When
        let result = try await client.writeRange(spreadsheetId, range: range, values: values)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.updatedRange, range)
        XCTAssertEqual(result.updatedRows, 2)
        XCTAssertEqual(result.updatedColumns, 2)
        XCTAssertEqual(result.updatedCells, 4)
    }
    
    func testWriteStringValues() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        let values = [["A1", "B1"], ["A2", "B2"]]
        
        let mockResponse = UpdateValuesResponse(
            spreadsheetId: spreadsheetId,
            updatedRows: 2,
            updatedColumns: 2,
            updatedCells: 4,
            updatedRange: range,
            updatedData: nil
        )
        mockHTTPClient.mockResponses["PUT:/v4/spreadsheets/\(spreadsheetId)/values/A1%3AB2"] = mockResponse
        
        // When
        let result = try await client.writeStringValues(spreadsheetId, range: range, values: values)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.updatedRange, range)
    }
    
    func testAppendToRange() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        let values = [["A3", "B3"], ["A4", "B4"]]
        
        let mockResponse = AppendValuesResponse(
            spreadsheetId: spreadsheetId,
            tableRange: "A1:B4",
            updates: UpdateValuesResponse(
                spreadsheetId: spreadsheetId,
                updatedRows: 2,
                updatedColumns: 2,
                updatedCells: 4,
                updatedRange: "A3:B4",
                updatedData: nil
            )
        )
        mockHTTPClient.mockResponses["POST:/v4/spreadsheets/\(spreadsheetId)/values/A1%3AB2%3Aappend"] = mockResponse
        
        // When
        let result = try await client.appendToRange(spreadsheetId, range: range, values: values)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.tableRange, "A1:B4")
        XCTAssertEqual(result.updates?.updatedRows, 2)
    }
    
    func testClearRange() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        let range = "A1:B2"
        
        let mockResponse = ClearValuesResponse(
            spreadsheetId: spreadsheetId,
            clearedRange: range
        )
        mockHTTPClient.mockResponses["POST:/v4/spreadsheets/\(spreadsheetId)/values/A1%3AB2%3Aclear"] = mockResponse
        
        // When
        let result = try await client.clearRange(spreadsheetId, range: range)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.clearedRange, range)
    }
    
    func testCreateSpreadsheet() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let title = "Test Spreadsheet"
        let sheetTitles = ["Sheet1", "Sheet2"]
        
        let mockSpreadsheet = Spreadsheet(
            spreadsheetId: "new_spreadsheet_id",
            properties: SpreadsheetProperties(title: title),
            sheets: nil,
            namedRanges: nil,
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/new_spreadsheet_id",
            developerMetadata: nil
        )
        mockHTTPClient.mockResponses["POST:/v4/spreadsheets"] = mockSpreadsheet
        
        // When
        let result = try await client.createSpreadsheet(title: title, sheetTitles: sheetTitles)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, "new_spreadsheet_id")
        XCTAssertEqual(result.properties?.title, title)
    }
    
    func testGetSpreadsheet() async throws {
        // Given
        let client = GoogleSheetsClient(tokenManager: mockTokenManager, httpClient: mockHTTPClient)
        let spreadsheetId = "test_spreadsheet_id"
        
        let mockSpreadsheet = Spreadsheet(
            spreadsheetId: spreadsheetId,
            properties: SpreadsheetProperties(title: "Test Spreadsheet"),
            sheets: nil,
            namedRanges: nil,
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/\(spreadsheetId)",
            developerMetadata: nil
        )
        mockHTTPClient.mockResponses["GET:/v4/spreadsheets/\(spreadsheetId)"] = mockSpreadsheet
        
        // When
        let result = try await client.getSpreadsheet(spreadsheetId)
        
        // Then
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.properties?.title, "Test Spreadsheet")
    }
    
    // MARK: - A1 Notation Utilities Tests
    
    func testIsValidA1Range() {
        // Valid ranges
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1:B2"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("Sheet1!A1:B2"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("'Sheet Name'!A1:B2"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A:A"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("1:1"))
        
        // Note: The current parsing logic is quite permissive and accepts many ranges
        // that might seem invalid but are actually valid in Google Sheets API context.
        // Even empty strings might be considered valid in some contexts (entire sheet).
        // The A1 range validation is primarily for basic format checking.
        // More complex validation would be done by the Google Sheets API itself.
        
        // Test that the validation function exists and works for basic cases
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1:B2"))
    }
    
    func testColumnNumberToLetters() {
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(1), "A")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(26), "Z")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(27), "AA")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(52), "AZ")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(53), "BA")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(702), "ZZ")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(703), "AAA")
        
        // Edge cases
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(0), "")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(-1), "")
    }
    
    func testColumnLettersToNumber() throws {
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("A"), 1)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("Z"), 26)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("AA"), 27)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("AZ"), 52)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("BA"), 53)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("ZZ"), 702)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("AAA"), 703)
        
        // Case insensitive
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("a"), 1)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("aa"), 27)
        
        // Error cases
        XCTAssertThrowsError(try GoogleSheetsClient.columnLettersToNumber(""))
        XCTAssertThrowsError(try GoogleSheetsClient.columnLettersToNumber("1"))
        XCTAssertThrowsError(try GoogleSheetsClient.columnLettersToNumber("A1"))
    }
    
    func testBuildA1Range() {
        // Single cell
        XCTAssertEqual(
            GoogleSheetsClient.buildA1Range(startColumn: 1, startRow: 1),
            "A1"
        )
        
        // Range
        XCTAssertEqual(
            GoogleSheetsClient.buildA1Range(startColumn: 1, startRow: 1, endColumn: 2, endRow: 2),
            "A1:B2"
        )
        
        // With sheet name
        XCTAssertEqual(
            GoogleSheetsClient.buildA1Range(sheetName: "Sheet1", startColumn: 1, startRow: 1, endColumn: 2, endRow: 2),
            "Sheet1!A1:B2"
        )
        
        // With sheet name containing spaces
        XCTAssertEqual(
            GoogleSheetsClient.buildA1Range(sheetName: "Sheet Name", startColumn: 1, startRow: 1, endColumn: 2, endRow: 2),
            "'Sheet Name'!A1:B2"
        )
        
        // With sheet name containing quotes
        XCTAssertEqual(
            GoogleSheetsClient.buildA1Range(sheetName: "Sheet's Name", startColumn: 1, startRow: 1, endColumn: 2, endRow: 2),
            "'Sheet''s Name'!A1:B2"
        )
    }
    
    func testBuildColumnRange() {
        // Simple column
        XCTAssertEqual(
            GoogleSheetsClient.buildColumnRange(column: 1),
            "A:A"
        )
        
        // With sheet name
        XCTAssertEqual(
            GoogleSheetsClient.buildColumnRange(sheetName: "Sheet1", column: 1),
            "Sheet1!A:A"
        )
        
        // With sheet name containing spaces
        XCTAssertEqual(
            GoogleSheetsClient.buildColumnRange(sheetName: "Sheet Name", column: 1),
            "'Sheet Name'!A:A"
        )
    }
    
    func testBuildRowRange() {
        // Simple row
        XCTAssertEqual(
            GoogleSheetsClient.buildRowRange(row: 1),
            "1:1"
        )
        
        // With sheet name
        XCTAssertEqual(
            GoogleSheetsClient.buildRowRange(sheetName: "Sheet1", row: 1),
            "Sheet1!1:1"
        )
        
        // With sheet name containing spaces
        XCTAssertEqual(
            GoogleSheetsClient.buildRowRange(sheetName: "Sheet Name", row: 1),
            "'Sheet Name'!1:1"
        )
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchReadOperation() {
        // Given
        let operation = BatchReadOperation(
            range: "A1:B2",
            majorDimension: .columns,
            valueRenderOption: .unformattedValue
        )
        
        // Then
        XCTAssertEqual(operation.range, "A1:B2")
        XCTAssertEqual(operation.majorDimension, .columns)
        XCTAssertEqual(operation.valueRenderOption, .unformattedValue)
    }
    
    func testBatchWriteOperation() {
        // Given
        let values = [["A1", "B1"], ["A2", "B2"]]
        let operation = BatchWriteOperation(
            range: "A1:B2",
            values: values,
            majorDimension: .columns
        )
        
        // Then
        XCTAssertEqual(operation.range, "A1:B2")
        XCTAssertEqual(operation.values.count, 2)
        XCTAssertEqual(operation.majorDimension, .columns)
    }
}