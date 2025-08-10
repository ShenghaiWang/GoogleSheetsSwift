import Foundation

/// Comprehensive error types for Google Sheets API operations
public enum GoogleSheetsError: Error, LocalizedError, Equatable {
    // MARK: - Authentication Errors
    
    /// Authentication failed with the provided credentials
    case authenticationFailed(String)
    
    /// Access token has expired and needs to be refreshed
    case tokenExpired
    
    /// OAuth2 flow was cancelled by the user
    case authenticationCancelled
    
    /// Invalid or missing credentials
    case invalidCredentials(String)
    
    // MARK: - API Errors
    
    /// Invalid spreadsheet ID provided
    case invalidSpreadsheetId(String)
    
    /// Invalid range specification (A1 notation)
    case invalidRange(String)
    
    /// API returned an error response
    case apiError(code: Int, message: String, details: [String: Any]?)
    
    /// Rate limit exceeded - too many requests
    case rateLimitExceeded(retryAfter: TimeInterval?)
    
    /// API quota exceeded for the current billing period
    case quotaExceeded
    
    /// Requested resource was not found
    case notFound(String)
    
    /// Access denied - insufficient permissions
    case accessDenied(String)
    
    /// Bad request - invalid parameters or request format
    case badRequest(String)
    
    // MARK: - Network Errors
    
    /// Network connectivity issues
    case networkError(Error)
    
    /// Request timeout
    case timeout
    
    /// Invalid response from server
    case invalidResponse(String)
    
    /// Server returned invalid JSON
    case invalidJSON(Error)
    
    // MARK: - Data Errors
    
    /// Failed to encode request data
    case encodingError(Error)
    
    /// Failed to decode response data
    case decodingError(Error)
    
    /// Invalid data format or type
    case invalidData(String)
    
    // MARK: - Configuration Errors
    
    /// Invalid API key
    case invalidAPIKey
    
    /// Missing required configuration
    case missingConfiguration(String)
    
    /// Invalid URL or endpoint
    case invalidURL(String)
    
    /// Feature not yet implemented
    case notImplemented(String)
    
    // MARK: - LocalizedError Conformance
    
