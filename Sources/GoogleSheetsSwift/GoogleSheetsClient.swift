import Foundation

/// Main client for Google Sheets API operations
public class GoogleSheetsClient {
    /// Service for spreadsheet management operations
    public let spreadsheets: SpreadsheetsServiceProtocol
    
    /// Service for values operations
    public let values: ValuesServiceProtocol
    
    /// HTTP client for API requests
    private let httpClient: HTTPClient
    
    /// OAuth2 token manager for authentication
    private let tokenManager: OAuth2TokenManager
    
    /// Optional API key for read-only operations
    private var apiKey: String?
    
    /// Logger for debugging and monitoring
    private var logger: GoogleSheetsLogger?
    
    /// Initialize the client with a token manager
    /// - Parameters:
    ///   - tokenManager: OAuth2 token manager for authentication
    ///   - httpClient: Optional custom HTTP client (uses default if not provided)
    ///   - logger: Optional logger for debugging and monitoring
    ///   - cache: Optional response cache for read operations
    ///   - cacheConfiguration: Configuration for caching behavior
    ///   - batchOptimizer: Optimizer for batch operations
    ///   - memoryHandler: Handler for memory-efficient operations
    public init(
        tokenManager: OAuth2TokenManager, 
        httpClient: HTTPClient? = nil, 
        logger: GoogleSheetsLogger? = nil,
        cache: ResponseCache? = InMemoryResponseCache(),
        cacheConfiguration: CacheConfiguration = .default,
        batchOptimizer: BatchOptimizer = BatchOptimizer(),
        memoryHandler: MemoryEfficientDataHandler = MemoryEfficientDataHandler()
    ) {
        self.tokenManager = tokenManager
        self.logger = logger
        
        // Create HTTP client with logger if provided
        if let logger = logger, httpClient == nil {
            self.httpClient = URLSessionHTTPClient(logger: LoggingHTTPClientAdapter(logger: logger))
        } else {
            self.httpClient = httpClient ?? URLSessionHTTPClient()
        }
        
        // Initialize services with concrete implementations and performance optimizations
        self.spreadsheets = SpreadsheetsService(
            httpClient: self.httpClient, 
            tokenManager: self.tokenManager,
            cache: cache,
            cacheConfiguration: cacheConfiguration
        )
        self.values = ValuesService(
            httpClient: self.httpClient, 
            tokenManager: self.tokenManager,
            cache: cache,
            cacheConfiguration: cacheConfiguration,
            batchOptimizer: batchOptimizer,
            memoryHandler: memoryHandler
        )
        
        logger?.info("GoogleSheetsClient initialized with OAuth2 authentication and performance optimizations")
    }
    
    /// Initialize the client with an API key for read-only operations
    /// - Parameters:
    ///   - apiKey: Google API key for read-only access
    ///   - httpClient: Optional custom HTTP client (uses default if not provided)
    ///   - logger: Optional logger for debugging and monitoring
    ///   - cache: Optional response cache for read operations
    ///   - cacheConfiguration: Configuration for caching behavior
    ///   - batchOptimizer: Optimizer for batch operations
    ///   - memoryHandler: Handler for memory-efficient operations
    public init(
        apiKey: String, 
        httpClient: HTTPClient? = nil, 
        logger: GoogleSheetsLogger? = nil,
        cache: ResponseCache? = InMemoryResponseCache(),
        cacheConfiguration: CacheConfiguration = .default,
        batchOptimizer: BatchOptimizer = BatchOptimizer(),
        memoryHandler: MemoryEfficientDataHandler = MemoryEfficientDataHandler()
    ) {
        // Create a dummy token manager for API key usage
        self.tokenManager = APIKeyTokenManager(apiKey: apiKey)
        self.logger = logger
        self.apiKey = apiKey
        
        // Create HTTP client with logger if provided
        if let logger = logger, httpClient == nil {
            self.httpClient = URLSessionHTTPClient(logger: LoggingHTTPClientAdapter(logger: logger))
        } else {
            self.httpClient = httpClient ?? URLSessionHTTPClient()
        }
        
        // Initialize services with concrete implementations and performance optimizations
        self.spreadsheets = SpreadsheetsService(
            httpClient: self.httpClient, 
            tokenManager: self.tokenManager,
            cache: cache,
            cacheConfiguration: cacheConfiguration
        )
        self.values = ValuesService(
            httpClient: self.httpClient, 
            tokenManager: self.tokenManager,
            cache: cache,
            cacheConfiguration: cacheConfiguration,
            batchOptimizer: batchOptimizer,
            memoryHandler: memoryHandler
        )
        
        logger?.info("GoogleSheetsClient initialized with API key authentication and performance optimizations")
    }
    
