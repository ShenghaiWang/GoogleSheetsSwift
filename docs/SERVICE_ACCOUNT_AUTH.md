# Service Account Authentication Guide

This comprehensive guide covers everything you need to know about using service account authentication with GoogleSheetsSwift.

## Table of Contents

1. [Overview](#overview)
2. [When to Use Service Accounts](#when-to-use-service-accounts)
3. [Setup Process](#setup-process)
4. [Authentication Methods](#authentication-methods)
5. [Domain-Wide Delegation](#domain-wide-delegation)
6. [Security Best Practices](#security-best-practices)
7. [Error Handling](#error-handling)
8. [Examples](#examples)
9. [Troubleshooting](#troubleshooting)

## Overview

Service account authentication enables server-to-server communication with Google APIs without requiring user interaction. This is perfect for automated scripts, background processes, and server applications.

### Key Benefits

- **No User Interaction**: Authenticate without requiring user consent
- **Programmatic Access**: Perfect for automation and batch processing
- **Consistent Identity**: Service accounts have a fixed identity
- **Domain-Wide Delegation**: Can impersonate users in G Suite/Google Workspace
- **Secure**: Uses RSA key pairs for authentication

## When to Use Service Accounts

### ✅ Ideal Use Cases

- **Server-side applications** that process spreadsheet data
- **Automated reporting** and data synchronization
- **Batch processing** of spreadsheet operations
- **Background services** that don't require user interaction
- **CI/CD pipelines** that need to update documentation or reports
- **Data migration** and ETL processes

### ❌ Not Suitable For

- **Client-side applications** (mobile apps, web frontends)
- **Applications requiring user-specific permissions**
- **Interactive applications** where users need to grant consent
- **Public applications** where you can't secure the private key

## Setup Process

### Step 1: Create a Service Account

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Navigate to **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Fill in the service account details:
   - **Name**: Descriptive name (e.g., "Sheets Data Processor")
   - **Description**: Purpose of the service account
6. Click **Create and Continue**

### Step 2: Generate a Key

1. In the service accounts list, click on your newly created service account
2. Go to the **Keys** tab
3. Click **Add Key** → **Create New Key**
4. Select **JSON** format
5. Click **Create** - the key file will be downloaded automatically

### Step 3: Enable APIs

1. Go to **APIs & Services** → **Library**
2. Search for "Google Sheets API"
3. Click on it and press **Enable**

### Step 4: Share Spreadsheets

For each spreadsheet you want to access:

1. Open the spreadsheet in Google Sheets
2. Click **Share**
3. Add the service account email (found in the JSON file as `client_email`)
4. Grant appropriate permissions (Viewer, Editor, or Owner)

## Authentication Methods

### Method 1: Load from File Path

The most straightforward method for development and testing:

```swift
import GoogleSheetsSwift

do {
    let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Use the client
    let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
    print("Read \(values.values?.count ?? 0) rows")
} catch {
    print("Failed to load service account: \(error)")
}
```

### Method 2: Environment Variable (Recommended for Production)

Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

Then in your Swift code:

```swift
import GoogleSheetsSwift

do {
    let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Use the client
    let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
} catch GoogleSheetsError.authenticationFailed(let message) {
    print("Authentication failed: \(message)")
    print("Make sure GOOGLE_APPLICATION_CREDENTIALS is set correctly")
} catch {
    print("Error: \(error)")
}
```

### Method 3: Direct Initialization

For advanced scenarios where you need more control:

```swift
import GoogleSheetsSwift

do {
    // Load the JSON data
    let jsonURL = URL(fileURLWithPath: "/path/to/service-account.json")
    let jsonData = try Data(contentsOf: jsonURL)
    
    // Decode the service account key
    let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: jsonData)
    
    // Create token manager
    let tokenManager = ServiceAccountTokenManager(serviceAccountKey: serviceAccountKey)
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Use the client
    let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
} catch DecodingError.keyNotFound(let key, _) {
    print("Invalid service account JSON: missing key '\(key.stringValue)'")
} catch {
    print("Error: \(error)")
}
```

### Method 4: Embedded JSON (Not Recommended for Production)

For testing or when you need to embed credentials:

```swift
import GoogleSheetsSwift

let serviceAccountJSON = """
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n",
  "client_email": "your-service-account@your-project.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project.iam.gserviceaccount.com"
}
"""

do {
    let jsonData = serviceAccountJSON.data(using: .utf8)!
    let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: jsonData)
    let tokenManager = ServiceAccountTokenManager(serviceAccountKey: serviceAccountKey)
    let client = GoogleSheetsClient(tokenManager: tokenManager)
} catch {
    print("Error: \(error)")
}
```

## Domain-Wide Delegation

Domain-wide delegation allows a service account to impersonate users in your G Suite or Google Workspace domain.

### Setup Domain-Wide Delegation

1. **Enable Domain-Wide Delegation** for your service account:
   - Go to the Google Cloud Console
   - Navigate to your service account
   - Check "Enable G Suite Domain-wide Delegation"
   - Note the "Client ID" (numeric)

2. **Configure in Google Workspace Admin Console**:
   - Go to [admin.google.com](https://admin.google.com)
   - Navigate to **Security** → **API Controls** → **Domain-wide Delegation**
   - Click **Add new**
   - Enter the Client ID from step 1
   - Add the required scopes: `https://www.googleapis.com/auth/spreadsheets`

### Using Domain-Wide Delegation

```swift
import GoogleSheetsSwift

do {
    let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
    
    // Impersonate a specific user
    tokenManager.setImpersonationUser("user@yourdomain.com")
    
    let client = GoogleSheetsClient(tokenManager: tokenManager)
    
    // Operations will be performed as the impersonated user
    let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
    
    // Switch to a different user
    tokenManager.setImpersonationUser("admin@yourdomain.com")
    
    // Create a new spreadsheet as the admin user
    let spreadsheet = try await client.createSpreadsheet(title: "Admin Report")
    
    // Clear impersonation to return to service account identity
    tokenManager.clearImpersonationUser()
    
    // Check current impersonation status
    if let currentUser = tokenManager.currentImpersonationUser {
        print("Currently impersonating: \(currentUser)")
    } else {
        print("Using service account identity")
    }
    
} catch {
    print("Error: \(error)")
}
```

### Multiple User Operations

```swift
import GoogleSheetsSwift

class MultiUserSpreadsheetManager {
    private let tokenManager: ServiceAccountTokenManager
    private let client: GoogleSheetsClient
    
    init() throws {
        self.tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
    }
    
    func processUserData(users: [String], spreadsheetId: String) async throws {
        for user in users {
            // Impersonate each user
            tokenManager.setImpersonationUser(user)
            
            // Read user-specific data
            let userData = try await client.readRange(
                spreadsheetId,
                range: "UserData!\(user)!A1:Z100"
            )
            
            // Process the data
            let processedData = processData(userData)
            
            // Write results to user's summary sheet
            try await client.writeRange(
                spreadsheetId,
                range: "Summary!\(user)!A1:C10",
                values: processedData
            )
            
            print("Processed data for user: \(user)")
        }
        
        // Clear impersonation when done
        tokenManager.clearImpersonationUser()
    }
    
    private func processData(_ data: ValueRange) -> [[String]] {
        // Your data processing logic here
        return [["Processed", "Data", "Example"]]
    }
}
```

## Security Best Practices

### 1. Secure Key Storage

**❌ Never do this:**
```swift
// Don't hardcode credentials in source code
let privateKey = "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us8cKB..."
```

**✅ Do this instead:**
```swift
// Use environment variables or secure key management
let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
```

### 2. Environment Variables

Set up environment variables securely:

```bash
# In production, use your deployment system's secret management
export GOOGLE_APPLICATION_CREDENTIALS="/secure/path/to/service-account.json"

# For Docker containers
docker run -e GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json myapp

# For Kubernetes
kubectl create secret generic sheets-credentials --from-file=credentials.json
```

### 3. File Permissions

Secure your service account JSON files:

```bash
# Set restrictive permissions
chmod 600 /path/to/service-account.json
chown myapp:myapp /path/to/service-account.json

# Verify permissions
ls -la /path/to/service-account.json
# Should show: -rw------- 1 myapp myapp
```

### 4. Key Rotation

Regularly rotate your service account keys:

```swift
class SecureServiceAccountManager {
    private var tokenManager: ServiceAccountTokenManager?
    private let keyRotationInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    private var lastKeyRotation: Date?
    
    func getTokenManager() throws -> ServiceAccountTokenManager {
        if shouldRotateKey() {
            try rotateKey()
        }
        
        guard let tokenManager = tokenManager else {
            throw GoogleSheetsError.authenticationFailed("No token manager available")
        }
        
        return tokenManager
    }
    
    private func shouldRotateKey() -> Bool {
        guard let lastRotation = lastKeyRotation else { return true }
        return Date().timeIntervalSince(lastRotation) > keyRotationInterval
    }
    
    private func rotateKey() throws {
        // Load new key (implement your key rotation logic)
        tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        lastKeyRotation = Date()
    }
}
```

### 5. Minimal Permissions

Only grant necessary permissions:

```swift
// When sharing spreadsheets, use minimal permissions
// Viewer: Read-only access
// Editor: Read/write access (avoid if possible)
// Owner: Full control (only when necessary)
```

## Error Handling

### Common Errors and Solutions

```swift
import GoogleSheetsSwift

func handleServiceAccountErrors() async {
    do {
        let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")
        let client = GoogleSheetsClient(tokenManager: tokenManager)
        
        let values = try await client.readRange("spreadsheet-id", range: "Sheet1!A1:C10")
        
    } catch GoogleSheetsError.authenticationFailed(let message) {
        print("Authentication failed: \(message)")
        
        if message.contains("private key") {
            print("Solution: Check your service account JSON file format")
        } else if message.contains("JWT") {
            print("Solution: Verify your service account has the correct permissions")
        }
        
    } catch CocoaError.fileReadNoSuchFile {
        print("Service account file not found")
        print("Solution: Check the file path and ensure the file exists")
        
    } catch DecodingError.keyNotFound(let key, _) {
        print("Invalid service account JSON: missing key '\(key.stringValue)'")
        print("Solution: Re-download the service account JSON from Google Cloud Console")
        
    } catch DecodingError.dataCorrupted(let context) {
        print("Corrupted service account JSON: \(context.debugDescription)")
        print("Solution: Re-download the service account JSON file")
        
    } catch GoogleSheetsError.apiError(let code, let message) {
        switch code {
        case 403:
            print("Permission denied: \(message)")
            print("Solution: Share the spreadsheet with your service account email")
        case 404:
            print("Spreadsheet not found: \(message)")
            print("Solution: Check the spreadsheet ID and ensure it exists")
        default:
            print("API error \(code): \(message)")
        }
        
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

### Validation Helper

```swift
extension ServiceAccountTokenManager {
    static func validateServiceAccountFile(at path: String) throws -> Bool {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw GoogleSheetsError.authenticationFailed("Service account file not found at: \(path)")
        }
        
        // Check file permissions
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        
        if let perms = permissions, perms.intValue & 0o077 != 0 {
            print("Warning: Service account file has overly permissive permissions")
        }
        
        // Validate JSON structure
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: data)
        
        // Basic validation
        guard serviceAccountKey.type == "service_account" else {
            throw GoogleSheetsError.authenticationFailed("Invalid service account type")
        }
        
        guard !serviceAccountKey.privateKey.isEmpty else {
            throw GoogleSheetsError.authenticationFailed("Missing private key")
        }
        
        guard !serviceAccountKey.clientEmail.isEmpty else {
            throw GoogleSheetsError.authenticationFailed("Missing client email")
        }
        
        return true
    }
}

// Usage
do {
    try ServiceAccountTokenManager.validateServiceAccountFile(at: "/path/to/service-account.json")
    print("Service account file is valid")
} catch {
    print("Validation failed: \(error)")
}
```

## Examples

### Example 1: Automated Report Generation

```swift
import GoogleSheetsSwift
import Foundation

class AutomatedReportGenerator {
    private let client: GoogleSheetsClient
    
    init() throws {
        let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
    }
    
    func generateDailyReport() async throws {
        let today = DateFormatter().string(from: Date())
        
        // Create new spreadsheet for the report
        let spreadsheet = try await client.createSpreadsheet(
            title: "Daily Report - \(today)",
            sheetTitles: ["Summary", "Details", "Metrics"]
        )
        
        guard let spreadsheetId = spreadsheet.spreadsheetId else {
            throw GoogleSheetsError.invalidResponse
        }
        
        // Generate summary data
        let summaryData = [
            ["Metric", "Value", "Change"],
            ["Total Sales", "$50,000", "+5%"],
            ["New Customers", "125", "+12%"],
            ["Orders", "890", "+8%"]
        ]
        
        try await client.writeRange(
            spreadsheetId,
            range: "Summary!A1:C4",
            values: summaryData
        )
        
        // Generate detailed data
        let detailsData = generateDetailedData()
        try await client.writeRange(
            spreadsheetId,
            range: "Details!A1:E\(detailsData.count)",
            values: detailsData
        )
        
        print("Report generated: \(spreadsheet.spreadsheetUrl ?? "Unknown URL")")
    }
    
    private func generateDetailedData() -> [[String]] {
        // Your data generation logic here
        var data = [["Order ID", "Customer", "Amount", "Status", "Date"]]
        
        for i in 1...100 {
            data.append([
                "ORD-\(String(format: "%04d", i))",
                "Customer \(i)",
                "$\(Int.random(in: 10...500))",
                ["Pending", "Completed", "Cancelled"].randomElement()!,
                DateFormatter().string(from: Date())
            ])
        }
        
        return data
    }
}

// Usage
Task {
    do {
        let generator = try AutomatedReportGenerator()
        try await generator.generateDailyReport()
    } catch {
        print("Report generation failed: \(error)")
    }
}
```

### Example 2: Data Synchronization

```swift
import GoogleSheetsSwift

class DataSynchronizer {
    private let client: GoogleSheetsClient
    private let sourceSpreadsheetId: String
    private let targetSpreadsheetId: String
    
    init(sourceId: String, targetId: String) throws {
        let tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
        self.sourceSpreadsheetId = sourceId
        self.targetSpreadsheetId = targetId
    }
    
    func synchronizeData() async throws {
        // Read data from source
        let sourceData = try await client.readRange(
            sourceSpreadsheetId,
            range: "Data!A1:Z1000"
        )
        
        guard let values = sourceData.values, !values.isEmpty else {
            print("No data to synchronize")
            return
        }
        
        // Transform data if needed
        let transformedData = transformData(values)
        
        // Clear target range first
        try await client.clearRange(
            targetSpreadsheetId,
            range: "SyncedData!A1:Z1000"
        )
        
        // Write to target
        try await client.writeRange(
            targetSpreadsheetId,
            range: "SyncedData!A1:Z\(transformedData.count)",
            values: transformedData
        )
        
        // Add sync metadata
        let metadata = [
            ["Last Sync", DateFormatter().string(from: Date())],
            ["Records Synced", String(transformedData.count - 1)] // Subtract header row
        ]
        
        try await client.writeRange(
            targetSpreadsheetId,
            range: "Metadata!A1:B2",
            values: metadata
        )
        
        print("Synchronized \(transformedData.count - 1) records")
    }
    
    private func transformData(_ data: [[AnyCodable]]) -> [[String]] {
        // Your data transformation logic here
        return data.map { row in
            row.map { cell in
                cell.stringValue ?? ""
            }
        }
    }
}

// Usage with error handling
Task {
    do {
        let synchronizer = try DataSynchronizer(
            sourceId: "source-spreadsheet-id",
            targetId: "target-spreadsheet-id"
        )
        try await synchronizer.synchronizeData()
    } catch {
        print("Synchronization failed: \(error)")
    }
}
```

### Example 3: Batch Processing with Domain-Wide Delegation

```swift
import GoogleSheetsSwift

class BatchUserDataProcessor {
    private let tokenManager: ServiceAccountTokenManager
    private let client: GoogleSheetsClient
    
    init() throws {
        self.tokenManager = try ServiceAccountTokenManager.loadFromEnvironment()
        self.client = GoogleSheetsClient(tokenManager: tokenManager)
    }
    
    func processAllUserData(users: [String], templateSpreadsheetId: String) async throws {
        var results: [String: ProcessingResult] = [:]
        
        for user in users {
            do {
                let result = try await processUserData(user: user, templateId: templateSpreadsheetId)
                results[user] = result
                print("✅ Processed data for \(user)")
            } catch {
                results[user] = .failure(error)
                print("❌ Failed to process data for \(user): \(error)")
            }
        }
        
        // Generate summary report
        try await generateSummaryReport(results: results)
    }
    
    private func processUserData(user: String, templateId: String) async throws -> ProcessingResult {
        // Impersonate the user
        tokenManager.setImpersonationUser(user)
        
        // Read user's data
        let userData = try await client.readRange(
            templateId,
            range: "UserData!A1:Z100"
        )
        
        // Process the data
        let processedData = processData(userData)
        
        // Create user-specific spreadsheet
        let userSpreadsheet = try await client.createSpreadsheet(
            title: "Processed Data - \(user)",
            sheetTitles: ["Results", "Summary"]
        )
        
        guard let spreadsheetId = userSpreadsheet.spreadsheetId else {
            throw GoogleSheetsError.invalidResponse
        }
        
        // Write processed data
        try await client.writeRange(
            spreadsheetId,
            range: "Results!A1:C\(processedData.count)",
            values: processedData
        )
        
        return .success(spreadsheetId: spreadsheetId, recordCount: processedData.count - 1)
    }
    
    private func processData(_ data: ValueRange) -> [[String]] {
        // Your data processing logic
        var processed = [["Processed Field 1", "Processed Field 2", "Processed Field 3"]]
        
        if let values = data.values {
            for row in values.dropFirst() { // Skip header
                let processedRow = [
                    "Processed: \(row[0]?.stringValue ?? "")",
                    "Calculated: \(calculateValue(row))",
                    "Status: Completed"
                ]
                processed.append(processedRow)
            }
        }
        
        return processed
    }
    
    private func calculateValue(_ row: [AnyCodable]) -> String {
        // Your calculation logic
        return "42"
    }
    
    private func generateSummaryReport(results: [String: ProcessingResult]) async throws {
        // Clear impersonation for summary report
        tokenManager.clearImpersonationUser()
        
        let summarySpreadsheet = try await client.createSpreadsheet(
            title: "Batch Processing Summary - \(DateFormatter().string(from: Date()))"
        )
        
        guard let spreadsheetId = summarySpreadsheet.spreadsheetId else {
            throw GoogleSheetsError.invalidResponse
        }
        
        var summaryData = [["User", "Status", "Records Processed", "Spreadsheet ID"]]
        
        for (user, result) in results {
            switch result {
            case .success(let spreadsheetId, let recordCount):
                summaryData.append([user, "Success", String(recordCount), spreadsheetId])
            case .failure(let error):
                summaryData.append([user, "Failed", "0", error.localizedDescription])
            }
        }
        
        try await client.writeRange(
            spreadsheetId,
            range: "A1:D\(summaryData.count)",
            values: summaryData
        )
        
        print("Summary report created: \(summarySpreadsheet.spreadsheetUrl ?? "Unknown URL")")
    }
}

enum ProcessingResult {
    case success(spreadsheetId: String, recordCount: Int)
    case failure(Error)
}

// Usage
Task {
    do {
        let processor = try BatchUserDataProcessor()
        let users = ["user1@company.com", "user2@company.com", "user3@company.com"]
        try await processor.processAllUserData(users: users, templateSpreadsheetId: "template-id")
    } catch {
        print("Batch processing failed: \(error)")
    }
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "Authentication failed: Invalid private key format"

**Cause**: The private key in your JSON file is malformed or corrupted.

**Solutions**:
- Re-download the service account JSON file from Google Cloud Console
- Check that the JSON file wasn't modified or corrupted during transfer
- Ensure the private key includes the full PEM headers and footers

#### 2. "Authentication failed: GOOGLE_APPLICATION_CREDENTIALS environment variable not set"

**Cause**: The environment variable is not set or not accessible.

**Solutions**:
```bash
# Check if the variable is set
echo $GOOGLE_APPLICATION_CREDENTIALS

# Set the variable
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# For permanent setting, add to your shell profile
echo 'export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"' >> ~/.bashrc
```

#### 3. "API error 403: The caller does not have permission"

**Cause**: The service account doesn't have access to the spreadsheet.

**Solutions**:
- Share the spreadsheet with the service account email
- Check that you're using the correct service account email from the JSON file
- Verify the service account has the necessary permissions (Viewer, Editor, or Owner)

#### 4. "API error 404: Requested entity was not found"

**Cause**: The spreadsheet ID is incorrect or the spreadsheet doesn't exist.

**Solutions**:
- Verify the spreadsheet ID from the URL
- Ensure the spreadsheet exists and is accessible
- Check that you're not using a sheet name instead of the spreadsheet ID

#### 5. Token Generation Issues

**Cause**: Issues with JWT generation or signing.

**Solutions**:
```swift
// Add debugging to see what's happening
let tokenManager = try ServiceAccountTokenManager.loadFromFile("/path/to/service-account.json")

// Enable debug logging
let logger = ConsoleGoogleSheetsLogger(minimumLevel: .debug)
let client = GoogleSheetsClient(tokenManager: tokenManager, logger: logger)
client.setDebugMode(true)

// This will show detailed authentication logs
try await client.readRange("spreadsheet-id", range: "A1:B2")
```

### Debug Checklist

When troubleshooting service account authentication:

1. **✅ Verify file exists and is readable**
   ```swift
   let path = "/path/to/service-account.json"
   print("File exists: \(FileManager.default.fileExists(atPath: path))")
   ```

2. **✅ Check JSON structure**
   ```swift
   let data = try Data(contentsOf: URL(fileURLWithPath: path))
   let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
   print("Required keys present:")
   print("- type: \(json?["type"] != nil)")
   print("- private_key: \(json?["private_key"] != nil)")
   print("- client_email: \(json?["client_email"] != nil)")
   ```

3. **✅ Verify service account email**
   ```swift
   let serviceAccountKey = try JSONDecoder().decode(ServiceAccountKey.self, from: data)
   print("Service account email: \(serviceAccountKey.clientEmail)")
   ```

4. **✅ Test spreadsheet access**
   - Open the spreadsheet in your browser
   - Check if the service account email is in the sharing list
   - Verify the permission level (Viewer/Editor/Owner)

5. **✅ Enable debug logging**
   ```swift
   let logger = ConsoleGoogleSheetsLogger(minimumLevel: .debug)
   let client = GoogleSheetsClient(tokenManager: tokenManager, logger: logger)
   client.setDebugMode(true)
   ```

### Getting Help

If you're still having issues:

1. **Check the logs** - Enable debug mode to see detailed error information
2. **Verify permissions** - Ensure all sharing and API permissions are correct
3. **Test with a simple operation** - Try reading a single cell first
4. **Check Google Cloud Console** - Verify your service account and API settings
5. **Review the JSON file** - Ensure it's valid and complete

For additional support:
- [GitHub Issues](https://github.com/your-username/GoogleSheetsSwift/issues)
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Google Cloud Service Account Documentation](https://cloud.google.com/iam/docs/service-accounts)