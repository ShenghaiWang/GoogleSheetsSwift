# GoogleSheetsSwift

A modern, Swift-native SDK for the Google Sheets API v4. Built with async/await, comprehensive error handling, and developer experience in mind.

[![Swift 5.7+](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-blue.svg)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## Features

- ✅ **Modern Swift**: Built with async/await, Codable, and Swift concurrency
- ✅ **Comprehensive API Coverage**: Full support for Google Sheets API v4
- ✅ **Type Safety**: Strongly-typed models and responses
- ✅ **OAuth2 & API Key Authentication**: Flexible authentication options
- ✅ **Performance Optimized**: Built-in caching, batch operations, and memory efficiency
- ✅ **Error Handling**: Comprehensive error types with recovery suggestions
- ✅ **Logging & Debugging**: Configurable logging for development and production
- ✅ **Zero Dependencies**: Lightweight with no external dependencies
- ✅ **Extensive Testing**: Unit tests, integration tests, and performance tests

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add GoogleSheetsSwift to your project using Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/ShenghaiWang/GoogleSheetsSwift.git`
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ShenghaiWang/GoogleSheetsSwift.git", from: "1.0.0")
]
```

## Quick Start

### 1. Authentication Setup

#### OAuth2 Authentication (Recommended)

```swift
import GoogleSheetsSwift

// Create OAuth2 token manager
let tokenManager = GoogleOAuth2TokenManager(
    clientId: "your-client-id",
    clientSecret: "your-client-secret", 
    redirectURI: "your-redirect-uri"
)

// Authenticate with required scopes
let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
let authResult = try await tokenManager.authenticate(scopes: scopes)

// Create client
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

#### API Key Authentication (Read-only)

```swift
import GoogleSheetsSwift

// Create client with API key for read-only operations
let client = GoogleSheetsClient(apiKey: "your-api-key")
```

#### Service Account Authentication (Server-to-Server)

Service account authentication is ideal for server-side applications, automation scripts, and scenarios where you need to access Google Sheets without user interaction.

##### Setup

1. **Create a Service Account** in the [Google Cloud Console](https://console.cloud.google.com/)
2. **Download the JSON key file** for your service account
3. **Share your spreadsheet** with the service account email address (found in the JSON file)
4. **Enable the Google Sheets API** for your project

##### Authentication Methods

**Method 1: Load from JSON file**

```swift
import GoogleSheetsSwift

// Load service account from JSON file
let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
let client = GoogleSheetsClient(tokenManager: tokenManager)

// Now you can perform operations
let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
```

**Method 2: Load from environment variable**

```swift
import GoogleSheetsSwift

// Set environment variable: GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

**Method 3: Initialize directly with ServiceAccountKey**

```swift
import GoogleSheetsSwift

// Load and parse the service account JSON
let serviceAccountData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/service-account.json"))
let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: serviceAccountData)

// Create token manager
let tokenManager = ServiceAccountTokenManager(serviceAccountKey: serviceAccountKey)
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

##### Domain-Wide Delegation (G Suite/Google Workspace)

If you need to impersonate users in your organization:

```swift
// Set up service account with domain-wide delegation
let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")

// Impersonate a specific user
tokenManager.setImpersonationUser("user@yourdomain.com")

let client = GoogleSheetsClient(tokenManager: tokenManager)

// Operations will be performed as the impersonated user
let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")

// Clear impersonation to return to service account identity
tokenManager.clearImpersonationUser()
```

##### Service Account JSON Structure

Your service account JSON file should contain:

```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "your-service-account@your-project.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project.iam.gserviceaccount.com"
}
```

##### Error Handling

```swift
do {
    let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    let values = try await client.readRange("spreadsheet-id", range: "A1:B2")
    // Process values
} catch GoogleSheetsError.authenticationFailed(let message) {
    print("Service account authentication failed: \(message)")
    // Check your service account JSON file and permissions
} catch CocoaError.fileReadNoSuchFile {
    print("Service account JSON file not found")
    // Verify the file path
} catch DecodingError.keyNotFound(let key, _) {
    print("Invalid service account JSON: missing key '\(key.stringValue)'")
    // Check your JSON file format
} catch {
    print("Unexpected error: \(error)")
}
```

##### Best Practices

1. **Secure Storage**: Never commit service account JSON files to version control
2. **Environment Variables**: Use `GOOGLE_APPLICATION_CREDENTIALS` in production
3. **Minimal Permissions**: Only grant necessary scopes to your service account
4. **Share Spreadsheets**: Remember to share spreadsheets with the service account email
5. **Key Rotation**: Regularly rotate service account keys for security

##### Example: Automated Data Processing

```swift
import GoogleSheetsSwift

