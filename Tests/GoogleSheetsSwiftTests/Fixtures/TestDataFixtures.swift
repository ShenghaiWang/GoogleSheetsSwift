import Foundation
@testable import GoogleSheetsSwift

/// Test data fixtures for common API responses
public struct TestDataFixtures {
    
    // MARK: - Spreadsheet Fixtures
    
    /// Sample spreadsheet with basic properties
    public static let basicSpreadsheet = Spreadsheet(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        properties: SpreadsheetProperties(
            title: "Test Spreadsheet",
            locale: "en_US",
            autoRecalc: .onChange,
            timeZone: "America/New_York"
        ),
        spreadsheetUrl: "https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit"
    )
    
    /// Sample spreadsheet with sheets and data
    public static let spreadsheetWithSheets = Spreadsheet(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        properties: SpreadsheetProperties(
            title: "Test Spreadsheet with Sheets",
            locale: "en_US"
        ),
        sheets: [
            Sheet(
                properties: SheetProperties(
                    sheetId: 0,
                    title: "Sheet1",
                    index: 0,
                    sheetType: .grid,
                    gridProperties: GridProperties()
                )
            ),
            Sheet(
                properties: SheetProperties(
                    sheetId: 1,
                    title: "Data",
                    index: 1,
                    sheetType: .grid,
                    gridProperties: GridProperties()
                )
            )
        ],
        spreadsheetUrl: "https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit"
    )
    
    /// Sample spreadsheet create request
    public static let createSpreadsheetRequest = SpreadsheetCreateRequest(
        properties: SpreadsheetProperties(
            title: "New Test Spreadsheet",
            locale: "en_US",
            timeZone: "America/New_York"
        ),
        sheets: [
            Sheet(
                properties: SheetProperties(
                    title: "Sheet1",
                    sheetType: .grid,
                    gridProperties: GridProperties()
                )
            )
        ]
    )
    
    // MARK: - Value Range Fixtures
    
    /// Simple value range with string data
    public static let simpleValueRange = ValueRange(
        range: "Sheet1!A1:B2",
        majorDimension: .rows,
        values: [
            [AnyCodable("Name"), AnyCodable("Age")],
            [AnyCodable("John Doe"), AnyCodable(30)]
        ]
    )
    
    /// Value range with mixed data types
    public static let mixedValueRange = ValueRange(
        range: "Sheet1!A1:D3",
        majorDimension: .rows,
        values: [
            [AnyCodable("Name"), AnyCodable("Age"), AnyCodable("Salary"), AnyCodable("Active")],
            [AnyCodable("John Doe"), AnyCodable(30), AnyCodable(50000.50), AnyCodable(true)],
            [AnyCodable("Jane Smith"), AnyCodable(25), AnyCodable(45000.00), AnyCodable(false)]
        ]
    )
    
    /// Empty value range
    public static let emptyValueRange = ValueRange(
        range: "Sheet1!A1:A1",
        majorDimension: .rows,
        values: []
    )
    
    /// Value range with formulas
    public static let formulaValueRange = ValueRange(
        range: "Sheet1!A1:C2",
        majorDimension: .rows,
        values: [
            [AnyCodable("Value1"), AnyCodable("Value2"), AnyCodable("Sum")],
            [AnyCodable(10), AnyCodable(20), AnyCodable("=A2+B2")]
        ]
    )
    
    // MARK: - Response Fixtures
    
