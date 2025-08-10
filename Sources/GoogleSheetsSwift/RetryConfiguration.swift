import Foundation

/// Configuration for retry behavior with exponential backoff
public struct RetryConfiguration {
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Base delay in seconds before the first retry
    public let baseDelay: TimeInterval
    
    /// Maximum delay in seconds between retries
    public let maxDelay: TimeInterval
    
    /// Multiplier for exponential backoff (delay *= backoffMultiplier after each retry)
    public let backoffMultiplier: Double
    
    /// Jitter factor to add randomness to delays (0.0 to 1.0)
    public let jitterFactor: Double
    
    /// Initialize retry configuration
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay in seconds (default: 60.0)
    ///   - backoffMultiplier: Exponential backoff multiplier (default: 2.0)
    ///   - jitterFactor: Jitter factor for randomness (default: 0.1)
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        backoffMultiplier: Double = 2.0,
        jitterFactor: Double = 0.1
    ) {
        self.maxRetries = max(0, maxRetries)
        let validatedBaseDelay = max(0.1, baseDelay)
        self.baseDelay = validatedBaseDelay
        self.maxDelay = max(validatedBaseDelay, maxDelay)
        self.backoffMultiplier = max(1.0, backoffMultiplier)
        self.jitterFactor = max(0.0, min(1.0, jitterFactor))
    }
    
    /// Default retry configuration
    public static let `default` = RetryConfiguration()
    
    /// Conservative retry configuration with longer delays
    public static let conservative = RetryConfiguration(
        maxRetries: 5,
        baseDelay: 2.0,
        maxDelay: 120.0,
        backoffMultiplier: 2.5,
        jitterFactor: 0.2
    )
    
    /// Aggressive retry configuration with shorter delays
    public static let aggressive = RetryConfiguration(
        maxRetries: 2,
        baseDelay: 0.5,
        maxDelay: 10.0,
        backoffMultiplier: 1.5,
        jitterFactor: 0.05
    )
    
    /// No retry configuration
    public static let none = RetryConfiguration(maxRetries: 0)
    
    /// Calculate the delay for a specific retry attempt
    /// - Parameter attempt: The retry attempt number (0-based)
    /// - Returns: The delay in seconds before the retry
    public func delayForAttempt(_ attempt: Int) -> TimeInterval {
        guard attempt >= 0 && attempt < maxRetries else {
            return 0
        }
        
        // Calculate exponential backoff delay
        let exponentialDelay = baseDelay * pow(backoffMultiplier, Double(attempt))
        
        // Cap at maximum delay
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitter = cappedDelay * jitterFactor * Double.random(in: -1.0...1.0)
        let finalDelay = cappedDelay + jitter
        
        return max(0.1, finalDelay) // Minimum 0.1 second delay
    }
    
    /// Get all delays for all retry attempts
    /// - Returns: Array of delays for each retry attempt
    public func getAllDelays() -> [TimeInterval] {
        return (0..<maxRetries).map { delayForAttempt($0) }
    }
}

/// Retry logic implementation
public struct RetryLogic {
    /// The retry configuration to use
    public let configuration: RetryConfiguration
    
    /// Initialize with retry configuration
    /// - Parameter configuration: The retry configuration (default: .default)
    public init(configuration: RetryConfiguration = .default) {
        self.configuration = configuration
    }
    
    /// Execute an operation with retry logic
    /// - Parameters:
    ///   - operation: The async operation to execute
    ///   - shouldRetry: Optional custom retry predicate (defaults to error.isRetryable)
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all retries fail
    public func execute<T>(
        operation: @escaping () async throws -> T,
        shouldRetry: ((Error) -> Bool)? = nil
    ) async throws -> T {
        var lastError: Error?
        
        // Initial attempt (not counted as a retry)
        do {
            return try await operation()
        } catch {
            lastError = error
            
            // Check if we should retry this error
            let shouldRetryError = shouldRetry?(error) ?? defaultShouldRetry(error)
            if !shouldRetryError || configuration.maxRetries == 0 {
                throw error
            }
        }
        
        // Retry attempts
        for attempt in 0..<configuration.maxRetries {
            let delay = configuration.delayForAttempt(attempt)
            
            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should continue retrying
                let shouldRetryError = shouldRetry?(error) ?? defaultShouldRetry(error)
                if !shouldRetryError {
                    throw error
                }
                
                // If this was the last attempt, throw the error
                if attempt == configuration.maxRetries - 1 {
                    throw error
                }
            }
        }
        