class SpreadsheetProcessor {
    private let client: GoogleSheetsClient
    
    init() throws {
        // Load service account from environment
        let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
    }
    
    func processMonthlyData() async throws {
        let spreadsheetId = "your-spreadsheet-id"
        
        // Read raw data
        let rawData = try await client.readStringValues(
            spreadsheetId,
            range: "RawData!A2:E1000"
        )
        
        // Process data (example: calculate totals)
        var processedData: [[String]] = [["Category", "Total", "Average"]]
        
        // Group by category and calculate totals
        let groupedData = Dictionary(grouping: rawData) { row in
            row[0] ?? "Unknown" // Group by first column
        }
        
        for (category, rows) in groupedData {
            let values = rows.compactMap { row in
                Double(row[1] ?? "0") // Sum second column
            }
            let total = values.reduce(0, +)
            let average = values.isEmpty ? 0 : total / Double(values.count)
            
            processedData.append([
                category,
                String(format: "%.2f", total),
                String(format: "%.2f", average)
            ])
        }
        
        // Write processed data to summary sheet
        try await client.writeRange(
            spreadsheetId,
            range: "Summary!A1:C\(processedData.count)",
            values: processedData
        )
        
        print("Processed \(rawData.count) rows into \(processedData.count - 1) categories")
    }
}

// Usage
do {
    let processor = try SpreadsheetProcessor()
    try await processor.processMonthlyData()
} catch {
    print("Processing failed: \(error)")
}
```

### 2. Basic Operations

#### Reading Data

```swift
// Read values from a range
let values = try await client.readRange(
    "your-spreadsheet-id",
    range: "Sheet1!A1:C10"
)

// Get string values directly
let stringValues = try await client.readStringValues(
    "your-spreadsheet-id", 
    range: "Sheet1!A1:C10"
)

print("First cell: \(stringValues[0][0] ?? "Empty")")
```

#### Writing Data

```swift
// Write data to a range
let data = [
    ["Name", "Age", "City"],
    ["John", "25", "New York"],
    ["Jane", "30", "San Francisco"]
]

let response = try await client.writeRange(
    "your-spreadsheet-id",
    range: "Sheet1!A1:C3",
    values: data
)

print("Updated \(response.updatedCells ?? 0) cells")
```

#### Creating Spreadsheets

```swift
// Create a new spreadsheet
let spreadsheet = try await client.createSpreadsheet(
    title: "My New Spreadsheet",
    sheetTitles: ["Data", "Analysis"]
)

print("Created spreadsheet: \(spreadsheet.spreadsheetId ?? "unknown")")
```

## Advanced Usage

### Batch Operations

```swift
// Batch read multiple ranges
let operations = [
    BatchReadOperation(range: "Sheet1!A1:C10"),
    BatchReadOperation(range: "Sheet2!A1:D5")
]

let results = try await client.batchRead(
    "your-spreadsheet-id",
    operations: operations
)

// Batch write to multiple ranges
let writeOperations = [
    BatchWriteOperation(range: "Sheet1!A1:B2", values: [["A1", "B1"], ["A2", "B2"]]),
    BatchWriteOperation(range: "Sheet1!D1:E2", values: [["D1", "E1"], ["D2", "E2"]])
]

