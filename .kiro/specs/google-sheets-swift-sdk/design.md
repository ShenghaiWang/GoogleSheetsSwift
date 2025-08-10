# Design Document

## Overview

The Google Sheets Swift SDK provides a modern, Swift-native interface for interacting with the Google Sheets API v4. The SDK is designed with a focus on type safety, async/await patterns, and developer experience. It abstracts the complexity of HTTP requests and JSON parsing while providing comprehensive access to Google Sheets functionality.

The SDK follows Swift best practices including:
- Protocol-oriented design for testability and flexibility
- Comprehensive error handling with custom error types
- Async/await for all network operations
- Codable conformance for all data models
- Swift Package Manager integration

## Architecture

The SDK follows a layered architecture pattern:

```
┌─────────────────────────────────────┐
│           Client Layer              │
│  (GoogleSheetsClient)               │
├─────────────────────────────────────┤
│          Service Layer              │
│ (SpreadsheetsService, ValuesService)│
├─────────────────────────────────────┤
│         Transport Layer             │
│    (HTTPClient, RequestBuilder)     │
├─────────────────────────────────────┤
│        Authentication Layer         │
│      (OAuth2TokenManager)           │
└─────────────────────────────────────┘
```

### Core Components

1. **GoogleSheetsClient**: Main entry point providing high-level API access
2. **Service Classes**: Domain-specific services (Spreadsheets, Values, etc.)
3. **HTTPClient**: Handles HTTP communication with Google APIs
4. **OAuth2TokenManager**: Manages authentication tokens and refresh logic
5. **Data Models**: Swift structs representing API responses and requests
6. **Error Types**: Comprehensive error handling for different failure scenarios

## Components and Interfaces

### 1. Main Client Interface

```swift
public class GoogleSheetsClient {
    public let spreadsheets: SpreadsheetsService
    public let values: ValuesService
    
    public init(tokenManager: OAuth2TokenManager)
    public func setAPIKey(_ apiKey: String)
}
```

### 2. Authentication Component

```swift
public protocol OAuth2TokenManager {
    func getAccessToken() async throws -> String
    func refreshToken() async throws -> String
    var isAuthenticated: Bool { get }
}

public class GoogleOAuth2TokenManager: OAuth2TokenManager {
    public init(clientId: String, clientSecret: String, redirectURI: String)
    public func authenticate(scopes: [String]) async throws -> AuthResult
}

public class ServiceAccountTokenManager: OAuth2TokenManager {
    public init(serviceAccountKey: ServiceAccountKey)
    public init(serviceAccountKeyPath: String) throws
    public func setImpersonationUser(_ email: String)
    public func authenticate(scopes: [String]) async throws -> AuthResult
}

public struct ServiceAccountKey: Codable {
    public let type: String
    public let projectId: String
    public let privateKeyId: String
    public let privateKey: String
    public let clientEmail: String
    public let clientId: String
    public let authUri: String
    public let tokenUri: String
    public let authProviderX509CertUrl: String
    public let clientX509CertUrl: String
}
```

### 3. Service Interfaces

```swift
public class SpreadsheetsService {
    func create(_ spreadsheet: SpreadsheetCreateRequest) async throws -> Spreadsheet
    func get(spreadsheetId: String, ranges: [String]? = nil, includeGridData: Bool = false) async throws -> Spreadsheet
    func batchUpdate(spreadsheetId: String, requests: [Request]) async throws -> BatchUpdateSpreadsheetResponse
}

public class ValuesService {
    func get(spreadsheetId: String, range: String, options: ValueGetOptions? = nil) async throws -> ValueRange
    func update(spreadsheetId: String, range: String, values: ValueRange, options: ValueUpdateOptions? = nil) async throws -> UpdateValuesResponse
    func append(spreadsheetId: String, range: String, values: ValueRange, options: ValueAppendOptions? = nil) async throws -> AppendValuesResponse
    func clear(spreadsheetId: String, range: String) async throws -> ClearValuesResponse
    func batchGet(spreadsheetId: String, ranges: [String], options: ValueGetOptions? = nil) async throws -> BatchGetValuesResponse
}
```

### 4. HTTP Transport Layer