    /// Set an API key for read-only operations
    /// - Parameter apiKey: Google API key
    public func setAPIKey(_ apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Get the current API key
    public func getAPIKey() -> String? {
        return apiKey
    }
    
    // MARK: - Logging Configuration
    
    /// Set the logger for debugging and monitoring
    /// - Parameter logger: The logger to use, or nil to disable logging
    public func setLogger(_ logger: GoogleSheetsLogger?) {
        self.logger = logger
        
        if let logger = logger {
            logger.info("Logger configured for GoogleSheetsClient")
        }
    }
    
    /// Get the current logger
    /// - Returns: The current logger, or nil if logging is disabled
    public func getLogger() -> GoogleSheetsLogger? {
        return logger
    }
    
    /// Enable debug mode with detailed logging
    /// - Parameter enabled: Whether to enable debug mode
    public func setDebugMode(_ enabled: Bool) {
        if enabled {
            if logger == nil {
                logger = ConsoleGoogleSheetsLogger(minimumLevel: .debug)
            }
            logger?.info("Debug mode enabled")
        } else {
            logger?.info("Debug mode disabled")
        }
    }
    
    /// Check if debug mode is enabled
    /// - Returns: true if debug logging is enabled
    public func isDebugModeEnabled() -> Bool {
        return logger?.isEnabled(for: .debug) ?? false
    }
}

// MARK: - Convenience Methods

extension GoogleSheetsClient {
    
    // MARK: - Read Operations
    
    /// Read values from a single range with simplified parameters
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to read
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    ///   - valueRenderOption: How values should be rendered (default: .formattedValue)
    /// - Returns: ValueRange containing the requested data
    /// - Throws: GoogleSheetsError if the operation fails
    public func readRange(
        _ spreadsheetId: String,
        range: String,
        majorDimension: MajorDimension = .rows,
        valueRenderOption: ValueRenderOption = .formattedValue
    ) async throws -> ValueRange {
        let context = LoggingContext(
            operation: "readRange",
            spreadsheetId: spreadsheetId,
            range: range
        )
        
        logger?.logRequestStart(context)
        
        do {
            let options = ValueGetOptions(
                valueRenderOption: valueRenderOption,
                dateTimeRenderOption: nil,
                majorDimension: majorDimension
            )
            
            let result = try await values.get(
                spreadsheetId: spreadsheetId,
                range: range,
                options: options
            )
            
            logger?.logRequestComplete(context)
            return result
        } catch {
            logger?.logRequestFailure(context, error: error)
            throw error
        }
    }
    
    /// Read values from multiple ranges in a single request
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - ranges: Array of A1 notation ranges to read
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    ///   - valueRenderOption: How values should be rendered (default: .formattedValue)
    /// - Returns: BatchGetValuesResponse containing the requested data
    /// - Throws: GoogleSheetsError if the operation fails
    public func readRanges(
        _ spreadsheetId: String,
        ranges: [String],
        majorDimension: MajorDimension = .rows,
        valueRenderOption: ValueRenderOption = .formattedValue
    ) async throws -> BatchGetValuesResponse {
        let options = ValueGetOptions(
            valueRenderOption: valueRenderOption,
            dateTimeRenderOption: nil,
            majorDimension: majorDimension
        )
        
        return try await values.batchGet(
            spreadsheetId: spreadsheetId,
            ranges: ranges,
            options: options
        )
    }
    
    /// Read string values from a range, automatically converting to String array
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to read
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    /// - Returns: 2D array of optional strings
    /// - Throws: GoogleSheetsError if the operation fails
    public func readStringValues(
        _ spreadsheetId: String,
        range: String,
        majorDimension: MajorDimension = .rows
    ) async throws -> [[String?]] {
        let valueRange = try await readRange(
            spreadsheetId,
            range: range,
            majorDimension: majorDimension,
            valueRenderOption: .formattedValue
        )
        
        return valueRange.getStringValues()
    }
    
    // MARK: - Write Operations
    
