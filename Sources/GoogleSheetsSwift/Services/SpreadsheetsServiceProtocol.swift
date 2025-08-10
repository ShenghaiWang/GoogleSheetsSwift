import Foundation

/// Protocol for spreadsheet management operations
public protocol SpreadsheetsServiceProtocol: GoogleSheetsService {
    /// Create a new spreadsheet
    func create(_ request: SpreadsheetCreateRequest) async throws -> Spreadsheet
    
    /// Get spreadsheet information by ID
    func get(spreadsheetId: String, ranges: [String]?, includeGridData: Bool, fields: String?) async throws -> Spreadsheet
    
    /// Perform batch updates on a spreadsheet
    func batchUpdate(spreadsheetId: String, requests: [BatchUpdateRequest]) async throws -> BatchUpdateSpreadsheetResponse
}

// Spreadsheet models are now implemented in SpreadsheetModels.swift