import Foundation

/// Service for managing spreadsheet operations
public class SpreadsheetsService: SpreadsheetsServiceProtocol {
    public let httpClient: HTTPClient
    public let tokenManager: OAuth2TokenManager
    private let cache: ResponseCache?
    private let cacheConfiguration: CacheConfiguration
    
    /// Initialize the spreadsheets service
    /// - Parameters:
    ///   - httpClient: HTTP client for making requests
    ///   - tokenManager: OAuth2 token manager for authentication
    ///   - cache: Optional response cache for read operations
    ///   - cacheConfiguration: Configuration for caching behavior
    public init(
        httpClient: HTTPClient, 
        tokenManager: OAuth2TokenManager,
        cache: ResponseCache? = nil,
        cacheConfiguration: CacheConfiguration = .default
    ) {
        self.httpClient = httpClient
        self.tokenManager = tokenManager
        self.cache = cache
        self.cacheConfiguration = cacheConfiguration
    }
    
    /// Create a new spreadsheet
    /// - Parameter request: The spreadsheet creation request
    /// - Returns: The created spreadsheet
    /// - Throws: GoogleSheetsError if the operation fails
    public func create(_ request: SpreadsheetCreateRequest) async throws -> Spreadsheet {
        let path = "/spreadsheets"
        
        // Encode the request body
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        
        // Create authenticated request
        let httpRequest = try await createAuthenticatedRequest(
            method: .POST,
            path: path,
            body: body
        )
        
        // Execute request and decode response
        do {
            let response: Spreadsheet = try await httpClient.execute(httpRequest)
            return response
        } catch {
            throw mapHTTPError(error)
        }
    }
    
    /// Get spreadsheet information by ID
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet to retrieve
    ///   - ranges: The ranges to retrieve from the spreadsheet (optional)
    ///   - includeGridData: Whether to include grid data in the response
    ///   - fields: The fields to include in the response (optional)
    /// - Returns: The spreadsheet information
    /// - Throws: GoogleSheetsError if the operation fails
    public func get(spreadsheetId: String, ranges: [String]? = nil, includeGridData: Bool = false, fields: String? = nil) async throws -> Spreadsheet {
        // Validate spreadsheet ID
        guard !spreadsheetId.isEmpty else {
            throw GoogleSheetsError.invalidSpreadsheetId("Spreadsheet ID cannot be empty")
        }
        
        // Check cache first if enabled
        if let cache = cache, cacheConfiguration.enabled {
            let cacheKey = CacheKeyGenerator.spreadsheetKey(
                spreadsheetId: spreadsheetId,
                ranges: ranges,
                includeGridData: includeGridData,
                fields: fields
            )
            
            if let cachedResult = await cache.retrieve(Spreadsheet.self, for: cacheKey) {
                return cachedResult
            }
        }
        
        // Build query parameters
        var queryItems: [URLQueryItem] = []
        
        if let ranges = ranges, !ranges.isEmpty {
            for range in ranges {
                queryItems.append(URLQueryItem(name: "ranges", value: range))
            }
        }
        
        if includeGridData {
            queryItems.append(URLQueryItem(name: "includeGridData", value: "true"))
        }
        
        if let fields = fields, !fields.isEmpty {
            queryItems.append(URLQueryItem(name: "fields", value: fields))
        }
        
        // Build path with query parameters
        var path = "/spreadsheets/\(spreadsheetId)"
        if !queryItems.isEmpty {
            var urlComponents = URLComponents()
            urlComponents.queryItems = queryItems
            if let queryString = urlComponents.query {
                path += "?" + queryString
            }
        }
        
        // Create authenticated request
        let httpRequest = try await createAuthenticatedRequest(
            method: .GET,
            path: path
        )
        
        // Execute request and decode response
        do {
            let response: Spreadsheet = try await httpClient.execute(httpRequest)
            
            // Cache the result if caching is enabled
            if let cache = cache, cacheConfiguration.enabled {
                let cacheKey = CacheKeyGenerator.spreadsheetKey(
                    spreadsheetId: spreadsheetId,
                    ranges: ranges,
                    includeGridData: includeGridData,
                    fields: fields
                )
                await cache.store(response, for: cacheKey, ttl: cacheConfiguration.spreadsheetTTL)
            }
            
            return response
        } catch {
            throw mapHTTPError(error)
        }
    }
    
    /// Perform batch updates on a spreadsheet
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet to update
    ///   - requests: The batch update requests to perform
    /// - Returns: The batch update response
    /// - Throws: GoogleSheetsError if the operation fails
    public func batchUpdate(spreadsheetId: String, requests: [BatchUpdateRequest]) async throws -> BatchUpdateSpreadsheetResponse {
        // Validate spreadsheet ID
        guard !spreadsheetId.isEmpty else {
            throw GoogleSheetsError.invalidSpreadsheetId("Spreadsheet ID cannot be empty")
        }
        
        // Validate requests
        guard !requests.isEmpty else {
            throw GoogleSheetsError.apiError(code: 400, message: "Batch update requests cannot be empty", details: nil)
        }
        
        let path = "/spreadsheets/\(spreadsheetId):batchUpdate"
        
        // Create request body
        let requestBody = BatchUpdateRequestBody(requests: requests)
        
        // Encode the request body
        let encoder = JSONEncoder()
        let body = try encoder.encode(requestBody)
        
        // Create authenticated request
        let httpRequest = try await createAuthenticatedRequest(
            method: .POST,
            path: path,
            body: body
        )
        
        // Execute request and decode response
        do {
            let response: BatchUpdateSpreadsheetResponse = try await httpClient.execute(httpRequest)
            return response
        } catch {
            throw mapHTTPError(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Create an authenticated HTTP request
    /// - Parameters:
    ///   - method: HTTP method
    ///   - path: API path
    ///   - body: Optional request body
    /// - Returns: HTTPRequest with authentication headers
    /// - Throws: GoogleSheetsError if authentication fails
    private func createAuthenticatedRequest(
        method: HTTPMethod,
        path: String,
        body: Data? = nil
    ) async throws -> HTTPRequest {
        let accessToken = try await tokenManager.getAccessToken()
        let requestBuilder = RequestBuilder(accessToken: accessToken)
        
        let baseURL = "https://sheets.googleapis.com/v4"
        guard let url = URL(string: baseURL + path) else {
            throw GoogleSheetsError.invalidURL(baseURL + path)
        }
        
        var headers: [String: String] = [
            "Authorization": "Bearer \(accessToken)"
        ]
        
        if body != nil {
            headers["Content-Type"] = "application/json"
        }
        
        return HTTPRequest(method: method, url: url, headers: headers, body: body)
    }
    
    /// Map HTTP errors to GoogleSheetsError
    private func mapHTTPError(_ error: Error) -> GoogleSheetsError {
        if let sheetsError = error as? GoogleSheetsError {
            return sheetsError
        }
        
        // Map common HTTP errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return GoogleSheetsError.networkError(urlError)
            case .timedOut:
                return GoogleSheetsError.networkError(urlError)
            default:
                return GoogleSheetsError.networkError(urlError)
            }
        }
        
        return GoogleSheetsError.networkError(error)
    }
}

// MARK: - Supporting Types

/// Internal request body for batch updates
private struct BatchUpdateRequestBody: Codable {
    let requests: [BatchUpdateRequest]
}