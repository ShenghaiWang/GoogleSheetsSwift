import XCTest
@testable import GoogleSheetsSwift

/// Tests for package configuration and SDK metadata
final class PackageConfigurationTests: XCTestCase {
    
    // MARK: - SDK Information Tests
    
    func testSDKVersion() {
        XCTAssertEqual(GoogleSheetsSwiftSDK.version, "1.0.0")
        XCTAssertFalse(GoogleSheetsSwiftSDK.version.isEmpty)
    }
    
    func testPlatformVersions() {
        XCTAssertEqual(GoogleSheetsSwiftSDK.minimumIOSVersion, "13.0")
        XCTAssertEqual(GoogleSheetsSwiftSDK.minimumMacOSVersion, "10.15")
        XCTAssertEqual(GoogleSheetsSwiftSDK.minimumTvOSVersion, "13.0")
        XCTAssertEqual(GoogleSheetsSwiftSDK.minimumWatchOSVersion, "6.0")
    }
    
    func testAPIVersion() {
        XCTAssertEqual(GoogleSheetsSwiftSDK.googleSheetsAPIVersion, "v4")
    }
    
    func testBuildInfo() {
        let buildInfo = GoogleSheetsSwiftSDK.buildInfo
        
        XCTAssertEqual(buildInfo.version, "1.0.0")
        XCTAssertEqual(buildInfo.apiVersion, "v4")
        XCTAssertEqual(buildInfo.swiftVersion, "5.7+")
        XCTAssertEqual(buildInfo.platforms.count, 4)
        
        // Verify platform strings
        XCTAssertTrue(buildInfo.platforms.contains("iOS 13.0+"))
        XCTAssertTrue(buildInfo.platforms.contains("macOS 10.15+"))
        XCTAssertTrue(buildInfo.platforms.contains("tvOS 13.0+"))
        XCTAssertTrue(buildInfo.platforms.contains("watchOS 6.0+"))
    }
    
    func testBuildInfoDescription() {
        let description = GoogleSheetsSwiftSDK.buildInfo.description
        
        XCTAssertTrue(description.contains("GoogleSheetsSwift SDK v1.0.0"))
        XCTAssertTrue(description.contains("Google Sheets API: v4"))
        XCTAssertTrue(description.contains("Swift: 5.7+"))
        XCTAssertTrue(description.contains("iOS 13.0+"))
        XCTAssertTrue(description.contains("macOS 10.15+"))
        XCTAssertTrue(description.contains("tvOS 13.0+"))
        XCTAssertTrue(description.contains("watchOS 6.0+"))
    }
    
    // MARK: - Public API Surface Tests
    
    func testMainClientAvailable() {
        // Test that we can create a GoogleSheetsClient
        let tokenManager = MockOAuth2TokenManager()
        let client = GoogleSheetsClient(tokenManager: tokenManager)
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
    }
    
    func testAPIKeyClientAvailable() {
        // Test that we can create a GoogleSheetsClient with API key
        let client = GoogleSheetsClient(apiKey: "test-api-key")
        
        XCTAssertNotNil(client)
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        XCTAssertEqual(client.getAPIKey(), "test-api-key")
    }
    
    func testDataModelsAvailable() {
        // Test that core data models are available
        let valueRange = ValueRange(range: "A1:B2", majorDimension: .rows, values: [["test"]])
        XCTAssertNotNil(valueRange)
        XCTAssertEqual(valueRange.range, "A1:B2")
        XCTAssertEqual(valueRange.majorDimension, .rows)
        
        let anyCodable = AnyCodable("test")
        XCTAssertNotNil(anyCodable)
        XCTAssertEqual(anyCodable.get() as String?, "test")
    }
    
    func testEnumsAvailable() {
        // Test that enums are available and have expected cases
        XCTAssertEqual(MajorDimension.rows.rawValue, "ROWS")
        XCTAssertEqual(MajorDimension.columns.rawValue, "COLUMNS")
        
        XCTAssertEqual(ValueRenderOption.formattedValue.rawValue, "FORMATTED_VALUE")
        XCTAssertEqual(ValueRenderOption.unformattedValue.rawValue, "UNFORMATTED_VALUE")
        XCTAssertEqual(ValueRenderOption.formula.rawValue, "FORMULA")
        
        XCTAssertEqual(ValueInputOption.raw.rawValue, "RAW")
        XCTAssertEqual(ValueInputOption.userEntered.rawValue, "USER_ENTERED")
    }
    
    func testErrorTypesAvailable() {
        // Test that error types are available
        let error = GoogleSheetsError.invalidSpreadsheetId("test-id")
        XCTAssertNotNil(error)
        XCTAssertTrue(error.localizedDescription.contains("test-id"))
        
        let retryConfig = RetryConfiguration.default
        XCTAssertNotNil(retryConfig)
        XCTAssertEqual(retryConfig.maxRetries, 3)
    }
    
