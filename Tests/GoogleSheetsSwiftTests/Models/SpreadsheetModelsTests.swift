import XCTest
@testable import GoogleSheetsSwift

final class SpreadsheetModelsTests: XCTestCase {
    
    // MARK: - Spreadsheet Tests
    
    func testSpreadsheetInitialization() {
        let properties = SpreadsheetProperties(title: "Test Spreadsheet", locale: "en_US")
        let sheet = Sheet(properties: SheetProperties(title: "Sheet1"))
        let spreadsheet = Spreadsheet(
            spreadsheetId: "test-id",
            properties: properties,
            sheets: [sheet],
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/test-id"
        )
        
        XCTAssertEqual(spreadsheet.spreadsheetId, "test-id")
        XCTAssertEqual(spreadsheet.properties?.title, "Test Spreadsheet")
        XCTAssertEqual(spreadsheet.sheets?.count, 1)
        XCTAssertEqual(spreadsheet.spreadsheetUrl, "https://docs.google.com/spreadsheets/d/test-id")
        XCTAssertNil(spreadsheet.namedRanges)
        XCTAssertNil(spreadsheet.developerMetadata)
    }
    
    func testSpreadsheetDefaultInitialization() {
        let spreadsheet = Spreadsheet()
        
        XCTAssertNil(spreadsheet.spreadsheetId)
        XCTAssertNil(spreadsheet.properties)
        XCTAssertNil(spreadsheet.sheets)
        XCTAssertNil(spreadsheet.namedRanges)
        XCTAssertNil(spreadsheet.spreadsheetUrl)
        XCTAssertNil(spreadsheet.developerMetadata)
        XCTAssertNil(spreadsheet.dataSources)
        XCTAssertNil(spreadsheet.dataSourceSchedules)
    }
    
