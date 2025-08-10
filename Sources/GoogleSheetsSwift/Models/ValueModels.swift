import Foundation

// MARK: - ValueRange Model

/// A range of values in a spreadsheet
public struct ValueRange: Codable, Equatable {
    /// The range the values cover, in A1 notation
    public let range: String?
    
    /// The major dimension of the values
    public let majorDimension: MajorDimension?
    
    /// The data that was read or to be written
    public let values: [[AnyCodable]]?
    
    /// Initialize a ValueRange
    /// - Parameters:
    ///   - range: The range in A1 notation (optional)
    ///   - majorDimension: The major dimension (optional, defaults to ROWS)
    ///   - values: The values as a 2D array (optional)
    public init(range: String? = nil, majorDimension: MajorDimension? = nil, values: [[AnyCodable]]? = nil) {
        self.range = range
        self.majorDimension = majorDimension
        self.values = values
    }
    
    /// Initialize a ValueRange with Any values (convenience initializer)
    /// - Parameters:
    ///   - range: The range in A1 notation (optional)
    ///   - majorDimension: The major dimension (optional, defaults to ROWS)
    ///   - values: The values as a 2D array of Any (optional)
    public init(range: String? = nil, majorDimension: MajorDimension? = nil, values: [[Any]]? = nil) {
        self.range = range
        self.majorDimension = majorDimension
        self.values = values?.map { row in
            row.map { AnyCodable($0) }
        }
    }
    
