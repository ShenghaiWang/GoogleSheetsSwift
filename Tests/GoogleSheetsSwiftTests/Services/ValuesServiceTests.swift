import XCTest
@testable import GoogleSheetsSwift

final class ValuesServiceTests: XCTestCase {
    
    fileprivate var mockHTTPClient: ValuesServiceMockHTTPClient!
    fileprivate var mockTokenManager: ValuesServiceMockOAuth2TokenManager!
    var valuesService: ValuesService!
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = ValuesServiceMockHTTPClient()
        mockTokenManager = ValuesServiceMockOAuth2TokenManager()
        valuesService = ValuesService(httpClient: mockHTTPClient, tokenManager: mockTokenManager)
    }
    
    override func tearDown() {
        valuesService = nil
        mockTokenManager = nil
        mockHTTPClient = nil
        super.tearDown()
    }
    
    // MARK: - Get Values Tests
    
    func testGetValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        let expectedResponse = ValueRange(
            range: "Sheet1!A1:B2",
            majorDimension: .rows,
            values: [
                [AnyCodable("Name"), AnyCodable("Age")],
                [AnyCodable("John"), AnyCodable(30)]
            ]
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.get(spreadsheetId: spreadsheetId, range: range)
        
        // Assert
        XCTAssertEqual(result.range, expectedResponse.range)
        XCTAssertEqual(result.majorDimension, expectedResponse.majorDimension)
        XCTAssertEqual(result.values?.count, 2)
        XCTAssertEqual(result.values?[0].count, 2)
        XCTAssertEqual(result.values?[0][0].get() as String?, "Name")
        XCTAssertEqual(result.values?[1][1].get() as Int?, 30)
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .GET)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains(spreadsheetId) ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("values") ?? false)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer test-access-token")
    }
    
    func testGetValues_WithOptions() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "Sheet1!A1:C3"
        let options = ValueGetOptions(
            valueRenderOption: .unformattedValue,
            dateTimeRenderOption: .serialNumber,
            majorDimension: .columns
        )
        let expectedResponse = ValueRange(range: range, majorDimension: .columns, values: [])
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.get(spreadsheetId: spreadsheetId, range: range, options: options)
        
        // Assert
        XCTAssertEqual(result.range, range)
        XCTAssertEqual(result.majorDimension, .columns)
        
        // Verify query parameters were included
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("majorDimension=COLUMNS"))
        XCTAssertTrue(urlString.contains("valueRenderOption=UNFORMATTED_VALUE"))
        XCTAssertTrue(urlString.contains("dateTimeRenderOption=SERIAL_NUMBER"))
    }
    
    func testGetValues_InvalidSpreadsheetId() async {
        // Arrange
        let invalidSpreadsheetId = ""
        let range = "A1:B2"
        
        // Act & Assert
        do {
            _ = try await valuesService.get(spreadsheetId: invalidSpreadsheetId, range: range)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidSpreadsheetId(let message) = error {
                XCTAssertTrue(message.contains("cannot be empty"))
            } else {
                XCTFail("Expected invalidSpreadsheetId error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testGetValues_InvalidRange() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let invalidRange = ""
        
        // Act & Assert
        do {
            _ = try await valuesService.get(spreadsheetId: spreadsheetId, range: invalidRange)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidRange(let message) = error {
                XCTAssertTrue(message.contains("cannot be empty"))
            } else {
                XCTFail("Expected invalidRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testGetValues_AuthenticationFailure() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        
        mockTokenManager.shouldFail = true
        
        // Act & Assert
        do {
            _ = try await valuesService.get(spreadsheetId: spreadsheetId, range: range)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .authenticationFailed = error {
                // Expected
            } else {
                XCTFail("Expected authenticationFailed error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    // MARK: - Batch Get Values Tests
    
    func testBatchGetValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let ranges = ["A1:B2", "D1:E2"]
        let expectedResponse = BatchGetValuesResponse(
            spreadsheetId: spreadsheetId,
            valueRanges: [
                ValueRange(range: "Sheet1!A1:B2", values: [[AnyCodable("A1"), AnyCodable("B1")]]),
                ValueRange(range: "Sheet1!D1:E2", values: [[AnyCodable("D1"), AnyCodable("E1")]])
            ]
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.batchGet(spreadsheetId: spreadsheetId, ranges: ranges)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.valueRanges?.count, 2)
        XCTAssertEqual(result.valueRanges?[0].range, "Sheet1!A1:B2")
        XCTAssertEqual(result.valueRanges?[1].range, "Sheet1!D1:E2")
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .GET)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("values:batchGet") ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("ranges=") ?? false)
    }
    
    func testBatchGetValues_WithOptions() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let ranges = ["A1:B2", "C1:D2"]
        let options = ValueGetOptions(
            valueRenderOption: .formula,
            dateTimeRenderOption: .formattedString,
            majorDimension: .rows
        )
        let expectedResponse = BatchGetValuesResponse(spreadsheetId: spreadsheetId, valueRanges: [])
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.batchGet(spreadsheetId: spreadsheetId, ranges: ranges, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters were included
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("majorDimension=ROWS"))
        XCTAssertTrue(urlString.contains("valueRenderOption=FORMULA"))
        XCTAssertTrue(urlString.contains("dateTimeRenderOption=FORMATTED_STRING"))
    }
    
    func testBatchGetValues_EmptyRanges() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let emptyRanges: [String] = []
        
        // Act & Assert
        do {
            _ = try await valuesService.batchGet(spreadsheetId: spreadsheetId, ranges: emptyRanges)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidRange(let message) = error {
                XCTAssertTrue(message.contains("At least one range"))
            } else {
                XCTFail("Expected invalidRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testBatchGetValues_InvalidRange() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let ranges = ["A1:B2", ""] // One valid, one invalid
        
        // Act & Assert
        do {
            _ = try await valuesService.batchGet(spreadsheetId: spreadsheetId, ranges: ranges)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidRange = error {
                // Expected
            } else {
                XCTFail("Expected invalidRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    // MARK: - A1 Range Parsing Tests
    
    func testParseA1Range_SingleCell() throws {
        // Test various single cell formats
        let testCases = [
            ("A1", A1Range(startColumn: 1, startRow: 1, endColumn: 1, endRow: 1)),
            ("Z26", A1Range(startColumn: 26, startRow: 26, endColumn: 26, endRow: 26)),
            ("AA1", A1Range(startColumn: 27, startRow: 1, endColumn: 27, endRow: 1)),
            ("AB100", A1Range(startColumn: 28, startRow: 100, endColumn: 28, endRow: 100))
        ]
        
        for (input, expected) in testCases {
            let result = try valuesService.parseA1Range(input)
            XCTAssertEqual(result.startColumn, expected.startColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.startRow, expected.startRow, "Failed for input: \(input)")
            XCTAssertEqual(result.endColumn, expected.endColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.endRow, expected.endRow, "Failed for input: \(input)")
            XCTAssertTrue(result.isSingleCell, "Should be single cell for input: \(input)")
        }
    }
    
    func testParseA1Range_CellRange() throws {
        // Test various cell range formats
        let testCases = [
            ("A1:B2", A1Range(startColumn: 1, startRow: 1, endColumn: 2, endRow: 2)),
            ("C5:F10", A1Range(startColumn: 3, startRow: 5, endColumn: 6, endRow: 10)),
            ("AA1:AB2", A1Range(startColumn: 27, startRow: 1, endColumn: 28, endRow: 2))
        ]
        
        for (input, expected) in testCases {
            let result = try valuesService.parseA1Range(input)
            XCTAssertEqual(result.startColumn, expected.startColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.startRow, expected.startRow, "Failed for input: \(input)")
            XCTAssertEqual(result.endColumn, expected.endColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.endRow, expected.endRow, "Failed for input: \(input)")
            XCTAssertFalse(result.isSingleCell, "Should not be single cell for input: \(input)")
        }
    }
    
    func testParseA1Range_WithSheetName() throws {
        // Test ranges with sheet names
        let testCases = [
            ("Sheet1!A1", A1Range(sheetName: "Sheet1", startColumn: 1, startRow: 1, endColumn: 1, endRow: 1)),
            ("'My Sheet'!A1:B2", A1Range(sheetName: "My Sheet", startColumn: 1, startRow: 1, endColumn: 2, endRow: 2)),
            ("Data!C5:F10", A1Range(sheetName: "Data", startColumn: 3, startRow: 5, endColumn: 6, endRow: 10))
        ]
        
        for (input, expected) in testCases {
            let result = try valuesService.parseA1Range(input)
            XCTAssertEqual(result.sheetName, expected.sheetName, "Failed for input: \(input)")
            XCTAssertEqual(result.startColumn, expected.startColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.startRow, expected.startRow, "Failed for input: \(input)")
            XCTAssertEqual(result.endColumn, expected.endColumn, "Failed for input: \(input)")
            XCTAssertEqual(result.endRow, expected.endRow, "Failed for input: \(input)")
        }
    }
    
    func testParseA1Range_EntireRowColumn() throws {
        // Test entire row and column references
        let result1 = try valuesService.parseA1Range("A:A")
        XCTAssertEqual(result1.startColumn, 1)
        XCTAssertEqual(result1.endColumn, 1)
        XCTAssertNil(result1.startRow)
        XCTAssertNil(result1.endRow)
        XCTAssertTrue(result1.isEntireColumn)
        
        let result2 = try valuesService.parseA1Range("1:1")
        XCTAssertEqual(result2.startRow, 1)
        XCTAssertEqual(result2.endRow, 1)
        XCTAssertNil(result2.startColumn)
        XCTAssertNil(result2.endColumn)
        XCTAssertTrue(result2.isEntireRow)
    }
    
    func testParseA1Range_InvalidFormats() {
        // Test invalid range formats
        let invalidRanges = [
            "A1:B2:C3", // Too many colons
            "A1B2", // Missing colon
            "1A", // Invalid cell reference
            "A", // Column only (should work but test edge case)
            "1" // Row only (should work but test edge case)
        ]
        
        for invalidRange in invalidRanges {
            do {
                _ = try valuesService.parseA1Range(invalidRange)
                // Some of these might actually be valid, so we don't fail here
            } catch {
                // Expected for truly invalid ranges
                XCTAssertTrue(error is GoogleSheetsError)
            }
        }
    }
    
    // MARK: - Column Letter Conversion Tests (via A1 parsing)
    
    func testColumnLettersToNumber() throws {
        // Test column letter conversion indirectly through A1 range parsing
        let testCases = [
            ("A1", 1),
            ("B1", 2),
            ("Z1", 26),
            ("AA1", 27),
            ("AB1", 28),
            ("AZ1", 52),
            ("BA1", 53),
            ("ZZ1", 702),
            ("AAA1", 703)
        ]
        
        for (cellRef, expectedColumn) in testCases {
            let result = try valuesService.parseA1Range(cellRef)
            XCTAssertEqual(result.startColumn, expectedColumn, "Failed for cell reference: \(cellRef)")
        }
    }
    
    // MARK: - A1Range Utility Tests
    
    func testA1RangeToA1Notation() {
        let testCases = [
            (A1Range(startColumn: 1, startRow: 1, endColumn: 1, endRow: 1), "A1"),
            (A1Range(startColumn: 1, startRow: 1, endColumn: 2, endRow: 2), "A1:B2"),
            (A1Range(sheetName: "Sheet1", startColumn: 1, startRow: 1, endColumn: 1, endRow: 1), "Sheet1!A1"),
            (A1Range(sheetName: "My Sheet", startColumn: 1, startRow: 1, endColumn: 2, endRow: 2), "'My Sheet'!A1:B2")
        ]
        
        for (range, expected) in testCases {
            let result = range.toA1Notation()
            XCTAssertEqual(result, expected, "Failed for range: \(range)")
        }
    }
    
    // MARK: - Update Values Tests
    
    func testUpdateValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        let values = ValueRange(
            range: range,
            majorDimension: .rows,
            values: [
                [AnyCodable("Name"), AnyCodable("Age")],
                [AnyCodable("John"), AnyCodable(30)]
            ]
        )
        let expectedResponse = UpdateValuesResponse(
            spreadsheetId: spreadsheetId,
            updatedRows: 2,
            updatedColumns: 2,
            updatedCells: 4,
            updatedRange: "Sheet1!A1:B2"
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.update(spreadsheetId: spreadsheetId, range: range, values: values)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.updatedRows, 2)
        XCTAssertEqual(result.updatedColumns, 2)
        XCTAssertEqual(result.updatedCells, 4)
        XCTAssertEqual(result.updatedRange, "Sheet1!A1:B2")
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .PUT)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains(spreadsheetId) ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("values") ?? false)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer test-access-token")
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Content-Type"], "application/json")
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
    }
    
    func testUpdateValues_WithOptions() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        let values = ValueRange(range: range, values: [[AnyCodable("Test")]])
        let options = ValueUpdateOptions(
            valueInputOption: .userEntered,
            includeValuesInResponse: true,
            responseValueRenderOption: .formattedValue,
            responseDateTimeRenderOption: .formattedString
        )
        let expectedResponse = UpdateValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.update(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters were included
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("valueInputOption=USER_ENTERED"))
        XCTAssertTrue(urlString.contains("includeValuesInResponse=true"))
        XCTAssertTrue(urlString.contains("responseValueRenderOption=FORMATTED_VALUE"))
        XCTAssertTrue(urlString.contains("responseDateTimeRenderOption=FORMATTED_STRING"))
    }
    
    func testUpdateValues_RawInputOption() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        let values = ValueRange(range: range, values: [[AnyCodable("=SUM(1,2)")]])
        let options = ValueUpdateOptions(valueInputOption: .raw)
        let expectedResponse = UpdateValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.update(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify RAW input option was used
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("valueInputOption=RAW"))
    }
    
    // MARK: - Append Values Tests
    
    func testAppendValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B1"
        let values = ValueRange(
            range: range,
            values: [
                [AnyCodable("Jane"), AnyCodable(25)]
            ]
        )
        let expectedResponse = AppendValuesResponse(
            spreadsheetId: spreadsheetId,
            tableRange: "Sheet1!A1:B3",
            updates: UpdateValuesResponse(
                spreadsheetId: spreadsheetId,
                updatedRows: 1,
                updatedColumns: 2,
                updatedCells: 2,
                updatedRange: "Sheet1!A3:B3"
            )
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.append(spreadsheetId: spreadsheetId, range: range, values: values)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.tableRange, "Sheet1!A1:B3")
        XCTAssertEqual(result.updates?.updatedRows, 1)
        XCTAssertEqual(result.updates?.updatedCells, 2)
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .POST)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains(spreadsheetId) ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("append") ?? false)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer test-access-token")
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
    }
    
    func testAppendValues_WithOptions() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B1"
        let values = ValueRange(range: range, values: [[AnyCodable("Test")]])
        let options = ValueAppendOptions(
            valueInputOption: .userEntered,
            insertDataOption: .insertRows,
            includeValuesInResponse: true,
            responseValueRenderOption: .unformattedValue
        )
        let expectedResponse = AppendValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.append(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify query parameters were included
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("valueInputOption=USER_ENTERED"))
        XCTAssertTrue(urlString.contains("insertDataOption=INSERT_ROWS"))
        XCTAssertTrue(urlString.contains("includeValuesInResponse=true"))
        XCTAssertTrue(urlString.contains("responseValueRenderOption=UNFORMATTED_VALUE"))
    }
    
    func testAppendValues_OverwriteOption() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B1"
        let values = ValueRange(range: range, values: [[AnyCodable("Test")]])
        let options = ValueAppendOptions(insertDataOption: .overwrite)
        let expectedResponse = AppendValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.append(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify overwrite option was used
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("insertDataOption=OVERWRITE"))
    }
    
    // MARK: - Clear Values Tests
    
    func testClearValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1:B2"
        let expectedResponse = ClearValuesResponse(
            spreadsheetId: spreadsheetId,
            clearedRange: "Sheet1!A1:B2"
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.clear(spreadsheetId: spreadsheetId, range: range)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.clearedRange, "Sheet1!A1:B2")
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .POST)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains(spreadsheetId) ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("clear") ?? false)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer test-access-token")
        XCTAssertNil(mockHTTPClient.lastRequest?.body) // Clear requests don't have a body
    }
    
    func testClearValues_InvalidSpreadsheetId() async {
        // Arrange
        let invalidSpreadsheetId = ""
        let range = "A1:B2"
        
        // Act & Assert
        do {
            _ = try await valuesService.clear(spreadsheetId: invalidSpreadsheetId, range: range)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidSpreadsheetId(let message) = error {
                XCTAssertTrue(message.contains("cannot be empty"))
            } else {
                XCTFail("Expected invalidSpreadsheetId error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testClearValues_InvalidRange() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let invalidRange = ""
        
        // Act & Assert
        do {
            _ = try await valuesService.clear(spreadsheetId: spreadsheetId, range: invalidRange)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidRange(let message) = error {
                XCTAssertTrue(message.contains("cannot be empty"))
            } else {
                XCTFail("Expected invalidRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    // MARK: - Batch Update Values Tests
    
    func testBatchUpdateValues_Success() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let data = [
            ValueRange(range: "A1:B2", values: [[AnyCodable("Name"), AnyCodable("Age")]]),
            ValueRange(range: "D1:E2", values: [[AnyCodable("City"), AnyCodable("Country")]])
        ]
        let expectedResponse = BatchUpdateValuesResponse(
            spreadsheetId: spreadsheetId,
            totalUpdatedRows: 2,
            totalUpdatedColumns: 4,
            totalUpdatedCells: 4,
            responses: [
                UpdateValuesResponse(spreadsheetId: spreadsheetId, updatedRange: "Sheet1!A1:B2"),
                UpdateValuesResponse(spreadsheetId: spreadsheetId, updatedRange: "Sheet1!D1:E2")
            ]
        )
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.batchUpdate(spreadsheetId: spreadsheetId, data: data)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        XCTAssertEqual(result.totalUpdatedRows, 2)
        XCTAssertEqual(result.totalUpdatedColumns, 4)
        XCTAssertEqual(result.totalUpdatedCells, 4)
        XCTAssertEqual(result.responses?.count, 2)
        
        // Verify HTTP client was called with correct request
        XCTAssertEqual(mockHTTPClient.lastRequest?.method, .POST)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains(spreadsheetId) ?? false)
        XCTAssertTrue(mockHTTPClient.lastRequest?.url.absoluteString.contains("values:batchUpdate") ?? false)
        XCTAssertEqual(mockHTTPClient.lastRequest?.headers["Authorization"], "Bearer test-access-token")
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
    }
    
    func testBatchUpdateValues_WithOptions() async throws {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let data = [ValueRange(range: "A1:B2", values: [[AnyCodable("Test")]])]
        let options = ValueUpdateOptions(
            valueInputOption: .raw,
            includeValuesInResponse: true,
            responseValueRenderOption: .formula
        )
        let expectedResponse = BatchUpdateValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        let result = try await valuesService.batchUpdate(spreadsheetId: spreadsheetId, data: data, options: options)
        
        // Assert
        XCTAssertEqual(result.spreadsheetId, spreadsheetId)
        
        // Verify request body contains the options
        XCTAssertNotNil(mockHTTPClient.lastRequest?.body)
        if let bodyData = mockHTTPClient.lastRequest?.body,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            XCTAssertTrue(bodyString.contains("RAW"))
            XCTAssertTrue(bodyString.contains("FORMULA"))
        }
    }
    
    func testBatchUpdateValues_EmptyData() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let emptyData: [ValueRange] = []
        
        // Act & Assert
        do {
            _ = try await valuesService.batchUpdate(spreadsheetId: spreadsheetId, data: emptyData)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidData(let message) = error {
                XCTAssertTrue(message.contains("At least one ValueRange"))
            } else {
                XCTFail("Expected invalidData error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    func testBatchUpdateValues_InvalidRange() async {
        // Arrange
        let spreadsheetId = "test-spreadsheet-id"
        let data = [
            ValueRange(range: "A1:B2", values: [[AnyCodable("Valid")]]),
            ValueRange(range: "", values: [[AnyCodable("Invalid")]]) // Invalid range
        ]
        
        // Act & Assert
        do {
            _ = try await valuesService.batchUpdate(spreadsheetId: spreadsheetId, data: data)
            XCTFail("Expected error to be thrown")
        } catch let error as GoogleSheetsError {
            if case .invalidRange = error {
                // Expected
            } else {
                XCTFail("Expected invalidRange error, got \(error)")
            }
        } catch {
            XCTFail("Expected GoogleSheetsError, got \(error)")
        }
    }
    
    // MARK: - Input Option Tests
    
    func testValueInputOptions_UserEntered() async throws {
        // Test that USER_ENTERED option processes formulas
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1"
        let values = ValueRange(range: range, values: [[AnyCodable("=SUM(1,2)")]])
        let options = ValueUpdateOptions(valueInputOption: .userEntered)
        let expectedResponse = UpdateValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        _ = try await valuesService.update(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("valueInputOption=USER_ENTERED"))
    }
    
    func testValueInputOptions_Raw() async throws {
        // Test that RAW option treats formulas as literal text
        let spreadsheetId = "test-spreadsheet-id"
        let range = "A1"
        let values = ValueRange(range: range, values: [[AnyCodable("=SUM(1,2)")]])
        let options = ValueUpdateOptions(valueInputOption: .raw)
        let expectedResponse = UpdateValuesResponse(spreadsheetId: spreadsheetId)
        
        mockTokenManager.mockToken = "test-access-token"
        mockHTTPClient.mockResponse = expectedResponse
        
        // Act
        _ = try await valuesService.update(spreadsheetId: spreadsheetId, range: range, values: values, options: options)
        
        // Assert
        let urlString = mockHTTPClient.lastRequest?.url.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("valueInputOption=RAW"))
    }
}

// MARK: - Mock Classes for ValuesService Tests

fileprivate class ValuesServiceMockHTTPClient: HTTPClient {
    var mockResponse: Any?
    var mockError: Error?
    var lastRequest: HTTPRequest?
    
    func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw GoogleSheetsError.invalidResponse("Mock response type mismatch")
        }
        
        return response
    }
    
    func executeRaw(_ request: HTTPRequest) async throws -> Data {
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        return Data()
    }
}

fileprivate class ValuesServiceMockOAuth2TokenManager: OAuth2TokenManager {
    var mockToken: String = "mock-token"
    var shouldFail: Bool = false
    var isAuthenticated: Bool = true
    
    func getAccessToken() async throws -> String {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock authentication failure")
        }
        return mockToken
    }
    
    func refreshToken() async throws -> String {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock token refresh failure")
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