        // This should never be reached, but just in case
        throw lastError ?? GoogleSheetsError.invalidResponse("Retry logic failed unexpectedly")
    }
    
    /// Execute an operation with retry logic and custom error handling
    /// - Parameters:
    ///   - operation: The async operation to execute
    ///   - shouldRetry: Custom retry predicate
    ///   - onRetry: Optional callback called before each retry attempt
    /// - Returns: The result of the operation
    /// - Throws: The last error encountered if all retries fail
    public func execute<T>(
        operation: @escaping () async throws -> T,
        shouldRetry: @escaping (Error) -> Bool,
        onRetry: ((Int, Error, TimeInterval) -> Void)? = nil
    ) async throws -> T {
        var lastError: Error?
        
        // Initial attempt
        do {
            return try await operation()
        } catch {
            lastError = error
            
            if !shouldRetry(error) || configuration.maxRetries == 0 {
                throw error
            }
        }
        
        // Retry attempts
        for attempt in 0..<configuration.maxRetries {
            let delay = configuration.delayForAttempt(attempt)
            
            // Call retry callback if provided
            if let lastError = lastError {
                onRetry?(attempt, lastError, delay)
            }
            
            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if !shouldRetry(error) {
                    throw error
                }
                
                if attempt == configuration.maxRetries - 1 {
                    throw error
                }
            }
        }
        
        throw lastError ?? GoogleSheetsError.invalidResponse("Retry logic failed unexpectedly")
    }
    
    /// Default retry predicate based on GoogleSheetsError properties
    /// - Parameter error: The error to check
    /// - Returns: True if the error should be retried
    private func defaultShouldRetry(_ error: Error) -> Bool {
        if let gsError = error as? GoogleSheetsError {
            return gsError.isRetryable
        }
        
        // For non-GoogleSheetsError types, be conservative
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}

/// Convenience extension for HTTPClient to add retry functionality
extension HTTPClient {
    /// Execute an HTTP request with retry logic
    /// - Parameters:
    ///   - request: The HTTP request to execute
    ///   - retryConfiguration: The retry configuration to use
    /// - Returns: The decoded response
    /// - Throws: GoogleSheetsError or the last error encountered
    public func executeWithRetry<T: Codable>(
        _ request: HTTPRequest,
        retryConfiguration: RetryConfiguration = .default
    ) async throws -> T {
        let retryLogic = RetryLogic(configuration: retryConfiguration)
        
        return try await retryLogic.execute {
            try await self.execute(request)
        }
    }
    
    /// Execute an HTTP request with retry logic and custom retry predicate
    /// - Parameters:
    ///   - request: The HTTP request to execute
    ///   - retryConfiguration: The retry configuration to use
    ///   - shouldRetry: Custom retry predicate
    /// - Returns: The decoded response
    /// - Throws: GoogleSheetsError or the last error encountered
    public func executeWithRetry<T: Codable>(
        _ request: HTTPRequest,
        retryConfiguration: RetryConfiguration = .default,
        shouldRetry: @escaping (Error) -> Bool
    ) async throws -> T {
        let retryLogic = RetryLogic(configuration: retryConfiguration)
        
        return try await retryLogic.execute(
            operation: { try await self.execute(request) },
            shouldRetry: shouldRetry
        )
    }
    
    /// Execute a raw HTTP request with retry logic
    /// - Parameters:
    ///   - request: The HTTP request to execute
    ///   - retryConfiguration: The retry configuration to use
    /// - Returns: The raw response data
    /// - Throws: GoogleSheetsError or the last error encountered
    public func executeRawWithRetry(
        _ request: HTTPRequest,
        retryConfiguration: RetryConfiguration = .default
    ) async throws -> Data {
        let retryLogic = RetryLogic(configuration: retryConfiguration)
        
        return try await retryLogic.execute {
            try await self.executeRaw(request)
        }
    }
}

/// Rate limiting helper
public class RateLimiter {
    private let maxRequestsPerSecond: Double
    private let timeWindow: TimeInterval
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "com.googlesheets.ratelimiter", attributes: .concurrent)
    
    /// Initialize rate limiter
    /// - Parameters:
    ///   - maxRequestsPerSecond: Maximum requests per second
    ///   - timeWindow: Time window in seconds (default: 1.0)
    public init(maxRequestsPerSecond: Double, timeWindow: TimeInterval = 1.0) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
        self.timeWindow = timeWindow
    }
    
    /// Wait if necessary to respect rate limits
    public func waitIfNeeded() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async(flags: .barrier) {
                let now = Date()
                let cutoff = now.addingTimeInterval(-self.timeWindow)
                
                // Remove old requests outside the time window
                self.requestTimes.removeAll { $0 < cutoff }
                
                // Check if we need to wait
                if self.requestTimes.count >= Int(self.maxRequestsPerSecond * self.timeWindow) {
                    // Calculate delay needed
                    if let oldestRequest = self.requestTimes.first {
                        let delay = self.timeWindow - now.timeIntervalSince(oldestRequest)
                        if delay > 0 {
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                self.requestTimes.append(now.addingTimeInterval(delay))
                                continuation.resume()
                            }
                            return
                        }
                    }
                }
                
                // No delay needed
                self.requestTimes.append(now)
                continuation.resume()
            }
        }
    }
}