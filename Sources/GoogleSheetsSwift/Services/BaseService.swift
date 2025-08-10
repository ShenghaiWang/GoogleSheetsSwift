import Foundation

/// Base protocol for all Google Sheets API services
public protocol GoogleSheetsService {
    /// The HTTP client used for API requests
    var httpClient: HTTPClient { get }
    
    /// The OAuth2 token manager for authentication
    var tokenManager: OAuth2TokenManager { get }
    
    /// Base URL for Google Sheets API
    var baseURL: String { get }
}

/// Default implementation for common service functionality
extension GoogleSheetsService {
    public var baseURL: String {
        return "https://sheets.googleapis.com/v4"
    }
    
    /// Create an authenticated HTTP request
    func createAuthenticatedRequest(method: HTTPMethod, path: String, body: Data? = nil) async throws -> HTTPRequest {
        let accessToken = try await tokenManager.getAccessToken()
        let url = URL(string: baseURL + path)!
        
        var headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        if body != nil {
            headers["Content-Length"] = "\(body!.count)"
        }
        
        return HTTPRequest(method: method, url: url, headers: headers, body: body)
    }
    
    /// Create an API key authenticated request (for read-only operations)
    func createAPIKeyRequest(method: HTTPMethod, path: String, apiKey: String, body: Data? = nil) -> HTTPRequest {
        let url = URL(string: baseURL + path + (path.contains("?") ? "&" : "?") + "key=\(apiKey)")!
        
        var headers = [
            "Content-Type": "application/json"
        ]
        
        if body != nil {
            headers["Content-Length"] = "\(body!.count)"
        }
        
        return HTTPRequest(method: method, url: url, headers: headers, body: body)
    }
}