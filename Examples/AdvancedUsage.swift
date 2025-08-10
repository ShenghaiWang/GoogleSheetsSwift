import Foundation
import GoogleSheetsSwift

/**
 * Advanced Usage Examples for GoogleSheetsSwift
 * 
 * This file demonstrates advanced features including:
 * - Custom logging and debugging
 * - Performance optimization
 * - Complex data operations
 * - Error recovery strategies
 * - Custom configurations
 */

class AdvancedUsageExamples {
    private let client: GoogleSheetsClient
    private let spreadsheetId = "your-spreadsheet-id-here"
    
    init() {
        // Create a custom logger
        let logger = CompositeGoogleSheetsLogger(loggers: [
            ConsoleGoogleSheetsLogger(minimumLevel: .info),
            createFileLogger()
        ].compactMap { $0 })
        
        // Create OAuth2 token manager
        let tokenManager = GoogleOAuth2TokenManager(
            clientId: "your-client-id",
            clientSecret: "your-client-secret",
            redirectURI: "your-redirect-uri"
        )
        
        // Create client with advanced configuration
        let cache = InMemoryResponseCache()
        let cacheConfig = CacheConfiguration(
            ttl: 300,           // 5 minutes
            maxSize: 100,       // 100 cached responses
            enabled: true
        )
        
        let batchOptimizer = BatchOptimizer()
        let memoryHandler = MemoryEfficientDataHandler()
        
        self.client = GoogleSheetsClient(
            tokenManager: tokenManager,
            logger: logger,
            cache: cache,
            cacheConfiguration: cacheConfig,
            batchOptimizer: batchOptimizer,
            memoryHandler: memoryHandler
        )
        
        // Enable debug mode for detailed logging
        client.setDebugMode(true)
    }
    
    // MARK: - Custom Logging
    
    /// Create a file logger for persistent logging
    private func createFileLogger() -> FileGoogleSheetsLogger? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFileURL = documentsPath.appendingPathComponent("googlesheets-sdk.log")
        
