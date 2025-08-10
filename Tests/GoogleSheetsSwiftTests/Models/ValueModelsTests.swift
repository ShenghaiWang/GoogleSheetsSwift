import XCTest
@testable import GoogleSheetsSwift

final class ValueModelsTests: XCTestCase {
    
    // MARK: - ValueRange Tests
    
    func testValueRangeInitialization() {
        let valueRange = ValueRange(
            range: "A1:B2",
            majorDimension: .rows,
            values: [[AnyCodable("hello"), AnyCodable(42)], [AnyCodable(true), AnyCodable(3.14)]]
        )
        
        XCTAssertEqual(valueRange.range, "A1:B2")
        XCTAssertEqual(valueRange.majorDimension, .rows)
        XCTAssertEqual(valueRange.values?.count, 2)
        XCTAssertEqual(valueRange.values?[0].count, 2)
        XCTAssertEqual(valueRange.values?[0][0].getString(), "hello")
        XCTAssertEqual(valueRange.values?[0][1].getInt(), 42)
        XCTAssertEqual(valueRange.values?[1][0].getBool(), true)
        XCTAssertEqual(valueRange.values?[1][1].getDouble(), 3.14)
    }
    
    func testValueRangeConvenienceInitializer() {
        let values: [[Any]] = [["hello", 42], [true, 3.14]]
        let valueRange = ValueRange(range: "A1:B2", majorDimension: .columns, values: values)
        
        XCTAssertEqual(valueRange.range, "A1:B2")
        XCTAssertEqual(valueRange.majorDimension, .columns)
        XCTAssertEqual(valueRange.values?.count, 2)
        XCTAssertEqual(valueRange.values?[0][0].getString(), "hello")
        XCTAssertEqual(valueRange.values?[0][1].getInt(), 42)
        XCTAssertEqual(valueRange.values?[1][0].getBool(), true)
        XCTAssertEqual(valueRange.values?[1][1].getDouble(), 3.14)
    }
    
    func testValueRangeDefaultInitialization() {
        let valueRange = ValueRange()
        
        XCTAssertNil(valueRange.range)
        XCTAssertNil(valueRange.majorDimension)
        XCTAssertNil(valueRange.values)
    }
    
    func testValueRangeConvenienceMethods() {
        let values: [[Any]] = [["hello", "42"], ["true", "3.14"]]
        let valueRange = ValueRange(values: values)
        
        let stringValues = valueRange.getStringValues()
        XCTAssertEqual(stringValues.count, 2)
        XCTAssertEqual(stringValues[0][0], "hello")
        XCTAssertEqual(stringValues[0][1], "42")
        XCTAssertEqual(stringValues[1][0], "true")
        XCTAssertEqual(stringValues[1][1], "3.14")
        
        let doubleValues = valueRange.getDoubleValues()
        XCTAssertNil(doubleValues[0][0]) // "hello" can't be converted to double
        XCTAssertEqual(doubleValues[0][1], 42.0)
        XCTAssertNil(doubleValues[1][0]) // "true" can't be converted to double
        XCTAssertEqual(doubleValues[1][1], 3.14)
        
        let intValues = valueRange.getIntValues()
        XCTAssertNil(intValues[0][0]) // "hello" can't be converted to int
        XCTAssertEqual(intValues[0][1], 42)
        XCTAssertNil(intValues[1][0]) // "true" can't be converted to int
        XCTAssertNil(intValues[1][1]) // "3.14" can't be converted to int directly from string
        
        let boolValues = valueRange.getBoolValues()
        XCTAssertNil(boolValues[0][0]) // "hello" can't be converted to bool
        XCTAssertNil(boolValues[0][1]) // "42" can't be converted to bool
        XCTAssertEqual(boolValues[1][0], true)
        XCTAssertNil(boolValues[1][1]) // "3.14" can't be converted to bool
    }
    
    func testValueRangeProperties() {
        let emptyValueRange = ValueRange()
        XCTAssertEqual(emptyValueRange.rowCount, 0)
        XCTAssertEqual(emptyValueRange.columnCount, 0)
        XCTAssertTrue(emptyValueRange.isEmpty)
        
        let valueRange = ValueRange(values: [["a", "b", "c"], ["d", "e"]])
        XCTAssertEqual(valueRange.rowCount, 2)
        XCTAssertEqual(valueRange.columnCount, 3) // Based on first row
        XCTAssertFalse(valueRange.isEmpty)
        
        let emptyValuesRange = ValueRange(values: [])
        XCTAssertEqual(emptyValuesRange.rowCount, 0)
        XCTAssertEqual(emptyValuesRange.columnCount, 0)
        XCTAssertTrue(emptyValuesRange.isEmpty)
    }
    