    /// Write values to a single range with simplified parameters
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to write to
    ///   - values: 2D array of values to write
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    ///   - valueInputOption: How input data should be interpreted (default: .userEntered)
    /// - Returns: UpdateValuesResponse containing update information
    /// - Throws: GoogleSheetsError if the operation fails
    public func writeRange(
        _ spreadsheetId: String,
        range: String,
        values: [[Any]],
        majorDimension: MajorDimension = .rows,
        valueInputOption: ValueInputOption = .userEntered
    ) async throws -> UpdateValuesResponse {
        let valueRange = ValueRange(
            range: range,
            majorDimension: majorDimension,
            values: values
        )
        
        let options = ValueUpdateOptions(
            valueInputOption: valueInputOption,
            includeValuesInResponse: false,
            responseValueRenderOption: nil,
            responseDateTimeRenderOption: nil
        )
        
        return try await self.values.update(
            spreadsheetId: spreadsheetId,
            range: range,
            values: valueRange,
            options: options
        )
    }
    
    /// Write string values to a range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to write to
    ///   - values: 2D array of strings to write
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    /// - Returns: UpdateValuesResponse containing update information
    /// - Throws: GoogleSheetsError if the operation fails
    public func writeStringValues(
        _ spreadsheetId: String,
        range: String,
        values: [[String]],
        majorDimension: MajorDimension = .rows
    ) async throws -> UpdateValuesResponse {
        let anyValues: [[Any]] = values.map { row in
            row.map { $0 as Any }
        }
        
        return try await writeRange(
            spreadsheetId,
            range: range,
            values: anyValues,
            majorDimension: majorDimension,
            valueInputOption: .userEntered
        )
    }
    
    /// Append values to a range with simplified parameters
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to append to
    ///   - values: 2D array of values to append
    ///   - majorDimension: How the data should be interpreted (default: .rows)
    ///   - valueInputOption: How input data should be interpreted (default: .userEntered)
    /// - Returns: AppendValuesResponse containing append information
    /// - Throws: GoogleSheetsError if the operation fails
    public func appendToRange(
        _ spreadsheetId: String,
        range: String,
        values: [[Any]],
        majorDimension: MajorDimension = .rows,
        valueInputOption: ValueInputOption = .userEntered
    ) async throws -> AppendValuesResponse {
        let valueRange = ValueRange(
            range: range,
            majorDimension: majorDimension,
            values: values
        )
        
        let options = ValueAppendOptions(
            valueInputOption: valueInputOption,
            insertDataOption: .insertRows,
            includeValuesInResponse: false,
            responseValueRenderOption: nil,
            responseDateTimeRenderOption: nil
        )
        
        return try await self.values.append(
            spreadsheetId: spreadsheetId,
            range: range,
            values: valueRange,
            options: options
        )
    }
    
