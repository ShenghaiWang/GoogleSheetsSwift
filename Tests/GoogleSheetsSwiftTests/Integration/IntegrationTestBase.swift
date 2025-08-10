import XCTest
import Foundation
@testable import GoogleSheetsSwift

/// Base class for integration tests that run against the real Google Sheets API
open class IntegrationTestBase: XCTestCase {
    
    // MARK: - Properties
    
    /// Integration test configuration
    public static let config = IntegrationTestConfig.fromEnvironment()
    
    /// Google Sheets client for testing
    public var client: GoogleSheetsClient!
    
    /// Test spreadsheet ID (either from config or created during test)
    public var testSpreadsheetId: String!
    
    /// Whether this test created its own spreadsheet (needs cleanup)
    public var shouldCleanupSpreadsheet = false
    
    /// Test data used across tests
    public var testData: TestSpreadsheetData!
    
    // MARK: - Test Lifecycle
    
    override open func setUp() {
        super.setUp()
        
        // Skip integration tests if not configured
        guard Self.config.shouldRunIntegrationTests else {
            // We can't throw XCTSkip from setUp, so we'll set a flag and skip in individual tests
            return
        }
        
        // Set up the client based on available credentials
        setupClient()
        
        // Set up test spreadsheet
        setupTestSpreadsheet()
        
        // Initialize test data
        testData = TestSpreadsheetData()
    }
    
    /// Check if integration tests should be skipped and throw XCTSkip if so
    public func skipIfNotConfigured() throws {
        guard Self.config.shouldRunIntegrationTests else {
            throw XCTSkip("Integration tests are disabled. Set environment variables to enable.")
        }
    }
    
    override open func tearDown() {
        // Clean up test spreadsheet if we created it
        if shouldCleanupSpreadsheet, let spreadsheetId = testSpreadsheetId {
            cleanupTestSpreadsheet(spreadsheetId)
        }
        
        super.tearDown()
    }
    
    // MARK: - Setup Methods
    
    private func setupClient() {
        if Self.config.hasOAuth2Config {
            // Use OAuth2 for full access
            let tokenManager = TestOAuth2TokenManager(
                clientId: Self.config.clientId!,
                clientSecret: Self.config.clientSecret!,
                refreshToken: Self.config.refreshToken!
            )
            client = GoogleSheetsClient(tokenManager: tokenManager)
        } else if Self.config.hasAPIKey {
            // Use API key for read-only access
            client = GoogleSheetsClient(apiKey: Self.config.apiKey!)
        } else {
            XCTFail("No valid credentials configured for integration tests")
        }
    }
    
    private func setupTestSpreadsheet() {
        if Self.config.hasTestSpreadsheet {
            // Use existing test spreadsheet
            testSpreadsheetId = Self.config.testSpreadsheetId!
            shouldCleanupSpreadsheet = false
        } else if Self.config.hasOAuth2Config {
            // Create a new test spreadsheet
            createTestSpreadsheet()
        } else {
            XCTFail("No test spreadsheet configured and no OAuth2 credentials to create one")
        }
    }
    