let writeResponse = try await client.batchWrite(
    "your-spreadsheet-id",
    operations: writeOperations
)
```

### Custom Configuration

```swift
// Create client with custom configuration
let logger = ConsoleGoogleSheetsLogger(minimumLevel: .debug)
let cache = InMemoryResponseCache()
let cacheConfig = CacheConfiguration(ttl: 300, maxSize: 100)

let client = GoogleSheetsClient(
    tokenManager: tokenManager,
    logger: logger,
    cache: cache,
    cacheConfiguration: cacheConfig
)

// Enable debug mode
client.setDebugMode(true)
```

### Error Handling

```swift
do {
    let values = try await client.readRange("spreadsheet-id", range: "A1:B2")
    // Process values
} catch GoogleSheetsError.authenticationFailed(let message) {
    print("Authentication failed: \(message)")
} catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
    print("Rate limited. Retry after: \(retryAfter ?? 0) seconds")
} catch GoogleSheetsError.invalidSpreadsheetId(let id) {
    print("Invalid spreadsheet ID: \(id)")
} catch {
    print("Unexpected error: \(error)")
}
```

### A1 Notation Utilities

```swift
// Validate A1 notation
let isValid = GoogleSheetsClient.isValidA1Range("Sheet1!A1:B10")

// Convert column numbers to letters
let columnLetter = GoogleSheetsClient.columnNumberToLetters(27) // "AA"

// Convert column letters to numbers  
let columnNumber = try GoogleSheetsClient.columnLettersToNumber("AA") // 27

// Build A1 ranges programmatically
let range = GoogleSheetsClient.buildA1Range(
    sheetName: "Data",
    startColumn: 1, startRow: 1,
    endColumn: 5, endRow: 100
) // "Data!A1:E100"
```

## API Reference

### Core Classes

#### `GoogleSheetsClient`

The main entry point for all Google Sheets operations.

**Initialization:**
```swift
// OAuth2 authentication
init(tokenManager: OAuth2TokenManager, httpClient: HTTPClient? = nil, logger: GoogleSheetsLogger? = nil)

// API key authentication  
init(apiKey: String, httpClient: HTTPClient? = nil, logger: GoogleSheetsLogger? = nil)
```

**Properties:**
- `spreadsheets: SpreadsheetsServiceProtocol` - Spreadsheet management operations
- `values: ValuesServiceProtocol` - Values read/write operations

**Key Methods:**
- `readRange(_:range:majorDimension:valueRenderOption:)` - Read values from a range
- `writeRange(_:range:values:majorDimension:valueInputOption:)` - Write values to a range
- `createSpreadsheet(title:sheetTitles:)` - Create a new spreadsheet
- `batchRead(_:operations:)` - Batch read operations
- `batchWrite(_:operations:valueInputOption:)` - Batch write operations

### Data Models

#### `ValueRange`

Represents a range of values in a spreadsheet.

```swift
public struct ValueRange: Codable {
    public let range: String?
    public let majorDimension: MajorDimension?
    public let values: [[AnyCodable]]?
    
    // Convenience methods
    public func getStringValues() -> [[String?]]
    public func getDoubleValues() -> [[Double?]]
}
```

#### `Spreadsheet`

Represents a Google Sheets spreadsheet.

```swift
public struct Spreadsheet: Codable {
    public let spreadsheetId: String?
    public let properties: SpreadsheetProperties?
    public let sheets: [Sheet]?
    public let namedRanges: [NamedRange]?
    public let spreadsheetUrl: String?
}
```

### Enums

#### `MajorDimension`

Specifies how data should be interpreted.

```swift
public enum MajorDimension: String, Codable {
    case rows = "ROWS"
    case columns = "COLUMNS"
}
```

#### `ValueRenderOption`

Specifies how values should be rendered.

```swift
public enum ValueRenderOption: String, Codable {
    case formattedValue = "FORMATTED_VALUE"
    case unformattedValue = "UNFORMATTED_VALUE" 
    case formula = "FORMULA"
}
```

#### `ValueInputOption`

Specifies how input data should be interpreted.

```swift
public enum ValueInputOption: String, Codable {
    case raw = "RAW"
    case userEntered = "USER_ENTERED"
}
```

### Error Handling

#### `GoogleSheetsError`

Comprehensive error types for different failure scenarios.

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
}
```

