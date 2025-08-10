import Foundation
@testable import GoogleSheetsSwift

/// Configuration for integration tests
public struct IntegrationTestConfig {
    /// Google Sheets API key for read-only operations
    public let apiKey: String?
    
    /// OAuth2 client credentials for full access operations
    public let clientId: String?
    public let clientSecret: String?
    public let refreshToken: String?
    
    /// Test spreadsheet ID to use for integration tests
    public let testSpreadsheetId: String?
    
    /// Whether integration tests should run
    public let shouldRunIntegrationTests: Bool
    
    /// Base URL for Google Sheets API (for testing against different environments)
    public let baseURL: String
    
    /// Timeout for integration test operations
    public let operationTimeout: TimeInterval
    
    public init(
        apiKey: String? = nil,
        clientId: String? = nil,
        clientSecret: String? = nil,
        refreshToken: String? = nil,
        testSpreadsheetId: String? = nil,
        shouldRunIntegrationTests: Bool = false,
        baseURL: String = "https://sheets.googleapis.com/v4",
        operationTimeout: TimeInterval = 30.0
    ) {
        self.apiKey = apiKey
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.refreshToken = refreshToken
        self.testSpreadsheetId = testSpreadsheetId
        self.shouldRunIntegrationTests = shouldRunIntegrationTests
        self.baseURL = baseURL
        self.operationTimeout = operationTimeout
    }
    
    /// Load configuration from environment variables
    public static func fromEnvironment() -> IntegrationTestConfig {
        let apiKey = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_API_KEY"]
        let clientId = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_CLIENT_ID"]
        let clientSecret = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_CLIENT_SECRET"]
        let refreshToken = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_REFRESH_TOKEN"]
        let testSpreadsheetId = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_TEST_SPREADSHEET_ID"]
        let baseURL = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_BASE_URL"] ?? "https://sheets.googleapis.com/v4"
        
        // Integration tests should run if we have either API key or OAuth credentials
        let shouldRun = apiKey != nil || (clientId != nil && clientSecret != nil && refreshToken != nil)
        
        let timeoutString = ProcessInfo.processInfo.environment["GOOGLE_SHEETS_TEST_TIMEOUT"]
        let timeout = timeoutString.flatMap(Double.init) ?? 30.0
        
        return IntegrationTestConfig(
            apiKey: apiKey,
            clientId: clientId,
            clientSecret: clientSecret,
            refreshToken: refreshToken,
            testSpreadsheetId: testSpreadsheetId,
            shouldRunIntegrationTests: shouldRun,
            baseURL: baseURL,
            operationTimeout: timeout
        )
    }
    
    /// Check if we have valid API key configuration
    public var hasAPIKey: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    /// Check if we have valid OAuth2 configuration
    public var hasOAuth2Config: Bool {
        return clientId != nil && !clientId!.isEmpty &&
               clientSecret != nil && !clientSecret!.isEmpty &&
               refreshToken != nil && !refreshToken!.isEmpty
    }
    
    /// Check if we have a test spreadsheet configured
    public var hasTestSpreadsheet: Bool {
        return testSpreadsheetId != nil && !testSpreadsheetId!.isEmpty
    }
    
    /// Get scopes needed for integration tests
    public static let requiredScopes = [
        "https://www.googleapis.com/auth/spreadsheets"
    ]
}

/// Environment variable names for integration test configuration
public enum IntegrationTestEnvironment {
    public static let apiKey = "GOOGLE_SHEETS_API_KEY"
    public static let clientId = "GOOGLE_SHEETS_CLIENT_ID"
    public static let clientSecret = "GOOGLE_SHEETS_CLIENT_SECRET"
    public static let refreshToken = "GOOGLE_SHEETS_REFRESH_TOKEN"
    public static let testSpreadsheetId = "GOOGLE_SHEETS_TEST_SPREADSHEET_ID"
    public static let baseURL = "GOOGLE_SHEETS_BASE_URL"
    public static let testTimeout = "GOOGLE_SHEETS_TEST_TIMEOUT"
    public static let runIntegrationTests = "RUN_INTEGRATION_TESTS"
}