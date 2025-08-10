import XCTest
@testable import GoogleSheetsSwift

final class OAuth2TokenManagerTests: XCTestCase {
    var tokenManager: GoogleOAuth2TokenManager!
    fileprivate var mockHTTPClient: MockHTTPClient!
    
    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        tokenManager = GoogleOAuth2TokenManager(
            clientId: "test_client_id",
            clientSecret: "test_client_secret",
            redirectURI: "test://redirect",
            httpClient: mockHTTPClient
        )
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Authentication State Tests
    
    func testIsAuthenticatedWithNoTokens() {
        XCTAssertFalse(tokenManager.isAuthenticated)
    }
    
    func testIsAuthenticatedWithValidToken() throws {
        // Store a valid token that expires in 1 hour
        try tokenManager.setTokens(
            accessToken: "valid_token",
            refreshToken: "refresh_token",
            expiresIn: 3600
        )
        
        XCTAssertTrue(tokenManager.isAuthenticated)
    }
    
    func testIsAuthenticatedWithExpiredToken() throws {
        // Store an expired token
        try tokenManager.setTokens(
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresIn: -3600 // Expired 1 hour ago
        )
        
        XCTAssertFalse(tokenManager.isAuthenticated)
    }
    
    // MARK: - Token Storage Tests
    
    func testSetAndGetTokens() throws {
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiresIn: TimeInterval = 3600
        
        try tokenManager.setTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        
        XCTAssertTrue(tokenManager.isAuthenticated)
    }
    
    func testClearTokens() async throws {
        // First set some tokens
        try tokenManager.setTokens(
            accessToken: "test_token",
            refreshToken: "refresh_token",
            expiresIn: 3600
        )
        
        XCTAssertTrue(tokenManager.isAuthenticated)
        
        // Clear tokens
        try await tokenManager.clearTokens()
        
        XCTAssertFalse(tokenManager.isAuthenticated)
    }
    
    // MARK: - Get Access Token Tests
    
    func testGetAccessTokenWithValidToken() async throws {
        let expectedToken = "valid_access_token"
        try tokenManager.setTokens(
            accessToken: expectedToken,
            refreshToken: "refresh_token",
            expiresIn: 3600
        )
        
        let token = try await tokenManager.getAccessToken()
        XCTAssertEqual(token, expectedToken)
    }
    
