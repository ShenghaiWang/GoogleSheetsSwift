import Foundation

/// Service for managing spreadsheet values operations
public class ValuesService: ValuesServiceProtocol {
    public let httpClient: HTTPClient
    public let tokenManager: OAuth2TokenManager
    private let requestBuilder: RequestBuilder
    private let cache: ResponseCache?
    private let cacheConfiguration: CacheConfiguration
    private let batchOptimizer: BatchOptimizer
    private let memoryHandler: MemoryEfficientDataHandler
    
    /// Initialize the ValuesService
    /// - Parameters:
    ///   - httpClient: HTTP client for making requests
    ///   - tokenManager: OAuth2 token manager for authentication
    ///   - cache: Optional response cache for read operations
    ///   - cacheConfiguration: Configuration for caching behavior
    ///   - batchOptimizer: Optimizer for batch operations
    ///   - memoryHandler: Handler for memory-efficient operations
    public init(
        httpClient: HTTPClient, 
        tokenManager: OAuth2TokenManager,
        cache: ResponseCache? = nil,
        cacheConfiguration: CacheConfiguration = .default,
        batchOptimizer: BatchOptimizer = BatchOptimizer(),
        memoryHandler: MemoryEfficientDataHandler = MemoryEfficientDataHandler()
    ) {
        self.httpClient = httpClient
        self.tokenManager = tokenManager
        self.requestBuilder = RequestBuilder()
        self.cache = cache
        self.cacheConfiguration = cacheConfiguration
        self.batchOptimizer = batchOptimizer
        self.memoryHandler = memoryHandler
    }
    
    // MARK: - Reading Operations
    
    /// Get values from a specific range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to retrieve
    ///   - options: Optional parameters for the request
    /// - Returns: ValueRange containing the requested data
    /// - Throws: GoogleSheetsError if the operation fails
    public func get(spreadsheetId: String, range: String, options: ValueGetOptions? = nil) async throws -> ValueRange {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        try validateRange(range)
        
        // Check cache first if enabled
        if let cache = cache, cacheConfiguration.enabled {
            let cacheKey = CacheKeyGenerator.valuesKey(
                spreadsheetId: spreadsheetId,
                range: range,
                options: options
            )
            
            if let cachedResult = await cache.retrieve(ValueRange.self, for: cacheKey) {
                return cachedResult
            }
        }
        
        // Check if range should be split for memory efficiency
        let ranges = try memoryHandler.splitRangeIntoChunks(range)
        
        if ranges.count > 1 {
            // Process large range in chunks
            let batchResponse = try await batchGet(
                spreadsheetId: spreadsheetId,
                ranges: ranges,
                options: options
            )
            
            // Merge the results back into a single ValueRange
            return try mergeValueRanges(batchResponse.valueRanges ?? [], originalRange: range)
        }
        
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Build query parameters from options
        var queryParams: [String: String] = [:]
        
        if let majorDimension = options?.majorDimension {
            queryParams["majorDimension"] = majorDimension.rawValue
        }
        
        if let valueRenderOption = options?.valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption.rawValue
        }
        
