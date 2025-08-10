import Foundation

/// Protocol for spreadsheet values operations
public protocol ValuesServiceProtocol: GoogleSheetsService {
    /// Get values from a specific range
    func get(spreadsheetId: String, range: String, options: ValueGetOptions?) async throws -> ValueRange
    
    /// Update values in a specific range
    func update(spreadsheetId: String, range: String, values: ValueRange, options: ValueUpdateOptions?) async throws -> UpdateValuesResponse
    
    /// Append values to a range
    func append(spreadsheetId: String, range: String, values: ValueRange, options: ValueAppendOptions?) async throws -> AppendValuesResponse
    
    /// Clear values in a range
    func clear(spreadsheetId: String, range: String) async throws -> ClearValuesResponse
    
    /// Get values from multiple ranges in a single request
    func batchGet(spreadsheetId: String, ranges: [String], options: ValueGetOptions?) async throws -> BatchGetValuesResponse
    
    /// Update values in multiple ranges in a single request
    func batchUpdate(spreadsheetId: String, data: [ValueRange], options: ValueUpdateOptions?) async throws -> BatchUpdateValuesResponse
}

// Value models are now implemented in ValueModels.swift