    /// Sample update values response
    public static let updateValuesResponse = UpdateValuesResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        updatedRows: 2,
        updatedColumns: 2,
        updatedCells: 4,
        updatedRange: "Sheet1!A1:B2",
        updatedData: simpleValueRange
    )
    
    /// Sample append values response
    public static let appendValuesResponse = AppendValuesResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        tableRange: "Sheet1!A1:B3",
        updates: UpdateValuesResponse(
            spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
            updatedRows: 1,
            updatedColumns: 2,
            updatedCells: 2,
            updatedRange: "Sheet1!A3:B3"
        )
    )
    
    /// Sample clear values response
    public static let clearValuesResponse = ClearValuesResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        clearedRange: "Sheet1!A1:B2"
    )
    
    /// Sample batch get values response
    public static let batchGetValuesResponse = BatchGetValuesResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        valueRanges: [
            ValueRange(
                range: "Sheet1!A1:B2",
                majorDimension: .rows,
                values: [
                    [AnyCodable("Name"), AnyCodable("Age")],
                    [AnyCodable("John"), AnyCodable(30)]
                ]
            ),
            ValueRange(
                range: "Sheet1!D1:E2",
                majorDimension: .rows,
                values: [
                    [AnyCodable("City"), AnyCodable("Country")],
                    [AnyCodable("New York"), AnyCodable("USA")]
                ]
            )
        ]
    )
    
    /// Sample batch update values response
    public static let batchUpdateValuesResponse = BatchUpdateValuesResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        totalUpdatedRows: 4,
        totalUpdatedColumns: 4,
        totalUpdatedCells: 8,
        responses: [
            UpdateValuesResponse(
                spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
                updatedRows: 2,
                updatedColumns: 2,
                updatedCells: 4,
                updatedRange: "Sheet1!A1:B2"
            ),
            UpdateValuesResponse(
                spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
                updatedRows: 2,
                updatedColumns: 2,
                updatedCells: 4,
                updatedRange: "Sheet1!D1:E2"
            )
        ]
    )
    
    /// Sample batch update spreadsheet response
    public static let batchUpdateSpreadsheetResponse = BatchUpdateSpreadsheetResponse(
        spreadsheetId: "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
        replies: [
            Response(),
            Response()
        ]
    )
    
    // MARK: - Authentication Fixtures
    
    /// Sample auth result
    public static let authResult = AuthResult(
        accessToken: "ya29.a0AfH6SMC...",
        refreshToken: "1//04...",
        expiresIn: 3600,
        tokenType: "Bearer",
        scope: "https://www.googleapis.com/auth/spreadsheets"
    )
    
    // MARK: - Error Fixtures
    
    /// Common error scenarios
    public static let authenticationError = GoogleSheetsError.authenticationFailed("Invalid credentials")
    public static let rateLimitError = GoogleSheetsError.rateLimitExceeded(retryAfter: 60)
    public static let networkError = GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
    public static let invalidSpreadsheetError = GoogleSheetsError.invalidSpreadsheetId("Invalid spreadsheet ID")
    public static let invalidRangeError = GoogleSheetsError.invalidRange("Invalid range format")
    public static let quotaExceededError = GoogleSheetsError.quotaExceeded
    
    // MARK: - Helper Methods
    
    /// Convert column number to letter (1 = A, 26 = Z, 27 = AA, etc.)
    private static func columnLetter(for column: Int) -> String {
        var result = ""
        var num = column
        
        while num > 0 {
            num -= 1
            result = String(Character(UnicodeScalar(65 + (num % 26))!)) + result
            num /= 26
        }
        
        return result
    }
    
    /// Create a value range with specified dimensions
    public static func valueRange(
        range: String,
        rows: Int,
        columns: Int,
        majorDimension: MajorDimension = .rows,
        fillPattern: String = "Cell"
    ) -> ValueRange {
        var values: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowValues: [AnyCodable] = []
            for col in 1...columns {
                rowValues.append(AnyCodable("\(fillPattern)R\(row)C\(col)"))
            }
            values.append(rowValues)
        }
        
        return ValueRange(
            range: range,
            majorDimension: majorDimension,
            values: values
        )
    }
    
    /// Create a spreadsheet with specified number of sheets
    public static func spreadsheet(
        id: String = "test-spreadsheet-id",
        title: String = "Test Spreadsheet",
        sheetCount: Int = 1
    ) -> Spreadsheet {
        var sheets: [Sheet] = []
        
        for i in 0..<sheetCount {
            sheets.append(
                Sheet(
                    properties: SheetProperties(
                        sheetId: i,
                        title: i == 0 ? "Sheet1" : "Sheet\(i + 1)",
                        index: i,
                        sheetType: .grid,
                        gridProperties: GridProperties()
                    )
                )
            )
        }
        
        return Spreadsheet(
            spreadsheetId: id,
            properties: SpreadsheetProperties(
                title: title,
                locale: "en_US"
            ),
            sheets: sheets,
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/\(id)/edit"
        )
    }
    
    /// Create test values with specified dimensions
    public static func createTestValues(rows: Int, columns: Int, prefix: String = "Value") -> [[AnyCodable]] {
        var values: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowValues: [AnyCodable] = []
            for col in 1...columns {
                rowValues.append(AnyCodable("\(prefix)R\(row)C\(col)"))
            }
            values.append(rowValues)
        }
        
        return values
    }
    
    /// Create numeric test values
    public static func createNumericTestValues(rows: Int, columns: Int) -> [[AnyCodable]] {
        var values: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowValues: [AnyCodable] = []
            for col in 1...columns {
                rowValues.append(AnyCodable(Double(row * columns + col)))
            }
            values.append(rowValues)
        }
        
        return values
    }
    
    /// Create mixed type test values
    public static func createMixedTestValues(rows: Int, columns: Int) -> [[AnyCodable]] {
        var values: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowValues: [AnyCodable] = []
            for col in 1...columns {
                switch col % 4 {
                case 0:
                    rowValues.append(AnyCodable("String\(row)\(col)"))
                case 1:
                    rowValues.append(AnyCodable(Double(row * col)))
                case 2:
                    rowValues.append(AnyCodable(row % 2 == 0))
                case 3:
                    rowValues.append(AnyCodable(row + col))
                default:
                    rowValues.append(AnyCodable("Default"))
                }
            }
            values.append(rowValues)
        }
        
        return values
    }
}