import Foundation

/// Batch operation optimizer for multiple ranges
public class BatchOptimizer {
    
    /// Configuration for batch optimization
    public struct Configuration {
        /// Maximum number of ranges to include in a single batch request
        public let maxBatchSize: Int
        
        /// Minimum number of ranges to trigger batch optimization
        public let minBatchSize: Int
        
        /// Whether to merge adjacent ranges
        public let mergeAdjacentRanges: Bool
        
        /// Whether to sort ranges for optimal processing
        public let sortRanges: Bool
        
        public static let `default` = Configuration(
            maxBatchSize: 100,
            minBatchSize: 2,
            mergeAdjacentRanges: true,
            sortRanges: true
        )
        
        public init(maxBatchSize: Int, minBatchSize: Int, mergeAdjacentRanges: Bool, sortRanges: Bool) {
            self.maxBatchSize = maxBatchSize
            self.minBatchSize = minBatchSize
            self.mergeAdjacentRanges = mergeAdjacentRanges
            self.sortRanges = sortRanges
        }
    }
    
    private let configuration: Configuration
    
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    /// Optimize a list of ranges for batch operations
    public func optimizeRanges(_ ranges: [String]) -> [String] {
        guard ranges.count >= configuration.minBatchSize else {
            return ranges
        }
        
        var optimizedRanges = ranges
        
        // Sort ranges if enabled
        if configuration.sortRanges {
            optimizedRanges = sortRanges(optimizedRanges)
        }
        
        // Merge adjacent ranges if enabled
        if configuration.mergeAdjacentRanges {
            optimizedRanges = mergeAdjacentRanges(optimizedRanges)
        }
        
        return optimizedRanges
    }
    
    /// Split ranges into batches based on configuration
    public func createBatches(from ranges: [String]) -> [[String]] {
        let optimizedRanges = optimizeRanges(ranges)
        
        guard optimizedRanges.count > configuration.maxBatchSize else {
            return [optimizedRanges]
        }
        
        var batches: [[String]] = []
        var currentBatch: [String] = []
        
        for range in optimizedRanges {
            if currentBatch.count >= configuration.maxBatchSize {
                batches.append(currentBatch)
                currentBatch = []
            }
            currentBatch.append(range)
        }
        
        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }
        
        return batches
    }
    
    /// Optimize batch read operations
    public func optimizeBatchReadOperations(_ operations: [BatchReadOperation]) -> [BatchReadOperation] {
        guard operations.count >= configuration.minBatchSize else {
            return operations
        }
        
        // Group operations by their options to maintain consistency
        let groupedOperations = Dictionary(grouping: operations) { operation in
            BatchReadOperationKey(
                majorDimension: operation.majorDimension,
                valueRenderOption: operation.valueRenderOption
            )
        }
        
        var optimizedOperations: [BatchReadOperation] = []
        
        for (key, ops) in groupedOperations {
            let ranges = ops.map { $0.range }
            let optimizedRanges = optimizeRanges(ranges)
            
            let newOperations = optimizedRanges.map { range in
                BatchReadOperation(
                    range: range,
                    majorDimension: key.majorDimension,
                    valueRenderOption: key.valueRenderOption
                )
            }
            
            optimizedOperations.append(contentsOf: newOperations)
        }
        
        return optimizedOperations
    }
    
    /// Optimize batch write operations
    public func optimizeBatchWriteOperations(_ operations: [BatchWriteOperation]) -> [BatchWriteOperation] {
        guard operations.count >= configuration.minBatchSize else {
            return operations
        }
        
        // Group operations by major dimension
        let groupedOperations = Dictionary(grouping: operations) { $0.majorDimension }
        
        var optimizedOperations: [BatchWriteOperation] = []
        
        for (majorDimension, ops) in groupedOperations {
            // Sort operations by range for better performance
            let sortedOps = ops.sorted { op1, op2 in
                return op1.range < op2.range
            }
            
            optimizedOperations.append(contentsOf: sortedOps)
        }
        
        return optimizedOperations
    }
    
    // MARK: - Private Helper Methods
    
    private func sortRanges(_ ranges: [String]) -> [String] {
        return ranges.sorted { range1, range2 in
            // Parse ranges and sort by sheet name, then by position
            do {
                let parsed1 = try parseRangeForSorting(range1)
                let parsed2 = try parseRangeForSorting(range2)
                
                // First sort by sheet name
                if parsed1.sheetName != parsed2.sheetName {
                    return (parsed1.sheetName ?? "") < (parsed2.sheetName ?? "")
                }
                
                // Then by start row
                if parsed1.startRow != parsed2.startRow {
                    return (parsed1.startRow ?? 0) < (parsed2.startRow ?? 0)
                }
                
                // Finally by start column
                return (parsed1.startColumn ?? 0) < (parsed2.startColumn ?? 0)
            } catch {
                // If parsing fails, fall back to string comparison
                return range1 < range2
            }
        }
    }
    
    private func mergeAdjacentRanges(_ ranges: [String]) -> [String] {
        // This is a simplified implementation
        // In a full implementation, we would parse ranges and merge adjacent ones
        // For now, we'll just return the original ranges
        return ranges
    }
    
    private func parseRangeForSorting(_ range: String) throws -> (sheetName: String?, startRow: Int?, startColumn: Int?) {
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
        
        // Parse the range part (simplified)
        let parts = workingRange.components(separatedBy: ":")
        let startPart = parts.first ?? ""
        
        var startRow: Int?
        var startColumn: Int?
        
        // Extract row and column from start part
        var columnPart = ""
        var rowPart = ""
        
        for char in startPart {
            if char.isLetter {
                columnPart.append(char)
            } else if char.isNumber {
                rowPart.append(char)
            }
        }
        
        if !rowPart.isEmpty {
            startRow = Int(rowPart)
        }
        
        if !columnPart.isEmpty {
            startColumn = columnLettersToNumber(columnPart.uppercased())
        }
        
        return (sheetName: sheetName, startRow: startRow, startColumn: startColumn)
    }
    
    private func columnLettersToNumber(_ letters: String) -> Int {
        var result = 0
        for char in letters {
            let value = Int(char.asciiValue! - Character("A").asciiValue! + 1)
            result = result * 26 + value
        }
        return result
    }
}

/// Key for grouping batch read operations
private struct BatchReadOperationKey: Hashable {
    let majorDimension: MajorDimension
    let valueRenderOption: ValueRenderOption
}

/// Batch operation statistics
public struct BatchOperationStats {
    /// Number of original operations
    public let originalCount: Int
    
    /// Number of optimized operations
    public let optimizedCount: Int
    
    /// Number of batches created
    public let batchCount: Int
    
    /// Estimated performance improvement (as a percentage)
    public let estimatedImprovement: Double
    
    public init(originalCount: Int, optimizedCount: Int, batchCount: Int) {
        self.originalCount = originalCount
        self.optimizedCount = optimizedCount
        self.batchCount = batchCount
        
        // Simple heuristic for estimated improvement
        if originalCount > 0 {
            self.estimatedImprovement = max(0, Double(originalCount - batchCount) / Double(originalCount) * 100)
        } else {
            self.estimatedImprovement = 0
        }
    }
}

/// Batch operation result
public struct BatchOperationResult<T> {
    /// The results from the batch operation
    public let results: [T]
    
    /// Statistics about the batch operation
    public let stats: BatchOperationStats
    
    /// Time taken for the operation
    public let executionTime: TimeInterval
    
    public init(results: [T], stats: BatchOperationStats, executionTime: TimeInterval) {
        self.results = results
        self.stats = stats
        self.executionTime = executionTime
    }
}