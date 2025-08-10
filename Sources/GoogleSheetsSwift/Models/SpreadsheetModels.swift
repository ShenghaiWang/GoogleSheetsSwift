import Foundation

// MARK: - Spreadsheet Model

/// Resource that represents a spreadsheet
public struct Spreadsheet: Codable, Equatable {
    /// The ID of the spreadsheet (read-only)
    public let spreadsheetId: String?
    
    /// Overall properties of the spreadsheet
    public let properties: SpreadsheetProperties?
    
    /// The sheets that are part of the spreadsheet
    public let sheets: [Sheet]?
    
    /// The named ranges defined in the spreadsheet
    public let namedRanges: [NamedRange]?
    
    /// The URL of the spreadsheet (read-only)
    public let spreadsheetUrl: String?
    
    /// The developer metadata associated with the spreadsheet
    public let developerMetadata: [DeveloperMetadata]?
    
    /// A list of external data sources connected with the spreadsheet
    public let dataSources: [DataSource]?
    
    /// A list of data source refresh schedules (read-only)
    public let dataSourceSchedules: [DataSourceRefreshSchedule]?
    
    public init(spreadsheetId: String? = nil, properties: SpreadsheetProperties? = nil,
                sheets: [Sheet]? = nil, namedRanges: [NamedRange]? = nil,
                spreadsheetUrl: String? = nil, developerMetadata: [DeveloperMetadata]? = nil,
                dataSources: [DataSource]? = nil, dataSourceSchedules: [DataSourceRefreshSchedule]? = nil) {
        self.spreadsheetId = spreadsheetId
        self.properties = properties
        self.sheets = sheets
        self.namedRanges = namedRanges
        self.spreadsheetUrl = spreadsheetUrl
        self.developerMetadata = developerMetadata
        self.dataSources = dataSources
        self.dataSourceSchedules = dataSourceSchedules
    }
}

// MARK: - SpreadsheetProperties Model

/// Properties of a spreadsheet
public struct SpreadsheetProperties: Codable, Equatable {
    /// The title of the spreadsheet
    public let title: String?
    
    /// The locale of the spreadsheet
    public let locale: String?
    
    /// The amount of time to wait before volatile functions are recalculated
    public let autoRecalc: RecalculationInterval?
    
    /// The time zone of the spreadsheet, in CLDR format
    public let timeZone: String?
    
    /// The default format of all cells in the spreadsheet (read-only)
    public let defaultFormat: CellFormat? 
   
    /// Iterative calculation settings
    public let iterativeCalculationSettings: IterativeCalculationSettings?
    
    /// Theme applied to the spreadsheet
    public let spreadsheetTheme: SpreadsheetTheme?
    
    /// Whether to allow external URL access for image and import functions
    public let importFunctionsExternalUrlAccessAllowed: Bool?
    
    public init(title: String? = nil, locale: String? = nil, autoRecalc: RecalculationInterval? = nil,
                timeZone: String? = nil, defaultFormat: CellFormat? = nil,
                iterativeCalculationSettings: IterativeCalculationSettings? = nil,
                spreadsheetTheme: SpreadsheetTheme? = nil,
                importFunctionsExternalUrlAccessAllowed: Bool? = nil) {
        self.title = title
        self.locale = locale
        self.autoRecalc = autoRecalc
        self.timeZone = timeZone
        self.defaultFormat = defaultFormat
        self.iterativeCalculationSettings = iterativeCalculationSettings
        self.spreadsheetTheme = spreadsheetTheme
        self.importFunctionsExternalUrlAccessAllowed = importFunctionsExternalUrlAccessAllowed
    }
}

// MARK: - Sheet Model

/// A sheet in a spreadsheet
public struct Sheet: Codable, Equatable {
    /// The properties of the sheet
    public let properties: SheetProperties?
    
    /// Data in the grid, if this is a grid sheet
    public let data: [GridData]?
    
    /// The ranges that are merged together
    public let merges: [GridRange]?
    
    /// The conditional format rules in this sheet
    public let conditionalFormats: [ConditionalFormatRule]?
    
    /// The filter views in this sheet
    public let filterViews: [FilterView]?
    
    /// The protected ranges in this sheet
    public let protectedRanges: [ProtectedRange]?
    
    /// The filter on this sheet, if any
    public let basicFilter: BasicFilter?
    
