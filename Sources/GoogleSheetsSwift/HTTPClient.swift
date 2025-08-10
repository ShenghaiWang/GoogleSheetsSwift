import Foundation

/// HTTP method enumeration
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

/// Protocol for URLSession abstraction to enable testing
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Extension to make URLSession conform to URLSessionProtocol
extension URLSession: URLSessionProtocol {}

/// Request builder for constructing Google Sheets API requests
public class RequestBuilder {
    private let baseURL: String
    private let apiKey: String?
    private let accessToken: String?
    
    public init(baseURL: String = "https://sheets.googleapis.com/v4", apiKey: String? = nil, accessToken: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.accessToken = accessToken
    }
    
    /// Build a request for spreadsheet operations
    public func buildSpreadsheetRequest(
        method: HTTPMethod,
        spreadsheetId: String? = nil,
        endpoint: String,
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw GoogleSheetsError.invalidURL(baseURL)
        }
        
        // Build the path
        var pathComponents = ["v4", "spreadsheets"]
        if let spreadsheetId = spreadsheetId {
            pathComponents.append(spreadsheetId)
        }
        pathComponents.append(endpoint)
        
        urlComponents.path = "/" + pathComponents.joined(separator: "/")
        
        // Add query parameters
        var queryItems: [URLQueryItem] = []
        
        // Add API key if available and no access token
        if let apiKey = apiKey, accessToken == nil {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }
        
        // Add custom query parameters
        for (key, value) in queryParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw GoogleSheetsError.invalidURL(urlComponents.string ?? "unknown")
        }
        
        // Build headers
        var headers: [String: String] = [:]
        
        if let accessToken = accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        if body != nil {
            headers["Content-Type"] = "application/json"
        }
        
        return HTTPRequest(method: method, url: url, headers: headers, body: body)
    }
    
    /// Build a request for values operations
    public func buildValuesRequest(
        method: HTTPMethod,
        spreadsheetId: String,
        range: String? = nil,
        endpoint: String = "values",
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        var pathEndpoint = endpoint
        if let range = range {
            // Don't encode here - let URLComponents handle it properly
            pathEndpoint = "\(endpoint)/\(range)"
        }
        
        return try buildSpreadsheetRequest(
            method: method,
            spreadsheetId: spreadsheetId,
            endpoint: pathEndpoint,
            queryParameters: queryParameters,
            body: body
        )
    }
    
    /// Build a request for batch operations
    public func buildBatchRequest(
        method: HTTPMethod,
        spreadsheetId: String,
        endpoint: String,
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        return try buildSpreadsheetRequest(
            method: method,
            spreadsheetId: spreadsheetId,
            endpoint: endpoint,
            queryParameters: queryParameters,
            body: body
        )
    }
}

/// Convenience methods for common request patterns
extension RequestBuilder {
    /// Create a GET request for reading spreadsheet data
    public func getSpreadsheet(
        spreadsheetId: String,
        ranges: [String]? = nil,
        includeGridData: Bool = false,
        fields: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]
        
        if let ranges = ranges, !ranges.isEmpty {
            queryParams["ranges"] = ranges.joined(separator: "&ranges=")
        }
        
        if includeGridData {
            queryParams["includeGridData"] = "true"
        }
        
        if let fields = fields {
            queryParams["fields"] = fields
        }
        