    private func createTestSpreadsheet() {
        let expectation = expectation(description: "Create test spreadsheet")
        
        Task {
            do {
                let request = SpreadsheetCreateRequest(
                    properties: SpreadsheetProperties(
                        title: "GoogleSheetsSwift Integration Test - \(Date().timeIntervalSince1970)"
                    )
                )
                
                let spreadsheet = try await client.spreadsheets.create(request)
                
                DispatchQueue.main.async {
                    self.testSpreadsheetId = spreadsheet.spreadsheetId
                    self.shouldCleanupSpreadsheet = true
                    expectation.fulfill()
                }
            } catch {
                DispatchQueue.main.async {
                    XCTFail("Failed to create test spreadsheet: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: Self.config.operationTimeout)
    }
    
    private func cleanupTestSpreadsheet(_ spreadsheetId: String) {
        // Note: Google Sheets API doesn't provide a delete endpoint for spreadsheets
        // In a real implementation, you might want to:
        // 1. Clear all data from the spreadsheet
        // 2. Rename it to indicate it's for deletion
        // 3. Use Google Drive API to delete it (requires additional scope)
        
        print("⚠️ Test spreadsheet \(spreadsheetId) should be manually deleted")
    }
    
    // MARK: - Helper Methods
    
    /// Execute an async operation with timeout
    public func executeWithTimeout<T>(
        timeout: TimeInterval? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let timeoutInterval = timeout ?? Self.config.operationTimeout
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutInterval * 1_000_000_000))
                throw IntegrationTestError.timeout
            }
            
            guard let result = try await group.next() else {
                throw IntegrationTestError.noResult
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Wait for a condition to be true with timeout
    public func waitForCondition(
        timeout: TimeInterval = 10.0,
        interval: TimeInterval = 0.5,
        condition: @escaping () async throws -> Bool
    ) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if try await condition() {
                return
            }
            
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        throw IntegrationTestError.conditionTimeout
    }
    
    /// Generate a unique range name for testing
    public func generateTestRange(sheet: String = "Sheet1", rows: Int = 10, columns: Int = 5) -> String {
        let endColumn = String(Character(UnicodeScalar(65 + columns - 1)!))
        return "\(sheet)!A1:\(endColumn)\(rows)"
    }
    
    /// Create test data for a range
    public func createTestData(rows: Int, columns: Int) -> [[AnyCodable]] {
        var data: [[AnyCodable]] = []
        
        for row in 1...rows {
            var rowData: [AnyCodable] = []
            for col in 1...columns {
                rowData.append(AnyCodable("Test_R\(row)C\(col)_\(Date().timeIntervalSince1970)"))
            }
            data.append(rowData)
        }
        
        return data
    }
}

// MARK: - Test OAuth2 Token Manager

/// Simple OAuth2 token manager for integration tests that uses a pre-configured refresh token
private class TestOAuth2TokenManager: OAuth2TokenManager {
    private let clientId: String
    private let clientSecret: String
    private let refreshToken: String
    private var accessToken: String?
    private var tokenExpiration: Date?
    
    init(clientId: String, clientSecret: String, refreshToken: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.refreshToken = refreshToken
    }
    
    var isAuthenticated: Bool {
        guard let expiration = tokenExpiration else { return false }
        return Date() < expiration.addingTimeInterval(-300) // 5 minute buffer
    }
    
    func getAccessToken() async throws -> String {
        if let token = accessToken, isAuthenticated {
            return token
        }
        
        return try await refreshTokens()
    }
    
    func refreshToken() async throws -> String {
        return try await refreshTokens()
    }
    
    private func refreshTokens() async throws -> String {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw IntegrationTestError.authenticationFailed("HTTP \(httpResponse.statusCode)")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
        
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
        
        return tokenResponse.accessToken
    }
    
    func authenticate(scopes: [String]) async throws -> AuthResult {
        let token = try await getAccessToken()
        return AuthResult(
            accessToken: token,
            refreshToken: refreshToken,
            expiresIn: tokenExpiration?.timeIntervalSinceNow,
            tokenType: "Bearer",
            scope: scopes.joined(separator: " ")
        )
    }
    
    func clearTokens() async throws {
        accessToken = nil
        tokenExpiration = nil
    }
}

// MARK: - Supporting Types

/// Test data structure for integration tests
public struct TestSpreadsheetData {
    public let sampleData: [[AnyCodable]]
    public let headerRow: [AnyCodable]
    public let numericData: [[AnyCodable]]
    
    public init() {
        self.headerRow = [
            AnyCodable("Name"),
            AnyCodable("Age"),
            AnyCodable("City"),
            AnyCodable("Active")
        ]
        
        self.sampleData = [
            headerRow,
            [AnyCodable("John Doe"), AnyCodable(30), AnyCodable("New York"), AnyCodable(true)],
            [AnyCodable("Jane Smith"), AnyCodable(25), AnyCodable("Los Angeles"), AnyCodable(false)],
            [AnyCodable("Bob Johnson"), AnyCodable(35), AnyCodable("Chicago"), AnyCodable(true)]
        ]
        
        self.numericData = [
            [AnyCodable("Value1"), AnyCodable("Value2"), AnyCodable("Sum")],
            [AnyCodable(10), AnyCodable(20), AnyCodable("=A2+B2")],
            [AnyCodable(15), AnyCodable(25), AnyCodable("=A3+B3")],
            [AnyCodable(5), AnyCodable(10), AnyCodable("=A4+B4")]
        ]
    }
}

/// Token refresh response model
private struct TokenRefreshResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/// Integration test specific errors
public enum IntegrationTestError: Error, LocalizedError {
    case timeout
    case noResult
    case conditionTimeout
    case invalidResponse
    case authenticationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Integration test operation timed out"
        case .noResult:
            return "Integration test operation returned no result"
        case .conditionTimeout:
            return "Condition wait timed out"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}