```swift
protocol HTTPClient {
    func execute<T: Codable>(_ request: HTTPRequest) async throws -> T
}

struct HTTPRequest {
    let method: HTTPMethod
    let url: URL
    let headers: [String: String]
    let body: Data?
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}
```

## Data Models

### Core Models

```swift
public struct Spreadsheet: Codable {
    public let spreadsheetId: String?
    public let properties: SpreadsheetProperties?
    public let sheets: [Sheet]?
    public let namedRanges: [NamedRange]?
    public let spreadsheetUrl: String?
    public let developerMetadata: [DeveloperMetadata]?
}

public struct SpreadsheetProperties: Codable {
    public let title: String?
    public let locale: String?
    public let autoRecalc: RecalculationInterval?
    public let timeZone: String?
    public let defaultFormat: CellFormat?
}

public struct ValueRange: Codable {
    public let range: String?
    public let majorDimension: MajorDimension?
    public let values: [[AnyCodable]]?
    
    public init(range: String? = nil, majorDimension: MajorDimension? = nil, values: [[Any]]? = nil)
}

public struct Sheet: Codable {
    public let properties: SheetProperties?
    public let data: [GridData]?
    public let merges: [GridRange]?
    public let conditionalFormats: [ConditionalFormatRule]?
}
```

### Enums and Options

```swift
public enum MajorDimension: String, Codable {
    case dimensionUnspecified = "DIMENSION_UNSPECIFIED"
    case rows = "ROWS"
    case columns = "COLUMNS"
}

public enum ValueRenderOption: String, Codable {
    case formattedValue = "FORMATTED_VALUE"
    case unformattedValue = "UNFORMATTED_VALUE"
    case formula = "FORMULA"
}

public enum ValueInputOption: String, Codable {
    case inputValueOptionUnspecified = "INPUT_VALUE_OPTION_UNSPECIFIED"
    case raw = "RAW"
    case userEntered = "USER_ENTERED"
}

public struct ValueGetOptions {
    public let majorDimension: MajorDimension?
    public let valueRenderOption: ValueRenderOption?
    public let dateTimeRenderOption: DateTimeRenderOption?
}

public struct ValueUpdateOptions {
    public let valueInputOption: ValueInputOption?
    public let includeValuesInResponse: Bool?
    public let responseValueRenderOption: ValueRenderOption?
    public let responseDateTimeRenderOption: DateTimeRenderOption?
}
```

### Type-Safe Value Handling

```swift
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? NSNull()
    }
    
    public func get<T>() -> T? {
        return value as? T
    }
}

extension ValueRange {
    public func getStringValues() -> [[String?]] {
        return values?.map { row in
            row.map { $0.get() }
        } ?? []
    }
    
    public func getDoubleValues() -> [[Double?]] {
        return values?.map { row in
            row.map { $0.get() }
        } ?? []
    }
}
```

## Error Handling

### Custom Error Types

```swift
public enum GoogleSheetsError: Error, LocalizedError {
    case authenticationFailed(String)
    case invalidSpreadsheetId(String)
    case invalidRange(String)
    case networkError(Error)
    case apiError(code: Int, message: String)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case quotaExceeded
    case invalidResponse
    case tokenExpired
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidSpreadsheetId(let id):
            return "Invalid spreadsheet ID: \(id)"
        case .invalidRange(let range):
            return "Invalid range: \(range)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after: \(retryAfter?.description ?? "unknown")"
        case .quotaExceeded:
            return "API quota exceeded"
        case .invalidResponse:
            return "Invalid response from server"
        case .tokenExpired:
            return "Access token expired"
        }
    }
}
```

### Error Recovery and Retry Logic

```swift
public struct RetryConfiguration {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let backoffMultiplier: Double
    
    public static let `default` = RetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        maxDelay: 60.0,
        backoffMultiplier: 2.0
    )
}

extension HTTPClient {
    func executeWithRetry<T: Codable>(_ request: HTTPRequest, retryConfig: RetryConfiguration = .default) async throws -> T {
        // Implements exponential backoff retry logic
        // Handles rate limiting (429) and temporary server errors (5xx)
    }
}
```

## Testing Strategy

### 1. Unit Testing Approach

- **Protocol-based mocking**: All major components implement protocols for easy mocking
- **Dependency injection**: Services accept their dependencies through initializers
- **Isolated testing**: Each component can be tested independently

### 2. Test Doubles