    public var errorDescription: String? {
        switch self {
        // Authentication Errors
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .tokenExpired:
            return "Access token has expired. Please re-authenticate."
        case .authenticationCancelled:
            return "Authentication was cancelled by the user."
        case .invalidCredentials(let message):
            return "Invalid credentials: \(message)"
            
        // API Errors
        case .invalidSpreadsheetId(let id):
            return "Invalid spreadsheet ID: \(id)"
        case .invalidRange(let range):
            return "Invalid range specification: \(range). Please use A1 notation (e.g., 'A1:B10')."
        case .apiError(let code, let message, _):
            return "API error (\(code)): \(message)"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Please retry after \(Int(retryAfter)) seconds."
            } else {
                return "Rate limit exceeded. Please retry later."
            }
        case .quotaExceeded:
            return "API quota exceeded. Please check your billing settings or try again later."
        case .notFound(let resource):
            return "Resource not found: \(resource)"
        case .accessDenied(let message):
            return "Access denied: \(message). Please check your permissions."
        case .badRequest(let message):
            return "Bad request: \(message)"
            
        // Network Errors
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .invalidResponse(let message):
            return "Invalid response from server: \(message)"
        case .invalidJSON(let error):
            return "Invalid JSON response: \(error.localizedDescription)"
            
        // Data Errors
        case .encodingError(let error):
            return "Failed to encode request data: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response data: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
            
        // Configuration Errors
        case .invalidAPIKey:
            return "Invalid API key. Please check your API key configuration."
        case .missingConfiguration(let config):
            return "Missing required configuration: \(config)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .authenticationFailed:
            return "The provided credentials are invalid or expired."
        case .tokenExpired:
            return "The access token has expired and needs to be refreshed."
        case .authenticationCancelled:
            return "The user cancelled the authentication process."
        case .invalidCredentials:
            return "The OAuth2 credentials are missing or invalid."
        case .invalidSpreadsheetId:
            return "The spreadsheet ID format is invalid or the spreadsheet doesn't exist."
        case .invalidRange:
            return "The range specification doesn't follow A1 notation format."
        case .apiError(let code, _, _):
            return "The Google Sheets API returned an error with status code \(code)."
        case .rateLimitExceeded:
            return "Too many requests have been made in a short period."
        case .quotaExceeded:
            return "The API usage quota has been exceeded."
        case .notFound:
            return "The requested resource could not be found."
        case .accessDenied:
            return "Insufficient permissions to access the requested resource."
        case .badRequest:
            return "The request parameters are invalid or malformed."
        case .networkError:
            return "A network connectivity issue occurred."
        case .timeout:
            return "The request took too long to complete."
        case .invalidResponse:
            return "The server returned an unexpected response format."
        case .invalidJSON:
            return "The server response contains invalid JSON."
        case .encodingError:
            return "Failed to encode the request data to JSON."
        case .decodingError:
            return "Failed to decode the response data from JSON."
        case .invalidData:
            return "The provided data is in an invalid format."
        case .invalidAPIKey:
            return "The API key is missing, invalid, or doesn't have the required permissions."
        case .missingConfiguration:
            return "Required configuration parameters are missing."
        case .invalidURL:
            return "The constructed URL is invalid."
        case .notImplemented:
            return "This feature has not been implemented yet."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed, .tokenExpired, .invalidCredentials:
            return "Please re-authenticate with valid Google credentials."
        case .authenticationCancelled:
            return "Please complete the authentication process to continue."
        case .invalidSpreadsheetId:
            return "Verify the spreadsheet ID and ensure the spreadsheet exists and is accessible."
        case .invalidRange:
            return "Use A1 notation for ranges (e.g., 'A1:B10', 'Sheet1!A1:C5')."
        case .apiError(let code, _, _):
            if code >= 500 {
                return "This is a server error. Please try again later."
            } else {
                return "Check your request parameters and try again."
            }
        case .rateLimitExceeded:
            return "Wait before making additional requests, or implement exponential backoff."
        case .quotaExceeded:
            return "Check your Google Cloud Console billing settings or wait for quota reset."
        case .notFound:
            return "Verify the resource exists and you have permission to access it."
        case .accessDenied:
            return "Ensure you have the required permissions and scopes for this operation."
        case .badRequest:
            return "Review your request parameters and ensure they meet the API requirements."
        case .networkError, .timeout:
            return "Check your internet connection and try again."
        case .invalidResponse, .invalidJSON:
            return "This may be a temporary server issue. Please try again."
        case .encodingError, .decodingError:
            return "Check your data format and ensure it's compatible with the API."
        case .invalidData:
            return "Verify your data format and values are correct."
        case .invalidAPIKey:
            return "Check your API key in the Google Cloud Console and ensure it has the required permissions."
        case .missingConfiguration:
            return "Provide the required configuration parameters."
        case .invalidURL:
            return "Check the API endpoint configuration."
        case .notImplemented:
            return "This feature will be available in a future version."
        }
    }
    
    // MARK: - Error Classification
    
    /// Indicates whether this error type is retryable
    public var isRetryable: Bool {
        switch self {
        case .rateLimitExceeded, .timeout, .networkError:
            return true
        case .apiError(let code, _, _):
            // Retry on server errors (5xx) but not client errors (4xx)
            return code >= 500
        case .invalidResponse, .invalidJSON:
            return true
        case .tokenExpired:
            return true // Can retry after token refresh
        default:
            return false
        }
    }
    
    /// Indicates whether this error suggests the token should be refreshed
    public var shouldRefreshToken: Bool {
        switch self {
        case .tokenExpired:
            return true
        case .apiError(let code, _, _):
            return code == 401 // Unauthorized
        case .authenticationFailed:
            return true
        default:
            return false
        }
    }
    
    /// Returns the suggested delay before retrying (in seconds)
    public var retryDelay: TimeInterval? {
        switch self {
        case .rateLimitExceeded(let retryAfter):
            return retryAfter ?? 60.0 // Default to 60 seconds if not specified
        case .apiError(let code, _, _):
            if code >= 500 {
                return 1.0 // Start with 1 second for server errors
            }
            return nil
        case .timeout, .networkError:
            return 1.0
        default:
            return nil
        }
    }
    
    // MARK: - Equatable Conformance
    
    public static func == (lhs: GoogleSheetsError, rhs: GoogleSheetsError) -> Bool {
        switch (lhs, rhs) {
        case (.authenticationFailed(let lhsMsg), .authenticationFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.tokenExpired, .tokenExpired):
            return true
        case (.authenticationCancelled, .authenticationCancelled):
            return true
        case (.invalidCredentials(let lhsMsg), .invalidCredentials(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.invalidSpreadsheetId(let lhsId), .invalidSpreadsheetId(let rhsId)):
            return lhsId == rhsId
        case (.invalidRange(let lhsRange), .invalidRange(let rhsRange)):
            return lhsRange == rhsRange
        case (.apiError(let lhsCode, let lhsMsg, _), .apiError(let rhsCode, let rhsMsg, _)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        case (.rateLimitExceeded(let lhsRetry), .rateLimitExceeded(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.quotaExceeded, .quotaExceeded):
            return true
        case (.notFound(let lhsResource), .notFound(let rhsResource)):
            return lhsResource == rhsResource
        case (.accessDenied(let lhsMsg), .accessDenied(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.badRequest(let lhsMsg), .badRequest(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.timeout, .timeout):
            return true
        case (.invalidResponse(let lhsMsg), .invalidResponse(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.invalidData(let lhsMsg), .invalidData(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.invalidAPIKey, .invalidAPIKey):
            return true
        case (.missingConfiguration(let lhsConfig), .missingConfiguration(let rhsConfig)):
            return lhsConfig == rhsConfig
        case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
            return lhsURL == rhsURL
        case (.notImplemented(let lhsFeature), .notImplemented(let rhsFeature)):
            return lhsFeature == rhsFeature
        default:
            return false
        }
    }
}

// MARK: - Error Creation Helpers

extension GoogleSheetsError {
    /// Create an API error from HTTP response
    static func fromHTTPResponse(statusCode: Int, data: Data?) -> GoogleSheetsError {
        // Try to parse error details from response
        var errorMessage = "Unknown error"
        var errorDetails: [String: Any]?
        
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any] {
            
            if let message = error["message"] as? String {
                errorMessage = message
            }
            
            errorDetails = error
        }
        
        switch statusCode {
        case 400:
            return .badRequest(errorMessage)
        case 401:
            return .authenticationFailed(errorMessage)
        case 403:
            return .accessDenied(errorMessage)
        case 404:
            return .notFound(errorMessage)
        case 429:
            // Try to extract retry-after from error details
            var retryAfter: TimeInterval?
            if let details = errorDetails,
               let retryAfterValue = details["retryAfter"] as? TimeInterval {
                retryAfter = retryAfterValue
            }
            return .rateLimitExceeded(retryAfter: retryAfter)
        default:
            return .apiError(code: statusCode, message: errorMessage, details: errorDetails)
        }
    }
    
    /// Create a network error from URLError
    static func fromURLError(_ error: URLError) -> GoogleSheetsError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
}