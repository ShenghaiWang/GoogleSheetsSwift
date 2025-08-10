import XCTest
@testable import GoogleSheetsSwift

/// Integration tests for spreadsheet operations
final class SpreadsheetsIntegrationTests: IntegrationTestBase {
    
    // MARK: - Spreadsheet Creation Tests
    
    func testCreateSpreadsheet() async throws {
        // Skip if we don't have OAuth2 credentials (needed for creation)
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for spreadsheet creation tests")
        }
        
        let request = SpreadsheetCreateRequest(
            properties: SpreadsheetProperties(
                title: "Integration Test Spreadsheet - \(Date().timeIntervalSince1970)",
                locale: "en_US",
                timeZone: "America/New_York"
            )
        )
        
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.create(request)
        }
        
        // Verify the created spreadsheet
        XCTAssertNotNil(spreadsheet.spreadsheetId)
        XCTAssertNotNil(spreadsheet.spreadsheetUrl)
        XCTAssertEqual(spreadsheet.properties?.locale, "en_US")
        XCTAssertEqual(spreadsheet.properties?.timeZone, "America/New_York")
        
        // Clean up - mark for deletion
        print("Created test spreadsheet: \(spreadsheet.spreadsheetId!) - should be manually deleted")
    }
    
    func testCreateSpreadsheetWithSheets() async throws {
        guard Self.config.hasOAuth2Config else {
            throw XCTSkip("OAuth2 credentials required for spreadsheet creation tests")
        }
        
        let request = SpreadsheetCreateRequest(
            properties: SpreadsheetProperties(
                title: "Multi-Sheet Test - \(Date().timeIntervalSince1970)"
            ),
            sheets: [
                Sheet(
                    properties: SheetProperties(
                        title: "Data",
                        sheetType: .grid
                    )
                ),
                Sheet(
                    properties: SheetProperties(
                        title: "Summary",
                        sheetType: .grid
                    )
                )
            ]
        )
        
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.create(request)
        }
        
        // Verify the spreadsheet has the expected sheets
        XCTAssertNotNil(spreadsheet.sheets)
        XCTAssertGreaterThanOrEqual(spreadsheet.sheets?.count ?? 0, 2)
        
        let sheetTitles = spreadsheet.sheets?.compactMap { $0.properties?.title } ?? []
        XCTAssertTrue(sheetTitles.contains("Data"))
        XCTAssertTrue(sheetTitles.contains("Summary"))
        
        print("Created multi-sheet spreadsheet: \(spreadsheet.spreadsheetId!) - should be manually deleted")
    }
    
    // MARK: - Spreadsheet Retrieval Tests
    
    func testGetSpreadsheet() async throws {
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.get(
                spreadsheetId: self.testSpreadsheetId,
                ranges: nil,
                includeGridData: false,
                fields: nil
            )
        }
        
        // Verify basic spreadsheet properties
        XCTAssertEqual(spreadsheet.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(spreadsheet.properties)
        XCTAssertNotNil(spreadsheet.spreadsheetUrl)
        XCTAssertNotNil(spreadsheet.sheets)
        XCTAssertGreaterThan(spreadsheet.sheets?.count ?? 0, 0)
    }
    
    func testGetSpreadsheetWithRanges() async throws {
        let ranges = ["Sheet1!A1:C3", "Sheet1!E1:G3"]
        
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.get(
                spreadsheetId: self.testSpreadsheetId,
                ranges: ranges,
                includeGridData: false,
                fields: nil
            )
        }
        
        // Verify the spreadsheet was retrieved
        XCTAssertEqual(spreadsheet.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(spreadsheet.sheets)
        
        // Note: The actual data verification would depend on what's in the test spreadsheet
        // This test mainly verifies that the API call succeeds with range parameters
    }
    
    func testGetSpreadsheetWithIncludeGridData() async throws {
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.get(
                spreadsheetId: self.testSpreadsheetId,
                ranges: nil,
                includeGridData: true,
                fields: nil
            )
        }
        
        // Verify the spreadsheet was retrieved
        XCTAssertEqual(spreadsheet.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(spreadsheet.sheets)
        
        // When includeGridData is true, sheets should have data property populated
        // (though it might be empty if the spreadsheet has no data)
        if spreadsheet.sheets?.first != nil {
            // The data property should be present (though it might be empty)
            // This is mainly testing that the parameter is correctly passed to the API
        }
    }
    
    func testGetSpreadsheetWithFields() async throws {
        let fields = "properties.title,sheets.properties.title"
        
        let spreadsheet = try await executeWithTimeout {
            try await self.client.spreadsheets.get(
                spreadsheetId: self.testSpreadsheetId,
                ranges: nil,
                includeGridData: false,
                fields: fields
            )
        }
        
        // Verify the spreadsheet was retrieved
        XCTAssertEqual(spreadsheet.spreadsheetId, testSpreadsheetId)
        XCTAssertNotNil(spreadsheet.properties?.title)
        
        // When using field masks, only requested fields should be populated
        // This test mainly verifies that the fields parameter is correctly passed
    }
    
    // MARK: - Error Handling Tests
    
    func testGetNonexistentSpreadsheet() async throws {
        let nonexistentId = "1InvalidSpreadsheetId123"
        
        do {
            _ = try await executeWithTimeout {
                try await self.client.spreadsheets.get(
                    spreadsheetId: nonexistentId,
                    ranges: nil,
                    includeGridData: false,
                    fields: nil
                )
            }
            XCTFail("Expected error for nonexistent spreadsheet")
        } catch let error as GoogleSheetsError {
            // Should get a not found or invalid ID error
            switch error {
            case .notFound, .invalidSpreadsheetId, .apiError:
                // Expected error types
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testGetSpreadsheetWithInvalidRange() async throws {
        let invalidRanges = ["InvalidRange!@#$"]
        
        do {
            _ = try await executeWithTimeout {
                try await self.client.spreadsheets.get(
                    spreadsheetId: self.testSpreadsheetId,
                    ranges: invalidRanges,
                    includeGridData: false,
                    fields: nil
                )
            }
            XCTFail("Expected error for invalid range")
        } catch let error as GoogleSheetsError {
            // Should get an invalid range or API error
            switch error {
            case .invalidRange, .apiError, .badRequest:
                // Expected error types
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testSpreadsheetRetrievalPerformance() async throws {
        // Measure the time it takes to retrieve a spreadsheet
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try await executeWithTimeout {
            try await self.client.spreadsheets.get(
                spreadsheetId: self.testSpreadsheetId,
                ranges: nil,
                includeGridData: false,
                fields: nil
            )
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Verify that the operation completes within a reasonable time
        XCTAssertLessThan(duration, 10.0, "Spreadsheet retrieval should complete within 10 seconds")
        
        print("Spreadsheet retrieval took \(String(format: "%.3f", duration)) seconds")
    }
    
    func testConcurrentSpreadsheetRequests() async throws {
        // Test multiple concurrent requests to the same spreadsheet
        let requestCount = 5
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await withThrowingTaskGroup(of: Spreadsheet.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    try await self.executeWithTimeout {
                        try await self.client.spreadsheets.get(
                            spreadsheetId: self.testSpreadsheetId,
                            ranges: nil,
                            includeGridData: false,
                            fields: nil
                        )
                    }
                }
            }
            
            var results: [Spreadsheet] = []
            for try await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, requestCount)
            
            // All results should be for the same spreadsheet
            for result in results {
                XCTAssertEqual(result.spreadsheetId, testSpreadsheetId)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        print("Concurrent requests (\(requestCount)) completed in \(String(format: "%.3f", duration)) seconds")
    }
}