        if let dateTimeRenderOption = options?.dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption.rawValue
        }
        
        // Build and execute request
        let request = try authenticatedBuilder.getValues(
            spreadsheetId: spreadsheetId,
            range: range,
            majorDimension: queryParams["majorDimension"],
            valueRenderOption: queryParams["valueRenderOption"],
            dateTimeRenderOption: queryParams["dateTimeRenderOption"]
        )
        
        let result: ValueRange = try await httpClient.execute(request)
        
        // Cache the result if caching is enabled
        if let cache = cache, cacheConfiguration.enabled {
            let cacheKey = CacheKeyGenerator.valuesKey(
                spreadsheetId: spreadsheetId,
                range: range,
                options: options
            )
            await cache.store(result, for: cacheKey, ttl: cacheConfiguration.valuesTTL)
        }
        
        return result
    }
    
    /// Get values from multiple ranges in a single request
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - ranges: Array of A1 notation ranges to retrieve
    ///   - options: Optional parameters for the request
    /// - Returns: BatchGetValuesResponse containing the requested data
    /// - Throws: GoogleSheetsError if the operation fails
    public func batchGet(spreadsheetId: String, ranges: [String], options: ValueGetOptions? = nil) async throws -> BatchGetValuesResponse {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        guard !ranges.isEmpty else {
            throw GoogleSheetsError.invalidRange("At least one range must be specified")
        }
        
        // Validate all ranges
        for range in ranges {
            try validateRange(range)
        }
        
        // Check cache first if enabled
        if let cache = cache, cacheConfiguration.enabled {
            let cacheKey = CacheKeyGenerator.batchValuesKey(
                spreadsheetId: spreadsheetId,
                ranges: ranges,
                options: options
            )
            
            if let cachedResult = await cache.retrieve(BatchGetValuesResponse.self, for: cacheKey) {
                return cachedResult
            }
        }
        
        // Optimize ranges for batch processing
        let optimizedRanges = batchOptimizer.optimizeRanges(ranges)
        let batches = batchOptimizer.createBatches(from: optimizedRanges)
        
        // If we have multiple batches, process them separately and merge results
        if batches.count > 1 {
            var allValueRanges: [ValueRange] = []
            
            for batch in batches {
                let batchResponse = try await executeBatchGetRequest(
                    spreadsheetId: spreadsheetId,
                    ranges: batch,
                    options: options
                )
                
                if let valueRanges = batchResponse.valueRanges {
                    allValueRanges.append(contentsOf: valueRanges)
                }
            }
            
            let result = BatchGetValuesResponse(
                spreadsheetId: spreadsheetId,
                valueRanges: allValueRanges
            )
            
            // Cache the result if caching is enabled
            if let cache = cache, cacheConfiguration.enabled {
                let cacheKey = CacheKeyGenerator.batchValuesKey(
                    spreadsheetId: spreadsheetId,
                    ranges: ranges,
                    options: options
                )
                await cache.store(result, for: cacheKey, ttl: cacheConfiguration.valuesTTL)
            }
            
            return result
        }
        
        // Single batch processing
        let result = try await executeBatchGetRequest(
            spreadsheetId: spreadsheetId,
            ranges: optimizedRanges,
            options: options
        )
        
        // Cache the result if caching is enabled
        if let cache = cache, cacheConfiguration.enabled {
            let cacheKey = CacheKeyGenerator.batchValuesKey(
                spreadsheetId: spreadsheetId,
                ranges: ranges,
                options: options
            )
            await cache.store(result, for: cacheKey, ttl: cacheConfiguration.valuesTTL)
        }
        
        return result
    }
    
    /// Execute a single batch get request
    private func executeBatchGetRequest(
        spreadsheetId: String,
        ranges: [String],
        options: ValueGetOptions?
    ) async throws -> BatchGetValuesResponse {
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Build query parameters from options
        var queryParams: [String: String] = [:]
        
        if let majorDimension = options?.majorDimension {
            queryParams["majorDimension"] = majorDimension.rawValue
        }
        
        if let valueRenderOption = options?.valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption.rawValue
        }
        
        if let dateTimeRenderOption = options?.dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption.rawValue
        }
        
        // Build and execute request
        let request = try authenticatedBuilder.batchGetValues(
            spreadsheetId: spreadsheetId,
            ranges: ranges,
            majorDimension: queryParams["majorDimension"],
            valueRenderOption: queryParams["valueRenderOption"],
            dateTimeRenderOption: queryParams["dateTimeRenderOption"]
        )
        
        return try await httpClient.execute(request)
    }
    
    // MARK: - Writing Operations
    
    /// Update values in a specific range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to update
    ///   - values: The ValueRange containing the data to write
    ///   - options: Optional parameters for the request
    /// - Returns: UpdateValuesResponse containing update information
    /// - Throws: GoogleSheetsError if the operation fails
    public func update(spreadsheetId: String, range: String, values: ValueRange, options: ValueUpdateOptions? = nil) async throws -> UpdateValuesResponse {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        try validateRange(range)
        
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Prepare request body
        let requestBody = values
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestBody)
        
        // Build request with options
        let request = try authenticatedBuilder.updateValues(
            spreadsheetId: spreadsheetId,
            range: range,
            valueInputOption: options?.valueInputOption?.rawValue,
            includeValuesInResponse: options?.includeValuesInResponse ?? false,
            responseValueRenderOption: options?.responseValueRenderOption?.rawValue,
            responseDateTimeRenderOption: options?.responseDateTimeRenderOption?.rawValue,
            body: bodyData
        )
        
        let result: UpdateValuesResponse = try await httpClient.execute(request)
        
        // Invalidate cache for the updated range
        if let cache = cache, cacheConfiguration.enabled {
            let invalidator = CacheInvalidator(cache: cache)
            await invalidator.invalidateRanges(spreadsheetId, ranges: [range])
        }
        
        return result
    }
    
    /// Append values to a range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to append to
    ///   - values: The ValueRange containing the data to append
    ///   - options: Optional parameters for the request
    /// - Returns: AppendValuesResponse containing append information
    /// - Throws: GoogleSheetsError if the operation fails
    public func append(spreadsheetId: String, range: String, values: ValueRange, options: ValueAppendOptions? = nil) async throws -> AppendValuesResponse {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        try validateRange(range)
        
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Prepare request body
        let requestBody = values
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestBody)
        
        // Build request with options
        let request = try authenticatedBuilder.appendValues(
            spreadsheetId: spreadsheetId,
            range: range,
            valueInputOption: options?.valueInputOption?.rawValue,
            insertDataOption: options?.insertDataOption?.rawValue,
            includeValuesInResponse: options?.includeValuesInResponse ?? false,
            responseValueRenderOption: options?.responseValueRenderOption?.rawValue,
            responseDateTimeRenderOption: options?.responseDateTimeRenderOption?.rawValue,
            body: bodyData
        )
        
        let result: AppendValuesResponse = try await httpClient.execute(request)
        
        // Invalidate cache for the appended range
        if let cache = cache, cacheConfiguration.enabled {
            let invalidator = CacheInvalidator(cache: cache)
            await invalidator.invalidateRanges(spreadsheetId, ranges: [range])
        }
        
        return result
    }
    
    /// Clear values in a range
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - range: The A1 notation range to clear
    /// - Returns: ClearValuesResponse containing clear information
    /// - Throws: GoogleSheetsError if the operation fails
    public func clear(spreadsheetId: String, range: String) async throws -> ClearValuesResponse {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        try validateRange(range)
        
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Build request
        let request = try authenticatedBuilder.clearValues(
            spreadsheetId: spreadsheetId,
            range: range
        )
        
        let result: ClearValuesResponse = try await httpClient.execute(request)
        
        // Invalidate cache for the cleared range
        if let cache = cache, cacheConfiguration.enabled {
            let invalidator = CacheInvalidator(cache: cache)
            await invalidator.invalidateRanges(spreadsheetId, ranges: [range])
        }
        
        return result
    }
    
    /// Update values in multiple ranges in a single request
    /// - Parameters:
    ///   - spreadsheetId: The ID of the spreadsheet
    ///   - data: Array of ValueRange objects containing the data to update
    ///   - options: Optional parameters for the request
    /// - Returns: BatchUpdateValuesResponse containing update information
    /// - Throws: GoogleSheetsError if the operation fails
    public func batchUpdate(spreadsheetId: String, data: [ValueRange], options: ValueUpdateOptions? = nil) async throws -> BatchUpdateValuesResponse {
        // Validate inputs
        try validateSpreadsheetId(spreadsheetId)
        guard !data.isEmpty else {
            throw GoogleSheetsError.invalidData("At least one ValueRange must be provided for batch update")
        }
        
        // Validate all ranges in the data
        for valueRange in data {
            if let range = valueRange.range {
                try validateRange(range)
            }
        }
        
        // Get access token
        let accessToken = try await tokenManager.getAccessToken()
        let authenticatedBuilder = RequestBuilder(accessToken: accessToken)
        
        // Prepare request body
        let requestBody = BatchUpdateValuesRequest(
            valueInputOption: options?.valueInputOption,
            data: data,
            includeValuesInResponse: options?.includeValuesInResponse,
            responseValueRenderOption: options?.responseValueRenderOption,
            responseDateTimeRenderOption: options?.responseDateTimeRenderOption
        )
        
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(requestBody)
        
        // Build request
        let request = try authenticatedBuilder.buildBatchRequest(
            method: .POST,
            spreadsheetId: spreadsheetId,
            endpoint: "values:batchUpdate",
            body: bodyData
        )
        
        let result: BatchUpdateValuesResponse = try await httpClient.execute(request)
        
        // Invalidate cache for all updated ranges
        if let cache = cache, cacheConfiguration.enabled {
            let invalidator = CacheInvalidator(cache: cache)
            let ranges = data.compactMap { $0.range }
            await invalidator.invalidateRanges(spreadsheetId, ranges: ranges)
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    /// Merge multiple ValueRanges back into a single ValueRange
    /// - Parameters:
    ///   - valueRanges: Array of ValueRange objects to merge
    ///   - originalRange: The original range that was split
    /// - Returns: Merged ValueRange
    /// - Throws: GoogleSheetsError if merging fails
    private func mergeValueRanges(_ valueRanges: [ValueRange], originalRange: String) throws -> ValueRange {
        guard !valueRanges.isEmpty else {
            return ValueRange(range: originalRange, majorDimension: .rows, values: [])
        }
        
        // If only one range, return it with the original range
        if valueRanges.count == 1 {
            let valueRange = valueRanges[0]
            return ValueRange(
                range: originalRange,
                majorDimension: valueRange.majorDimension,
                values: valueRange.values
            )
        }
        
        // Merge multiple ranges
        var allValues: [[AnyCodable]] = []
        let majorDimension = valueRanges.first?.majorDimension ?? .rows
        
        for valueRange in valueRanges {
            if let values = valueRange.values {
                allValues.append(contentsOf: values)
            }
        }
        
        return ValueRange(
            range: originalRange,
            majorDimension: majorDimension,
            values: allValues
        )
    }
}

// MARK: - A1 Notation Validation and Utilities

extension ValuesService {
    /// Validate a spreadsheet ID
    /// - Parameter spreadsheetId: The spreadsheet ID to validate
    /// - Throws: GoogleSheetsError.invalidSpreadsheetId if invalid
    private func validateSpreadsheetId(_ spreadsheetId: String) throws {
        guard !spreadsheetId.isEmpty else {
            throw GoogleSheetsError.invalidSpreadsheetId("Spreadsheet ID cannot be empty")
        }
        
        // Basic validation - Google Sheets IDs are typically 44 characters long
        // and contain alphanumeric characters, hyphens, and underscores
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard spreadsheetId.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            throw GoogleSheetsError.invalidSpreadsheetId("Spreadsheet ID contains invalid characters: \(spreadsheetId)")
        }
    }
    
    /// Validate an A1 notation range
    /// - Parameter range: The range to validate
    /// - Throws: GoogleSheetsError.invalidRange if invalid
    private func validateRange(_ range: String) throws {
        guard !range.isEmpty else {
            throw GoogleSheetsError.invalidRange("Range cannot be empty")
        }
        
        // Parse and validate the range
        let parsedRange = try parseA1Range(range)
        
        // Additional validation can be added here
        if let sheetName = parsedRange.sheetName {
            try validateSheetName(sheetName)
        }
    }
    
    /// Validate a sheet name
    /// - Parameter sheetName: The sheet name to validate
    /// - Throws: GoogleSheetsError.invalidRange if invalid
    private func validateSheetName(_ sheetName: String) throws {
        guard !sheetName.isEmpty else {
            throw GoogleSheetsError.invalidRange("Sheet name cannot be empty")
        }
        
        // Sheet names cannot contain certain characters
        let invalidCharacters = CharacterSet(charactersIn: "[]?*\\/:")
        guard sheetName.rangeOfCharacter(from: invalidCharacters) == nil else {
            throw GoogleSheetsError.invalidRange("Sheet name contains invalid characters: \(sheetName)")
        }
    }
}

