// GoogleSheetsSwift
// A Swift SDK for the Google Sheets API
//
// Copyright (c) 2024 GoogleSheetsSwift
// Licensed under the MIT License
//
// Version: 1.0.0

import Foundation

// MARK: - Public API Exports
// This file serves as the main entry point for the GoogleSheetsSwift SDK
// All public types and protocols are automatically available when importing GoogleSheetsSwift

// Note: All public APIs are automatically exported from their respective files
// when they are marked as 'public'. This file serves as documentation of the
// complete public API surface and provides SDK metadata.

// MARK: - SDK Information
public struct GoogleSheetsSwiftSDK {
    /// The current version of the SDK
    public static let version = "1.0.0"
    
    /// The minimum supported iOS version
    public static let minimumIOSVersion = "13.0"
    
    /// The minimum supported macOS version  
    public static let minimumMacOSVersion = "10.15"
    
    /// The minimum supported tvOS version
    public static let minimumTvOSVersion = "13.0"
    
    /// The minimum supported watchOS version
    public static let minimumWatchOSVersion = "6.0"
    
    /// The Google Sheets API version this SDK targets
    public static let googleSheetsAPIVersion = "v4"
    
    /// SDK build information
    public static let buildInfo = BuildInfo(
        version: version,
        apiVersion: googleSheetsAPIVersion,
        swiftVersion: "5.7+",
        platforms: [
            "iOS \(minimumIOSVersion)+",
            "macOS \(minimumMacOSVersion)+", 
            "tvOS \(minimumTvOSVersion)+",
            "watchOS \(minimumWatchOSVersion)+"
        ]
    )
}

/// Build information for the SDK
public struct BuildInfo {
    public let version: String
    public let apiVersion: String
    public let swiftVersion: String
    public let platforms: [String]
    
    public var description: String {
        return """
        GoogleSheetsSwift SDK v\(version)
        Google Sheets API: \(apiVersion)
        Swift: \(swiftVersion)
        Platforms: \(platforms.joined(separator: ", "))
        """
    }
}