```swift
class MockHTTPClient: HTTPClient {
    var responses: [String: Any] = [:]
    var errors: [String: Error] = [:]
    
    func execute<T: Codable>(_ request: HTTPRequest) async throws -> T {
        // Return mock responses based on request URL
    }
}

class MockOAuth2TokenManager: OAuth2TokenManager {
    var mockToken: String = "mock_token"
    var shouldFail: Bool = false
    
    func getAccessToken() async throws -> String {
        if shouldFail {
            throw GoogleSheetsError.authenticationFailed("Mock failure")
        }
        return mockToken
    }
}
```

### 3. Integration Testing

- **Real API testing**: Optional integration tests against real Google Sheets API
- **Test spreadsheet**: Dedicated test spreadsheet for integration tests
- **Environment configuration**: Separate test credentials and configuration

### 4. Performance Testing

- **Response time benchmarks**: Measure typical API response times
- **Memory usage**: Monitor memory usage during large data operations
- **Concurrent operations**: Test behavior under concurrent API calls

## Implementation Considerations

### 1. Swift Package Manager Integration

```swift
// Package.swift
let package = Package(
    name: "GoogleSheetsSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "GoogleSheetsSwift", targets: ["GoogleSheetsSwift"])
    ],
    dependencies: [],
    targets: [
        .target(name: "GoogleSheetsSwift", dependencies: []),
        .testTarget(name: "GoogleSheetsSwiftTests", dependencies: ["GoogleSheetsSwift"])
    ]
)
```

### 2. Concurrency and Thread Safety

- All public APIs use async/await
- Internal state is protected with actors where necessary
- Token refresh operations are serialized to prevent race conditions

### 3. Memory Management

- Weak references used appropriately to prevent retain cycles
- Large responses can be processed in chunks
- Optional streaming support for very large datasets

### 4. Logging and Debugging

```swift
public protocol GoogleSheetsLogger {
    func log(level: LogLevel, message: String, metadata: [String: Any]?)
}

public enum LogLevel {
    case debug, info, warning, error
}

// Optional logging configuration
extension GoogleSheetsClient {
    public func setLogger(_ logger: GoogleSheetsLogger)
    public func setLogLevel(_ level: LogLevel)
}
```

### 5. Rate Limiting and Quotas

- Built-in rate limiting to respect Google's API limits
- Automatic retry with exponential backoff for rate limit errors
- Quota usage tracking and warnings

### 6. Caching Strategy

- Optional response caching for read operations
- Cache invalidation on write operations
- Configurable cache TTL and size limits

### 7. Service Account Authentication

Service account authentication enables server-to-server API access without user interaction, making it ideal for backend services and automation scenarios.

#### JWT Token Generation

```swift
internal class JWTGenerator {
    static func generateJWT(
        serviceAccountKey: ServiceAccountKey,
        scopes: [String],
        impersonationUser: String? = nil
    ) throws -> String {
        // Creates JWT with proper claims for Google OAuth2
        // Signs with RSA private key from service account
    }
}

internal struct JWTClaims: Codable {
    let iss: String // Service account email
    let scope: String // Space-delimited scopes
    let aud: String // Token endpoint URL
    let exp: Int // Expiration timestamp
    let iat: Int // Issued at timestamp
    let sub: String? // Impersonation user email (optional)
}
```

#### Service Account Key Management

```swift
extension ServiceAccountTokenManager {
    public static func loadFromFile(_ path: String) throws -> ServiceAccountTokenManager {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let key = try JSONDecoder().decode(ServiceAccountKey.self, from: data)
        return ServiceAccountTokenManager(serviceAccountKey: key)
    }
    
    public static func loadFromEnvironment() throws -> ServiceAccountTokenManager {
        // Loads from GOOGLE_APPLICATION_CREDENTIALS environment variable
    }
}
```

#### Domain-Wide Delegation Support

For G Suite/Google Workspace environments, service accounts can impersonate domain users:

```swift
// Usage example
let tokenManager = try ServiceAccountTokenManager.loadFromFile("service-account.json")
tokenManager.setImpersonationUser("user@company.com")
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

This design provides a robust, Swift-native SDK that abstracts the complexity of the Google Sheets API while maintaining flexibility and performance. The modular architecture allows for easy testing, maintenance, and future enhancements.