## Performance Features

### Caching

The SDK includes built-in response caching for read operations:

```swift
// Configure caching
let cacheConfig = CacheConfiguration(
    ttl: 300,        // 5 minutes
    maxSize: 100,    // Maximum 100 cached responses
    enabled: true
)

let cache = InMemoryResponseCache()
let client = GoogleSheetsClient(
    tokenManager: tokenManager,
    cache: cache,
    cacheConfiguration: cacheConfig
)
```

### Batch Optimization

The SDK automatically optimizes batch operations:

```swift
// The SDK will optimize these operations for better performance
let batchOptimizer = BatchOptimizer()
let client = GoogleSheetsClient(
    tokenManager: tokenManager,
    batchOptimizer: batchOptimizer
)
```

### Memory Efficiency

For large datasets, the SDK provides memory-efficient handling:

```swift
let memoryHandler = MemoryEfficientDataHandler()
let client = GoogleSheetsClient(
    tokenManager: tokenManager,
    memoryHandler: memoryHandler
)
```

## Logging and Debugging

### Console Logging

```swift
let logger = ConsoleGoogleSheetsLogger(
    minimumLevel: .debug,
    includeTimestamp: true,
    includeMetadata: true
)

let client = GoogleSheetsClient(tokenManager: tokenManager, logger: logger)
```

### File Logging

```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let logFileURL = documentsPath.appendingPathComponent("sheets-sdk.log")

if let fileLogger = FileGoogleSheetsLogger(fileURL: logFileURL) {
    let client = GoogleSheetsClient(tokenManager: tokenManager, logger: fileLogger)
}
```

### Custom Logging

```swift
class CustomLogger: GoogleSheetsLogger {
    func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        // Your custom logging implementation
    }
    
    func isEnabled(for level: LogLevel) -> Bool {
        return level >= .info
    }
}

let client = GoogleSheetsClient(tokenManager: tokenManager, logger: CustomLogger())
```

## Testing

The SDK includes comprehensive testing utilities:

### Mock Objects

```swift
import GoogleSheetsSwift

// Use mock objects for testing
let mockTokenManager = MockOAuth2TokenManager()
let mockHTTPClient = MockHTTPClient()

let client = GoogleSheetsClient(
    tokenManager: mockTokenManager,
    httpClient: mockHTTPClient
)

// Configure mock responses
mockHTTPClient.responses["spreadsheets/test-id/values/A1:B2"] = ValueRange(
    range: "A1:B2",
    values: [["A1", "B1"], ["A2", "B2"]]
)
```

### Integration Tests

The SDK includes integration tests that can run against the real Google Sheets API:

```swift
// Set environment variables for integration tests
// GOOGLE_SHEETS_CLIENT_ID=your-client-id
// GOOGLE_SHEETS_CLIENT_SECRET=your-client-secret
// GOOGLE_SHEETS_TEST_SPREADSHEET_ID=your-test-spreadsheet-id

swift test --filter IntegrationTests
```

## Examples

### Example 1: Simple Data Import

```swift
import GoogleSheetsSwift

func importDataToSheet() async throws {
    let client = GoogleSheetsClient(apiKey: "your-api-key")
    
    let csvData = [
        ["Product", "Price", "Stock"],
        ["iPhone", "999", "50"],
        ["iPad", "599", "30"],
        ["MacBook", "1299", "20"]
    ]
    
    let response = try await client.writeRange(
        "your-spreadsheet-id",
        range: "Products!A1:C4",
        values: csvData
    )
    
    print("Imported \(response.updatedRows ?? 0) rows")
}
```

### Example 2: Data Analysis