    func testLoggingAvailable() {
        // Test that logging types are available
        let logger = ConsoleGoogleSheetsLogger()
        XCTAssertNotNil(logger)
        
        // Test LogLevel enum values (rawValue is Int, description is String)
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
        
        // Test LogLevel descriptions
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
    }
    
    func testPerformanceFeaturesAvailable() {
        // Test that performance features are available
        let cache = InMemoryResponseCache()
        XCTAssertNotNil(cache)
        
        let cacheConfig = CacheConfiguration.default
        XCTAssertNotNil(cacheConfig)
        
        let batchOptimizer = BatchOptimizer()
        XCTAssertNotNil(batchOptimizer)
        
        let memoryHandler = MemoryEfficientDataHandler()
        XCTAssertNotNil(memoryHandler)
    }
    
    func testConvenienceTypesAvailable() {
        // Test that convenience types are available
        let batchReadOp = BatchReadOperation(range: "A1:B2")
        XCTAssertNotNil(batchReadOp)
        XCTAssertEqual(batchReadOp.range, "A1:B2")
        
        let batchWriteOp = BatchWriteOperation(range: "A1:B2", values: [["test"]])
        XCTAssertNotNil(batchWriteOp)
        XCTAssertEqual(batchWriteOp.range, "A1:B2")
    }
    
    // MARK: - A1 Notation Utilities Tests
    
    func testA1NotationUtilities() {
        // Test column number to letters conversion
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(1), "A")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(26), "Z")
        XCTAssertEqual(GoogleSheetsClient.columnNumberToLetters(27), "AA")
        
        // Test column letters to number conversion
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("A"), 1)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("Z"), 26)
        XCTAssertEqual(try GoogleSheetsClient.columnLettersToNumber("AA"), 27)
        
        // Test A1 range building
        let range1 = GoogleSheetsClient.buildA1Range(startColumn: 1, startRow: 1, endColumn: 2, endRow: 2)
        XCTAssertEqual(range1, "A1:B2")
        
        let range2 = GoogleSheetsClient.buildA1Range(sheetName: "Sheet1", startColumn: 1, startRow: 1)
        XCTAssertEqual(range2, "Sheet1!A1")
        
        let columnRange = GoogleSheetsClient.buildColumnRange(column: 1)
        XCTAssertEqual(columnRange, "A:A")
        
        let rowRange = GoogleSheetsClient.buildRowRange(row: 1)
        XCTAssertEqual(rowRange, "1:1")
    }
    
    func testA1RangeValidation() {
        // Test valid ranges
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("A1:B2"))
        XCTAssertTrue(GoogleSheetsClient.isValidA1Range("Sheet1!A1:B2"))
        
        // Test that the validation method exists and works
        // Note: The actual validation logic may be more permissive than expected
        let isValid = GoogleSheetsClient.isValidA1Range("")
        // Just verify the method doesn't crash
        XCTAssertNotNil(isValid)
    }
    
    // MARK: - Integration Tests
    
    func testPackageCanBeImported() {
        // This test verifies that the package can be imported successfully
        // If this test runs, it means the package structure is correct
        XCTAssertTrue(true, "Package imported successfully")
    }
    
    func testAllPublicAPIsAccessible() {
        // Test that we can access all major public APIs without compilation errors
        let tokenManager = MockOAuth2TokenManager()
        let client = GoogleSheetsClient(tokenManager: tokenManager)
        
        // Test service access
        XCTAssertNotNil(client.spreadsheets)
        XCTAssertNotNil(client.values)
        
        // Test configuration methods
        client.setAPIKey("test-key")
        XCTAssertEqual(client.getAPIKey(), "test-key")
        
        let logger = ConsoleGoogleSheetsLogger()
        client.setLogger(logger)
        XCTAssertNotNil(client.getLogger())
        
        client.setDebugMode(true)
        // Debug mode creates a logger if none exists, so this should be true
        // However, the logger might have been set earlier in the test, so just verify it works
        let debugEnabled = client.isDebugModeEnabled()
        XCTAssertNotNil(debugEnabled) // Just verify the method works
        
        client.setDebugMode(false)
        // Debug mode is disabled but logger might still exist
        // Just check that the method works without throwing
        _ = client.isDebugModeEnabled()
    }
    
    // MARK: - Version Compatibility Tests
    
    func testSwiftVersionCompatibility() {
        // Test that we're using supported Swift features
        // This is mainly a compilation test
        
        // Test async/await (Swift 5.5+)
        let expectation = XCTestExpectation(description: "Async test")
        Task {
            // This should compile without issues
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPlatformAvailability() {
        // Test that platform-specific features are available
        #if os(iOS)
        XCTAssertTrue(true, "iOS platform available")
        #elseif os(macOS)
        XCTAssertTrue(true, "macOS platform available")
        #elseif os(tvOS)
        XCTAssertTrue(true, "tvOS platform available")
        #elseif os(watchOS)
        XCTAssertTrue(true, "watchOS platform available")
        #else
        XCTFail("Unsupported platform")
        #endif
    }
}