    /// Initialize a ValueRange with optional Any values (convenience initializer)
    /// - Parameters:
    ///   - range: The range in A1 notation (optional)
    ///   - majorDimension: The major dimension (optional, defaults to ROWS)
    ///   - values: The values as a 2D array of optional Any (optional)
    public init(range: String? = nil, majorDimension: MajorDimension? = nil, values: [[Any?]]? = nil) {
        self.range = range
        self.majorDimension = majorDimension
        self.values = values?.map { row in
            row.map { AnyCodable($0) }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get values as strings
    /// - Returns: 2D array of optional strings
    public func getStringValues() -> [[String?]] {
        return values?.toStrings() ?? []
    }
    
    /// Get values as doubles
    /// - Returns: 2D array of optional doubles
    public func getDoubleValues() -> [[Double?]] {
        return values?.toDoubles() ?? []
    }
    
    /// Get values as integers
    /// - Returns: 2D array of optional integers
    public func getIntValues() -> [[Int?]] {
        return values?.toInts() ?? []
    }
    
    /// Get values as booleans
    /// - Returns: 2D array of optional booleans
    public func getBoolValues() -> [[Bool?]] {
        return values?.toBools() ?? []
    }
    
    /// Get the number of rows
    /// - Returns: Number of rows in the values array
    public var rowCount: Int {
        return values?.count ?? 0
    }
    
    /// Get the number of columns (based on the first row)
    /// - Returns: Number of columns in the first row, or 0 if no values
    public var columnCount: Int {
        return values?.first?.count ?? 0
    }
    
    /// Check if the ValueRange is empty
    /// - Returns: True if there are no values
    public var isEmpty: Bool {
        return values?.isEmpty ?? true
    }
}

// MARK: - Response Models

/// Response from updating values
public struct UpdateValuesResponse: Codable, Equatable {
    /// The spreadsheet the updates were applied to
    public let spreadsheetId: String?
    
    /// The number of rows where at least one cell in the row was updated
    public let updatedRows: Int?
    
    /// The number of columns where at least one cell in the column was updated
    public let updatedColumns: Int?
    
    /// The number of cells updated
    public let updatedCells: Int?
    
    /// The range (in A1 notation) that updates were applied to
    public let updatedRange: String?
    
    /// The values of the cells after updates were applied
    public let updatedData: ValueRange?
    
    public init(spreadsheetId: String? = nil, updatedRows: Int? = nil, updatedColumns: Int? = nil, 
                updatedCells: Int? = nil, updatedRange: String? = nil, updatedData: ValueRange? = nil) {
        self.spreadsheetId = spreadsheetId
        self.updatedRows = updatedRows
        self.updatedColumns = updatedColumns
        self.updatedCells = updatedCells
        self.updatedRange = updatedRange
        self.updatedData = updatedData
    }
}

/// Response from appending values
public struct AppendValuesResponse: Codable, Equatable {
    /// The spreadsheet the updates were applied to
    public let spreadsheetId: String?
    
    /// The range (in A1 notation) of the table that values were appended to
    public let tableRange: String?
    
    /// Information about the updates that were applied
    public let updates: UpdateValuesResponse?
    
    public init(spreadsheetId: String? = nil, tableRange: String? = nil, updates: UpdateValuesResponse? = nil) {
        self.spreadsheetId = spreadsheetId
        self.tableRange = tableRange
        self.updates = updates
    }
}

/// Response from clearing values
public struct ClearValuesResponse: Codable, Equatable {
    /// The spreadsheet the updates were applied to
    public let spreadsheetId: String?
    
    /// The range (in A1 notation) that was cleared
    public let clearedRange: String?
    
    public init(spreadsheetId: String? = nil, clearedRange: String? = nil) {
        self.spreadsheetId = spreadsheetId
        self.clearedRange = clearedRange
    }
}

/// Response from batch get values
public struct BatchGetValuesResponse: Codable, Equatable {
    /// The spreadsheet the data was retrieved from
    public let spreadsheetId: String?
    
    /// The requested ranges the data was retrieved from
    public let valueRanges: [ValueRange]?
    
    public init(spreadsheetId: String? = nil, valueRanges: [ValueRange]? = nil) {
        self.spreadsheetId = spreadsheetId
        self.valueRanges = valueRanges
    }
}

/// Response from batch update values
public struct BatchUpdateValuesResponse: Codable, Equatable {
    /// The spreadsheet the updates were applied to
    public let spreadsheetId: String?
    
    /// The total number of rows where at least one cell in the row was updated
    public let totalUpdatedRows: Int?
    
    /// The total number of columns where at least one cell in the column was updated
    public let totalUpdatedColumns: Int?
    
    /// The total number of cells updated
    public let totalUpdatedCells: Int?
    
    /// One UpdateValuesResponse per requested range, in the same order as the requests appeared
    public let responses: [UpdateValuesResponse]?
    
    public init(spreadsheetId: String? = nil, totalUpdatedRows: Int? = nil, totalUpdatedColumns: Int? = nil,
                totalUpdatedCells: Int? = nil, responses: [UpdateValuesResponse]? = nil) {
        self.spreadsheetId = spreadsheetId
        self.totalUpdatedRows = totalUpdatedRows
        self.totalUpdatedColumns = totalUpdatedColumns
        self.totalUpdatedCells = totalUpdatedCells
        self.responses = responses
    }
}

// MARK: - Options Models

/// Options for getting values
public struct ValueGetOptions: Equatable {
    /// How values should be represented in the output
    public let valueRenderOption: ValueRenderOption?
    
    /// How dates, times, and durations should be represented in the output
    public let dateTimeRenderOption: DateTimeRenderOption?
    
    /// The major dimension that results should use
    public let majorDimension: MajorDimension?
    
    public init(valueRenderOption: ValueRenderOption? = nil, 
                dateTimeRenderOption: DateTimeRenderOption? = nil,
                majorDimension: MajorDimension? = nil) {
        self.valueRenderOption = valueRenderOption
        self.dateTimeRenderOption = dateTimeRenderOption
        self.majorDimension = majorDimension
    }
}

/// Options for updating values
public struct ValueUpdateOptions: Equatable {
    /// How the input data should be interpreted
    public let valueInputOption: ValueInputOption?
    
    /// Determines if the update response should include the values of the cells that were updated
    public let includeValuesInResponse: Bool?
    
    /// Determines how values in the response should be rendered
    public let responseValueRenderOption: ValueRenderOption?
    
    /// Determines how dates, times, and durations in the response should be rendered
    public let responseDateTimeRenderOption: DateTimeRenderOption?
    
    public init(valueInputOption: ValueInputOption? = nil,
                includeValuesInResponse: Bool? = nil,
                responseValueRenderOption: ValueRenderOption? = nil,
                responseDateTimeRenderOption: DateTimeRenderOption? = nil) {
        self.valueInputOption = valueInputOption
        self.includeValuesInResponse = includeValuesInResponse
        self.responseValueRenderOption = responseValueRenderOption
        self.responseDateTimeRenderOption = responseDateTimeRenderOption
    }
}

/// Options for appending values
public struct ValueAppendOptions: Equatable {
    /// How the input data should be interpreted
    public let valueInputOption: ValueInputOption?
    
    /// How the input data should be inserted
    public let insertDataOption: InsertDataOption?
    
    /// Determines if the update response should include the values of the cells that were updated
    public let includeValuesInResponse: Bool?
    
    /// Determines how values in the response should be rendered
    public let responseValueRenderOption: ValueRenderOption?
    
    /// Determines how dates, times, and durations in the response should be rendered
    public let responseDateTimeRenderOption: DateTimeRenderOption?
    
    public init(valueInputOption: ValueInputOption? = nil,
                insertDataOption: InsertDataOption? = nil,
                includeValuesInResponse: Bool? = nil,
                responseValueRenderOption: ValueRenderOption? = nil,
                responseDateTimeRenderOption: DateTimeRenderOption? = nil) {
        self.valueInputOption = valueInputOption
        self.insertDataOption = insertDataOption
        self.includeValuesInResponse = includeValuesInResponse
        self.responseValueRenderOption = responseValueRenderOption
        self.responseDateTimeRenderOption = responseDateTimeRenderOption
    }
}

/// How the input data should be inserted
public enum InsertDataOption: String, Codable, CaseIterable {
    /// The new data overwrites existing data in the areas it is written
    case overwrite = "OVERWRITE"
    /// Rows are inserted for the new data
    case insertRows = "INSERT_ROWS"
}

extension InsertDataOption {
    /// Returns a user-friendly description of the insert data option
    public var description: String {
        switch self {
        case .overwrite:
            return "Overwrite existing data"
        case .insertRows:
            return "Insert new rows"
        }
    }
}

// MARK: - Request Models

/// Request body for batch update values operation
public struct BatchUpdateValuesRequest: Codable, Equatable {
    /// How the input data should be interpreted
    public let valueInputOption: ValueInputOption?
    
    /// The new values to apply to the spreadsheet
    public let data: [ValueRange]
    
    /// Determines if the update response should include the values of the cells that were updated
    public let includeValuesInResponse: Bool?
    
    /// Determines how values in the response should be rendered
    public let responseValueRenderOption: ValueRenderOption?
    
    /// Determines how dates, times, and durations in the response should be rendered
    public let responseDateTimeRenderOption: DateTimeRenderOption?
    
    public init(valueInputOption: ValueInputOption? = nil,
                data: [ValueRange],
                includeValuesInResponse: Bool? = nil,
                responseValueRenderOption: ValueRenderOption? = nil,
                responseDateTimeRenderOption: DateTimeRenderOption? = nil) {
        self.valueInputOption = valueInputOption
        self.data = data
        self.includeValuesInResponse = includeValuesInResponse
        self.responseValueRenderOption = responseValueRenderOption
        self.responseDateTimeRenderOption = responseDateTimeRenderOption
    }
}