// MARK: - A1 Range Parsing

/// Represents a parsed A1 notation range
public struct A1Range {
    /// The sheet name (if specified)
    public let sheetName: String?
    /// The start column (e.g., "A" -> 1, "B" -> 2)
    public let startColumn: Int?
    /// The start row
    public let startRow: Int?
    /// The end column (e.g., "A" -> 1, "B" -> 2)
    public let endColumn: Int?
    /// The end row
    public let endRow: Int?
    /// Whether this is a single cell reference
    public let isSingleCell: Bool
    /// Whether this is an entire row reference (e.g., "1:1")
    public let isEntireRow: Bool
    /// Whether this is an entire column reference (e.g., "A:A")
    public let isEntireColumn: Bool
    
    public init(sheetName: String? = nil, startColumn: Int? = nil, startRow: Int? = nil, 
                endColumn: Int? = nil, endRow: Int? = nil) {
        self.sheetName = sheetName
        self.startColumn = startColumn
        self.startRow = startRow
        self.endColumn = endColumn
        self.endRow = endRow
        
        // Determine range type
        self.isSingleCell = (startColumn == endColumn && startRow == endRow) && 
                           (startColumn != nil && startRow != nil)
        self.isEntireRow = (startColumn == nil && endColumn == nil) && 
                          (startRow != nil || endRow != nil)
        self.isEntireColumn = (startRow == nil && endRow == nil) && 
                             (startColumn != nil || endColumn != nil)
    }
}