    func testSpreadsheetCodable() throws {
        let properties = SpreadsheetProperties(title: "Test Spreadsheet", locale: "en_US")
        let original = Spreadsheet(
            spreadsheetId: "test-id",
            properties: properties,
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/test-id"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Spreadsheet.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    func testSpreadsheetEquality() {
        let properties = SpreadsheetProperties(title: "Test")
        let spreadsheet1 = Spreadsheet(spreadsheetId: "id1", properties: properties)
        let spreadsheet2 = Spreadsheet(spreadsheetId: "id1", properties: properties)
        let spreadsheet3 = Spreadsheet(spreadsheetId: "id2", properties: properties)
        
        XCTAssertEqual(spreadsheet1, spreadsheet2)
        XCTAssertNotEqual(spreadsheet1, spreadsheet3)
    }
    
    // MARK: - SpreadsheetProperties Tests
    
    func testSpreadsheetPropertiesInitialization() {
        let properties = SpreadsheetProperties(
            title: "My Spreadsheet",
            locale: "en_US",
            autoRecalc: .onChange,
            timeZone: "America/New_York",
            importFunctionsExternalUrlAccessAllowed: true
        )
        
        XCTAssertEqual(properties.title, "My Spreadsheet")
        XCTAssertEqual(properties.locale, "en_US")
        XCTAssertEqual(properties.autoRecalc, .onChange)
        XCTAssertEqual(properties.timeZone, "America/New_York")
        XCTAssertEqual(properties.importFunctionsExternalUrlAccessAllowed, true)
        XCTAssertNil(properties.defaultFormat)
        XCTAssertNil(properties.iterativeCalculationSettings)
        XCTAssertNil(properties.spreadsheetTheme)
    }
    
    func testSpreadsheetPropertiesDefaultInitialization() {
        let properties = SpreadsheetProperties()
        
        XCTAssertNil(properties.title)
        XCTAssertNil(properties.locale)
        XCTAssertNil(properties.autoRecalc)
        XCTAssertNil(properties.timeZone)
        XCTAssertNil(properties.defaultFormat)
        XCTAssertNil(properties.iterativeCalculationSettings)
        XCTAssertNil(properties.spreadsheetTheme)
        XCTAssertNil(properties.importFunctionsExternalUrlAccessAllowed)
    }
    
    func testSpreadsheetPropertiesCodable() throws {
        let original = SpreadsheetProperties(
            title: "Test Sheet",
            locale: "fr_FR",
            autoRecalc: .onChangeAndMinute,
            timeZone: "Europe/Paris"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SpreadsheetProperties.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - Sheet Tests
    
    func testSheetInitialization() {
        let sheetProperties = SheetProperties(sheetId: 0, title: "Sheet1", index: 0)
        let gridData = [GridData()]
        let sheet = Sheet(
            properties: sheetProperties,
            data: gridData
        )
        
        XCTAssertEqual(sheet.properties?.sheetId, 0)
        XCTAssertEqual(sheet.properties?.title, "Sheet1")
        XCTAssertEqual(sheet.data?.count, 1)
        XCTAssertNil(sheet.merges)
        XCTAssertNil(sheet.conditionalFormats)
    }
    
    func testSheetDefaultInitialization() {
        let sheet = Sheet()
        
        XCTAssertNil(sheet.properties)
        XCTAssertNil(sheet.data)
        XCTAssertNil(sheet.merges)
        XCTAssertNil(sheet.conditionalFormats)
        XCTAssertNil(sheet.filterViews)
        XCTAssertNil(sheet.protectedRanges)
        XCTAssertNil(sheet.basicFilter)
        XCTAssertNil(sheet.charts)
        XCTAssertNil(sheet.bandedRanges)
        XCTAssertNil(sheet.developerMetadata)
        XCTAssertNil(sheet.rowGroups)
        XCTAssertNil(sheet.columnGroups)
        XCTAssertNil(sheet.slicers)
        XCTAssertNil(sheet.tables)
    }
    
    func testSheetCodable() throws {
        let properties = SheetProperties(sheetId: 1, title: "Test Sheet")
        let original = Sheet(properties: properties)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Sheet.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - SheetProperties Tests
    
    func testSheetPropertiesInitialization() {
        let properties = SheetProperties(
            sheetId: 123,
            title: "My Sheet",
            index: 1,
            sheetType: .grid,
            hidden: false,
            rightToLeft: false
        )
        
        XCTAssertEqual(properties.sheetId, 123)
        XCTAssertEqual(properties.title, "My Sheet")
        XCTAssertEqual(properties.index, 1)
        XCTAssertEqual(properties.sheetType, .grid)
        XCTAssertEqual(properties.hidden, false)
        XCTAssertEqual(properties.rightToLeft, false)
        XCTAssertNil(properties.gridProperties)
        XCTAssertNil(properties.tabColor)
        XCTAssertNil(properties.tabColorStyle)
        XCTAssertNil(properties.dataSourceSheetProperties)
    }
    
    func testSheetPropertiesDefaultInitialization() {
        let properties = SheetProperties()
        
        XCTAssertNil(properties.sheetId)
        XCTAssertNil(properties.title)
        XCTAssertNil(properties.index)
        XCTAssertNil(properties.sheetType)
        XCTAssertNil(properties.gridProperties)
        XCTAssertNil(properties.hidden)
        XCTAssertNil(properties.tabColor)
        XCTAssertNil(properties.tabColorStyle)
        XCTAssertNil(properties.rightToLeft)
        XCTAssertNil(properties.dataSourceSheetProperties)
    }
    
    func testSheetPropertiesCodable() throws {
        let original = SheetProperties(
            sheetId: 456,
            title: "Codable Test",
            index: 2,
            sheetType: .object
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SheetProperties.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - SheetType Tests
    
    func testSheetTypeRawValues() {
        XCTAssertEqual(SheetType.sheetTypeUnspecified.rawValue, "SHEET_TYPE_UNSPECIFIED")
        XCTAssertEqual(SheetType.grid.rawValue, "GRID")
        XCTAssertEqual(SheetType.object.rawValue, "OBJECT")
        XCTAssertEqual(SheetType.dataSource.rawValue, "DATA_SOURCE")
    }
    
    func testSheetTypeFromRawValue() {
        XCTAssertEqual(SheetType(rawValue: "SHEET_TYPE_UNSPECIFIED"), .sheetTypeUnspecified)
        XCTAssertEqual(SheetType(rawValue: "GRID"), .grid)
        XCTAssertEqual(SheetType(rawValue: "OBJECT"), .object)
        XCTAssertEqual(SheetType(rawValue: "DATA_SOURCE"), .dataSource)
        XCTAssertNil(SheetType(rawValue: "INVALID"))
    }
    
    func testSheetTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding
        let gridData = try encoder.encode(SheetType.grid)
        let gridString = String(data: gridData, encoding: .utf8)
        XCTAssertEqual(gridString, "\"GRID\"")
        
        // Test decoding
        let decodedGrid = try decoder.decode(SheetType.self, from: gridData)
        XCTAssertEqual(decodedGrid, .grid)
    }
    
    func testSheetTypeAllCases() {
        let allCases = SheetType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.sheetTypeUnspecified))
        XCTAssertTrue(allCases.contains(.grid))
        XCTAssertTrue(allCases.contains(.object))
        XCTAssertTrue(allCases.contains(.dataSource))
    }
    
    func testSheetTypeDescription() {
        XCTAssertEqual(SheetType.sheetTypeUnspecified.description, "Unspecified sheet type")
        XCTAssertEqual(SheetType.grid.description, "Grid sheet")
        XCTAssertEqual(SheetType.object.description, "Object sheet")
        XCTAssertEqual(SheetType.dataSource.description, "Data source sheet")
    }
    
    // MARK: - Request Models Tests
    
    func testSpreadsheetCreateRequest() throws {
        let properties = SpreadsheetProperties(title: "New Spreadsheet")
        let sheet = Sheet(properties: SheetProperties(title: "Sheet1"))
        let request = SpreadsheetCreateRequest(
            properties: properties,
            sheets: [sheet]
        )
        
        XCTAssertEqual(request.properties?.title, "New Spreadsheet")
        XCTAssertEqual(request.sheets?.count, 1)
        XCTAssertEqual(request.sheets?.first?.properties?.title, "Sheet1")
        XCTAssertNil(request.namedRanges)
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(SpreadsheetCreateRequest.self, from: data)
        
        XCTAssertEqual(request, decoded)
    }
    
    func testSpreadsheetCreateRequestDefaultInit() {
        let request = SpreadsheetCreateRequest()
        
        XCTAssertNil(request.properties)
        XCTAssertNil(request.sheets)
        XCTAssertNil(request.namedRanges)
    }
    
    func testBatchUpdateRequest() throws {
        let request = BatchUpdateRequest()
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(BatchUpdateRequest.self, from: data)
        
        XCTAssertEqual(request, decoded)
    }
    
    func testBatchUpdateSpreadsheetResponse() throws {
        let spreadsheet = Spreadsheet(spreadsheetId: "test-id")
        let response = BatchUpdateSpreadsheetResponse(
            spreadsheetId: "test-id",
            replies: [Response()],
            updatedSpreadsheet: spreadsheet
        )
        
        XCTAssertEqual(response.spreadsheetId, "test-id")
        XCTAssertEqual(response.replies?.count, 1)
        XCTAssertEqual(response.updatedSpreadsheet?.spreadsheetId, "test-id")
        
        // Test Codable
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(response)
        let decoded = try decoder.decode(BatchUpdateSpreadsheetResponse.self, from: data)
        
        XCTAssertEqual(response, decoded)
    }
    
    // MARK: - Placeholder Types Tests
    
    func testPlaceholderTypesCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test all placeholder types can be encoded/decoded
        let cellFormat = CellFormat()
        let cellFormatData = try encoder.encode(cellFormat)
        let decodedCellFormat = try decoder.decode(CellFormat.self, from: cellFormatData)
        XCTAssertEqual(cellFormat, decodedCellFormat)
        
        let iterativeSettings = IterativeCalculationSettings()
        let iterativeData = try encoder.encode(iterativeSettings)
        let decodedIterative = try decoder.decode(IterativeCalculationSettings.self, from: iterativeData)
        XCTAssertEqual(iterativeSettings, decodedIterative)
        
        let theme = SpreadsheetTheme()
        let themeData = try encoder.encode(theme)
        let decodedTheme = try decoder.decode(SpreadsheetTheme.self, from: themeData)
        XCTAssertEqual(theme, decodedTheme)
        
        let namedRange = NamedRange()
        let namedRangeData = try encoder.encode(namedRange)
        let decodedNamedRange = try decoder.decode(NamedRange.self, from: namedRangeData)
        XCTAssertEqual(namedRange, decodedNamedRange)
        
        let developerMetadata = DeveloperMetadata()
        let metadataData = try encoder.encode(developerMetadata)
        let decodedMetadata = try decoder.decode(DeveloperMetadata.self, from: metadataData)
        XCTAssertEqual(developerMetadata, decodedMetadata)
    }
    
    // MARK: - Integration Tests
    
    func testComplexSpreadsheetStructure() throws {
        // Create a complex spreadsheet structure
        let gridProperties = GridProperties()
        let sheetProperties1 = SheetProperties(
            sheetId: 0,
            title: "Data Sheet",
            index: 0,
            sheetType: .grid,
            gridProperties: gridProperties,
            hidden: false
        )
        
        let sheetProperties2 = SheetProperties(
            sheetId: 1,
            title: "Chart Sheet",
            index: 1,
            sheetType: .object,
            hidden: false
        )
        
        let sheet1 = Sheet(
            properties: sheetProperties1,
            data: [GridData()],
            charts: [EmbeddedChart()]
        )
        
        let sheet2 = Sheet(
            properties: sheetProperties2,
            charts: [EmbeddedChart(), EmbeddedChart()]
        )
        
        let spreadsheetProperties = SpreadsheetProperties(
            title: "Complex Spreadsheet",
            locale: "en_US",
            autoRecalc: .onChange,
            timeZone: "America/New_York"
        )
        
        let spreadsheet = Spreadsheet(
            spreadsheetId: "complex-test-id",
            properties: spreadsheetProperties,
            sheets: [sheet1, sheet2],
            namedRanges: [NamedRange()],
            spreadsheetUrl: "https://docs.google.com/spreadsheets/d/complex-test-id",
            developerMetadata: [DeveloperMetadata()]
        )
        
        // Test serialization of complex structure
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(spreadsheet)
        let decoded = try decoder.decode(Spreadsheet.self, from: data)
        
        XCTAssertEqual(decoded.spreadsheetId, "complex-test-id")
        XCTAssertEqual(decoded.properties?.title, "Complex Spreadsheet")
        XCTAssertEqual(decoded.sheets?.count, 2)
        XCTAssertEqual(decoded.sheets?[0].properties?.title, "Data Sheet")
        XCTAssertEqual(decoded.sheets?[0].properties?.sheetType, .grid)
        XCTAssertEqual(decoded.sheets?[1].properties?.title, "Chart Sheet")
        XCTAssertEqual(decoded.sheets?[1].properties?.sheetType, .object)
        XCTAssertEqual(decoded.sheets?[1].charts?.count, 2)
        XCTAssertEqual(decoded.namedRanges?.count, 1)
        XCTAssertEqual(decoded.developerMetadata?.count, 1)
    }
    
    func testSpreadsheetCreateRequestWithComplexStructure() throws {
        let properties = SpreadsheetProperties(
            title: "API Created Spreadsheet",
            locale: "ja_JP",
            autoRecalc: .onChangeAndMinute
        )
        
        let sheet1Properties = SheetProperties(
            sheetId: 0,
            title: "Main Data",
            sheetType: .grid
        )
        
        let sheet2Properties = SheetProperties(
            sheetId: 1,
            title: "Analysis",
            sheetType: .grid
        )
        
        let sheets = [
            Sheet(properties: sheet1Properties),
            Sheet(properties: sheet2Properties)
        ]
        
        let request = SpreadsheetCreateRequest(
            properties: properties,
            sheets: sheets,
            namedRanges: [NamedRange()]
        )
        
        // Test that the request can be serialized and deserialized
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(SpreadsheetCreateRequest.self, from: data)
        
        XCTAssertEqual(request, decoded)
        XCTAssertEqual(decoded.properties?.title, "API Created Spreadsheet")
        XCTAssertEqual(decoded.properties?.locale, "ja_JP")
        XCTAssertEqual(decoded.sheets?.count, 2)
        XCTAssertEqual(decoded.namedRanges?.count, 1)
    }
}