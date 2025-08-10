import Foundation

/// Memory-efficient data handler for large datasets
public class MemoryEfficientDataHandler {
    
    /// Configuration for memory-efficient operations
    public struct Configuration {
        /// Maximum number of rows to process in memory at once
        public let maxRowsInMemory: Int
        
        /// Maximum number of columns to process in memory at once
        public let maxColumnsInMemory: Int
        
        /// Whether to use streaming for large datasets
        public let useStreaming: Bool
        
        /// Threshold for considering a dataset "large" (number of cells)
        public let largeDatassetThreshold: Int
        
        /// Whether to compress data in memory
        public let compressInMemory: Bool
        
        public static let `default` = Configuration(
            maxRowsInMemory: 10000,
            maxColumnsInMemory: 100,
            useStreaming: true,
            largeDatassetThreshold: 100000,
            compressInMemory: false
        )
        
        public static let conservative = Configuration(
            maxRowsInMemory: 1000,
            maxColumnsInMemory: 50,
            useStreaming: true,
            largeDatassetThreshold: 10000,
            compressInMemory: true
        )
        
        public init(maxRowsInMemory: Int, maxColumnsInMemory: Int, useStreaming: Bool, 
                   largeDatassetThreshold: Int, compressInMemory: Bool) {
            self.maxRowsInMemory = maxRowsInMemory
            self.maxColumnsInMemory = maxColumnsInMemory
            self.useStreaming = useStreaming
            self.largeDatassetThreshold = largeDatassetThreshold
            self.compressInMemory = compressInMemory
        }
    }
    
    private let configuration: Configuration
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    /// Process large dataset in chunks
    public func processLargeDataset<T>(
        _ data: [[AnyCodable]],
        processor: (ArraySlice<[AnyCodable]>) async throws -> T
    ) async throws -> [T] {
        let totalCells = data.reduce(0) { $0 + $1.count }
        
        guard totalCells > configuration.largeDatassetThreshold else {
            // Process normally for small datasets
            return [try await processor(data[...])]
        }
        
        var results: [T] = []
        let chunkSize = configuration.maxRowsInMemory
        
        for startIndex in stride(from: 0, to: data.count, by: chunkSize) {
            let endIndex = min(startIndex + chunkSize, data.count)
            let chunk = data[startIndex..<endIndex]
            
            let result = try await processor(chunk)
            results.append(result)
            
            // Allow other tasks to run
            await Task.yield()
        }
        
        return results
    }
    
    /// Create memory-efficient ValueRange from large data
    public func createValueRange(
        range: String?,
        majorDimension: MajorDimension?,
        data: [[Any]]
    ) -> ValueRange {
        let totalCells = data.reduce(0) { $0 + $1.count }
        
        if totalCells <= configuration.largeDatassetThreshold {
            // Use normal initialization for small datasets
            return ValueRange(range: range, majorDimension: majorDimension, values: data)
        }
        
        // For large datasets, create a lazy-loaded ValueRange
        return createLazyValueRange(range: range, majorDimension: majorDimension, data: data)
    }
    
    /// Split large range into smaller chunks for processing
    public func splitRangeIntoChunks(_ range: String, maxRowsPerChunk: Int? = nil) throws -> [String] {
        let maxRows = maxRowsPerChunk ?? configuration.maxRowsInMemory
        
        // Parse the range to determine if it needs splitting
        let parsedRange = try parseRange(range)
        
        guard let startRow = parsedRange.startRow,
              let endRow = parsedRange.endRow,
              (endRow - startRow + 1) > maxRows else {
            return [range]
        }
        
        var chunks: [String] = []
        var currentRow = startRow
        
        while currentRow <= endRow {
            let chunkEndRow = min(currentRow + maxRows - 1, endRow)
            
            let chunkRange = buildRangeString(
                sheetName: parsedRange.sheetName,
                startColumn: parsedRange.startColumn,
                startRow: currentRow,
                endColumn: parsedRange.endColumn,
                endRow: chunkEndRow
            )
            
            chunks.append(chunkRange)
            currentRow = chunkEndRow + 1
        }
        
        return chunks
    }
    
    /// Estimate memory usage for a dataset
    public func estimateMemoryUsage(rowCount: Int, columnCount: Int, averageCellSize: Int = 50) -> Int {
        // Rough estimation: each cell takes approximately averageCellSize bytes
        // Plus overhead for arrays and objects
        let cellMemory = rowCount * columnCount * averageCellSize
        let arrayOverhead = rowCount * 64 + columnCount * 8 // Rough estimate for array overhead
        return cellMemory + arrayOverhead
    }
    
    /// Check if a dataset should be processed in chunks
    public func shouldProcessInChunks(rowCount: Int, columnCount: Int) -> Bool {
        let totalCells = rowCount * columnCount
        return totalCells > configuration.largeDatassetThreshold ||
               rowCount > configuration.maxRowsInMemory ||
               columnCount > configuration.maxColumnsInMemory
    }
    