extension ValuesService {
    /// Parse an A1 notation range string
    /// - Parameter range: The A1 notation range to parse
    /// - Returns: Parsed A1Range object
    /// - Throws: GoogleSheetsError.invalidRange if parsing fails
    func parseA1Range(_ range: String) throws -> A1Range {
        var workingRange = range.trimmingCharacters(in: .whitespacesAndNewlines)
        var sheetName: String?
        
        // Extract sheet name if present (format: 'SheetName'!A1:B2 or SheetName!A1:B2)
        if let exclamationIndex = workingRange.firstIndex(of: "!") {
            let sheetPart = String(workingRange[..<exclamationIndex])
            workingRange = String(workingRange[workingRange.index(after: exclamationIndex)...])
            
            // Remove quotes if present
            if sheetPart.hasPrefix("'") && sheetPart.hasSuffix("'") {
                sheetName = String(sheetPart.dropFirst().dropLast())
            } else {
                sheetName = sheetPart
            }
        }
        
        // Handle special cases
        if workingRange.isEmpty {
            return A1Range(sheetName: sheetName)
        }
        
        // Split by colon to get start and end parts
        let parts = workingRange.components(separatedBy: ":")
        
        if parts.count == 1 {
            // Single cell or entire sheet reference
            let cellRef = try parseCellReference(parts[0])
            return A1Range(
                sheetName: sheetName,
                startColumn: cellRef.column,
                startRow: cellRef.row,
                endColumn: cellRef.column,
                endRow: cellRef.row
            )
        } else if parts.count == 2 {
            // Range reference
            let startRef = try parseCellReference(parts[0])
            let endRef = try parseCellReference(parts[1])
            
            return A1Range(
                sheetName: sheetName,
                startColumn: startRef.column,
                startRow: startRef.row,
                endColumn: endRef.column,
                endRow: endRef.row
            )
        } else {
            throw GoogleSheetsError.invalidRange("Invalid range format: \(range)")
        }
    }
    