    /// The specifications of every chart on this sheet
    public let charts: [EmbeddedChart]?
    
    /// The banded (alternating colors) ranges on this sheet
    public let bandedRanges: [BandedRange]?
    
    /// The developer metadata associated with the sheet
    public let developerMetadata: [DeveloperMetadata]?
    
    /// All row groups on this sheet
    public let rowGroups: [DimensionGroup]?
    
    /// All column groups on this sheet
    public let columnGroups: [DimensionGroup]?
    
    /// The slicers on this sheet
    public let slicers: [Slicer]?
    
    /// The tables on this sheet
    public let tables: [Table]?
    
    public init(properties: SheetProperties? = nil, data: [GridData]? = nil,
                merges: [GridRange]? = nil, conditionalFormats: [ConditionalFormatRule]? = nil,
                filterViews: [FilterView]? = nil, protectedRanges: [ProtectedRange]? = nil,
                basicFilter: BasicFilter? = nil, charts: [EmbeddedChart]? = nil,
                bandedRanges: [BandedRange]? = nil, developerMetadata: [DeveloperMetadata]? = nil,
                rowGroups: [DimensionGroup]? = nil, columnGroups: [DimensionGroup]? = nil,
                slicers: [Slicer]? = nil, tables: [Table]? = nil) {
        self.properties = properties
        self.data = data
        self.merges = merges
        self.conditionalFormats = conditionalFormats
        self.filterViews = filterViews
        self.protectedRanges = protectedRanges
        self.basicFilter = basicFilter
        self.charts = charts
        self.bandedRanges = bandedRanges
        self.developerMetadata = developerMetadata
        self.rowGroups = rowGroups
        self.columnGroups = columnGroups
        self.slicers = slicers
        self.tables = tables
    }
}

// MARK: - SheetProperties Model

/// Properties of a sheet
public struct SheetProperties: Codable, Equatable {
    /// The ID of the sheet (must be non-negative, cannot be changed once set)
    public let sheetId: Int?
    
    /// The name of the sheet
    public let title: String?
    
    /// The index of the sheet within the spreadsheet
    public let index: Int?
    
    /// The type of sheet
    public let sheetType: SheetType?
    
    /// Additional properties if this is a grid sheet
    public let gridProperties: GridProperties?
    
    /// True if the sheet is hidden in the UI, false if it's visible
    public let hidden: Bool?
    
    /// The color of the tab in the UI
    public let tabColor: Color?
    
    /// The color of the tab in the UI (takes precedence over tabColor)
    public let tabColorStyle: ColorStyle?
    
    /// True if the sheet is an RTL sheet instead of an LTR sheet
    public let rightToLeft: Bool?
    
    /// Additional properties if this is a data source sheet
    public let dataSourceSheetProperties: DataSourceSheetProperties?
    
    public init(sheetId: Int? = nil, title: String? = nil, index: Int? = nil,
                sheetType: SheetType? = nil, gridProperties: GridProperties? = nil,
                hidden: Bool? = nil, tabColor: Color? = nil, tabColorStyle: ColorStyle? = nil,
                rightToLeft: Bool? = nil, dataSourceSheetProperties: DataSourceSheetProperties? = nil) {
        self.sheetId = sheetId
        self.title = title
        self.index = index
        self.sheetType = sheetType
        self.gridProperties = gridProperties
        self.hidden = hidden
        self.tabColor = tabColor
        self.tabColorStyle = tabColorStyle
        self.rightToLeft = rightToLeft
        self.dataSourceSheetProperties = dataSourceSheetProperties
    }
}

// MARK: - Supporting Enums and Types

/// The type of sheet
public enum SheetType: String, Codable, CaseIterable {
    /// Default value, do not use
    case sheetTypeUnspecified = "SHEET_TYPE_UNSPECIFIED"
    /// The sheet is a grid
    case grid = "GRID"
    /// The sheet has no grid and instead has an object like a chart or image
    case object = "OBJECT"
    /// The sheet connects with an external DataSource and shows the preview of data
    case dataSource = "DATA_SOURCE"
}

extension SheetType {
    /// Returns a user-friendly description of the sheet type
    public var description: String {
        switch self {
        case .sheetTypeUnspecified:
            return "Unspecified sheet type"
        case .grid:
            return "Grid sheet"
        case .object:
            return "Object sheet"
        case .dataSource:
            return "Data source sheet"
        }
    }
}

