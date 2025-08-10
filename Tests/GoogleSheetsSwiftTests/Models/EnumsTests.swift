import XCTest
@testable import GoogleSheetsSwift

final class EnumsTests: XCTestCase {
    
    // MARK: - MajorDimension Tests
    
    func testMajorDimensionRawValues() {
        XCTAssertEqual(MajorDimension.dimensionUnspecified.rawValue, "DIMENSION_UNSPECIFIED")
        XCTAssertEqual(MajorDimension.rows.rawValue, "ROWS")
        XCTAssertEqual(MajorDimension.columns.rawValue, "COLUMNS")
    }
    
    func testMajorDimensionFromRawValue() {
        XCTAssertEqual(MajorDimension(rawValue: "DIMENSION_UNSPECIFIED"), .dimensionUnspecified)
        XCTAssertEqual(MajorDimension(rawValue: "ROWS"), .rows)
        XCTAssertEqual(MajorDimension(rawValue: "COLUMNS"), .columns)
        XCTAssertNil(MajorDimension(rawValue: "INVALID"))
    }
    
    func testMajorDimensionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let rowsData = try encoder.encode(MajorDimension.rows)
        let rowsString = String(data: rowsData, encoding: .utf8)
        XCTAssertEqual(rowsString, "\"ROWS\"")
        