        return try buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            endpoint: "",
            queryParameters: queryParams
        )
    }
    
    /// Create a GET request for reading values
    public func getValues(
        spreadsheetId: String,
        range: String,
        majorDimension: String? = nil,
        valueRenderOption: String? = nil,
        dateTimeRenderOption: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]
        
        if let majorDimension = majorDimension {
            queryParams["majorDimension"] = majorDimension
        }
        
        if let valueRenderOption = valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption
        }
        
        if let dateTimeRenderOption = dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption
        }
        
        return try buildValuesRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            range: range,
            queryParameters: queryParams
        )
    }
    
    /// Create a PUT request for updating values
    public func updateValues(
        spreadsheetId: String,
        range: String,
        valueInputOption: String? = nil,
        includeValuesInResponse: Bool = false,
        responseValueRenderOption: String? = nil,
        responseDateTimeRenderOption: String? = nil,
        body: Data
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]
        
        if let valueInputOption = valueInputOption {
            queryParams["valueInputOption"] = valueInputOption
        }
        
        if includeValuesInResponse {
            queryParams["includeValuesInResponse"] = "true"
        }
        
        if let responseValueRenderOption = responseValueRenderOption {
            queryParams["responseValueRenderOption"] = responseValueRenderOption
        }
        
        if let responseDateTimeRenderOption = responseDateTimeRenderOption {
            queryParams["responseDateTimeRenderOption"] = responseDateTimeRenderOption
        }
        
        return try buildValuesRequest(
            method: .PUT,
            spreadsheetId: spreadsheetId,
            range: range,
            queryParameters: queryParams,
            body: body
        )
    }
    
    /// Create a POST request for appending values
    public func appendValues(
        spreadsheetId: String,
        range: String,
        valueInputOption: String? = nil,
        insertDataOption: String? = nil,
        includeValuesInResponse: Bool = false,
        responseValueRenderOption: String? = nil,
        responseDateTimeRenderOption: String? = nil,
        body: Data
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]
        
        if let valueInputOption = valueInputOption {
            queryParams["valueInputOption"] = valueInputOption
        }
        
        if let insertDataOption = insertDataOption {
            queryParams["insertDataOption"] = insertDataOption
        }
        
        if includeValuesInResponse {
            queryParams["includeValuesInResponse"] = "true"
        }
        
        if let responseValueRenderOption = responseValueRenderOption {
            queryParams["responseValueRenderOption"] = responseValueRenderOption
        }
        
        if let responseDateTimeRenderOption = responseDateTimeRenderOption {
            queryParams["responseDateTimeRenderOption"] = responseDateTimeRenderOption
        }
        
        return try buildValuesRequest(
            method: .POST,
            spreadsheetId: spreadsheetId,
            range: "\(range):append",
            queryParameters: queryParams,
            body: body
        )
    }
    
    /// Create a POST request for clearing values
    public func clearValues(
        spreadsheetId: String,
        range: String
    ) throws -> HTTPRequest {
        return try buildValuesRequest(
            method: .POST,
            spreadsheetId: spreadsheetId,
            range: "\(range):clear"
        )
    }
    
    /// Create a POST request for batch getting values
    public func batchGetValues(
        spreadsheetId: String,
        ranges: [String],
        majorDimension: String? = nil,
        valueRenderOption: String? = nil,
        dateTimeRenderOption: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]
        
        queryParams["ranges"] = ranges.joined(separator: "&ranges=")
        
        if let majorDimension = majorDimension {
            queryParams["majorDimension"] = majorDimension
        }
        
        if let valueRenderOption = valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption
        }
        
        if let dateTimeRenderOption = dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption
        }
        
        return try buildBatchRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            endpoint: "values:batchGet",
            queryParameters: queryParams
        )
    }
}

