import XCTest
@testable import GoogleSheetsSwift

/// Integration tests for values operations
final class ValuesIntegrationTests: IntegrationTestBase {
    
    // MARK: - Read Operations Tests
    
    func testReadValues() async throws {
        // First, write some test data
        let range = "Sheet1!A1:D4"
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: testData.sampleData
        )
        
        // Write data (skip if read-only)
        if Self.config.hasOAuth2Config {
            _ = try await executeWithTimeout {
                try await self.client.values.update(
                    spreadsheetId: self.testSpreadsheetId,
                    range: range,
                    values: writeData,
                    options: nil
                )
            }
        }
        
        // Read the data back
        let readData = try await executeWithTimeout {
            try await self.client.values.get(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                options: nil
            )
        }
        
        // Verify the read operation
        XCTAssertNotNil(readData.values)
        XCTAssertEqual(readData.range?.contains("Sheet1"), true)
        
        if Self.config.hasOAuth2Config {
            // If we wrote data, verify it matches
            XCTAssertGreaterThan(readData.values?.count ?? 0, 0)
        }
    }
    
    func testReadValuesWithOptions() async throws {
        let range = "Sheet1!A1:B2"
        let options = ValueGetOptions(
            valueRenderOption: .formattedValue,
            dateTimeRenderOption: .formattedString,
            majorDimension: .rows
        )
        
        let result = try await executeWithTimeout {
            try await self.client.values.get(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                options: options
            )
        }
        
        // Verify the read operation with options
        XCTAssertNotNil(result.values)
        XCTAssertEqual(result.majorDimension, .rows)
    }
    
    func testBatchReadValues() async throws {
        let ranges = ["Sheet1!A1:B2", "Sheet1!D1:E2"]
        
        let result = try await executeWithTimeout {
            try await self.client.values.batchGet(
                spreadsheetId: self.testSpreadsheetId,
                ranges: ranges,
                options: nil
            )
        }
        
        // Verify the batch read operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(result.valueRanges)
        XCTAssertEqual(result.valueRanges?.count, ranges.count)
    }
    
    // MARK: - Write Operations Tests (OAuth2 only)
    
    func testWriteValues() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let range = "Sheet1!F1:H3"
        let testValues = [
            [AnyCodable("Test1"), AnyCodable("Test2"), AnyCodable("Test3")],
            [AnyCodable(100), AnyCodable(200), AnyCodable(300)],
            [AnyCodable(true), AnyCodable(false), AnyCodable(true)]
        ]
        
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: testValues
        )
        
        let result = try await executeWithTimeout {
            try await self.client.values.update(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                values: writeData,
                options: nil
            )
        }
        
        // Verify the write operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertEqual(result.updatedRows, 3)
        XCTAssertEqual(result.updatedColumns, 3)
        XCTAssertEqual(result.updatedCells, 9)
        
        // Read back to verify
        let readResult = try await executeWithTimeout {
            try await self.client.values.get(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                options: nil
            )
        }
        
        XCTAssertNotNil(readResult.values)
        XCTAssertEqual(readResult.values?.count, 3)
    }
    
    func testWriteValuesWithOptions() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let range = "Sheet1!J1:K2"
        let testValues = [
            [AnyCodable("=1+1"), AnyCodable("Raw Text")],
            [AnyCodable("=2+2"), AnyCodable("More Text")]
        ]
        
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: testValues
        )
        
        let options = ValueUpdateOptions(
            valueInputOption: .userEntered, // This will evaluate formulas
            includeValuesInResponse: true,
            responseValueRenderOption: .formattedValue
        )
        
        let result = try await executeWithTimeout {
            try await self.client.values.update(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                values: writeData,
                options: options
            )
        }
        
        // Verify the write operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertEqual(result.updatedRows, 2)
        XCTAssertEqual(result.updatedColumns, 2)
        
        // If includeValuesInResponse was true, we should have updated data
        if let updatedData = result.updatedData {
            XCTAssertNotNil(updatedData.values)
        }
    }
    
    func testAppendValues() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let range = "Sheet1!A:D" // Append to columns A-D
        let appendData = [
            [AnyCodable("Appended1"), AnyCodable("Appended2"), AnyCodable("Appended3"), AnyCodable("Appended4")]
        ]
        
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: appendData
        )
        
        let result = try await executeWithTimeout {
            try await self.client.values.append(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                values: writeData,
                options: nil
            )
        }
        
        // Verify the append operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(result.tableRange)
        XCTAssertNotNil(result.updates)
        XCTAssertEqual(result.updates?.updatedRows, 1)
        XCTAssertEqual(result.updates?.updatedColumns, 4)
    }
    
    func testClearValues() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let range = "Sheet1!M1:N5"
        
        // First write some data
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: [
                [AnyCodable("Clear1"), AnyCodable("Clear2")],
                [AnyCodable("Clear3"), AnyCodable("Clear4")]
            ]
        )
        
        _ = try await executeWithTimeout {
            try await self.client.values.update(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                values: writeData,
                options: nil
            )
        }
        
        // Now clear the data
        let clearResult = try await executeWithTimeout {
            try await self.client.values.clear(
                spreadsheetId: self.testSpreadsheetId,
                range: range
            )
        }
        
        // Verify the clear operation
        XCTAssertEqual(clearResult.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(clearResult.clearedRange)
        
        // Read back to verify it's cleared
        let readResult = try await executeWithTimeout {
            try await self.client.values.get(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                options: nil
            )
        }
        
        // The range should be empty or have no values
        XCTAssertTrue(readResult.values?.isEmpty ?? true)
    }
    
    func testBatchUpdateValues() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let data = [
            ValueRange(
                range: "Sheet1!P1:Q2",
                majorDimension: .rows,
                values: [
                    [AnyCodable("Batch1"), AnyCodable("Batch2")],
                    [AnyCodable("Batch3"), AnyCodable("Batch4")]
                ]
            ),
            ValueRange(
                range: "Sheet1!P4:Q5",
                majorDimension: .rows,
                values: [
                    [AnyCodable("Batch5"), AnyCodable("Batch6")],
                    [AnyCodable("Batch7"), AnyCodable("Batch8")]
                ]
            )
        ]
        
        let result = try await executeWithTimeout {
            try await self.client.values.batchUpdate(
                spreadsheetId: self.testSpreadsheetId,
                data: data,
                options: nil
            )
        }
        
        // Verify the batch update operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertEqual(result.totalUpdatedRows, 4)
        XCTAssertEqual(result.totalUpdatedColumns, 4) // 2 columns × 2 ranges
        XCTAssertEqual(result.totalUpdatedCells, 8)
        XCTAssertEqual(result.responses?.count, 2)
    }
    
    // MARK: - Error Handling Tests
    
    func testReadFromInvalidRange() async throws {
        let invalidRange = "InvalidSheet!@#$%"
        
        do {
            _ = try await executeWithTimeout {
                try await self.client.values.get(
                    spreadsheetId: self.testSpreadsheetId,
                    range: invalidRange,
                    options: nil
                )
            }
            XCTFail("Expected error for invalid range")
        } catch let error as GoogleSheetsError {
            switch error {
            case .invalidRange, .apiError, .badRequest:
                // Expected error types
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testWriteToReadOnlySpreadsheet() async throws {
        guard Self.config.hasAPIKey && !Self.config.hasOAuth2Config else {
            throw XCTSkip("This test requires API key without OAuth2 credentials")
        }
        
        let range = "Sheet1!A1:B2"
        let writeData = ValueRange(
            range: range,
            values: [[AnyCodable("Test")]]
        )
        
        do {
            _ = try await executeWithTimeout {
                try await self.client.values.update(
                    spreadsheetId: self.testSpreadsheetId,
                    range: range,
                    values: writeData,
                    options: nil
                )
            }
            XCTFail("Expected error for write operation with API key only")
        } catch let error as GoogleSheetsError {
            switch error {
            case .accessDenied, .authenticationFailed, .apiError:
                // Expected error types for insufficient permissions
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataWrite() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        // Create a large dataset (100 rows × 10 columns)
        let rows = 100
        let columns = 10
        var largeData: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowData: [AnyCodable] = []
            for col in 1...columns {
                rowData.append(AnyCodable("Large_R\(row)C\(col)"))
            }
            largeData.append(rowData)
        }
        
        let range = "Sheet1!S1:AB\(rows)"
        let writeData = ValueRange(
            range: range,
            majorDimension: .rows,
            values: largeData
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try await executeWithTimeout(timeout: 60.0) {
            try await self.client.values.update(
                spreadsheetId: self.testSpreadsheetId,
                range: range,
                values: writeData,
                options: nil
            )
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Verify the large write operation
        XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
        XCTAssertEqual(result.updatedRows, rows)
        XCTAssertEqual(result.updatedColumns, columns)
        XCTAssertEqual(result.updatedCells, rows * columns)
        
        print("Large data write (\(rows)×\(columns) cells) took \(String(format: "%.3f", duration)) seconds")
    }
    
    func testConcurrentValueOperations() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for write operations")
        }
        
        let operationCount = 5
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await withThrowingTaskGroup(of: UpdateValuesResponse.self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    let range = "Sheet1!A\(i + 20):B\(i + 20)"
                    let data = ValueRange(
                        range: range,
                        values: [[AnyCodable("Concurrent\(i)"), AnyCodable(i)]]
                    )
                    
                    return try await self.executeWithTimeout {
                        try await self.client.values.update(
                            spreadsheetId: self.testSpreadsheetId,
                            range: range,
                            values: data,
                            options: nil
                        )
                    }
                }
            }
            
            var results: [UpdateValuesResponse] = []
            for try await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, operationCount)
            
            // All results should be successful
            for result in results {
                XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
                XCTAssertEqual(result.updatedCells, 2)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("Concurrent value operations (\(operationCount)) completed in \(String(format: "%.3f", duration)) seconds")
    }
}