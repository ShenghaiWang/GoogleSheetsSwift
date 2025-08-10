import Foundation

// MARK: - Core Enums for Google Sheets API

/// Indicates which dimension an operation should apply to
public enum MajorDimension: String, Codable, CaseIterable {
    /// The default value, do not use
    case dimensionUnspecified = "DIMENSION_UNSPECIFIED"
    /// Operates on the rows of a sheet
    case rows = "ROWS"
    /// Operates on the columns of a sheet
    case columns = "COLUMNS"
}

/// How values should be represented in the output
public enum ValueRenderOption: String, Codable, CaseIterable {
    /// Values will be calculated & formatted in the reply according to the cell's formatting
    case formattedValue = "FORMATTED_VALUE"
    /// Values will be calculated, but not formatted in the reply
    case unformattedValue = "UNFORMATTED_VALUE"
    /// Values will not be calculated. The reply will include the formulas
    case formula = "FORMULA"
}

/// How the input data should be interpreted
public enum ValueInputOption: String, Codable, CaseIterable {
    /// Default input value option is not specified
    case inputValueOptionUnspecified = "INPUT_VALUE_OPTION_UNSPECIFIED"
    /// The values the user has entered will not be parsed and will be stored as-is
    case raw = "RAW"
    /// The values will be parsed as if the user typed them into the UI
    case userEntered = "USER_ENTERED"
}

/// How dates, times, and durations should be represented in the output
public enum DateTimeRenderOption: String, Codable, CaseIterable {
    /// Instructs date, time, datetime, and duration fields to be output as doubles in "serial number" format
    case serialNumber = "SERIAL_NUMBER"
    /// Instructs date, time, datetime, and duration fields to be output as strings in their given number format
    case formattedString = "FORMATTED_STRING"
}

/// Determines how often the spreadsheet recalculates
public enum RecalculationInterval: String, Codable, CaseIterable {
    /// Default value. This value must not be used
    case recalculationIntervalUnspecified = "RECALCULATION_INTERVAL_UNSPECIFIED"
    /// Volatile functions are updated on every change
    case onChange = "ON_CHANGE"
    /// Volatile functions are updated on every change and every minute
    case onChangeAndMinute = "ON_CHANGE_AND_MINUTE"
}

// MARK: - Extensions for better usability

extension MajorDimension {
    /// Returns a user-friendly description of the dimension
    public var description: String {
        switch self {
        case .dimensionUnspecified:
            return "Unspecified dimension"
        case .rows:
            return "Rows"
        case .columns:
            return "Columns"
        }
    }
}

extension ValueRenderOption {
    /// Returns a user-friendly description of the render option
    public var description: String {
        switch self {
        case .formattedValue:
            return "Formatted value"
        case .unformattedValue:
            return "Unformatted value"
        case .formula:
            return "Formula"
        }
    }
}

extension ValueInputOption {
    /// Returns a user-friendly description of the input option
    public var description: String {
        switch self {
        case .inputValueOptionUnspecified:
            return "Unspecified input option"
        case .raw:
            return "Raw value"
        case .userEntered:
            return "User entered value"
        }
    }
}

extension DateTimeRenderOption {
    /// Returns a user-friendly description of the date time render option
    public var description: String {
        switch self {
        case .serialNumber:
            return "Serial number format"
        case .formattedString:
            return "Formatted string"
        }
    }
}

extension RecalculationInterval {
    /// Returns a user-friendly description of the recalculation interval
    public var description: String {
        switch self {
        case .recalculationIntervalUnspecified:
            return "Unspecified recalculation interval"
        case .onChange:
            return "Recalculate on change"
        case .onChangeAndMinute:
            return "Recalculate on change and every minute"
        }
    }
}