import Foundation
@testable import GoogleSheetsSwift

/// Mock HTTP client for unit testing service layers
public class MockHTTPClient: HTTPClient {
    // MARK: - Mock Configuration
    
    /// Dictionary to store mock responses by URL pattern
    private var responses: [String: Any] = [:]
    
    /// Dictionary to store mock errors by URL pattern
    private var errors: [String: Error] = [:]
    
    /// Dictionary to store mock raw data responses by URL pattern
    private var rawResponses: [String: Data] = [:]
    
    /// Flag to simulate general failure
    public var shouldFail = false
    
    /// General error to throw when shouldFail is true
    public var mockError: Error = GoogleSheetsError.networkError(URLError(.notConnectedToInternet))
    
    /// Last request that was executed (for verification in tests)
    public var lastRequest: HTTPRequest?
    
    /// All requests that have been executed (for verification in tests)
    public var allRequests: [HTTPRequest] = []
    
    /// Request count for tracking number of calls
    public var requestCount: Int { allRequests.count }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Mock Configuration Methods
    
    /// Configure a mock response for a specific URL pattern
    public func mockResponse<T: Codable>(for urlPattern: String, response: T) {
        responses[urlPattern] = response
    }
    
    /// Configure a mock error for a specific URL pattern
    public func mockError(for urlPattern: String, error: Error) {
        errors[urlPattern] = error
    }
    
    /// Configure a mock raw data response for a specific URL pattern
    public func mockRawResponse(for urlPattern: String, data: Data) {
        rawResponses[urlPattern] = data
    }
    
    /// Clear all mock configurations
    public func clearMocks() {
        responses.removeAll()
        errors.removeAll()
        rawResponses.removeAll()
        allRequests.removeAll()
        lastRequest = nil
        shouldFail = false
    }
    
    // MARK: - HTTPClient Implementation
    
    public func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
        // Store request for verification
        lastRequest = request
        allRequests.append(request)
        
        // Check for general failure
        if shouldFail {
            throw mockError
        }
        
        let urlString = request.url.absoluteString
        
        // Check for specific error for this URL
        if let error = findError(for: urlString) {
            throw error
        }
        
        // Check for specific response for this URL
        if let response = findResponse(for: urlString) as? T {
            return response
        }
        
        // If no mock configured, throw error
        throw GoogleSheetsError.invalidResponse("No mock response configured for URL: \(urlString)")
    }
    
    public func executeRaw(_ request: HTTPRequest) async throws -> Data {
        // Store request for verification
        lastRequest = request
        allRequests.append(request)
        
        // Check for general failure
        if shouldFail {
            throw mockError
        }
        
        let urlString = request.url.absoluteString
        
        // Check for specific error for this URL
        if let error = findError(for: urlString) {
            throw error
        }
        
        // Check for specific raw data response for this URL
        if let data = findRawResponse(for: urlString) {
            return data
        }
        
        // Return empty data as default
        return Data()
    }
    
    // MARK: - Helper Methods
    
    /// Find a response for the given URL, supporting pattern matching
    private func findResponse(for url: String) -> Any? {
        // First try exact match
        if let response = responses[url] {
            return response
        }
        
        // Then try pattern matching
        for (pattern, response) in responses {
            if url.contains(pattern) {
                return response
            }
        }
        
        return nil
    }
    
    /// Find an error for the given URL, supporting pattern matching
    private func findError(for url: String) -> Error? {
        // First try exact match
        if let error = errors[url] {
            return error
        }
        
        // Then try pattern matching
        for (pattern, error) in errors {
            if url.contains(pattern) {
                return error
            }
        }
        
        return nil
    }
    
    /// Find raw data response for the given URL, supporting pattern matching
    private func findRawResponse(for url: String) -> Data? {
        // First try exact match
        if let data = rawResponses[url] {
            return data
        }
        
        // Then try pattern matching
        for (pattern, data) in rawResponses {
            if url.contains(pattern) {
                return data
            }
        }
        
        return nil
    }
}

// MARK: - Convenience Methods

extension MockHTTPClient {
    /// Configure mock response for spreadsheet operations
    public func mockSpreadsheetResponse<T: Codable>(_ response: T) {
        mockResponse(for: "/spreadsheets", response: response)
    }
    
    /// Configure mock response for values operations
    public func mockValuesResponse<T: Codable>(_ response: T) {
        mockResponse(for: "/values", response: response)
    }
    
    /// Configure mock error for authentication failures
    public func mockAuthenticationError() {
        mockError(for: "googleapis.com", error: GoogleSheetsError.authenticationFailed("Mock authentication failure"))
    }
    
    /// Configure mock error for rate limiting
    public func mockRateLimitError(retryAfter: TimeInterval = 60) {
        mockError(for: "googleapis.com", error: GoogleSheetsError.rateLimitExceeded(retryAfter: retryAfter))
    }
    
    /// Configure mock error for network issues
    public func mockNetworkError() {
        mockError(for: "googleapis.com", error: GoogleSheetsError.networkError(URLError(.notConnectedToInternet)))
    }
    
    /// Set a response for a specific URL pattern (convenience method)
    public func setResponse<T: Codable>(_ response: T, for urlPattern: String) {
        responses[urlPattern] = response
    }
    
    /// Reset the request count
    public func resetRequestCount() {
        allRequests.removeAll()
        lastRequest = nil
    }
}