// MARK: - Placeholder Types
// These are complex nested types that would be implemented in future tasks
// For now, we provide basic structures to satisfy the Codable requirements

/// Placeholder for CellFormat
public struct CellFormat: Codable, Equatable {
    // This would be implemented with full cell formatting properties
    public init() {}
}

/// Placeholder for IterativeCalculationSettings
public struct IterativeCalculationSettings: Codable, Equatable {
    public init() {}
}

/// Placeholder for SpreadsheetTheme
public struct SpreadsheetTheme: Codable, Equatable {
    public init() {}
}

/// Placeholder for NamedRange
public struct NamedRange: Codable, Equatable {
    public init() {}
}

/// Placeholder for DeveloperMetadata
public struct DeveloperMetadata: Codable, Equatable {
    public init() {}
}

/// Placeholder for DataSource
public struct DataSource: Codable, Equatable {
    public init() {}
}

/// Placeholder for DataSourceRefreshSchedule
public struct DataSourceRefreshSchedule: Codable, Equatable {
    public init() {}
}

/// Placeholder for GridData
public struct GridData: Codable, Equatable {
    public init() {}
}

/// Placeholder for GridRange
public struct GridRange: Codable, Equatable {
    public init() {}
}

/// Placeholder for ConditionalFormatRule
public struct ConditionalFormatRule: Codable, Equatable {
    public init() {}
}

/// Placeholder for FilterView
public struct FilterView: Codable, Equatable {
    public init() {}
}

/// Placeholder for ProtectedRange
public struct ProtectedRange: Codable, Equatable {
    public init() {}
}

/// Placeholder for BasicFilter
public struct BasicFilter: Codable, Equatable {
    public init() {}
}

/// Placeholder for EmbeddedChart
public struct EmbeddedChart: Codable, Equatable {
    public init() {}
}

/// Placeholder for BandedRange
public struct BandedRange: Codable, Equatable {
    public init() {}
}

/// Placeholder for DimensionGroup
public struct DimensionGroup: Codable, Equatable {
    public init() {}
}

/// Placeholder for Slicer
public struct Slicer: Codable, Equatable {
    public init() {}
}

/// Placeholder for Table
public struct Table: Codable, Equatable {
    public init() {}
}

/// Placeholder for GridProperties
public struct GridProperties: Codable, Equatable {
    public init() {}
}

/// Placeholder for Color
public struct Color: Codable, Equatable {
    public init() {}
}

/// Placeholder for ColorStyle
public struct ColorStyle: Codable, Equatable {
    public init() {}
}

/// Placeholder for DataSourceSheetProperties
public struct DataSourceSheetProperties: Codable, Equatable {
    public init() {}
}

// MARK: - Request Models

/// Request for creating a spreadsheet
public struct SpreadsheetCreateRequest: Codable, Equatable {
    /// The spreadsheet to create
    public let properties: SpreadsheetProperties?
    
    /// The sheets to create in the spreadsheet
    public let sheets: [Sheet]?
    
    /// The named ranges to create in the spreadsheet
    public let namedRanges: [NamedRange]?
    
    public init(properties: SpreadsheetProperties? = nil, sheets: [Sheet]? = nil, namedRanges: [NamedRange]? = nil) {
        self.properties = properties
        self.sheets = sheets
        self.namedRanges = namedRanges
    }
}

/// Request for batch update operations
public struct BatchUpdateRequest: Codable, Equatable {
    // This would contain various request types for batch operations
    // For now, we provide a basic structure
    public init() {}
}

/// Response for batch update operations
public struct BatchUpdateSpreadsheetResponse: Codable, Equatable {
    /// The spreadsheet the updates were applied to
    public let spreadsheetId: String?
    
    /// The reply of the updates
    public let replies: [Response]?
    
    /// The updated spreadsheet
    public let updatedSpreadsheet: Spreadsheet?
    
    public init(spreadsheetId: String? = nil, replies: [Response]? = nil, updatedSpreadsheet: Spreadsheet? = nil) {
        self.spreadsheetId = spreadsheetId
        self.replies = replies
        self.updatedSpreadsheet = updatedSpreadsheet
    }
}

/// Placeholder for Response
public struct Response: Codable, Equatable {
    public init() {}
}