        // Test decoding
        let decodedRows = try decoder.decode(MajorDimension.self, from: rowsData)
        XCTAssertEqual(decodedRows, .rows)
    }
    
    func testMajorDimensionAllCases() {
        let allCases = MajorDimension.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.dimensionUnspecified))
        XCTAssertTrue(allCases.contains(.rows))
        XCTAssertTrue(allCases.contains(.columns))
    }
    
    func testMajorDimensionDescription() {
        XCTAssertEqual(MajorDimension.dimensionUnspecified.description, "Unspecified dimension")
        XCTAssertEqual(MajorDimension.rows.description, "Rows")
        XCTAssertEqual(MajorDimension.columns.description, "Columns")
    }
    
    // MARK: - ValueRenderOption Tests
    
    func testValueRenderOptionRawValues() {
        XCTAssertEqual(ValueRenderOption.formattedValue.rawValue, "FORMATTED_VALUE")
        XCTAssertEqual(ValueRenderOption.unformattedValue.rawValue, "UNFORMATTED_VALUE")
        XCTAssertEqual(ValueRenderOption.formula.rawValue, "FORMULA")
    }
    
    func testValueRenderOptionFromRawValue() {
        XCTAssertEqual(ValueRenderOption(rawValue: "FORMATTED_VALUE"), .formattedValue)
        XCTAssertEqual(ValueRenderOption(rawValue: "UNFORMATTED_VALUE"), .unformattedValue)
        XCTAssertEqual(ValueRenderOption(rawValue: "FORMULA"), .formula)
        XCTAssertNil(ValueRenderOption(rawValue: "INVALID"))
    }
    
    func testValueRenderOptionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let formattedData = try encoder.encode(ValueRenderOption.formattedValue)
        let formattedString = String(data: formattedData, encoding: .utf8)
        XCTAssertEqual(formattedString, "\"FORMATTED_VALUE\"")
        
        // Test decoding
        let decodedFormatted = try decoder.decode(ValueRenderOption.self, from: formattedData)
        XCTAssertEqual(decodedFormatted, .formattedValue)
    }
    
    func testValueRenderOptionAllCases() {
        let allCases = ValueRenderOption.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.formattedValue))
        XCTAssertTrue(allCases.contains(.unformattedValue))
        XCTAssertTrue(allCases.contains(.formula))
    }
    
    func testValueRenderOptionDescription() {
        XCTAssertEqual(ValueRenderOption.formattedValue.description, "Formatted value")
        XCTAssertEqual(ValueRenderOption.unformattedValue.description, "Unformatted value")
        XCTAssertEqual(ValueRenderOption.formula.description, "Formula")
    }
    
    // MARK: - ValueInputOption Tests
    
    func testValueInputOptionRawValues() {
        XCTAssertEqual(ValueInputOption.inputValueOptionUnspecified.rawValue, "INPUT_VALUE_OPTION_UNSPECIFIED")
        XCTAssertEqual(ValueInputOption.raw.rawValue, "RAW")
        XCTAssertEqual(ValueInputOption.userEntered.rawValue, "USER_ENTERED")
    }
    
    func testValueInputOptionFromRawValue() {
        XCTAssertEqual(ValueInputOption(rawValue: "INPUT_VALUE_OPTION_UNSPECIFIED"), .inputValueOptionUnspecified)
        XCTAssertEqual(ValueInputOption(rawValue: "RAW"), .raw)
        XCTAssertEqual(ValueInputOption(rawValue: "USER_ENTERED"), .userEntered)
        XCTAssertNil(ValueInputOption(rawValue: "INVALID"))
    }
    
    func testValueInputOptionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let rawData = try encoder.encode(ValueInputOption.raw)
        let rawString = String(data: rawData, encoding: .utf8)
        XCTAssertEqual(rawString, "\"RAW\"")
        
        // Test decoding
        let decodedRaw = try decoder.decode(ValueInputOption.self, from: rawData)
        XCTAssertEqual(decodedRaw, .raw)
    }
    
    func testValueInputOptionAllCases() {
        let allCases = ValueInputOption.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.inputValueOptionUnspecified))
        XCTAssertTrue(allCases.contains(.raw))
        XCTAssertTrue(allCases.contains(.userEntered))
    }
    
    func testValueInputOptionDescription() {
        XCTAssertEqual(ValueInputOption.inputValueOptionUnspecified.description, "Unspecified input option")
        XCTAssertEqual(ValueInputOption.raw.description, "Raw value")
        XCTAssertEqual(ValueInputOption.userEntered.description, "User entered value")
    }
    
    // MARK: - DateTimeRenderOption Tests
    
    func testDateTimeRenderOptionRawValues() {
        XCTAssertEqual(DateTimeRenderOption.serialNumber.rawValue, "SERIAL_NUMBER")
        XCTAssertEqual(DateTimeRenderOption.formattedString.rawValue, "FORMATTED_STRING")
    }
    
    func testDateTimeRenderOptionFromRawValue() {
        XCTAssertEqual(DateTimeRenderOption(rawValue: "SERIAL_NUMBER"), .serialNumber)
        XCTAssertEqual(DateTimeRenderOption(rawValue: "FORMATTED_STRING"), .formattedString)
        XCTAssertNil(DateTimeRenderOption(rawValue: "INVALID"))
    }
    
    func testDateTimeRenderOptionCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let serialData = try encoder.encode(DateTimeRenderOption.serialNumber)
        let serialString = String(data: serialData, encoding: .utf8)
        XCTAssertEqual(serialString, "\"SERIAL_NUMBER\"")
        
        // Test decoding
        let decodedSerial = try decoder.decode(DateTimeRenderOption.self, from: serialData)
        XCTAssertEqual(decodedSerial, .serialNumber)
    }
    
    func testDateTimeRenderOptionAllCases() {
        let allCases = DateTimeRenderOption.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.serialNumber))
        XCTAssertTrue(allCases.contains(.formattedString))
    }
    
    func testDateTimeRenderOptionDescription() {
        XCTAssertEqual(DateTimeRenderOption.serialNumber.description, "Serial number format")
        XCTAssertEqual(DateTimeRenderOption.formattedString.description, "Formatted string")
    }
    
    // MARK: - RecalculationInterval Tests
    
    func testRecalculationIntervalRawValues() {
        XCTAssertEqual(RecalculationInterval.recalculationIntervalUnspecified.rawValue, "RECALCULATION_INTERVAL_UNSPECIFIED")
        XCTAssertEqual(RecalculationInterval.onChange.rawValue, "ON_CHANGE")
        XCTAssertEqual(RecalculationInterval.onChangeAndMinute.rawValue, "ON_CHANGE_AND_MINUTE")
    }
    
    func testRecalculationIntervalFromRawValue() {
        XCTAssertEqual(RecalculationInterval(rawValue: "RECALCULATION_INTERVAL_UNSPECIFIED"), .recalculationIntervalUnspecified)
        XCTAssertEqual(RecalculationInterval(rawValue: "ON_CHANGE"), .onChange)
        XCTAssertEqual(RecalculationInterval(rawValue: "ON_CHANGE_AND_MINUTE"), .onChangeAndMinute)
        XCTAssertNil(RecalculationInterval(rawValue: "INVALID"))
    }
    
    func testRecalculationIntervalCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let onChangeData = try encoder.encode(RecalculationInterval.onChange)
        let onChangeString = String(data: onChangeData, encoding: .utf8)
        XCTAssertEqual(onChangeString, "\"ON_CHANGE\"")
        
        // Test decoding
        let decodedOnChange = try decoder.decode(RecalculationInterval.self, from: onChangeData)
        XCTAssertEqual(decodedOnChange, .onChange)
    }
    
    func testRecalculationIntervalAllCases() {
        let allCases = RecalculationInterval.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.recalculationIntervalUnspecified))
        XCTAssertTrue(allCases.contains(.onChange))
        XCTAssertTrue(allCases.contains(.onChangeAndMinute))
    }
    
    func testRecalculationIntervalDescription() {
        XCTAssertEqual(RecalculationInterval.recalculationIntervalUnspecified.description, "Unspecified recalculation interval")
        XCTAssertEqual(RecalculationInterval.onChange.description, "Recalculate on change")
        XCTAssertEqual(RecalculationInterval.onChangeAndMinute.description, "Recalculate on change and every minute")
    }
    
    // MARK: - JSON Serialization Integration Tests
    
    func testEnumsInJSONStructure() throws {
        struct TestStruct: Codable {
            let majorDimension: MajorDimension
            let valueRender: ValueRenderOption
            let valueInput: ValueInputOption
            let dateTimeRender: DateTimeRenderOption
            let recalculation: RecalculationInterval
        }
        
        let testData = TestStruct(
            majorDimension: .rows,
            valueRender: .formattedValue,
            valueInput: .userEntered,
            dateTimeRender: .serialNumber,
            recalculation: .onChange
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let jsonData = try encoder.encode(testData)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("\"ROWS\""))
        XCTAssertTrue(jsonString.contains("\"FORMATTED_VALUE\""))
        XCTAssertTrue(jsonString.contains("\"USER_ENTERED\""))
        XCTAssertTrue(jsonString.contains("\"SERIAL_NUMBER\""))
        XCTAssertTrue(jsonString.contains("\"ON_CHANGE\""))
        
        // Test decoding
        let decodedData = try decoder.decode(TestStruct.self, from: jsonData)
        XCTAssertEqual(decodedData.majorDimension, .rows)
        XCTAssertEqual(decodedData.valueRender, .formattedValue)
        XCTAssertEqual(decodedData.valueInput, .userEntered)
        XCTAssertEqual(decodedData.dateTimeRender, .serialNumber)
        XCTAssertEqual(decodedData.recalculation, .onChange)
    }
}