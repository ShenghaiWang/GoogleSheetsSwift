import Foundation
import GoogleSheetsSwift

/**
 * Basic Usage Examples for GoogleSheetsSwift
 * 
 * This file demonstrates the most common operations you'll perform
 * with the Google Sheets API using GoogleSheetsSwift.
 */

class BasicUsageExamples {
    private let client: GoogleSheetsClient
    private let spreadsheetId = "your-spreadsheet-id-here"
    
    init() {
        // Example 1: Initialize with OAuth2 (recommended for full access)
        let tokenManager = GoogleOAuth2TokenManager(
            clientId: "your-client-id.googleusercontent.com",
            clientSecret: "your-client-secret",
            redirectURI: "com.yourapp.googlesheets://oauth"
        )
        
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
        
        // Example 2: Initialize with API key (read-only access)
        // self.client = GoogleSheetsClient(apiKey: "your-api-key")
    }
    
    // MARK: - Authentication
    
    /// Authenticate with Google using OAuth2
    func authenticate() async throws {
        let scopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive.file"
        ]
        
        let result = try await client.tokenManager.authenticate(scopes: scopes)
        print("✅ Authentication successful")
        print("Access token: \(result.accessToken.prefix(20))...")
    }
    
    // MARK: - Reading Data
    
    /// Read data from a specific range
    func readBasicRange() async throws {
        print("\n📖 Reading basic range...")
        
        let values = try await client.readRange(
            spreadsheetId,
            range: "Sheet1!A1:C10"
        )
        
        print("Range: \(values.range ?? "Unknown")")
        print("Rows: \(values.values?.count ?? 0)")
        
        // Access individual cells
        if let rows = values.values, !rows.isEmpty {
            let firstRow = rows[0]
            let firstCell = firstRow.indices.contains(0) ? firstRow[0].get() as String? : nil
            print("First cell: \(firstCell ?? "Empty")")
        }
    }
    
    /// Read data as strings (most common use case)
    func readAsStrings() async throws {
        print("\n📖 Reading as strings...")
        
        let stringValues = try await client.readStringValues(
            spreadsheetId,
            range: "Sheet1!A1:C10"
        )
        
        for (rowIndex, row) in stringValues.enumerated() {
            print("Row \(rowIndex + 1): \(row.map { $0 ?? "Empty" }.joined(separator: " | "))")
        }
    }
    
    /// Read multiple ranges at once
    func readMultipleRanges() async throws {
        print("\n📖 Reading multiple ranges...")
        
        let operations = [
            BatchReadOperation(range: "Sheet1!A1:C5", valueRenderOption: .formattedValue),
            BatchReadOperation(range: "Sheet1!E1:G5", valueRenderOption: .unformattedValue)
        ]
        
        let results = try await client.batchRead(spreadsheetId, operations: operations)
        
        for (index, result) in results.enumerated() {
            print("Range \(index + 1): \(result.range ?? "Unknown") - \(result.values?.count ?? 0) rows")
        }
    }
    
    // MARK: - Writing Data
    
    /// Write data to a specific range
    func writeBasicData() async throws {
        print("\n✏️ Writing basic data...")
        
        let data = [
            ["Name", "Age", "City"],
            ["Alice", "25", "New York"],
            ["Bob", "30", "San Francisco"],
            ["Charlie", "28", "Chicago"]
        ]
        
        let response = try await client.writeRange(
            spreadsheetId,
            range: "Sheet1!A1:C4",
            values: data
        )
        
        print("✅ Updated \(response.updatedCells ?? 0) cells")
        print("Updated range: \(response.updatedRange ?? "Unknown")")
    }
    
    /// Append data to the end of a sheet
    func appendData() async throws {
        print("\n➕ Appending data...")
        
        let newData = [
            ["Diana", "32", "Boston"],
            ["Eve", "27", "Seattle"]
        ]
        
        let response = try await client.appendToRange(
            spreadsheetId,
            range: "Sheet1!A:C",
            values: newData
        )
        
        print("✅ Appended \(response.updates?.updatedCells ?? 0) cells")
        print("Updated range: \(response.updates?.updatedRange ?? "Unknown")")
    }
    
    /// Clear data from a range
    func clearData() async throws {
        print("\n🗑️ Clearing data...")
        
        let response = try await client.clearRange(
            spreadsheetId,
            range: "Sheet1!D1:F10"
        )
        
        print("✅ Cleared range: \(response.clearedRange ?? "Unknown")")
    }
    
    // MARK: - Batch Operations
    
    /// Perform multiple write operations at once
    func batchWrite() async throws {
        print("\n📝 Batch writing...")
        
        let operations = [
            BatchWriteOperation(
                range: "Sheet1!A1:B2",
                values: [["Header 1", "Header 2"], ["Value 1", "Value 2"]]
            ),
            BatchWriteOperation(
                range: "Sheet1!D1:E2",
                values: [["Header 3", "Header 4"], ["Value 3", "Value 4"]]
            )
        ]
        
        let response = try await client.batchWrite(
            spreadsheetId,
            operations: operations
        )
        
        print("✅ Batch update completed")
        print("Total updated cells: \(response.totalUpdatedCells ?? 0)")
    }
    
    // MARK: - Spreadsheet Management
    
    /// Create a new spreadsheet
    func createSpreadsheet() async throws {
        print("\n📄 Creating new spreadsheet...")
        
        let spreadsheet = try await client.createSpreadsheet(
            title: "My New Spreadsheet - \(Date())",
            sheetTitles: ["Data", "Analysis", "Summary"]
        )
        
        print("✅ Created spreadsheet:")
        print("ID: \(spreadsheet.spreadsheetId ?? "Unknown")")
        print("URL: \(spreadsheet.spreadsheetUrl ?? "Unknown")")
        print("Sheets: \(spreadsheet.sheets?.map { $0.properties?.title ?? "Untitled" } ?? [])")
    }
    
    /// Get spreadsheet information
    func getSpreadsheetInfo() async throws {
        print("\n📋 Getting spreadsheet info...")
        
        let spreadsheet = try await client.getSpreadsheet(spreadsheetId)
        
        print("Title: \(spreadsheet.properties?.title ?? "Unknown")")
        print("Locale: \(spreadsheet.properties?.locale ?? "Unknown")")
        print("Time Zone: \(spreadsheet.properties?.timeZone ?? "Unknown")")
        print("Number of sheets: \(spreadsheet.sheets?.count ?? 0)")
        
        if let sheets = spreadsheet.sheets {
            for sheet in sheets {
                let title = sheet.properties?.title ?? "Untitled"
                let rowCount = sheet.properties?.gridProperties?.rowCount ?? 0
                let columnCount = sheet.properties?.gridProperties?.columnCount ?? 0
                print("  - \(title): \(rowCount) rows × \(columnCount) columns")
            }
        }
    }
    
    // MARK: - Error Handling Examples
    
    /// Demonstrate proper error handling
    func demonstrateErrorHandling() async {
        print("\n⚠️ Demonstrating error handling...")
        
        do {
            // This will likely fail with an invalid spreadsheet ID
            _ = try await client.readRange("invalid-id", range: "A1:B2")
        } catch GoogleSheetsError.authenticationFailed(let message) {
            print("❌ Authentication failed: \(message)")
        } catch GoogleSheetsError.invalidSpreadsheetId(let id) {
            print("❌ Invalid spreadsheet ID: \(id)")
        } catch GoogleSheetsError.invalidRange(let range) {
            print("❌ Invalid range: \(range)")
        } catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
            print("❌ Rate limited. Retry after: \(retryAfter ?? 0) seconds")
        } catch GoogleSheetsError.networkError(let error) {
            print("❌ Network error: \(error.localizedDescription)")
        } catch GoogleSheetsError.apiError(let code, let message) {
            print("❌ API error (\(code)): \(message)")
        } catch {
            print("❌ Unexpected error: \(error)")
        }
    }
    
    // MARK: - A1 Notation Utilities
    
    /// Demonstrate A1 notation utilities
    func demonstrateA1Utilities() {
        print("\n🔤 A1 Notation utilities...")
        
        // Convert column numbers to letters
        print("Column 1: \(GoogleSheetsClient.columnNumberToLetters(1))") // A
        print("Column 26: \(GoogleSheetsClient.columnNumberToLetters(26))") // Z
        print("Column 27: \(GoogleSheetsClient.columnNumberToLetters(27))") // AA
        
        // Convert column letters to numbers
        do {
            print("Column A: \(try GoogleSheetsClient.columnLettersToNumber("A"))") // 1
            print("Column Z: \(try GoogleSheetsClient.columnLettersToNumber("Z"))") // 26
            print("Column AA: \(try GoogleSheetsClient.columnLettersToNumber("AA"))") // 27
        } catch {
            print("Error converting column letters: \(error)")
        }
        
        // Build A1 ranges
        let range1 = GoogleSheetsClient.buildA1Range(
            startColumn: 1, startRow: 1,
            endColumn: 5, endRow: 10
        )
        print("Built range: \(range1)") // A1:E10
        
        let range2 = GoogleSheetsClient.buildA1Range(
            sheetName: "Data",
            startColumn: 1, startRow: 1,
            endColumn: 3, endRow: 100
        )
        print("Built range with sheet: \(range2)") // Data!A1:C100
        
        // Validate ranges
        let validRanges = ["A1", "A1:B2", "Sheet1!A1:C10", "Data!A:A", "1:1"]
        for range in validRanges {
            let isValid = GoogleSheetsClient.isValidA1Range(range)
            print("Range '\(range)' is valid: \(isValid)")
        }
    }
    
    // MARK: - Run All Examples
    
    /// Run all examples in sequence
    func runAllExamples() async {
        print("🚀 Running GoogleSheetsSwift Basic Usage Examples")
        print("=" * 50)
        
        do {
            // Authentication
            try await authenticate()
            
            // Reading examples
            try await readBasicRange()
            try await readAsStrings()
            try await readMultipleRanges()
            
            // Writing examples
            try await writeBasicData()
            try await appendData()
            
            // Batch operations
            try await batchWrite()
            
            // Spreadsheet management
            try await getSpreadsheetInfo()
            try await createSpreadsheet()
            
            // Clear some data
            try await clearData()
            
            // Utilities
            demonstrateA1Utilities()
            
            // Error handling
            await demonstrateErrorHandling()
            
            print("\n✅ All examples completed successfully!")
            
        } catch {
            print("\n❌ Example failed with error: \(error)")
        }
    }
}

// MARK: - Usage

/*
 To use these examples:
 
 1. Replace "your-spreadsheet-id-here" with an actual spreadsheet ID
 2. Set up your authentication credentials
 3. Run the examples:
 
 let examples = BasicUsageExamples()
 await examples.runAllExamples()
 
 Or run individual examples:
 
 await examples.authenticate()
 await examples.readBasicRange()
 await examples.writeBasicData()
 */

// Helper extension for string repetition
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}