/// Represents an HTTP request
public struct HTTPRequest {
    public let method: HTTPMethod
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    
    public init(method: HTTPMethod, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

/// Protocol for HTTP client implementations
public protocol HTTPClient {
    /// Execute an HTTP request and decode the response
    func execute<T: Codable>(_ request: HTTPRequest) async throws -> T
    
    /// Execute an HTTP request and return raw data
    func executeRaw(_ request: HTTPRequest) async throws -> Data
}

/// Logger protocol for HTTP operations
public protocol HTTPLogger {
    func logRequest(_ request: HTTPRequest)
    func logResponse(_ response: HTTPURLResponse, data: Data)
    func logError(_ error: Error, for request: HTTPRequest)
}

/// Default implementation that logs to console
public class ConsoleHTTPLogger: HTTPLogger {
    public init() {}
    
    public func logRequest(_ request: HTTPRequest) {
        print("🌐 HTTP Request: \(request.method.rawValue) \(request.url)")
        if !request.headers.isEmpty {
            print("📋 Headers: \(request.headers)")
        }
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
    }
    
    public func logResponse(_ response: HTTPURLResponse, data: Data) {
        print("✅ HTTP Response: \(response.statusCode) from \(response.url?.absoluteString ?? "unknown")")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response Data: \(responseString)")
        }
    }
    
    public func logError(_ error: Error, for request: HTTPRequest) {
        print("❌ HTTP Error for \(request.method.rawValue) \(request.url): \(error)")
    }
}

/// URLSession-based HTTP client implementation
public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSessionProtocol
    private let logger: HTTPLogger?
    private let retryConfiguration: RetryConfiguration
    private let rateLimiter: RateLimiter?
    
    public init(
        session: URLSessionProtocol = URLSession.shared,
        logger: HTTPLogger? = nil,
        retryConfiguration: RetryConfiguration = .default,
        rateLimiter: RateLimiter? = nil
    ) {
        self.session = session
        self.logger = logger
        self.retryConfiguration = retryConfiguration
        self.rateLimiter = rateLimiter
    }
    
    public func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
        // Use retry logic for the complete execute operation
        let retryLogic = RetryLogic(configuration: retryConfiguration)
        
        return try await retryLogic.execute(
            operation: {
                let data = try await self.executeRawInternal(request)
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw GoogleSheetsError.decodingError(error)
                }
            },
            shouldRetry: { error in
                self.shouldRetryError(error)
            }
        )
    }
    
    public func executeRaw(_ request: HTTPRequest) async throws -> Data {
        // Use retry logic for raw data execution
        let retryLogic = RetryLogic(configuration: retryConfiguration)
        
        return try await retryLogic.execute(
            operation: {
                try await self.executeRawInternal(request)
            },
            shouldRetry: { error in
                self.shouldRetryError(error)
            }
        )
    }
    
    /// Internal method that performs the actual HTTP request without retry logic
    private func executeRawInternal(_ request: HTTPRequest) async throws -> Data {
        // Apply rate limiting if configured
        await rateLimiter?.waitIfNeeded()
        
        logger?.logRequest(request)
        
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        
        // Set headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set default headers if not provided
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil && request.body != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = GoogleSheetsError.invalidResponse("Response is not HTTPURLResponse")
                logger?.logError(error, for: request)
                throw error
            }
            
            logger?.logResponse(httpResponse, data: data)
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 400:
                throw GoogleSheetsError.badRequest("Bad Request")
            case 401:
                throw GoogleSheetsError.authenticationFailed("Unauthorized")
            case 403:
                throw GoogleSheetsError.accessDenied("Forbidden")
            case 404:
                throw GoogleSheetsError.notFound("Not Found")
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let retryInterval = retryAfter.flatMap(Double.init) ?? 60.0
                throw GoogleSheetsError.rateLimitExceeded(retryAfter: retryInterval)
            case 500...599:
                throw GoogleSheetsError.apiError(code: httpResponse.statusCode, message: "Server Error", details: nil)
            default:
                throw GoogleSheetsError.apiError(code: httpResponse.statusCode, message: "Unknown Error", details: nil)
            }
        } catch let error as GoogleSheetsError {
            logger?.logError(error, for: request)
            throw error
        } catch {
            let networkError = GoogleSheetsError.networkError(error)
            logger?.logError(networkError, for: request)
            throw networkError
        }
    }
    
    /// Determine if an error should be retried
    private func shouldRetryError(_ error: Error) -> Bool {
        if let gsError = error as? GoogleSheetsError {
            return gsError.isRetryable
        }
        
        // For non-GoogleSheetsError types, be conservative
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}