    /// Parse a single cell reference (e.g., "A1", "B", "1")
    /// - Parameter cellRef: The cell reference to parse
    /// - Returns: Tuple containing optional column and row numbers
    /// - Throws: GoogleSheetsError.invalidRange if parsing fails
    private func parseCellReference(_ cellRef: String) throws -> (column: Int?, row: Int?) {
        let trimmed = cellRef.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            throw GoogleSheetsError.invalidRange("Empty cell reference")
        }
        
        // Separate column letters from row numbers
        var columnPart = ""
        var rowPart = ""
        
        for char in trimmed {
            if char.isLetter {
                columnPart.append(char)
            } else if char.isNumber {
                rowPart.append(char)
            } else {
                throw GoogleSheetsError.invalidRange("Invalid character in cell reference: \(char)")
            }
        }
        
        // Parse column (convert letters to number)
        var column: Int?
        if !columnPart.isEmpty {
            column = try columnLettersToNumber(columnPart.uppercased())
        }
        
        // Parse row
        var row: Int?
        if !rowPart.isEmpty {
            guard let parsedRow = Int(rowPart), parsedRow > 0 else {
                throw GoogleSheetsError.invalidRange("Invalid row number: \(rowPart)")
            }
            row = parsedRow
        }
        
        return (column: column, row: row)
    }
    
    /// Convert column letters to column number (A=1, B=2, ..., Z=26, AA=27, etc.)
    /// - Parameter letters: The column letters (e.g., "A", "AB")
    /// - Returns: The column number
    /// - Throws: GoogleSheetsError.invalidRange if conversion fails
    private func columnLettersToNumber(_ letters: String) throws -> Int {
        guard !letters.isEmpty else {
            throw GoogleSheetsError.invalidRange("Empty column letters")
        }
        
        var result = 0
        for char in letters {
            guard char.isLetter && char.isASCII else {
                throw GoogleSheetsError.invalidRange("Invalid column letter: \(char)")
            }
            
            let value = Int(char.asciiValue! - Character("A").asciiValue! + 1)
            result = result * 26 + value
        }
        
        return result
    }
}