        return FileGoogleSheetsLogger(
            fileURL: logFileURL,
            minimumLevel: .debug,
            includeTimestamp: true,
            includeMetadata: true
        )
    }
    
    // MARK: - Performance Optimization Examples
    
    /// Demonstrate efficient batch reading
    func efficientBatchReading() async throws {
        print("\n🚀 Efficient batch reading...")
        
        // Read multiple ranges efficiently
        let ranges = [
            "Summary!A1:E10",
            "Data!A1:Z1000",
            "Charts!A1:F20",
            "Settings!A1:B50"
        ]
        
        let operations = ranges.map { range in
            BatchReadOperation(
                range: range,
                majorDimension: .rows,
                valueRenderOption: .formattedValue
            )
        }
        
        let startTime = Date()
        let results = try await client.batchRead(spreadsheetId, operations: operations)
        let duration = Date().timeIntervalSince(startTime)
        
        print("✅ Read \(results.count) ranges in \(String(format: "%.2f", duration)) seconds")
        
        for (index, result) in results.enumerated() {
            let rowCount = result.values?.count ?? 0
            print("  Range \(index + 1): \(rowCount) rows")
        }
    }
    
    /// Demonstrate memory-efficient large data processing
    func processLargeDataset() async throws {
        print("\n💾 Processing large dataset...")
        
        // Read large dataset in chunks
        let totalRows = 10000
        let chunkSize = 1000
        var processedRows = 0
        
        for startRow in stride(from: 1, to: totalRows, by: chunkSize) {
            let endRow = min(startRow + chunkSize - 1, totalRows)
            let range = "Data!A\(startRow):Z\(endRow)"
            
            do {
                let chunk = try await client.readRange(spreadsheetId, range: range)
                
                // Process chunk
                if let rows = chunk.values {
                    processedRows += rows.count
                    
                    // Simulate processing
                    let processedData = processChunk(rows)
                    
                    // Write processed results back
                    let outputRange = "Processed!A\(startRow):B\(endRow)"
                    try await client.writeRange(
                        spreadsheetId,
                        range: outputRange,
                        values: processedData
                    )
                }
                
                print("  Processed rows \(startRow)-\(endRow)")
                
            } catch {
                print("  ⚠️ Failed to process chunk \(startRow)-\(endRow): \(error)")
                // Continue with next chunk
            }
        }
        
        print("✅ Processed \(processedRows) total rows")
    }
    
    /// Process a chunk of data (example transformation)
    private func processChunk(_ rows: [[AnyCodable]]) -> [[Any]] {
        return rows.map { row in
            let originalValue = row.first?.get() as String? ?? ""
            let processedValue = originalValue.uppercased()
            return [originalValue, processedValue]
        }
    }
    
    // MARK: - Advanced Data Operations
    
    /// Demonstrate complex data analysis
    func performDataAnalysis() async throws {
        print("\n📊 Performing data analysis...")
        
        // Read sales data
        let salesData = try await client.readRange(
            spreadsheetId,
            range: "Sales!A2:E1000",
            valueRenderOption: .unformattedValue
        )
        
        guard let rows = salesData.values else {
            print("No data found")
            return
        }
        
        // Analyze data
        var totalSales: Double = 0
        var salesByRegion: [String: Double] = [:]
        var monthlySales: [String: Double] = [:]
        
        for row in rows {
            guard row.count >= 5 else { continue }
            
            let date = row[0].get() as String? ?? ""
            let region = row[1].get() as String? ?? ""
            let amount = row[4].get() as Double? ?? 0
            
            totalSales += amount
            salesByRegion[region, default: 0] += amount
            
            // Extract month from date (simplified)
            let month = String(date.prefix(7)) // Assumes YYYY-MM format
            monthlySales[month, default: 0] += amount
        }
        
        // Create summary report
        let summaryData = [
            ["Metric", "Value"],
            ["Total Sales", String(format: "%.2f", totalSales)],
            ["Number of Regions", String(salesByRegion.count)],
            ["Average per Region", String(format: "%.2f", totalSales / Double(salesByRegion.count))]
        ]
        
        // Write summary
        try await client.writeRange(
            spreadsheetId,
            range: "Analysis!A1:B4",
            values: summaryData
        )
        
        // Write regional breakdown
        var regionalData = [["Region", "Sales"]]
        for (region, sales) in salesByRegion.sorted(by: { $0.value > $1.value }) {
            regionalData.append([region, String(format: "%.2f", sales)])
        }
        
        try await client.writeRange(
            spreadsheetId,
            range: "Analysis!D1:E\(regionalData.count)",
            values: regionalData
        )
        
        print("✅ Analysis complete:")
        print("  Total Sales: $\(String(format: "%.2f", totalSales))")
        print("  Regions: \(salesByRegion.count)")
        print("  Top Region: \(salesByRegion.max(by: { $0.value < $1.value })?.key ?? "Unknown")")
    }
    
    /// Demonstrate data validation and cleaning
    func validateAndCleanData() async throws {
        print("\n🧹 Validating and cleaning data...")
        
        // Read raw data
        let rawData = try await client.readStringValues(
            spreadsheetId,
            range: "RawData!A1:D1000"
        )
        
        var cleanedData: [[String]] = []
        var errorLog: [[String]] = [["Row", "Column", "Error", "Original Value"]]
        
        for (rowIndex, row) in rawData.enumerated() {
            var cleanedRow: [String] = []
            var hasErrors = false
            
            for (colIndex, cell) in row.enumerated() {
                let originalValue = cell ?? ""
                var cleanedValue = originalValue
                
                // Validation rules based on column
                switch colIndex {
                case 0: // Email column
                    if !isValidEmail(originalValue) {
                        errorLog.append([
                            String(rowIndex + 1),
                            String(colIndex + 1),
                            "Invalid email format",
                            originalValue
                        ])
                        hasErrors = true
                        cleanedValue = "" // Clear invalid email
                    }
                    
                case 1: // Phone column
                    cleanedValue = cleanPhoneNumber(originalValue)
                    if cleanedValue != originalValue {
                        errorLog.append([
                            String(rowIndex + 1),
                            String(colIndex + 1),
                            "Phone number formatted",
                            originalValue
                        ])
                    }
                    
                case 2: // Date column
                    cleanedValue = standardizeDate(originalValue)
                    if cleanedValue.isEmpty && !originalValue.isEmpty {
                        errorLog.append([
                            String(rowIndex + 1),
                            String(colIndex + 1),
                            "Invalid date format",
                            originalValue
                        ])
                        hasErrors = true
                    }
                    
                case 3: // Amount column
                    cleanedValue = cleanAmount(originalValue)
                    if cleanedValue != originalValue {
                        errorLog.append([
                            String(rowIndex + 1),
                            String(colIndex + 1),
                            "Amount formatted",
                            originalValue
                        ])
                    }
                    
                default:
                    break
                }
                
                cleanedRow.append(cleanedValue)
            }
            
            // Only include rows without critical errors
            if !hasErrors {
                cleanedData.append(cleanedRow)
            }
        }
        
        // Write cleaned data
        if !cleanedData.isEmpty {
            try await client.writeRange(
                spreadsheetId,
                range: "CleanedData!A1:D\(cleanedData.count)",
                values: cleanedData
            )
        }
        
        // Write error log
        if errorLog.count > 1 {
            try await client.writeRange(
                spreadsheetId,
                range: "ErrorLog!A1:D\(errorLog.count)",
                values: errorLog
            )
        }
        
        print("✅ Data cleaning complete:")
        print("  Original rows: \(rawData.count)")
        print("  Cleaned rows: \(cleanedData.count)")
        print("  Errors found: \(errorLog.count - 1)")
    }
    
    // MARK: - Data Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func cleanPhoneNumber(_ phone: String) -> String {
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.count == 10 {
            let area = digits.prefix(3)
            let exchange = digits.dropFirst(3).prefix(3)
            let number = digits.suffix(4)
            return "(\(area)) \(exchange)-\(number)"
        } else if digits.count == 11 && digits.hasPrefix("1") {
            let area = digits.dropFirst().prefix(3)
            let exchange = digits.dropFirst(4).prefix(3)
            let number = digits.suffix(4)
            return "+1 (\(area)) \(exchange)-\(number)"
        }
        
        return phone // Return original if can't format
    }
    
    private func standardizeDate(_ date: String) -> String {
        let formatter = DateFormatter()
        let formats = ["MM/dd/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "MM-dd-yyyy"]
        
        for format in formats {
            formatter.dateFormat = format
            if let parsedDate = formatter.date(from: date) {
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: parsedDate)
            }
        }
        
        return "" // Return empty if can't parse
    }
    
    private func cleanAmount(_ amount: String) -> String {
        let cleaned = amount.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        
        if let value = Double(cleaned) {
            return String(format: "%.2f", value)
        }
        
        return amount // Return original if can't parse
    }
    
    // MARK: - Error Recovery Strategies
    
    /// Demonstrate robust error handling with retry logic
    func robustDataOperation() async throws {
        print("\n🛡️ Robust data operation with error recovery...")
        
        let maxRetries = 3
        let baseDelay: TimeInterval = 1.0
        
        for attempt in 1...maxRetries {
            do {
                // Attempt the operation
                let result = try await client.readRange(
                    spreadsheetId,
                    range: "Data!A1:Z1000"
                )
                
                print("✅ Operation succeeded on attempt \(attempt)")
                print("  Rows retrieved: \(result.values?.count ?? 0)")
                return
                
            } catch GoogleSheetsError.rateLimitExceeded(let retryAfter) {
                let delay = retryAfter ?? (baseDelay * pow(2.0, Double(attempt - 1)))
                print("  ⏳ Rate limited on attempt \(attempt), waiting \(delay) seconds...")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch GoogleSheetsError.networkError(let error) {
                print("  🌐 Network error on attempt \(attempt): \(error.localizedDescription)")
                
                if attempt == maxRetries {
                    throw error
                }
                
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch GoogleSheetsError.tokenExpired {
                print("  🔑 Token expired on attempt \(attempt), refreshing...")
                
                // Refresh token
                _ = try await client.tokenManager.refreshToken()
                
            } catch {
                print("  ❌ Unexpected error on attempt \(attempt): \(error)")
                
                if attempt == maxRetries {
                    throw error
                }
            }
        }
        
        throw GoogleSheetsError.apiError(code: 500, message: "Max retries exceeded")
    }
    
    // MARK: - Custom Configuration Examples
    
    /// Demonstrate custom HTTP client configuration
    func customHTTPConfiguration() async throws {
        print("\n⚙️ Custom HTTP configuration...")
        
        // Create custom HTTP client with specific timeout
        let customHTTPClient = URLSessionHTTPClient(
            session: URLSession(configuration: {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 30
                config.timeoutIntervalForResource = 300
                return config
            }())
        )
        
        // Create client with custom HTTP client
        let tokenManager = GoogleOAuth2TokenManager(
            clientId: "your-client-id",
            clientSecret: "your-client-secret",
            redirectURI: "your-redirect-uri"
        )
        
        let customClient = GoogleSheetsClient(
            tokenManager: tokenManager,
            httpClient: customHTTPClient
        )
        
        // Use the custom client
        let result = try await customClient.readRange(
            spreadsheetId,
            range: "A1:B2"
        )
        
        print("✅ Custom HTTP client operation completed")
        print("  Result: \(result.values?.count ?? 0) rows")
    }
    
    // MARK: - Performance Monitoring
    
    /// Monitor and log performance metrics
    func monitorPerformance() async throws {
        print("\n📈 Performance monitoring...")
        
        let operations = [
            ("Small read", { try await self.client.readRange(self.spreadsheetId, range: "A1:C10") }),
            ("Medium read", { try await self.client.readRange(self.spreadsheetId, range: "A1:Z100") }),
            ("Large read", { try await self.client.readRange(self.spreadsheetId, range: "A1:Z1000") }),
            ("Write operation", { 
                try await self.client.writeRange(
                    self.spreadsheetId,
                    range: "Test!A1:C3",
                    values: [["A", "B", "C"], ["1", "2", "3"], ["X", "Y", "Z"]]
                )
            })
        ]
        
        for (name, operation) in operations {
            let startTime = Date()
            
            do {
                _ = try await operation()
                let duration = Date().timeIntervalSince(startTime)
                print("  ✅ \(name): \(String(format: "%.3f", duration))s")
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("  ❌ \(name): \(String(format: "%.3f", duration))s - \(error)")
            }
        }
    }
    
    // MARK: - Run All Advanced Examples
    
    /// Run all advanced examples
    func runAllAdvancedExamples() async {
        print("🚀 Running GoogleSheetsSwift Advanced Usage Examples")
        print("=" * 60)
        
        do {
            // Performance examples
            try await efficientBatchReading()
            try await processLargeDataset()
            
            // Data analysis
            try await performDataAnalysis()
            try await validateAndCleanData()
            
            // Error recovery
            try await robustDataOperation()
            
            // Custom configuration
            try await customHTTPConfiguration()
            
            // Performance monitoring
            try await monitorPerformance()
            
            print("\n✅ All advanced examples completed successfully!")
            
        } catch {
            print("\n❌ Advanced example failed with error: \(error)")
        }
    }
}

// MARK: - Custom Logger Example

class CustomAnalyticsLogger: GoogleSheetsLogger {
    private let analytics: AnalyticsService
    
    init(analytics: AnalyticsService) {
        self.analytics = analytics
    }
    
    func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        // Send logs to analytics service
        analytics.track(event: "sheets_sdk_log", properties: [
            "level": level.description,
            "message": message,
            "metadata": metadata ?? [:]
        ])
        
        // Also log to console for debugging
        if level >= .warning {
            print("[\(level.description)] \(message)")
        }
    }
    
    func isEnabled(for level: LogLevel) -> Bool {
        return true // Always enabled for analytics
    }
}

// Mock analytics service
class AnalyticsService {
    func track(event: String, properties: [String: Any]) {
        print("📊 Analytics: \(event) - \(properties)")
    }
}

// Helper extension
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
}