import Foundation
@testable import GoogleSheetsSwift

/// Mock OAuth2 token manager for authentication testing
public class MockOAuth2TokenManager: OAuth2TokenManager {
    // MARK: - Mock Configuration
    
    /// Mock access token to return
    public var mockAccessToken = "mock_access_token"
    
    /// Mock refresh token to return
    public var mockRefreshToken = "mock_refresh_token"
    
    /// Mock authentication state
    public var mockIsAuthenticated = true
    
    /// Flag to simulate authentication failures
    public var shouldFailAuthentication = false
    
    /// Flag to simulate token refresh failures
    public var shouldFailRefresh = false
    
    /// Flag to simulate general failures
    public var shouldFail = false
    
    /// Mock error to throw when failures are simulated
    public var mockError: Error = GoogleSheetsError.authenticationFailed("Mock authentication failure")
    
    /// Track number of times getAccessToken was called
    public var getAccessTokenCallCount = 0
    
    /// Track number of times refreshToken was called
    public var refreshTokenCallCount = 0
    
    /// Track number of times authenticate was called
    public var authenticateCallCount = 0
    
    /// Track number of times clearTokens was called
    public var clearTokensCallCount = 0
    
    /// Track the scopes passed to authenticate method
    public var lastAuthenticateScopes: [String]?
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - OAuth2TokenManager Implementation
    
    public var isAuthenticated: Bool {
        return mockIsAuthenticated && !shouldFail && !shouldFailAuthentication
    }
    
    public func getAccessToken() async throws -> String {
        getAccessTokenCallCount += 1
        
        if shouldFail || shouldFailAuthentication {
            throw mockError
        }
        
        if !mockIsAuthenticated {
            throw GoogleSheetsError.tokenExpired
        }
        
        return mockAccessToken
    }
    
    public func refreshToken() async throws -> String {
        refreshTokenCallCount += 1
        
        if shouldFail || shouldFailRefresh {
            throw mockError
        }
        
        if !mockIsAuthenticated {
            throw GoogleSheetsError.authenticationFailed("No refresh token available")
        }
        
        // Simulate successful refresh by returning new token
        mockAccessToken = "refreshed_\(mockAccessToken)"
        return mockAccessToken
    }
    
    public func authenticate(scopes: [String]) async throws -> AuthResult {
        authenticateCallCount += 1
        lastAuthenticateScopes = scopes
        
        if shouldFail || shouldFailAuthentication {
            throw mockError
        }
        
        // Simulate successful authentication
        mockIsAuthenticated = true
        
        return AuthResult(
            accessToken: mockAccessToken,
            refreshToken: mockRefreshToken,
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: scopes.joined(separator: " ")
        )
    }
    
    public func clearTokens() async throws {
        clearTokensCallCount += 1
        
        if shouldFail {
            throw mockError
        }
        
        // Simulate clearing tokens
        mockIsAuthenticated = false
        mockAccessToken = "cleared_token"
        mockRefreshToken = "cleared_refresh_token"
    }
    
    // MARK: - Mock Configuration Methods
    
    /// Reset all mock state and counters
    public func reset() {
        mockAccessToken = "mock_access_token"
        mockRefreshToken = "mock_refresh_token"
        mockIsAuthenticated = true
        shouldFailAuthentication = false
        shouldFailRefresh = false
        shouldFail = false
        mockError = GoogleSheetsError.authenticationFailed("Mock authentication failure")
        
        // Reset counters
        getAccessTokenCallCount = 0
        refreshTokenCallCount = 0
        authenticateCallCount = 0
        clearTokensCallCount = 0
        lastAuthenticateScopes = nil
    }
    
    /// Configure the mock to simulate an authenticated state
    public func setAuthenticated(accessToken: String = "mock_access_token", refreshToken: String = "mock_refresh_token") {
        mockAccessToken = accessToken
        mockRefreshToken = refreshToken
        mockIsAuthenticated = true
        shouldFailAuthentication = false
        shouldFailRefresh = false
        shouldFail = false
    }
    
    /// Configure the mock to simulate an unauthenticated state
    public func setUnauthenticated() {
        mockIsAuthenticated = false
        mockAccessToken = ""
        mockRefreshToken = ""
    }
    
    /// Configure the mock to simulate authentication failures
    public func setAuthenticationFailure(error: Error? = nil) {
        shouldFailAuthentication = true
        if let error = error {
            mockError = error
        }
    }
    
    /// Configure the mock to simulate token refresh failures
    public func setRefreshFailure(error: Error? = nil) {
        shouldFailRefresh = true
        if let error = error {
            mockError = error
        }
    }
    
    /// Configure the mock to simulate expired tokens
    public func setTokenExpired() {
        mockIsAuthenticated = false
        mockError = GoogleSheetsError.tokenExpired
    }
    
    /// Configure the mock to simulate rate limiting
    public func setRateLimited(retryAfter: TimeInterval = 60) {
        shouldFail = true
        mockError = GoogleSheetsError.rateLimitExceeded(retryAfter: retryAfter)
    }
    
    /// Configure the mock to simulate network errors
    public func setNetworkError() {
        shouldFail = true
        mockError = GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
    }
}

// MARK: - Convenience Factory Methods

extension MockOAuth2TokenManager {
    /// Create a mock token manager in authenticated state
    public static func authenticated(accessToken: String = "mock_access_token") -> MockOAuth2TokenManager {
        let mock = MockOAuth2TokenManager()
        mock.setAuthenticated(accessToken: accessToken)
        return mock
    }
    
    /// Create a mock token manager in unauthenticated state
    public static func unauthenticated() -> MockOAuth2TokenManager {
        let mock = MockOAuth2TokenManager()
        mock.setUnauthenticated()
        return mock
    }
    
    /// Create a mock token manager that fails authentication
    public static func authenticationFailed(error: Error? = nil) -> MockOAuth2TokenManager {
        let mock = MockOAuth2TokenManager()
        mock.setAuthenticationFailure(error: error)
        return mock
    }
    
    /// Create a mock token manager with expired tokens
    public static func tokenExpired() -> MockOAuth2TokenManager {
        let mock = MockOAuth2TokenManager()
        mock.setTokenExpired()
        return mock
    }
}