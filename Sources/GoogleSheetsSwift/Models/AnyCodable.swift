import Foundation

/// A type-erased codable value that can represent any JSON-compatible type
/// This is particularly useful for Google Sheets API responses where cell values
/// can be strings, numbers, booleans, or null values
public struct AnyCodable: Codable, Equatable {
    /// The underlying value
    public let value: Any
    
    /// Initialize with any value
    /// - Parameter value: The value to wrap. Nil values are converted to NSNull
    public init<T>(_ value: T?) {
        if let value = value {
            self.value = value
        } else {
            self.value = NSNull()
        }
    }
    
    /// Initialize with a raw value
    /// - Parameter value: The raw value to wrap
    public init(_ value: Any) {
        self.value = value
    }
    
    // MARK: - Type-safe getters
    
    /// Get the value as a String
    /// - Returns: The value as a String, or nil if conversion is not possible
    public func getString() -> String? {
        if let string = value as? String {
            return string
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        if let number = value as? NSNumber {
            // Check if it's actually a boolean stored as NSNumber
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        if value is NSNull {
            return nil
        }
        return String(describing: value)
    }
    
    /// Get the value as a Double
    /// - Returns: The value as a Double, or nil if conversion is not possible
    public func getDouble() -> Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String {
            return Double(string)
        }
        return nil
    }
    
    /// Get the value as an Int
    /// - Returns: The value as an Int, or nil if conversion is not possible
    public func getInt() -> Int? {
        if let int = value as? Int {
            return int
        }
        if let double = value as? Double {
            return Int(double)
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            return Int(string)
        }
        return nil
    }
    
    /// Get the value as a Bool
    /// - Returns: The value as a Bool, or nil if conversion is not possible
    public func getBool() -> Bool? {
        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            switch string.lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }
    
    /// Check if the value is null
    /// - Returns: True if the value represents null/nil
    public var isNull: Bool {
        return value is NSNull
    }
    
    /// Get the value with a specific type
    /// - Returns: The value cast to the specified type, or nil if casting fails
    public func get<T>() -> T? {
        if value is NSNull {
            return nil
        }
        return value as? T
    }
    
    // MARK: - Codable Implementation
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [AnyCodable] {
            try container.encode(array)
        } else if let dictionary = value as? [String: AnyCodable] {
            try container.encode(dictionary)
        } else if let array = value as? [Any] {
            // Convert [Any] to [AnyCodable]
            let codableArray = array.map { AnyCodable($0) }
            try container.encode(codableArray)
        } else if let dictionary = value as? [String: Any] {
            // Convert [String: Any] to [String: AnyCodable]
            let codableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(codableDictionary)
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"
                )
            )
        }
    }
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull):
            return true
        case let (lhsBool as Bool, rhsBool as Bool):
            return lhsBool == rhsBool
        case let (lhsInt as Int, rhsInt as Int):
            return lhsInt == rhsInt
        case let (lhsDouble as Double, rhsDouble as Double):
            return lhsDouble == rhsDouble
        case let (lhsString as String, rhsString as String):
            return lhsString == rhsString
        case let (lhsArray as [AnyCodable], rhsArray as [AnyCodable]):
            return lhsArray == rhsArray
        case let (lhsDict as [String: AnyCodable], rhsDict as [String: AnyCodable]):
            return lhsDict == rhsDict
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        if value is NSNull {
            return "null"
        }
        return String(describing: value)
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "AnyCodable(\(description))"
    }
}

// MARK: - Collection Extensions

extension Array where Element == AnyCodable {
    /// Convert array of AnyCodable to array of Strings
    /// - Returns: Array of strings, with nil values for non-convertible elements
    public func toStrings() -> [String?] {
        return map { $0.getString() }
    }
    
    /// Convert array of AnyCodable to array of Doubles
    /// - Returns: Array of doubles, with nil values for non-convertible elements
    public func toDoubles() -> [Double?] {
        return map { $0.getDouble() }
    }
    
    /// Convert array of AnyCodable to array of Ints
    /// - Returns: Array of ints, with nil values for non-convertible elements
    public func toInts() -> [Int?] {
        return map { $0.getInt() }
    }
    
    /// Convert array of AnyCodable to array of Bools
    /// - Returns: Array of bools, with nil values for non-convertible elements
    public func toBools() -> [Bool?] {
        return map { $0.getBool() }
    }
}

extension Array where Element == [AnyCodable] {
    /// Convert 2D array of AnyCodable to 2D array of Strings
    /// - Returns: 2D array of strings, with nil values for non-convertible elements
    public func toStrings() -> [[String?]] {
        return map { $0.toStrings() }
    }
    
    /// Convert 2D array of AnyCodable to 2D array of Doubles
    /// - Returns: 2D array of doubles, with nil values for non-convertible elements
    public func toDoubles() -> [[Double?]] {
        return map { $0.toDoubles() }
    }
    
    /// Convert 2D array of AnyCodable to 2D array of Ints
    /// - Returns: 2D array of ints, with nil values for non-convertible elements
    public func toInts() -> [[Int?]] {
        return map { $0.toInts() }
    }
    
    /// Convert 2D array of AnyCodable to 2D array of Bools
    /// - Returns: 2D array of bools, with nil values for non-convertible elements
    public func toBools() -> [[Bool?]] {
        return map { $0.toBools() }
    }
}