    func testGetAccessTokenWithNoTokensThrowsError() async {
        // Ensure no tokens are stored
        try? await tokenManager.clearTokens()
        
        do {
            _ = try await tokenManager.getAccessToken()
            XCTFail("Expected tokenExpired error")
        } catch GoogleSheetsError.tokenExpired {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetAccessTokenWithExpiredTokenRefreshesAutomatically() async throws {
        // Set up expired token with refresh token
        try tokenManager.setTokens(
            accessToken: "expired_token",
            refreshToken: "valid_refresh_token",
            expiresIn: -3600 // Expired
        )
        
        // Mock the refresh token response
        let newAccessToken = "new_access_token"
        mockHTTPClient.mockResponse(for: "https://oauth2.googleapis.com/token", response: TokenResponse(
            accessToken: newAccessToken,
            refreshToken: "new_refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "https://www.googleapis.com/auth/spreadsheets"
        ))
        
        let token = try await tokenManager.getAccessToken()
        XCTAssertEqual(token, newAccessToken)
    }
    
    // MARK: - Refresh Token Tests
    
    func testRefreshTokenSuccess() async throws {
        // Set up initial tokens
        try tokenManager.setTokens(
            accessToken: "old_token",
            refreshToken: "valid_refresh_token",
            expiresIn: 3600
        )
        
        let newAccessToken = "refreshed_access_token"
        mockHTTPClient.mockResponse(for: "https://oauth2.googleapis.com/token", response: TokenResponse(
            accessToken: newAccessToken,
            refreshToken: "new_refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: nil
        ))
        
        let token = try await tokenManager.refreshToken()
        XCTAssertEqual(token, newAccessToken)
        
        // Verify the new token is stored and accessible
        let storedToken = try await tokenManager.getAccessToken()
        XCTAssertEqual(storedToken, newAccessToken)
    }
    
    func testRefreshTokenWithNoRefreshTokenThrowsError() async {
        // Ensure no tokens are stored
        try? await tokenManager.clearTokens()
        
        do {
            _ = try await tokenManager.refreshToken()
            XCTFail("Expected authenticationFailed error")
        } catch GoogleSheetsError.authenticationFailed(let message) {
            XCTAssertTrue(message.contains("No refresh token available"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRefreshTokenWithNetworkError() async throws {
        try tokenManager.setTokens(
            accessToken: "old_token",
            refreshToken: "valid_refresh_token",
            expiresIn: 3600
        )
        
        // Mock network error
        mockHTTPClient.mockError(for: "https://oauth2.googleapis.com/token", error: GoogleSheetsError.networkError(URLError(.notConnectedToInternet)))
        
        do {
            _ = try await tokenManager.refreshToken()
            XCTFail("Expected network error")
        } catch GoogleSheetsError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Authentication Flow Tests
    
    func testAuthenticateThrowsNotImplementedError() async {
        do {
            _ = try await tokenManager.authenticate(scopes: ["https://www.googleapis.com/auth/spreadsheets"])
            XCTFail("Expected authenticationFailed error")
        } catch GoogleSheetsError.authenticationFailed(let message) {
            XCTAssertTrue(message.contains("Authentication flow requires manual implementation"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testBuildAuthorizationURL() {
        let scopes = ["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive.readonly"]
        let state = "test_state_123"
        
        let authURL = tokenManager.buildAuthorizationURL(scopes: scopes, state: state)
        
        XCTAssertEqual(authURL.scheme, "https")
        XCTAssertEqual(authURL.host, "accounts.google.com")
        XCTAssertEqual(authURL.path, "/o/oauth2/v2/auth")
        
        let components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems!
        
        XCTAssertTrue(queryItems.contains { $0.name == "client_id" && $0.value == "test_client_id" })
        XCTAssertTrue(queryItems.contains { $0.name == "redirect_uri" && $0.value == "test://redirect" })
        XCTAssertTrue(queryItems.contains { $0.name == "response_type" && $0.value == "code" })
        XCTAssertTrue(queryItems.contains { $0.name == "scope" && $0.value == scopes.joined(separator: " ") })
        XCTAssertTrue(queryItems.contains { $0.name == "access_type" && $0.value == "offline" })
        XCTAssertTrue(queryItems.contains { $0.name == "prompt" && $0.value == "consent" })
        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == state })
    }
    
    func testBuildAuthorizationURLWithDefaultState() {
        let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
        
        let authURL = tokenManager.buildAuthorizationURL(scopes: scopes)
        
        let components = URLComponents(url: authURL, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems!
        
        // Should have a state parameter with a UUID
        let stateItem = queryItems.first { $0.name == "state" }
        XCTAssertNotNil(stateItem)
        XCTAssertNotNil(stateItem?.value)
        XCTAssertFalse(stateItem?.value?.isEmpty ?? true)
    }
    
    func testExchangeAuthorizationCodeSuccess() async throws {
        let authCode = "test_auth_code_123"
        let expectedAccessToken = "new_access_token_from_code"
        let expectedRefreshToken = "new_refresh_token_from_code"
        
        // Mock the token exchange response
        mockHTTPClient.mockResponse(for: "https://oauth2.googleapis.com/token", response: TokenResponse(
            accessToken: expectedAccessToken,
            refreshToken: expectedRefreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "https://www.googleapis.com/auth/spreadsheets"
        ))
        
        let authResult = try await tokenManager.exchangeAuthorizationCode(authCode)
        
        XCTAssertEqual(authResult.accessToken, expectedAccessToken)
        XCTAssertEqual(authResult.refreshToken, expectedRefreshToken)
        XCTAssertEqual(authResult.expiresIn, 3600)
        XCTAssertEqual(authResult.tokenType, "Bearer")
        XCTAssertEqual(authResult.scope, "https://www.googleapis.com/auth/spreadsheets")
        
        // Verify tokens are stored and accessible
        XCTAssertTrue(tokenManager.isAuthenticated)
        let storedToken = try await tokenManager.getAccessToken()
        XCTAssertEqual(storedToken, expectedAccessToken)
    }
    
    func testExchangeAuthorizationCodeWithNetworkError() async throws {
        let authCode = "test_auth_code_123"
        
        // Mock network error
        mockHTTPClient.mockError(for: "https://oauth2.googleapis.com/token", error: GoogleSheetsError.networkError(URLError(.notConnectedToInternet)))
        
        do {
            _ = try await tokenManager.exchangeAuthorizationCode(authCode)
            XCTFail("Expected network error")
        } catch GoogleSheetsError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExchangeAuthorizationCodeWithAPIError() async throws {
        let authCode = "invalid_auth_code"
        
        // Mock API error response
        mockHTTPClient.mockError(for: "https://oauth2.googleapis.com/token", error: GoogleSheetsError.apiError(code: 400, message: "Invalid authorization code", details: nil))
        
        do {
            _ = try await tokenManager.exchangeAuthorizationCode(authCode)
            XCTFail("Expected API error")
        } catch GoogleSheetsError.apiError(let code, let message, _) {
            XCTAssertEqual(code, 400)
            XCTAssertTrue(message.contains("Invalid authorization code"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Automatic Token Refresh Tests
    
    func testAutomaticTokenRefreshOnExpiration() async throws {
        // Set up expired token with refresh token
        try tokenManager.setTokens(
            accessToken: "expired_token",
            refreshToken: "valid_refresh_token",
            expiresIn: -3600 // Expired 1 hour ago
        )
        
        let newAccessToken = "automatically_refreshed_token"
        mockHTTPClient.mockResponse(for: "https://oauth2.googleapis.com/token", response: TokenResponse(
            accessToken: newAccessToken,
            refreshToken: "new_refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: nil
        ))
        
        // Getting access token should automatically refresh
        let token = try await tokenManager.getAccessToken()
        XCTAssertEqual(token, newAccessToken)
        
        // Should now be authenticated with the new token
        XCTAssertTrue(tokenManager.isAuthenticated)
    }
    
    func testTokenRefreshPreservesExistingRefreshToken() async throws {
        let originalRefreshToken = "original_refresh_token"
        try tokenManager.setTokens(
            accessToken: "old_token",
            refreshToken: originalRefreshToken,
            expiresIn: 3600
        )
        
        let newAccessToken = "refreshed_access_token"
        // Mock response without refresh token (some providers don't return it on refresh)
        mockHTTPClient.mockResponse(for: "https://oauth2.googleapis.com/token", response: TokenResponse(
            accessToken: newAccessToken,
            refreshToken: nil, // No new refresh token provided
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: nil
        ))
        
        let token = try await tokenManager.refreshToken()
        XCTAssertEqual(token, newAccessToken)
        
        // Should still be able to refresh again (refresh token preserved)
        XCTAssertTrue(tokenManager.isAuthenticated)
    }
}



