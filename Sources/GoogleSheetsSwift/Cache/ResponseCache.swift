import Foundation

/// Protocol for response caching
public protocol ResponseCache {
    /// Store a response in the cache
    func store<T: Codable>(_ response: T, for key: String, ttl: TimeInterval) async
    
    /// Retrieve a response from the cache
    func retrieve<T: Codable>(_ type: T.Type, for key: String) async -> T?
    
    /// Remove a response from the cache
    func remove(for key: String) async
    
    /// Clear all cached responses
    func clear() async
    
    /// Check if a key exists in the cache and is not expired
    func contains(key: String) async -> Bool
}

/// Cache entry with expiration
private struct CacheEntry<T: Codable>: Codable {
    let value: T
    let expirationDate: Date
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
}

/// In-memory response cache implementation
public class InMemoryResponseCache: ResponseCache {
    private actor CacheStorage {
        private var storage: [String: Data] = [:]
        
        func store(data: Data, for key: String) {
            storage[key] = data
        }
        
        func retrieve(for key: String) -> Data? {
            return storage[key]
        }
        
        func remove(for key: String) {
            storage.removeValue(forKey: key)
        }
        
        func clear() {
            storage.removeAll()
        }
        
        func contains(key: String) -> Bool {
            return storage[key] != nil
        }
        
        func getAllKeys() -> [String] {
            return Array(storage.keys)
        }
    }
    
    private let storage = CacheStorage()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {}
    
    public func store<T: Codable>(_ response: T, for key: String, ttl: TimeInterval) async {
        let expirationDate = Date().addingTimeInterval(ttl)
        let entry = CacheEntry(value: response, expirationDate: expirationDate)
        
        do {
            let data = try encoder.encode(entry)
            await storage.store(data: data, for: key)
        } catch {
            // Silently fail - caching is optional
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, for key: String) async -> T? {
        guard let data = await storage.retrieve(for: key) else {
            return nil
        }
        
        do {
            let entry = try decoder.decode(CacheEntry<T>.self, from: data)
            
            if entry.isExpired {
                await storage.remove(for: key)
                return nil
            }
            
            return entry.value
        } catch {
            // Remove corrupted entry
            await storage.remove(for: key)
            return nil
        }
    }
    
    public func remove(for key: String) async {
        await storage.remove(for: key)
    }
    
    public func clear() async {
        await storage.clear()
    }
    
    public func contains(key: String) async -> Bool {
        guard await storage.contains(key: key) else {
            return false
        }
        
        // Check if the entry is expired
        guard let data = await storage.retrieve(for: key) else {
            return false
        }
        
        do {
            let entry = try decoder.decode(CacheEntry<AnyCodable>.self, from: data)
            if entry.isExpired {
                await storage.remove(for: key)
                return false
            }
            return true
        } catch {
            await storage.remove(for: key)
            return false
        }
    }
}

/// Cache configuration
public struct CacheConfiguration {
    /// Default TTL for cached responses (in seconds)
    public let defaultTTL: TimeInterval
    
    /// TTL for spreadsheet metadata (in seconds)
    public let spreadsheetTTL: TimeInterval
    
    /// TTL for value ranges (in seconds)
    public let valuesTTL: TimeInterval
    
    /// Whether caching is enabled
    public let enabled: Bool
    
    public static let `default` = CacheConfiguration(
        defaultTTL: 300, // 5 minutes
        spreadsheetTTL: 600, // 10 minutes
        valuesTTL: 60, // 1 minute
        enabled: true
    )
    
    public static let disabled = CacheConfiguration(
        defaultTTL: 0,
        spreadsheetTTL: 0,
        valuesTTL: 0,
        enabled: false
    )
    
    public init(defaultTTL: TimeInterval, spreadsheetTTL: TimeInterval, valuesTTL: TimeInterval, enabled: Bool) {
        self.defaultTTL = defaultTTL
        self.spreadsheetTTL = spreadsheetTTL
        self.valuesTTL = valuesTTL
        self.enabled = enabled
    }
}

/// Cache key generator for consistent cache keys
public struct CacheKeyGenerator {
    /// Generate cache key for spreadsheet get operation
    public static func spreadsheetKey(
        spreadsheetId: String,
        ranges: [String]? = nil,
        includeGridData: Bool = false,
        fields: String? = nil
    ) -> String {
        var components = ["spreadsheet", spreadsheetId]
        
        if let ranges = ranges, !ranges.isEmpty {
            components.append("ranges:\(ranges.sorted().joined(separator: ","))")
        }
        
        if includeGridData {
            components.append("includeGridData:true")
        }
        
        if let fields = fields {
            components.append("fields:\(fields)")
        }
        
        return components.joined(separator: "|")
    }
    
    /// Generate cache key for values get operation
    public static func valuesKey(
        spreadsheetId: String,
        range: String,
        options: ValueGetOptions? = nil
    ) -> String {
        var components = ["values", spreadsheetId, range]
        
        if let options = options {
            if let majorDimension = options.majorDimension {
                components.append("majorDimension:\(majorDimension.rawValue)")
            }
            
            if let valueRenderOption = options.valueRenderOption {
                components.append("valueRenderOption:\(valueRenderOption.rawValue)")
            }
            
            if let dateTimeRenderOption = options.dateTimeRenderOption {
                components.append("dateTimeRenderOption:\(dateTimeRenderOption.rawValue)")
            }
        }
        
        return components.joined(separator: "|")
    }
    
    /// Generate cache key for batch get values operation
    public static func batchValuesKey(
        spreadsheetId: String,
        ranges: [String],
        options: ValueGetOptions? = nil
    ) -> String {
        var components = ["batchValues", spreadsheetId]
        components.append("ranges:\(ranges.sorted().joined(separator: ","))")
        
        if let options = options {
            if let majorDimension = options.majorDimension {
                components.append("majorDimension:\(majorDimension.rawValue)")
            }
            
            if let valueRenderOption = options.valueRenderOption {
                components.append("valueRenderOption:\(valueRenderOption.rawValue)")
            }
            
            if let dateTimeRenderOption = options.dateTimeRenderOption {
                components.append("dateTimeRenderOption:\(dateTimeRenderOption.rawValue)")
            }
        }
        
        return components.joined(separator: "|")
    }
}

/// Cache invalidation helper
public struct CacheInvalidator {
    private let cache: ResponseCache
    
    public init(cache: ResponseCache) {
        self.cache = cache
    }
    
    /// Invalidate cache entries for a specific spreadsheet
    public func invalidateSpreadsheet(_ spreadsheetId: String) async {
        // For simplicity, we'll clear all cache entries
        // In a more sophisticated implementation, we could track keys by spreadsheet ID
        await cache.clear()
    }
    
    /// Invalidate cache entries for specific ranges in a spreadsheet
    public func invalidateRanges(_ spreadsheetId: String, ranges: [String]) async {
        // Remove specific range cache entries
        for range in ranges {
            let key = CacheKeyGenerator.valuesKey(spreadsheetId: spreadsheetId, range: range)
            await cache.remove(for: key)
        }
        
        // Also invalidate batch operations that might include these ranges
        await cache.clear()
    }
}