// MARK: - Utility Extensions

extension A1Range {
    /// Convert the range back to A1 notation
    /// - Returns: A1 notation string representation
    public func toA1Notation() -> String {
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
        if let startCol = startColumn, let startRow = startRow {
            result += columnNumberToLetters(startCol) + "\(startRow)"
            
            if let endCol = endColumn, let endRow = endRow,
               !(startCol == endCol && startRow == endRow) {
                result += ":" + columnNumberToLetters(endCol) + "\(endRow)"
            }
        } else if let startCol = startColumn {
            result += columnNumberToLetters(startCol)
            if let endCol = endColumn, startCol != endCol {
                result += ":" + columnNumberToLetters(endCol)
            }
        } else if let startRow = startRow {
            result += "\(startRow)"
            if let endRow = endRow, startRow != endRow {
                result += ":\(endRow)"
            }
        }
        
        return result
    }
    
    /// Convert column number to letters (1=A, 2=B, ..., 26=Z, 27=AA, etc.)
    /// - Parameter number: The column number
    /// - Returns: The column letters
    private func columnNumberToLetters(_ number: Int) -> String {
        var result = ""
        var num = number
        
        while num > 0 {
            num -= 1
            let remainder = num % 26
            result = String(Character(UnicodeScalar(remainder + Int(Character("A").asciiValue!))!)) + result
            num /= 26
        }
        
        return result
    }
}