    /// Clear values in a range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to clear
    /// - Returns: ClearValuesResponse containing clear information
    /// - Throws: GoogleSheetsError if the operation fails
    public func clearRange(
        _ spreadsheetId: String,
        range: String
    ) async throws -> ClearValuesResponse {
        return try await values.clear(
            spreadsheetId: spreadsheetId,
            range: range
        )
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch read operations on multiple ranges
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - operations: Array of batch read operations
    /// - Returns: Array of ValueRange results corresponding to each operation
    /// - Throws: GoogleSheetsError if the operation fails
    public func batchRead(
        _ spreadsheetId: String,
        operations: [BatchReadOperation]
    ) async throws -> [ValueRange] {
        let ranges = operations.map { $0.range }
        let options = ValueGetOptions(
            valueRenderOption: operations.first?.valueRenderOption ?? .formattedValue,
            dateTimeRenderOption: nil,
            majorDimension: operations.first?.majorDimension ?? .rows
        )
        
        let response = try await values.batchGet(
            spreadsheetId: spreadsheetId,
            ranges: ranges,
            options: options
        )
        
        return response.valueRanges ?? []
    }
    
    /// Perform batch write operations on multiple ranges
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - operations: Array of batch write operations
    ///   - valueInputOption: How input data should be interpreted (default: .userEntered)
    /// - Returns: BatchUpdateValuesResponse containing update information
    /// - Throws: GoogleSheetsError if the operation fails
    public func batchWrite(
        _ spreadsheetId: String,
        operations: [BatchWriteOperation],
        valueInputOption: ValueInputOption = .userEntered
    ) async throws -> BatchUpdateValuesResponse {
        let data = operations.map { operation in
            ValueRange(
                range: operation.range,
                majorDimension: operation.majorDimension,
                values: operation.values
            )
        }
        
        let options = ValueUpdateOptions(
            valueInputOption: valueInputOption,
            includeValuesInResponse: false,
            responseValueRenderOption: nil,
            responseDateTimeRenderOption: nil
        )
        
        return try await values.batchUpdate(
            spreadsheetId: spreadsheetId,
            data: data,
            options: options
        )
    }
    
    // MARK: - Spreadsheet Operations
    
    /// Create a new spreadsheet with simplified parameters
    /// - Parameters:
    ///   - title: The title of the new spreadsheet
    ///   - sheetTitles: Optional array of sheet titles to create (default: single sheet named "Sheet1")
    /// - Returns: The created Spreadsheet
    /// - Throws: GoogleSheetsError if the operation fails
    public func createSpreadsheet(
        title: String,
        sheetTitles: [String] = ["Sheet1"]
    ) async throws -> Spreadsheet {
        let sheets = sheetTitles.map { sheetTitle in
            SheetProperties(title: sheetTitle)
        }
        
        let properties = SpreadsheetProperties(title: title)
        let request = SpreadsheetCreateRequest(
            properties: properties,
            sheets: sheets.map { Sheet(properties: $0) }
        )
        
        return try await spreadsheets.create(request)
    }
    
    /// Get basic spreadsheet information
    /// - Parameter spreadsheetId: The ID of the spreadsheet
    /// - Returns: The spreadsheet information
    /// - Throws: GoogleSheetsError if the operation fails
    public func getSpreadsheet(_ spreadsheetId: String) async throws -> Spreadsheet {
        return try await spreadsheets.get(
            spreadsheetId: spreadsheetId,
            ranges: nil,
            includeGridData: false,
            fields: nil
        )
    }
}

// MARK: - A1 Notation Utilities

extension GoogleSheetsClient {
    
    /// Validate an A1 notation range
    /// - Parameter range: The range to validate
    /// - Returns: true if the range is valid
    public static func isValidA1Range(_ range: String) -> Bool {
        do {
            _ = try parseA1Range(range)
            return true
        } catch {
            return false
        }
    }
#if canImport(Security)
    /// Parse an A1 notation range string
    /// - Parameter range: The A1 notation range to parse
    /// - Returns: Parsed A1Range object
    /// - Throws: GoogleSheetsError.invalidRange if parsing fails
    public static func parseA1Range(_ range: String) throws -> A1Range {
        let valuesService = ValuesService(
            httpClient: URLSessionHTTPClient(),
            tokenManager: GoogleOAuth2TokenManager(
                clientId: "dummy",
                clientSecret: "dummy",
                redirectURI: "dummy"
            )
        )
        return try valuesService.parseA1Range(range)
    }
#endif
    /// Convert column number to letters (1=A, 2=B, ..., 26=Z, 27=AA, etc.)
    /// - Parameter columnNumber: The column number (1-based)
    /// - Returns: The column letters
    public static func columnNumberToLetters(_ columnNumber: Int) -> String {
        guard columnNumber > 0 else { return "" }
        
        var result = ""
        var num = columnNumber
        
        while num > 0 {
            num -= 1
            let remainder = num % 26
            result = String(Character(UnicodeScalar(remainder + Int(Character("A").asciiValue!))!)) + result
            num /= 26
        }
        
        return result
    }
    
    /// Convert column letters to number (A=1, B=2, ..., Z=26, AA=27, etc.)
    /// - Parameter letters: The column letters (e.g., "A", "AB")
    /// - Returns: The column number (1-based)
    /// - Throws: GoogleSheetsError.invalidRange if conversion fails
    public static func columnLettersToNumber(_ letters: String) throws -> Int {
        guard !letters.isEmpty else {
            throw GoogleSheetsError.invalidRange("Empty column letters")
        }
        
        let uppercased = letters.uppercased()
        var result = 0
        
        for char in uppercased {
            guard char.isLetter && char.isASCII else {
                throw GoogleSheetsError.invalidRange("Invalid column letter: \(char)")
            }
            
            let value = Int(char.asciiValue! - Character("A").asciiValue! + 1)
            result = result * 26 + value
        }
        
        return result
    }
    
