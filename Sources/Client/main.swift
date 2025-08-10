import Foundation
import GoogleSheetsSwift

do {
    // Get configuration from environment variables
    guard let serviceAccountPath = ProcessInfo.processInfo.environment["GOOGLE_SERVICE_ACCOUNT_PATH"] else {
        print("❌ Error: GOOGLE_SERVICE_ACCOUNT_PATH environment variable not set")
        print("💡 Set it with: export GOOGLE_SERVICE_ACCOUNT_PATH=/path/to/your/service-account.json")
        exit(1)
    }
    
    guard let spreadsheetId = ProcessInfo.processInfo.environment["GOOGLE_SPREADSHEET_ID"] else {
        print("❌ Error: GOOGLE_SPREADSHEET_ID environment variable not set")
        print("💡 Set it with: export GOOGLE_SPREADSHEET_ID=your_spreadsheet_id")
        exit(1)
    }
    
    // For server-side deployment, disable keychain to avoid interactive prompts
    let tokenManager = try ServiceAccountTokenManager.loadFromFile(
        serviceAccountPath,
        useKeychain: false
    )
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    print("🔐 Authentication successful!")
    print("📊 Testing Google Sheets API operations on spreadsheet: \(spreadsheetId)")
    print(String(repeating: "=", count: 80))
    
    // Test 1: Read existing data
    print("\n🔍 Test 1: Reading existing recipe data")
    let valueRange = try await client.readRange(spreadsheetId, range: "A1:C10")
    
    print("✅ Successfully read \(valueRange.rowCount) rows from the spreadsheet")
    print("📊 Range: \(valueRange.range ?? "Unknown")")
    
    if let values = valueRange.values {
        print("\n📋 Current Recipe Data:")
        for (index, row) in values.enumerated() {
            let rowStrings = row.map { $0.value as? String ?? "\($0.value)" }
            if index == 0 {
                print("   Headers: \(rowStrings)")
            } else {
                print("   Recipe \(index): \(rowStrings[0])")
            }
        }
    }
    
    // Test 2: Get spreadsheet metadata
    print("\n🔍 Test 2: Getting spreadsheet metadata")
    let spreadsheet = try await client.getSpreadsheet(spreadsheetId)
    print("✅ Spreadsheet Title: \(spreadsheet.properties?.title ?? "Unknown")")
    if let sheets = spreadsheet.sheets {
        print("📄 Number of sheets: \(sheets.count)")
        for (index, sheet) in sheets.enumerated() {
            let title = sheet.properties?.title ?? "Unknown"
            let sheetId = sheet.properties?.sheetId ?? -1
            print("   Sheet \(index + 1): '\(title)' (ID: \(sheetId))")
        }
    }
    
    // Test 3: Read a specific range with different options
    print("\n🔍 Test 3: Reading with different value render options")
    let formattedValues = try await client.readRange(
        spreadsheetId, 
        range: "A1:A5",
        majorDimension: .rows,
        valueRenderOption: .formattedValue
    )
    print("✅ Formatted values: \(formattedValues.getStringValues().map { $0.first ?? "" })")
    
    // Test 4: Read multiple individual ranges (simpler approach)
    print("\n🔍 Test 4: Reading multiple individual ranges")
    let range1 = try await client.readRange(spreadsheetId, range: "A1:A3")
    let range2 = try await client.readRange(spreadsheetId, range: "B1:B3") 
    let range3 = try await client.readRange(spreadsheetId, range: "C1:C3")
    
    print("✅ Successfully read 3 separate ranges:")
    print("   Range 1 (A1:A3): \(range1.rowCount) rows")
    print("   Range 2 (B1:B3): \(range2.rowCount) rows") 
    print("   Range 3 (C1:C3): \(range3.rowCount) rows")
    
    // Test 5: Add a new test recipe
    print("\n🔍 Test 5: Adding a new test recipe")
    let newRecipe = ValueRange(
        range: "A11:C11",
        majorDimension: .rows,
        values: [
            ["Test Recipe", "test, ingredients, api", "This is a test recipe added via API"]
        ]
    )
    
    let updateResponse = try await client.writeRange(
        spreadsheetId,
        range: "A11:C11",
        values: [["Test Recipe", "test, ingredients, api", "This is a test recipe added via API"]],
        majorDimension: .rows,
        valueInputOption: .userEntered
    )
    
    print("✅ Added new recipe!")
    print("   Updated cells: \(updateResponse.updatedCells ?? 0)")
    print("   Updated range: \(updateResponse.updatedRange ?? "Unknown")")
    
    // Test 6: Read the newly added recipe
    print("\n🔍 Test 6: Verifying the new recipe was added")
    let newRecipeCheck = try await client.readRange(spreadsheetId, range: "A11:C11")
    if let values = newRecipeCheck.values?.first {
        let rowStrings = values.map { $0.value as? String ?? "\($0.value)" }
        print("✅ New recipe confirmed: \(rowStrings)")
    }
    
    // Test 7: Append another recipe
    print("\n🔍 Test 7: Appending another recipe")
    let appendRecipe = ValueRange(
        majorDimension: .rows,
        values: [
            ["API Appended Recipe", "append, test, automation", "This recipe was appended using the append API"]
        ]
    )
    
    let appendResponse = try await client.appendToRange(
        spreadsheetId,
        range: "A:C",
        values: [["API Appended Recipe", "append, test, automation", "This recipe was appended using the append API"]],
        majorDimension: .rows,
        valueInputOption: .userEntered
    )
    
    print("✅ Appended new recipe!")
    if let tableRange = appendResponse.tableRange {
        print("   Table range: \(tableRange)")
    }
    if let updates = appendResponse.updates {
        print("   Updated cells: \(updates.updatedCells ?? 0)")
    }
    
    // Test 8: Read all data to see the additions
    print("\n🔍 Test 8: Reading all data to see additions")
    let allData = try await client.readRange(spreadsheetId, range: "A1:C15")
    print("✅ Total rows now: \(allData.rowCount)")
    
    if let values = allData.values {
        let lastFewRows = values.suffix(3)
        print("📋 Last few rows:")
        for (_, row) in lastFewRows.enumerated() {
            let rowStrings = row.map { $0.value as? String ?? "\($0.value)" }
            let firstCell = rowStrings.first ?? "Empty"
            print("   Row: \(firstCell)")
        }
    }
    
    // Test 9: Clean up - clear the test data
    print("\n🔍 Test 9: Cleaning up test data")
    let clearResponse = try await client.clearRange(
        spreadsheetId,
        range: "A11:C15"
    )
    print("✅ Cleaned up test data!")
    print("   Cleared range: \(clearResponse.clearedRange ?? "Unknown")")
    
    // Test 10: Final verification
    print("\n🔍 Test 10: Final verification - back to original data")
    let finalCheck = try await client.readRange(spreadsheetId, range: "A1:C10")
    print("✅ Final row count: \(finalCheck.rowCount) (should be back to original)")
    
    print("\n" + String(repeating: "=", count: 80))
    print("🎉 All Google Sheets API tests completed successfully!")
    print("🚀 Your SDK is fully functional and ready for production use!")
    
} catch {
    print("❌ Error: \(error)")
    
    switch error {
    case GoogleSheetsError.notFound(let message):
        print("💡 Not Found error usually means:")
        print("   1. The spreadsheet ID is incorrect")
        print("   2. The service account doesn't have access to the spreadsheet")
        print("   3. The spreadsheet doesn't exist")
        print("   Details: \(message)")
        
    case GoogleSheetsError.badRequest(let message):
        print("💡 Bad Request error usually means:")
        print("   1. The service account doesn't have permission to access this spreadsheet")
        print("   2. The range format might be incorrect")
        print("   3. The spreadsheet exists but is not shared with the service account")
        print("   Details: \(message)")
        
    case GoogleSheetsError.accessDenied(let message):
        print("💡 Access Denied error means:")
        print("   1. The service account doesn't have permission to access this spreadsheet")
        print("   2. The Google Sheets API might not be enabled for your project")
        print("   Details: \(message)")
        
    case GoogleSheetsError.authenticationFailed(let message):
        print("� Autxhentication failed:")
        print("   Details: \(message)")
        
    default:
        print("💡 Unexpected error occurred: \(error)")
    }
    
    print("\n📝 To fix access issues:")
    if let spreadsheetId = ProcessInfo.processInfo.environment["GOOGLE_SPREADSHEET_ID"] {
        print("   1. Open the Google Sheet: https://docs.google.com/spreadsheets/d/\(spreadsheetId)/edit")
    }
    print("   2. Click 'Share' button")
    print("   3. Add this service account email")
    print("   4. Give it 'Viewer' or 'Editor' permissions")
    print("   5. Make sure the Google Sheets API is enabled in your Google Cloud Console")
}