    func testValueRangeCodable() throws {
        let original = ValueRange(
            range: "A1:B2",
            majorDimension: .rows,
            values: [["hello", 42], [true, 3.14]]
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ValueRange.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    func testValueRangeEquality() {
        let valueRange1 = ValueRange(range: "A1:B2", majorDimension: .rows, values: [["hello", 42]])
        let valueRange2 = ValueRange(range: "A1:B2", majorDimension: .rows, values: [["hello", 42]])
        let valueRange3 = ValueRange(range: "A1:B2", majorDimension: .columns, values: [["hello", 42]])
        
        XCTAssertEqual(valueRange1, valueRange2)
        XCTAssertNotEqual(valueRange1, valueRange3)
    }
    
    // MARK: - UpdateValuesResponse Tests
    
    func testUpdateValuesResponse() throws {
        let updatedData = ValueRange(range: "A1:B2", values: [["updated", "data"]])
        let response = UpdateValuesResponse(
            spreadsheetId: "test-id",
            updatedRows: 2,
            updatedColumns: 2,
            updatedCells: 4,
            updatedRange: "A1:B2",
            updatedData: updatedData
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.updatedRows, 2)
        XCTAssertEqual(response.updatedColumns, 2)
        XCTAssertEqual(response.updatedCells, 4)
        XCTAssertEqual(response.updatedRange, "A1:B2")
        XCTAssertEqual(response.updatedData, updatedData)
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(UpdateValuesResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    func testUpdateValuesResponseDefaultInit() {
        let response = UpdateValuesResponse()
        
        XCTAssertNil(response.spreadsheetId)
        XCTAssertNil(response.updatedRows)
        XCTAssertNil(response.updatedColumns)
        XCTAssertNil(response.updatedCells)
        XCTAssertNil(response.updatedRange)
        XCTAssertNil(response.updatedData)
    }
    
    // MARK: - AppendValuesResponse Tests
    
    func testAppendValuesResponse() throws {
        let updates = UpdateValuesResponse(spreadsheetId: "test-id", updatedCells: 2)
        let response = AppendValuesResponse(
            spreadsheetId: "test-id",
            tableRange: "A1:B10",
            updates: updates
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.tableRange, "A1:B10")
        XCTAssertEqual(response.updates, updates)
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(AppendValuesResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    // MARK: - ClearValuesResponse Tests
    
    func testClearValuesResponse() throws {
        let response = ClearValuesResponse(
            spreadsheetId: "test-id",
            clearedRange: "A1:B2"
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.clearedRange, "A1:B2")
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(ClearValuesResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    // MARK: - BatchGetValuesResponse Tests
    
    func testBatchGetValuesResponse() throws {
        let valueRanges = [
            ValueRange(range: "A1:B2", values: [["a", "b"]]),
            ValueRange(range: "C1:D2", values: [["c", "d"]])
        ]
        let response = BatchGetValuesResponse(
            spreadsheetId: "test-id",
            valueRanges: valueRanges
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.valueRanges?.count, 2)
        XCTAssertEqual(response.valueRanges?[0].range, "A1:B2")
        XCTAssertEqual(response.valueRanges?[1].range, "C1:D2")
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(BatchGetValuesResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    // MARK: - BatchUpdateValuesResponse Tests
    
    func testBatchUpdateValuesResponse() throws {
        let responses = [
            UpdateValuesResponse(spreadsheetId: "test-id", updatedCells: 2),
            UpdateValuesResponse(spreadsheetId: "test-id", updatedCells: 3)
        ]
        let response = BatchUpdateValuesResponse(
            spreadsheetId: "test-id",
            totalUpdatedRows: 2,
            totalUpdatedColumns: 3,
            totalUpdatedCells: 5,
            responses: responses
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.totalUpdatedRows, 2)
        XCTAssertEqual(response.totalUpdatedColumns, 3)
        XCTAssertEqual(response.totalUpdatedCells, 5)
        XCTAssertEqual(response.responses?.count, 2)
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(BatchUpdateValuesResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    // MARK: - ValueGetOptions Tests
    
    func testValueGetOptions() {
        let options = ValueGetOptions(
            valueRenderOption: .formattedValue,
            dateTimeRenderOption: .serialNumber,
            majorDimension: .rows
        )
        
        XCTAssertEqual(options.valueRenderOption, .formattedValue)
        XCTAssertEqual(options.dateTimeRenderOption, .serialNumber)
        XCTAssertEqual(options.majorDimension, .rows)
        
        let defaultOptions = ValueGetOptions()
        XCTAssertNil(defaultOptions.valueRenderOption)
        XCTAssertNil(defaultOptions.dateTimeRenderOption)
        XCTAssertNil(defaultOptions.majorDimension)
    }
    
    func testValueGetOptionsEquality() {
        let options1 = ValueGetOptions(valueRenderOption: .formattedValue, majorDimension: .rows)
        let options2 = ValueGetOptions(valueRenderOption: .formattedValue, majorDimension: .rows)
        let options3 = ValueGetOptions(valueRenderOption: .unformattedValue, majorDimension: .rows)
        
        XCTAssertEqual(options1, options2)
        XCTAssertNotEqual(options1, options3)
    }
    
    // MARK: - ValueUpdateOptions Tests
    
    func testValueUpdateOptions() {
        let options = ValueUpdateOptions(
            valueInputOption: .userEntered,
            includeValuesInResponse: true,
            responseValueRenderOption: .formattedValue,
            responseDateTimeRenderOption: .formattedString
        )
        
        XCTAssertEqual(options.valueInputOption, .userEntered)
        XCTAssertEqual(options.includeValuesInResponse, true)
        XCTAssertEqual(options.responseValueRenderOption, .formattedValue)
        XCTAssertEqual(options.responseDateTimeRenderOption, .formattedString)
        
        let defaultOptions = ValueUpdateOptions()
        XCTAssertNil(defaultOptions.valueInputOption)
        XCTAssertNil(defaultOptions.includeValuesInResponse)
        XCTAssertNil(defaultOptions.responseValueRenderOption)
        XCTAssertNil(defaultOptions.responseDateTimeRenderOption)
    }
    
    // MARK: - ValueAppendOptions Tests
    
    func testValueAppendOptions() {
        let options = ValueAppendOptions(
            valueInputOption: .raw,
            insertDataOption: .insertRows,
            includeValuesInResponse: false,
            responseValueRenderOption: .unformattedValue,
            responseDateTimeRenderOption: .serialNumber
        )
        
        XCTAssertEqual(options.valueInputOption, .raw)
        XCTAssertEqual(options.insertDataOption, .insertRows)
        XCTAssertEqual(options.includeValuesInResponse, false)
        XCTAssertEqual(options.responseValueRenderOption, .unformattedValue)
        XCTAssertEqual(options.responseDateTimeRenderOption, .serialNumber)
        
        let defaultOptions = ValueAppendOptions()
        XCTAssertNil(defaultOptions.valueInputOption)
        XCTAssertNil(defaultOptions.insertDataOption)
        XCTAssertNil(defaultOptions.includeValuesInResponse)
        XCTAssertNil(defaultOptions.responseValueRenderOption)
        XCTAssertNil(defaultOptions.responseDateTimeRenderOption)
    }
    
    // MARK: - InsertDataOption Tests
    
    func testInsertDataOptionRawValues() {
        XCTAssertEqual(InsertDataOption.overwrite.rawValue, "OVERWRITE")
        XCTAssertEqual(InsertDataOption.insertRows.rawValue, "INSERT_ROWS")
    }
    
    func testInsertDataOptionFromRawValue() {
        XCTAssertEqual(InsertDataOption(rawValue: "OVERWRITE"), .overwrite)
        XCTAssertEqual(InsertDataOption(rawValue: "INSERT_ROWS"), .insertRows)
        XCTAssertNil(InsertDataOption(rawValue: "INVALID"))
    }
    
    func testInsertDataOptionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let overwriteData = try encoder.encode(InsertDataOption.overwrite)
        let overwriteString = String(data: overwriteData, encoding: .utf8)
        XCTAssertEqual(overwriteString, "\"OVERWRITE\"")
        
        // Test decoding
        let decodedOverwrite = try decoder.decode(InsertDataOption.self, from: overwriteData)
        XCTAssertEqual(decodedOverwrite, .overwrite)
    }
    
    func testInsertDataOptionAllCases() {
        let allCases = InsertDataOption.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.overwrite))
        XCTAssertTrue(allCases.contains(.insertRows))
    }
    
    func testInsertDataOptionDescription() {
        XCTAssertEqual(InsertDataOption.overwrite.description, "Overwrite existing data")
        XCTAssertEqual(InsertDataOption.insertRows.description, "Insert new rows")
    }
    
    // MARK: - Integration Tests
    
    func testComplexValueRangeWithMixedTypes() throws {
        let values: [[Any?]] = [
            ["Name", "Age", "Active", "Score"],
            ["John", 25, true, 95.5],
            ["Jane", 30, false, 87.2],
            ["Bob", nil, true, 92.0]
        ]
        
        let valueRange = ValueRange(range: "A1:D4", majorDimension: .rows, values: values)
        
        // Test serialization
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(valueRange)
        let decoded = try decoder.decode(ValueRange.self, from: data)
        
        XCTAssertEqual(decoded.range, "A1:D4")
        XCTAssertEqual(decoded.majorDimension, .rows)
        XCTAssertEqual(decoded.rowCount, 4)
        XCTAssertEqual(decoded.columnCount, 4)
        
        // Test value extraction
        let stringValues = decoded.getStringValues()
        XCTAssertEqual(stringValues[0][0], "Name")
        XCTAssertEqual(stringValues[1][0], "John")
        XCTAssertEqual(stringValues[1][1], "25")
        XCTAssertEqual(stringValues[1][2], "true")
        XCTAssertEqual(stringValues[1][3], "95.5")
        XCTAssertNil(stringValues[3][1]) // nil value
        
        let doubleValues = decoded.getDoubleValues()
        XCTAssertNil(doubleValues[0][0]) // "Name" can't be converted
        XCTAssertEqual(doubleValues[1][1], 25.0)
        XCTAssertEqual(doubleValues[1][3], 95.5)
        XCTAssertNil(doubleValues[3][1]) // nil value
        
        let boolValues = decoded.getBoolValues()
        XCTAssertNil(boolValues[0][0]) // "Name" can't be converted
        XCTAssertEqual(boolValues[1][2], true)
        XCTAssertEqual(boolValues[2][2], false)
    }
    
    func testResponseModelsWithComplexData() throws {
        let valueRange = ValueRange(range: "A1:B2", values: [["updated", 42], [true, 3.14]])
        let updateResponse = UpdateValuesResponse(
            spreadsheetId: "test-spreadsheet",
            updatedRows: 2,
            updatedColumns: 2,
            updatedCells: 4,
            updatedRange: "A1:B2",
            updatedData: valueRange
        )
        
        let appendResponse = AppendValuesResponse(
            spreadsheetId: "test-spreadsheet",
            tableRange: "A1:B10",
            updates: updateResponse
        )
        
        // Test serialization of nested structures
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(appendResponse)
        let decoded = try decoder.decode(AppendValuesResponse.self, from: data)
        
        XCTAssertEqual(decoded.spreadsheetId, "test-spreadsheet")
        XCTAssertEqual(decoded.tableRange, "A1:B10")
        XCTAssertEqual(decoded.updates?.updatedCells, 4)
        XCTAssertEqual(decoded.updates?.updatedData?.range, "A1:B2")
        XCTAssertEqual(decoded.updates?.updatedData?.values?[0][0].getString(), "updated")
        XCTAssertEqual(decoded.updates?.updatedData?.values?[0][1].getInt(), 42)
    }
    
    // MARK: - BatchUpdateValuesRequest Tests
    
    func testBatchUpdateValuesRequest() throws {
        let data = [
            ValueRange(range: "A1:B2", values: [[AnyCodable("Name"), AnyCodable("Age")]]),
            ValueRange(range: "D1:E2", values: [[AnyCodable("City"), AnyCodable("Country")]])
        ]
        
        let request = BatchUpdateValuesRequest(
            valueInputOption: .userEntered,
            data: data,
            includeValuesInResponse: true,
            responseValueRenderOption: .formattedValue,
            responseDateTimeRenderOption: .formattedString
        )
        
        XCTAssertEqual(request.valueInputOption, .userEntered)
        XCTAssertEqual(request.data.count, 2)
        XCTAssertEqual(request.includeValuesInResponse, true)
        XCTAssertEqual(request.responseValueRenderOption, .formattedValue)
        XCTAssertEqual(request.responseDateTimeRenderOption, .formattedString)
        
        // Test Codable conformance
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(request)
        
        let decoder = JSONDecoder()
        let decodedRequest = try decoder.decode(BatchUpdateValuesRequest.self, from: encodedData)
        
        XCTAssertEqual(decodedRequest.valueInputOption, request.valueInputOption)
        XCTAssertEqual(decodedRequest.data.count, request.data.count)
        XCTAssertEqual(decodedRequest.includeValuesInResponse, request.includeValuesInResponse)
        XCTAssertEqual(decodedRequest.responseValueRenderOption, request.responseValueRenderOption)
        XCTAssertEqual(decodedRequest.responseDateTimeRenderOption, request.responseDateTimeRenderOption)
    }
    
    func testBatchUpdateValuesRequestDefaultInit() {
        let data = [ValueRange(range: "A1", values: [[AnyCodable("Test")]])]
        let request = BatchUpdateValuesRequest(data: data)
        
        XCTAssertNil(request.valueInputOption)
        XCTAssertEqual(request.data.count, 1)
        XCTAssertNil(request.includeValuesInResponse)
        XCTAssertNil(request.responseValueRenderOption)
        XCTAssertNil(request.responseDateTimeRenderOption)
    }
}