    /// Build an A1 notation range from components
    /// - Parameters:
    ///   - sheetName: Optional sheet name
    ///   - startColumn: Start column number (1-based)
    ///   - startRow: Start row number (1-based)
    ///   - endColumn: Optional end column number (1-based)
    ///   - endRow: Optional end row number (1-based)
    /// - Returns: A1 notation string
    public static func buildA1Range(
        sheetName: String? = nil,
        startColumn: Int,
        startRow: Int,
        endColumn: Int? = nil,
        endRow: Int? = nil
    ) -> String {
        var result = ""
        
        // Add sheet name if present
        if let sheetName = sheetName {
            if sheetName.contains(" ") || sheetName.contains("'") {
                result += "'\(sheetName.replacingOccurrences(of: "'", with: "''"))'"
            } else {
                result += sheetName
            }
            result += "!"
        }
        
        // Add range part
        result += columnNumberToLetters(startColumn) + "\(startRow)"
        
        if let endCol = endColumn, let endRow = endRow,
           !(startColumn == endCol && startRow == endRow) {
            result += ":" + columnNumberToLetters(endCol) + "\(endRow)"
        }
        
        return result
    }
    
    /// Build an A1 notation range for an entire column
    /// - Parameters:
    ///   - sheetName: Optional sheet name
    ///   - column: Column number (1-based)
    /// - Returns: A1 notation string for the entire column
    public static func buildColumnRange(sheetName: String? = nil, column: Int) -> String {
        var result = ""
        
        // Add sheet name if present
        if let sheetName = sheetName {
            if sheetName.contains(" ") || sheetName.contains("'") {
                result += "'\(sheetName.replacingOccurrences(of: "'", with: "''"))'"
            } else {
                result += sheetName
            }
            result += "!"
        }
        
        let columnLetters = columnNumberToLetters(column)
        result += "\(columnLetters):\(columnLetters)"
        
        return result
    }
    
    /// Build an A1 notation range for an entire row
    /// - Parameters:
    ///   - sheetName: Optional sheet name
    ///   - row: Row number (1-based)
    /// - Returns: A1 notation string for the entire row
    public static func buildRowRange(sheetName: String? = nil, row: Int) -> String {
        var result = ""
        
        // Add sheet name if present
        if let sheetName = sheetName {
            if sheetName.contains(" ") || sheetName.contains("'") {
                result += "'\(sheetName.replacingOccurrences(of: "'", with: "''"))'"
            } else {
                result += sheetName
            }
            result += "!"
        }
        
        result += "\(row):\(row)"
        
        return result
    }
}

// MARK: - Batch Operation Types

/// Represents a batch read operation
public struct BatchReadOperation {
    public let range: String
    public let majorDimension: MajorDimension
    public let valueRenderOption: ValueRenderOption
    
    public init(
        range: String,
        majorDimension: MajorDimension = .rows,
        valueRenderOption: ValueRenderOption = .formattedValue
    ) {
        self.range = range
        self.majorDimension = majorDimension
        self.valueRenderOption = valueRenderOption
    }
}

/// Represents a batch write operation
public struct BatchWriteOperation {
    public let range: String
    public let values: [[Any]]
    public let majorDimension: MajorDimension
    
    public init(
        range: String,
        values: [[Any]],
        majorDimension: MajorDimension = .rows
    ) {
        self.range = range
        self.values = values
        self.majorDimension = majorDimension
    }
}

// MARK: - API Key Token Manager

/// Token manager that uses API key for read-only operations
private class APIKeyTokenManager: OAuth2TokenManager {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getAccessToken() async throws -> String {
        // For API key usage, we don't use access tokens
        // The HTTPClient will handle API key authentication
        throw GoogleSheetsError.authenticationFailed("API key authentication does not use access tokens")
    }
    
    func refreshToken() async throws -> String {
        throw GoogleSheetsError.authenticationFailed("API key authentication does not support token refresh")
    }
    
    var isAuthenticated: Bool {
        return !apiKey.isEmpty
    }
    
    func authenticate(scopes: [String]) async throws -> AuthResult {
        throw GoogleSheetsError.authenticationFailed("API key authentication does not support OAuth2 flow")
    }
    
    func clearTokens() async throws {
        // No tokens to clear for API key authentication
    }
    
    func getAPIKey() -> String {
        return apiKey
    }
}