```swift
import GoogleSheetsSwift

func analyzeSheetData() async throws {
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Read sales data
    let salesData = try await client.readStringValues(
        "your-spreadsheet-id",
        range: "Sales!B2:B100" // Assuming column B contains sales amounts
    )
    
    // Calculate total sales
    let totalSales = salesData.compactMap { row in
        row.first?.flatMap(Double.init)
    }.reduce(0, +)
    
    // Write result back to sheet
    try await client.writeRange(
        "your-spreadsheet-id",
        range: "Summary!A1:B1",
        values: [["Total Sales", String(totalSales)]]
    )
    
    print("Total sales: $\(totalSales)")
}
```

### Example 3: Automated Report Generation

```swift
import GoogleSheetsSwift

func generateMonthlyReport() async throws {
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Create new spreadsheet for the report
    let spreadsheet = try await client.createSpreadsheet(
        title: "Monthly Report - \(DateFormatter().string(from: Date()))",
        sheetTitles: ["Summary", "Details", "Charts"]
    )
    
    guard let spreadsheetId = spreadsheet.spreadsheetId else {
        throw GoogleSheetsError.invalidResponse
    }
    
    // Add headers
    let headers = [["Metric", "Value", "Change"]]
    try await client.writeRange(
        spreadsheetId,
        range: "Summary!A1:C1",
        values: headers
    )
    
    // Add sample data
    let reportData = [
        ["Revenue", "50000", "+5%"],
        ["Customers", "1250", "+12%"],
        ["Orders", "890", "+8%"]
    ]
    
    try await client.writeRange(
        spreadsheetId,
        range: "Summary!A2:C4",
        values: reportData
    )
    
    print("Report created: \(spreadsheet.spreadsheetUrl ?? "Unknown URL")")
}
```

## Best Practices

### 1. Authentication

- Use OAuth2 for applications that modify data
- Use API keys only for read-only operations
- Store credentials securely (use Keychain on iOS/macOS)
- Handle token refresh automatically

### 2. Error Handling

- Always handle `GoogleSheetsError` cases specifically
- Implement retry logic for rate limiting
- Provide user-friendly error messages
- Log errors for debugging

### 3. Performance

- Use batch operations for multiple ranges
- Enable caching for frequently accessed data
- Use appropriate value render options
- Consider memory usage for large datasets

### 4. Rate Limiting

- Respect Google's API quotas
- Implement exponential backoff
- Use batch operations to reduce API calls
- Monitor your usage

## Troubleshooting

### Common Issues

#### Authentication Errors

```swift
// Check if tokens are valid
if !tokenManager.isAuthenticated {
    try await tokenManager.authenticate(scopes: scopes)
}
```

#### Rate Limiting

```swift
// Handle rate limiting gracefully
do {
    let result = try await client.readRange(spreadsheetId, range: range)
} catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
    // Wait and retry
    try await Task.sleep(nanoseconds: UInt64((retryAfter ?? 1) * 1_000_000_000))
    // Retry the operation
}
```

#### Invalid Ranges

```swift
// Validate ranges before using
if GoogleSheetsClient.isValidA1Range(range) {
    let result = try await client.readRange(spreadsheetId, range: range)
} else {
    print("Invalid range format: \(range)")
}
```

### Debug Mode

Enable debug mode to see detailed API interactions:

```swift
client.setDebugMode(true)
```

This will log all HTTP requests and responses, helping you debug issues.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Open in Xcode or use Swift Package Manager
3. Run tests: `swift test`
4. Run integration tests: `swift test --filter IntegrationTests`

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter GoogleSheetsClientTests

# Run integration tests (requires credentials)
swift test --filter IntegrationTests
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://your-username.github.io/GoogleSheetsSwift)
- 🐛 [Issue Tracker](https://github.com/your-username/GoogleSheetsSwift/issues)
- 💬 [Discussions](https://github.com/your-username/GoogleSheetsSwift/discussions)

## Acknowledgments

- Google Sheets API v4 documentation
- Swift community for best practices
- Contributors and testers

---

Made with ❤️ by the GoogleSheetsSwift team