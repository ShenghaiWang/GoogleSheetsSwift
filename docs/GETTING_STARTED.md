# Getting Started with GoogleSheetsSwift

This guide will help you get up and running with GoogleSheetsSwift quickly, covering all authentication methods and common use cases.

## Table of Contents

1. [Installation](#installation)
2. [Authentication Methods](#authentication-methods)
   - [API Key Authentication](#api-key-authentication)
   - [OAuth2 Authentication](#oauth2-authentication)
   - [Service Account Authentication](#service-account-authentication)
3. [Basic Operations](#basic-operations)
4. [Advanced Features](#advanced-features)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

## Installation

Add GoogleSheetsSwift to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/GoogleSheetsSwift", from: "1.0.0")
]
```

## Authentication Methods

### API Key Authentication

Best for: Read-only operations, simple applications, public data

#### Setup Steps:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Sheets API
4. Create an API key in "Credentials"
5. Restrict the API key to Google Sheets API (recommended)

#### Usage:

```swift
import GoogleSheetsSwift

let client = GoogleSheetsClient(apiKey: "your-api-key")

// Read data (read-only operations only)
let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
```

### OAuth2 Authentication

Best for: Interactive applications, user-specific data access

#### Setup Steps:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Configure authorized redirect URIs
4. Download the client configuration

#### Usage:

```swift
import GoogleSheetsSwift

let tokenManager = GoogleOAuth2TokenManager(
    clientId: "your-client-id",
    clientSecret: "your-client-secret",
    redirectURI: "your-redirect-uri"
)

// Build authorization URL
let authURL = tokenManager.buildAuthorizationURL(
    scopes: ["https://www.googleapis.com/auth/spreadsheets"]
)

// Open authURL in browser/web view, get authorization code
// Exchange code for tokens
let authResult = try await tokenManager.exchangeAuthorizationCode("authorization-code")

let client = GoogleSheetsClient(tokenManager: tokenManager)
```

### Service Account Authentication

Best for: Server-side applications, automation, background processing

#### Setup Steps:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "IAM & Admin" → "Service Accounts"
3. Create a new service account
4. Generate and download a JSON key file
5. Share your spreadsheets with the service account email

#### Method 1: Load from File

```swift
import GoogleSheetsSwift

// Load service account credentials from JSON file
let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
let client = GoogleSheetsClient(tokenManager: tokenManager)

// Perform operations
let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
```

#### Method 2: Environment Variable

```swift
import GoogleSheetsSwift

// Set environment variable: GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

#### Method 3: Direct Initialization

```swift
import GoogleSheetsSwift

let serviceAccountData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/service-account.json"))
let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: serviceAccountData)

let tokenManager = ServiceAccountTokenManager(serviceAccountKey: serviceAccountKey)
let client = GoogleSheetsClient(tokenManager: tokenManager)
```

#### Domain-Wide Delegation (G Suite/Google Workspace)

For impersonating users in your organization:

```swift
let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")

// Impersonate a specific user
tokenManager.setImpersonationUser("user@yourdomain.com")

let client = GoogleSheetsClient(tokenManager: tokenManager)

// Operations will be performed as the impersonated user
let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")

// Clear impersonation
tokenManager.clearImpersonationUser()
```

## Basic Operations

### Reading Data

```swift
// Read values from a range
let valueRange = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")

// Get string values directly
let stringValues = try await client.readStringValues("spreadsheet-id", range: "Sheet1!A1:C10")

// Access individual cells
if let firstRow = stringValues.first, let firstCell = firstRow.first {
    print("First cell value: \(firstCell ?? "Empty")")
}
```

### Writing Data

```swift
// Prepare data
let data = [
    ["Name", "Age", "City"],
    ["John Doe", "25", "New York"],
    ["Jane Smith", "30", "San Francisco"]
]

// Write to spreadsheet
let response = try await client.writeRange(
    "spreadsheet-id",
    range: "Sheet1!A1:C3",
    values: data
)

print("Updated \(response.updatedCells ?? 0) cells")
```

### Creating Spreadsheets

```swift
let spreadsheet = try await client.createSpreadsheet(
    title: "My New Spreadsheet",
    sheetTitles: ["Data", "Analysis", "Summary"]
)

print("Created spreadsheet: \(spreadsheet.spreadsheetId ?? "unknown")")
print("URL: \(spreadsheet.spreadsheetUrl ?? "unknown")")
```

### Appending Data

```swift
let newData = [
    ["Bob Johnson", "28", "Chicago"],
    ["Alice Brown", "32", "Boston"]
]

let response = try await client.appendToRange(
    "spreadsheet-id",
    range: "Sheet1!A:C",
    values: newData
)

print("Added \(response.updates?.updatedRows ?? 0) rows")
```

### Clearing Data

```swift
let response = try await client.clearRange("spreadsheet-id", range: "Sheet1!A1:C10")
print("Cleared range: \(response.clearedRange ?? "unknown")")
```

## Advanced Features

### Batch Operations

```swift
// Batch read multiple ranges
let readOperations = [
    BatchReadOperation(range: "Sheet1!A1:C10"),
    BatchReadOperation(range: "Sheet2!A1:D5"),
    BatchReadOperation(range: "Summary!A1:B20")
]

let results = try await client.batchRead("spreadsheet-id", operations: readOperations)

for (index, result) in results.enumerated() {
    print("Range \(index): \(result.values?.count ?? 0) rows")
}

// Batch write to multiple ranges
let writeOperations = [
    BatchWriteOperation(range: "Sheet1!A1:B2", values: [["A1", "B1"], ["A2", "B2"]]),
    BatchWriteOperation(range: "Sheet1!D1:E2", values: [["D1", "E1"], ["D2", "E2"]])
]

let writeResponse = try await client.batchWrite("spreadsheet-id", operations: writeOperations)
print("Total updated cells: \(writeResponse.totalUpdatedCells ?? 0)")
```

### Value Options

```swift
// Read with different render options
let formattedValues = try await client.readRange(
    "spreadsheet-id",
    range: "Sheet1!A1:C10",
    valueRenderOption: .formattedValue
)

let rawValues = try await client.readRange(
    "spreadsheet-id",
    range: "Sheet1!A1:C10",
    valueRenderOption: .unformattedValue
)

// Write with different input options
try await client.writeRange(
    "spreadsheet-id",
    range: "Sheet1!A1:C3",
    values: data,
    valueInputOption: .userEntered  // Interprets formulas
)

try await client.writeRange(
    "spreadsheet-id",
    range: "Sheet1!A1:C3",
    values: data,
    valueInputOption: .raw  // Treats everything as literal text
)
```

### A1 Notation Utilities

```swift
// Validate A1 notation
let isValid = GoogleSheetsClient.isValidA1Range("Sheet1!A1:B10")
print("Valid range: \(isValid)")

// Convert column numbers to letters
let columnLetter = GoogleSheetsClient.columnNumberToLetters(27) // "AA"

// Convert column letters to numbers
let columnNumber = try GoogleSheetsClient.columnLettersToNumber("AA") // 27

// Build ranges programmatically
let range = GoogleSheetsClient.buildA1Range(
    sheetName: "Data",
    startColumn: 1, startRow: 1,
    endColumn: 5, endRow: 100
) // "Data!A1:E100"
```

## Best Practices

### 1. Error Handling

Always handle specific error types:

```swift
do {
    let values = try await client.readRange("spreadsheet-id", range: "A1:B2")
    // Process values
} catch GoogleSheetsError.authenticationFailed(let message) {
    print("Authentication failed: \(message)")
    // Handle authentication error
} catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
    print("Rate limited. Retry after: \(retryAfter ?? 0) seconds")
    // Implement retry logic
} catch GoogleSheetsError.invalidSpreadsheetId(let id) {
    print("Invalid spreadsheet ID: \(id)")
    // Handle invalid ID
} catch GoogleSheetsError.invalidRange(let range) {
    print("Invalid range: \(range)")
    // Handle invalid range
} catch {
    print("Unexpected error: \(error)")
}
```

### 2. Rate Limiting

Implement proper retry logic:

```swift
func readRangeWithRetry(spreadsheetId: String, range: String, maxRetries: Int = 3) async throws -> ValueRange {
    var retryCount = 0
    
    while retryCount < maxRetries {
        do {
            return try await client.readRange(spreadsheetId, range: range)
        } catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
            let delay = retryAfter ?? pow(2.0, Double(retryCount)) // Exponential backoff
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            retryCount += 1
        }
    }
    
    throw GoogleSheetsError.rateLimitExceeded(retryAfter: nil)
}
```

### 3. Batch Operations

Use batch operations for better performance:

```swift
// Instead of multiple individual calls
// let range1 = try await client.readRange(id, range: "Sheet1!A1:C10")
// let range2 = try await client.readRange(id, range: "Sheet2!A1:D5")

// Use batch operations
let operations = [
    BatchReadOperation(range: "Sheet1!A1:C10"),
    BatchReadOperation(range: "Sheet2!A1:D5")
]
let results = try await client.batchRead(id, operations: operations)
```

### 4. Caching

Enable caching for frequently accessed data:

```swift
let cache = InMemoryResponseCache()
let cacheConfig = CacheConfiguration(ttl: 300, maxSize: 100, enabled: true)

let client = GoogleSheetsClient(
    tokenManager: tokenManager,
    cache: cache,
    cacheConfiguration: cacheConfig
)
```

### 5. Logging

Use logging for debugging and monitoring:

```swift
let logger = ConsoleGoogleSheetsLogger(minimumLevel: .info)
let client = GoogleSheetsClient(tokenManager: tokenManager, logger: logger)

// Enable debug mode for detailed logging
client.setDebugMode(true)
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors

**Problem**: `authenticationFailed` error

**Solutions**:
- Verify your credentials are correct
- Check that the Google Sheets API is enabled
- Ensure your service account has access to the spreadsheet
- Verify the spreadsheet is shared with the service account email

```swift
// Check authentication status
if !tokenManager.isAuthenticated {
    print("Token manager is not authenticated")
    // Re-authenticate or check credentials
}
```

#### 2. Permission Errors

**Problem**: `403 Forbidden` errors

**Solutions**:
- Share the spreadsheet with your service account email
- Check that your OAuth2 app has the correct scopes
- Verify the user has granted necessary permissions

#### 3. Invalid Range Errors

**Problem**: `invalidRange` error

**Solutions**:
- Validate A1 notation before using
- Check sheet names for typos
- Ensure the range exists in the spreadsheet

```swift
// Validate before using
if GoogleSheetsClient.isValidA1Range(range) {
    let result = try await client.readRange(spreadsheetId, range: range)
} else {
    print("Invalid range format: \(range)")
}
```

#### 4. Rate Limiting

**Problem**: `rateLimitExceeded` error

**Solutions**:
- Implement exponential backoff
- Use batch operations to reduce API calls
- Monitor your quota usage

#### 5. Network Issues

**Problem**: `networkError` errors

**Solutions**:
- Check internet connectivity
- Implement retry logic for transient failures
- Use appropriate timeouts

### Debug Mode

Enable debug mode to see detailed API interactions:

```swift
client.setDebugMode(true)
```

This will log:
- HTTP requests and responses
- Authentication attempts
- Rate limiting information
- Error details

### Testing

Use mock objects for testing:

```swift
let mockTokenManager = MockOAuth2TokenManager()
let mockHTTPClient = MockHTTPClient()

let client = GoogleSheetsClient(
    tokenManager: mockTokenManager,
    httpClient: mockHTTPClient
)

// Configure mock responses
mockHTTPClient.mockResponse(for: "spreadsheets/test-id/values/A1:B2", response: ValueRange(
    range: "A1:B2",
    values: [["A1", "B1"], ["A2", "B2"]]
))
```

## Next Steps

- Explore the [API Reference](README.md#api-reference) for detailed documentation
- Check out the [Examples](README.md#examples) for more use cases
- Review the [Performance Features](README.md#performance-features) for optimization
- Set up [Integration Tests](README.md#integration-tests) for your application

For more help, visit our [GitHub Issues](https://github.com/your-username/GoogleSheetsSwift/issues) or [Discussions](https://github.com/your-username/GoogleSheetsSwift/discussions).