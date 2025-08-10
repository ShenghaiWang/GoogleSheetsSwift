import XCTest
@testable import GoogleSheetsSwift
import Foundation

final class GoogleSheetsErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testAuthenticationErrorDescriptions() {
        let authFailed = GoogleSheetsError.authenticationFailed("Invalid token")
        XCTAssertEqual(authFailed.errorDescription, "Authentication failed: Invalid token")
        
        let tokenExpired = GoogleSheetsError.tokenExpired
        XCTAssertEqual(tokenExpired.errorDescription, "Access token has expired. Please re-authenticate.")
        
        let authCancelled = GoogleSheetsError.authenticationCancelled
        XCTAssertEqual(authCancelled.errorDescription, "Authentication was cancelled by the user.")
        
        let invalidCreds = GoogleSheetsError.invalidCredentials("Missing client ID")
        XCTAssertEqual(invalidCreds.errorDescription, "Invalid credentials: Missing client ID")
    }
    
    func testAPIErrorDescriptions() {
        let invalidSpreadsheetId = GoogleSheetsError.invalidSpreadsheetId("invalid-id")
        XCTAssertEqual(invalidSpreadsheetId.errorDescription, "Invalid spreadsheet ID: invalid-id")
        
        let invalidRange = GoogleSheetsError.invalidRange("Z999")
        XCTAssertEqual(invalidRange.errorDescription, "Invalid range specification: Z999. Please use A1 notation (e.g., 'A1:B10').")
        
        let apiError = GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil)
        XCTAssertEqual(apiError.errorDescription, "API error (400): Bad request")
        
        let rateLimitWithRetry = GoogleSheetsError.rateLimitExceeded(retryAfter: 30.0)
        XCTAssertEqual(rateLimitWithRetry.errorDescription, "Rate limit exceeded. Please retry after 30 seconds.")
        
        let rateLimitWithoutRetry = GoogleSheetsError.rateLimitExceeded(retryAfter: nil)
        XCTAssertEqual(rateLimitWithoutRetry.errorDescription, "Rate limit exceeded. Please retry later.")
        
        let quotaExceeded = GoogleSheetsError.quotaExceeded
        XCTAssertEqual(quotaExceeded.errorDescription, "API quota exceeded. Please check your billing settings or try again later.")
        
        let notFound = GoogleSheetsError.notFound("Spreadsheet")
        XCTAssertEqual(notFound.errorDescription, "Resource not found: Spreadsheet")
        
        let accessDenied = GoogleSheetsError.accessDenied("Insufficient permissions")
        XCTAssertEqual(accessDenied.errorDescription, "Access denied: Insufficient permissions. Please check your permissions.")
        
        let badRequest = GoogleSheetsError.badRequest("Invalid parameters")
        XCTAssertEqual(badRequest.errorDescription, "Bad request: Invalid parameters")
    }
    
    func testNetworkErrorDescriptions() {
        let urlError = URLError(.timedOut)
        let networkError = GoogleSheetsError.networkError(urlError)
        XCTAssertTrue(networkError.errorDescription?.contains("Network error:") == true)
        
        let timeout = GoogleSheetsError.timeout
        XCTAssertEqual(timeout.errorDescription, "Request timed out. Please check your connection and try again.")
        
        let invalidResponse = GoogleSheetsError.invalidResponse("Unexpected format")
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid response from server: Unexpected format")
        
        let jsonError = NSError(domain: "JSONError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        let invalidJSON = GoogleSheetsError.invalidJSON(jsonError)
        XCTAssertEqual(invalidJSON.errorDescription, "Invalid JSON response: Invalid JSON")
    }
    
    func testDataErrorDescriptions() {
        let encodingError = NSError(domain: "EncodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Encoding failed"])
        let encError = GoogleSheetsError.encodingError(encodingError)
        XCTAssertEqual(encError.errorDescription, "Failed to encode request data: Encoding failed")
        
        let decodingError = NSError(domain: "DecodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Decoding failed"])
        let decError = GoogleSheetsError.decodingError(decodingError)
        XCTAssertEqual(decError.errorDescription, "Failed to decode response data: Decoding failed")
        
        let invalidData = GoogleSheetsError.invalidData("Wrong format")
        XCTAssertEqual(invalidData.errorDescription, "Invalid data: Wrong format")
    }
    
    func testConfigurationErrorDescriptions() {
        let invalidAPIKey = GoogleSheetsError.invalidAPIKey
        XCTAssertEqual(invalidAPIKey.errorDescription, "Invalid API key. Please check your API key configuration.")
        
        let missingConfig = GoogleSheetsError.missingConfiguration("Client ID")
        XCTAssertEqual(missingConfig.errorDescription, "Missing required configuration: Client ID")
        
        let invalidURL = GoogleSheetsError.invalidURL("malformed-url")
        XCTAssertEqual(invalidURL.errorDescription, "Invalid URL: malformed-url")
    }
    
    // MARK: - Failure Reason Tests
    
    func testFailureReasons() {
        let authFailed = GoogleSheetsError.authenticationFailed("test")
        XCTAssertEqual(authFailed.failureReason, "The provided credentials are invalid or expired.")
        
        let tokenExpired = GoogleSheetsError.tokenExpired
        XCTAssertEqual(tokenExpired.failureReason, "The access token has expired and needs to be refreshed.")
        
        let invalidRange = GoogleSheetsError.invalidRange("test")
        XCTAssertEqual(invalidRange.failureReason, "The range specification doesn't follow A1 notation format.")
        
        let apiError500 = GoogleSheetsError.apiError(code: 500, message: "Server error", details: nil)
        XCTAssertEqual(apiError500.failureReason, "The Google Sheets API returned an error with status code 500.")
    }
    
    // MARK: - Recovery Suggestion Tests
    
    func testRecoverySuggestions() {
        let authFailed = GoogleSheetsError.authenticationFailed("test")
        XCTAssertEqual(authFailed.recoverySuggestion, "Please re-authenticate with valid Google credentials.")
        
        let invalidRange = GoogleSheetsError.invalidRange("test")
        XCTAssertEqual(invalidRange.recoverySuggestion, "Use A1 notation for ranges (e.g., 'A1:B10', 'Sheet1!A1:C5').")
        
        let serverError = GoogleSheetsError.apiError(code: 500, message: "Server error", details: nil)
        XCTAssertEqual(serverError.recoverySuggestion, "This is a server error. Please try again later.")
        
        let clientError = GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil)
        XCTAssertEqual(clientError.recoverySuggestion, "Check your request parameters and try again.")
        
        let rateLimitExceeded = GoogleSheetsError.rateLimitExceeded(retryAfter: nil)
        XCTAssertEqual(rateLimitExceeded.recoverySuggestion, "Wait before making additional requests, or implement exponential backoff.")
    }
    
    // MARK: - Error Classification Tests
    
    func testRetryableErrors() {
        // Retryable errors
        XCTAssertTrue(GoogleSheetsError.rateLimitExceeded(retryAfter: nil).isRetryable)
        XCTAssertTrue(GoogleSheetsError.timeout.isRetryable)
        XCTAssertTrue(GoogleSheetsError.networkError(URLError(.timedOut)).isRetryable)
        XCTAssertTrue(GoogleSheetsError.apiError(code: 500, message: "Server error", details: nil).isRetryable)
        XCTAssertTrue(GoogleSheetsError.apiError(code: 502, message: "Bad gateway", details: nil).isRetryable)
        XCTAssertTrue(GoogleSheetsError.invalidResponse("test").isRetryable)
        XCTAssertTrue(GoogleSheetsError.invalidJSON(NSError(domain: "test", code: 1)).isRetryable)
        XCTAssertTrue(GoogleSheetsError.tokenExpired.isRetryable)
        
        // Non-retryable errors
        XCTAssertFalse(GoogleSheetsError.authenticationFailed("test").isRetryable)
        XCTAssertFalse(GoogleSheetsError.invalidSpreadsheetId("test").isRetryable)
        XCTAssertFalse(GoogleSheetsError.invalidRange("test").isRetryable)
        XCTAssertFalse(GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil).isRetryable)
        XCTAssertFalse(GoogleSheetsError.apiError(code: 404, message: "Not found", details: nil).isRetryable)
        XCTAssertFalse(GoogleSheetsError.quotaExceeded.isRetryable)
        XCTAssertFalse(GoogleSheetsError.invalidAPIKey.isRetryable)
    }
    
    func testShouldRefreshToken() {
        // Should refresh token
        XCTAssertTrue(GoogleSheetsError.tokenExpired.shouldRefreshToken)
        XCTAssertTrue(GoogleSheetsError.apiError(code: 401, message: "Unauthorized", details: nil).shouldRefreshToken)
        XCTAssertTrue(GoogleSheetsError.authenticationFailed("test").shouldRefreshToken)
        
        // Should not refresh token
        XCTAssertFalse(GoogleSheetsError.rateLimitExceeded(retryAfter: nil).shouldRefreshToken)
        XCTAssertFalse(GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil).shouldRefreshToken)
        XCTAssertFalse(GoogleSheetsError.networkError(URLError(.timedOut)).shouldRefreshToken)
        XCTAssertFalse(GoogleSheetsError.invalidRange("test").shouldRefreshToken)
    }
    
    func testRetryDelay() {
        // Specific retry delays
        let rateLimitWithDelay = GoogleSheetsError.rateLimitExceeded(retryAfter: 30.0)
        XCTAssertEqual(rateLimitWithDelay.retryDelay, 30.0)
        
        let rateLimitWithoutDelay = GoogleSheetsError.rateLimitExceeded(retryAfter: nil)
        XCTAssertEqual(rateLimitWithoutDelay.retryDelay, 60.0) // Default
        
        let serverError = GoogleSheetsError.apiError(code: 500, message: "Server error", details: nil)
        XCTAssertEqual(serverError.retryDelay, 1.0)
        
        let timeout = GoogleSheetsError.timeout
        XCTAssertEqual(timeout.retryDelay, 1.0)
        
        let networkError = GoogleSheetsError.networkError(URLError(.timedOut))
        XCTAssertEqual(networkError.retryDelay, 1.0)
        
        // No retry delay
        let clientError = GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil)
        XCTAssertNil(clientError.retryDelay)
        
        let invalidRange = GoogleSheetsError.invalidRange("test")
        XCTAssertNil(invalidRange.retryDelay)
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        // Same errors should be equal
        let auth1 = GoogleSheetsError.authenticationFailed("test")
        let auth2 = GoogleSheetsError.authenticationFailed("test")
        XCTAssertEqual(auth1, auth2)
        
        let api1 = GoogleSheetsError.apiError(code: 400, message: "Bad request", details: nil)
        let api2 = GoogleSheetsError.apiError(code: 400, message: "Bad request", details: ["key": "value"])
        XCTAssertEqual(api1, api2) // Details are ignored in equality
        
        let tokenExpired1 = GoogleSheetsError.tokenExpired
        let tokenExpired2 = GoogleSheetsError.tokenExpired
        XCTAssertEqual(tokenExpired1, tokenExpired2)
        
        // Different errors should not be equal
        let auth3 = GoogleSheetsError.authenticationFailed("different")
        XCTAssertNotEqual(auth1, auth3)
        
        let api3 = GoogleSheetsError.apiError(code: 500, message: "Server error", details: nil)
        XCTAssertNotEqual(api1, api3)
        
        XCTAssertNotEqual(tokenExpired1, auth1)
    }
    
    // MARK: - HTTP Response Error Creation Tests
    
    func testFromHTTPResponse() {
        // Test 400 Bad Request
        let badRequestData = """
        {
            "error": {
                "message": "Invalid range",
                "code": 400
            }
        }
        """.data(using: .utf8)
        
        let badRequestError = GoogleSheetsError.fromHTTPResponse(statusCode: 400, data: badRequestData)
        if case .badRequest(let message) = badRequestError {
            XCTAssertEqual(message, "Invalid range")
        } else {
            XCTFail("Expected badRequest error")
        }
        
        // Test 401 Unauthorized
        let unauthorizedError = GoogleSheetsError.fromHTTPResponse(statusCode: 401, data: nil)
        if case .authenticationFailed(let message) = unauthorizedError {
            XCTAssertEqual(message, "Unknown error")
        } else {
            XCTFail("Expected authenticationFailed error")
        }
        
        // Test 403 Forbidden
        let forbiddenData = """
        {
            "error": {
                "message": "Insufficient permissions"
            }
        }
        """.data(using: .utf8)
        
        let forbiddenError = GoogleSheetsError.fromHTTPResponse(statusCode: 403, data: forbiddenData)
        if case .accessDenied(let message) = forbiddenError {
            XCTAssertEqual(message, "Insufficient permissions")
        } else {
            XCTFail("Expected accessDenied error")
        }
        
        // Test 404 Not Found
        let notFoundError = GoogleSheetsError.fromHTTPResponse(statusCode: 404, data: nil)
        if case .notFound(let message) = notFoundError {
            XCTAssertEqual(message, "Unknown error")
        } else {
            XCTFail("Expected notFound error")
        }
        
        // Test 429 Rate Limited
        let rateLimitError = GoogleSheetsError.fromHTTPResponse(statusCode: 429, data: nil)
        if case .rateLimitExceeded(let retryAfter) = rateLimitError {
            XCTAssertNil(retryAfter)
        } else {
            XCTFail("Expected rateLimitExceeded error")
        }
        
        // Test 500 Server Error
        let serverErrorData = """
        {
            "error": {
                "message": "Internal server error",
                "code": 500
            }
        }
        """.data(using: .utf8)
        
        let serverError = GoogleSheetsError.fromHTTPResponse(statusCode: 500, data: serverErrorData)
        if case .apiError(let code, let message, _) = serverError {
            XCTAssertEqual(code, 500)
            XCTAssertEqual(message, "Internal server error")
        } else {
            XCTFail("Expected apiError")
        }
    }
    
    // MARK: - URLError Conversion Tests
    
    func testFromURLError() {
        // Test timeout
        let timeoutError = URLError(.timedOut)
        let timeoutGSError = GoogleSheetsError.fromURLError(timeoutError)
        if case .timeout = timeoutGSError {
            // Success
        } else {
            XCTFail("Expected timeout error")
        }
        
        // Test network connection lost
        let connectionLostError = URLError(.networkConnectionLost)
        let connectionLostGSError = GoogleSheetsError.fromURLError(connectionLostError)
        if case .networkError(let error) = connectionLostGSError {
            XCTAssertTrue(error is URLError)
        } else {
            XCTFail("Expected networkError")
        }
        
        // Test not connected to internet
        let notConnectedError = URLError(.notConnectedToInternet)
        let notConnectedGSError = GoogleSheetsError.fromURLError(notConnectedError)
        if case .networkError(let error) = notConnectedGSError {
            XCTAssertTrue(error is URLError)
        } else {
            XCTFail("Expected networkError")
        }
        
        // Test other URL errors
        let otherError = URLError(.badURL)
        let otherGSError = GoogleSheetsError.fromURLError(otherError)
        if case .networkError(let error) = otherGSError {
            XCTAssertTrue(error is URLError)
        } else {
            XCTFail("Expected networkError")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyErrorMessages() {
        let emptyAuth = GoogleSheetsError.authenticationFailed("")
        XCTAssertEqual(emptyAuth.errorDescription, "Authentication failed: ")
        
        let emptyRange = GoogleSheetsError.invalidRange("")
        XCTAssertEqual(emptyRange.errorDescription, "Invalid range specification: . Please use A1 notation (e.g., 'A1:B10').")
    }
    
    func testLongErrorMessages() {
        let longMessage = String(repeating: "a", count: 1000)
        let longError = GoogleSheetsError.authenticationFailed(longMessage)
        XCTAssertTrue(longError.errorDescription?.contains(longMessage) == true)
    }
    
    func testSpecialCharactersInErrorMessages() {
        let specialMessage = "Error with special chars: !@#$%^&*()[]{}|\\:;\"'<>,.?/~`"
        let specialError = GoogleSheetsError.invalidData(specialMessage)
        XCTAssertEqual(specialError.errorDescription, "Invalid data: \(specialMessage)")
    }
}