    /// Create a streaming processor for large datasets
    public func createStreamingProcessor<T>(
        chunkProcessor: @escaping (ArraySlice<[AnyCodable]>) async throws -> T
    ) -> StreamingDataProcessor<T> {
        return StreamingDataProcessor(
            configuration: configuration,
            chunkProcessor: chunkProcessor
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func createLazyValueRange(
        range: String?,
        majorDimension: MajorDimension?,
        data: [[Any]]
    ) -> ValueRange {
        // For now, we'll still create the full ValueRange
        // In a more advanced implementation, we could create a lazy-loading wrapper
        return ValueRange(range: range, majorDimension: majorDimension, values: data)
    }
    
    private func parseRange(_ range: String) throws -> ParsedRange {
        var workingRange = range.trimmingCharacters(in: .whitespacesAndNewlines)
        var sheetName: String?
        
        // Extract sheet name if present
        if let exclamationIndex = workingRange.firstIndex(of: "!") {
            let sheetPart = String(workingRange[..<exclamationIndex])
            workingRange = String(workingRange[workingRange.index(after: exclamationIndex)...])
            
            if sheetPart.hasPrefix("'") && sheetPart.hasSuffix("'") {
                sheetName = String(sheetPart.dropFirst().dropLast())
            } else {
                sheetName = sheetPart
            }
        }
        
        // Parse range components
        let parts = workingRange.components(separatedBy: ":")
        
        if parts.count == 1 {
            let cellRef = try parseCellReference(parts[0])
            return ParsedRange(
                sheetName: sheetName,
                startColumn: cellRef.column,
                startRow: cellRef.row,
                endColumn: cellRef.column,
                endRow: cellRef.row
            )
        } else if parts.count == 2 {
            let startRef = try parseCellReference(parts[0])
            let endRef = try parseCellReference(parts[1])
            
            return ParsedRange(
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
    
    private func parseCellReference(_ cellRef: String) throws -> (column: Int?, row: Int?) {
        let trimmed = cellRef.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var columnPart = ""
        var rowPart = ""
        
        for char in trimmed {
            if char.isLetter {
                columnPart.append(char)
            } else if char.isNumber {
                rowPart.append(char)
            }
        }
        
        var column: Int?
        if !columnPart.isEmpty {
            column = try columnLettersToNumber(columnPart.uppercased())
        }
        
        var row: Int?
        if !rowPart.isEmpty {
            guard let parsedRow = Int(rowPart), parsedRow > 0 else {
                throw GoogleSheetsError.invalidRange("Invalid row number: \(rowPart)")
            }
            row = parsedRow
        }
        
        return (column: column, row: row)
    }
    
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
    
    private func buildRangeString(
        sheetName: String?,
        startColumn: Int?,
        startRow: Int?,
        endColumn: Int?,
        endRow: Int?
    ) -> String {
        var result = ""
        
        if let sheetName = sheetName {
            if sheetName.contains(" ") || sheetName.contains("'") {
                result += "'\(sheetName.replacingOccurrences(of: "'", with: "''"))'"
            } else {
                result += sheetName
            }
            result += "!"
        }
        
        if let startCol = startColumn, let startRow = startRow {
            result += columnNumberToLetters(startCol) + "\(startRow)"
            
            if let endCol = endColumn, let endRow = endRow,
               !(startCol == endCol && startRow == endRow) {
                result += ":" + columnNumberToLetters(endCol) + "\(endRow)"
            }
        }
        
        return result
    }
    
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

/// Parsed range structure
private struct ParsedRange {
    let sheetName: String?
    let startColumn: Int?
    let startRow: Int?
    let endColumn: Int?
    let endRow: Int?
}

/// Streaming data processor for large datasets
public class StreamingDataProcessor<T> {
    private let configuration: MemoryEfficientDataHandler.Configuration
    private let chunkProcessor: (ArraySlice<[AnyCodable]>) async throws -> T
    
    init(
        configuration: MemoryEfficientDataHandler.Configuration,
        chunkProcessor: @escaping (ArraySlice<[AnyCodable]>) async throws -> T
    ) {
        self.configuration = configuration
        self.chunkProcessor = chunkProcessor
    }
    
    /// Process data in streaming fashion
    public func process(_ data: [[AnyCodable]]) async throws -> [T] {
        var results: [T] = []
        let chunkSize = configuration.maxRowsInMemory
        
        for startIndex in stride(from: 0, to: data.count, by: chunkSize) {
            let endIndex = min(startIndex + chunkSize, data.count)
            let chunk = data[startIndex..<endIndex]
            
            let result = try await chunkProcessor(chunk)
            results.append(result)
            
            // Allow other tasks to run and potentially free memory
            await Task.yield()
        }
        
        return results
    }
}

/// Memory usage monitor
public class MemoryUsageMonitor {
    /// Get current memory usage in bytes
    public static func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
    
    /// Check if memory usage is above threshold
    public static func isMemoryUsageHigh(threshold: Int = 100 * 1024 * 1024) -> Bool {
        return getCurrentMemoryUsage() > threshold
    }
}