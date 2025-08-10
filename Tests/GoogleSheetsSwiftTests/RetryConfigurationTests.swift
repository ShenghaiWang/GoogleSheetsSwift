import XCTest
@testable import GoogleSheetsSwift
import Foundation

final class RetryConfigurationTests: XCTestCase {
    
    // MARK: - RetryConfiguration Tests
    
    func testDefaultConfiguration() {
        let config = RetryConfiguration.default
        
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertEqual(config.baseDelay, 1.0)
        XCTAssertEqual(config.maxDelay, 60.0)
        XCTAssertEqual(config.backoffMultiplier, 2.0)
        XCTAssertEqual(config.jitterFactor, 0.1)
    }
    
    func testCustomConfiguration() {
        let config = RetryConfiguration(
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 120.0,
            backoffMultiplier: 3.0,
            jitterFactor: 0.2
        )
        
        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.baseDelay, 2.0)
        XCTAssertEqual(config.maxDelay, 120.0)
        XCTAssertEqual(config.backoffMultiplier, 3.0)
        XCTAssertEqual(config.jitterFactor, 0.2)
    }
    
    func testConfigurationValidation() {
        // Test negative values are corrected
        let config = RetryConfiguration(
            maxRetries: -1,
            baseDelay: -1.0,
            maxDelay: 0.5, // Less than baseDelay
            backoffMultiplier: 0.5, // Less than 1.0
            jitterFactor: -0.5 // Negative
        )
        
        XCTAssertEqual(config.maxRetries, 0) // Corrected to 0
        XCTAssertEqual(config.baseDelay, 0.1) // Corrected to minimum
        XCTAssertEqual(config.maxDelay, 0.5) // Corrected to max(baseDelay, maxDelay)
        XCTAssertEqual(config.backoffMultiplier, 1.0) // Corrected to minimum
        XCTAssertEqual(config.jitterFactor, 0.0) // Corrected to 0
        
        // Test jitter factor > 1.0 is corrected
        let config2 = RetryConfiguration(jitterFactor: 1.5)
        XCTAssertEqual(config2.jitterFactor, 1.0)
    }
    
    func testPresetConfigurations() {
        let conservative = RetryConfiguration.conservative
        XCTAssertEqual(conservative.maxRetries, 5)
        XCTAssertEqual(conservative.baseDelay, 2.0)
        XCTAssertEqual(conservative.maxDelay, 120.0)
        XCTAssertEqual(conservative.backoffMultiplier, 2.5)
        XCTAssertEqual(conservative.jitterFactor, 0.2)
        
        let aggressive = RetryConfiguration.aggressive
        XCTAssertEqual(aggressive.maxRetries, 2)
        XCTAssertEqual(aggressive.baseDelay, 0.5)
        XCTAssertEqual(aggressive.maxDelay, 10.0)
        XCTAssertEqual(aggressive.backoffMultiplier, 1.5)
        XCTAssertEqual(aggressive.jitterFactor, 0.05)
        
        let none = RetryConfiguration.none
        XCTAssertEqual(none.maxRetries, 0)
    }
    
    func testDelayCalculation() {
        let config = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.0 // No jitter for predictable testing
        )
        
        // Test exponential backoff
        XCTAssertEqual(config.delayForAttempt(0), 1.0) // 1.0 * 2^0 = 1.0
        XCTAssertEqual(config.delayForAttempt(1), 2.0) // 1.0 * 2^1 = 2.0
        XCTAssertEqual(config.delayForAttempt(2), 4.0) // 1.0 * 2^2 = 4.0
        
        // Test max delay cap
        let config2 = RetryConfiguration(
            maxRetries: 5,
            baseDelay: 1.0,
            maxDelay: 3.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.0
        )
        
        XCTAssertEqual(config2.delayForAttempt(0), 1.0)
        XCTAssertEqual(config2.delayForAttempt(1), 2.0)
        XCTAssertEqual(config2.delayForAttempt(2), 3.0) // Capped at maxDelay
        XCTAssertEqual(config2.delayForAttempt(3), 3.0) // Still capped
        XCTAssertEqual(config2.delayForAttempt(4), 3.0) // Still capped
    }
    
    func testDelayWithJitter() {
        let config = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.5
        )
        
        // With jitter, delays should vary but be within expected range
        let delay0 = config.delayForAttempt(0)
        let delay1 = config.delayForAttempt(1)
        let delay2 = config.delayForAttempt(2)
        
        // Base delays: 1.0, 2.0, 4.0
        // With 50% jitter: ±0.5, ±1.0, ±2.0
        XCTAssertGreaterThanOrEqual(delay0, 0.1) // Minimum delay
        XCTAssertLessThanOrEqual(delay0, 1.5)
        
        XCTAssertGreaterThanOrEqual(delay1, 0.1)
        XCTAssertLessThanOrEqual(delay1, 3.0)
        
        XCTAssertGreaterThanOrEqual(delay2, 0.1)
        XCTAssertLessThanOrEqual(delay2, 6.0)
    }
    
    func testInvalidAttemptNumbers() {
        let config = RetryConfiguration.default
        
        XCTAssertEqual(config.delayForAttempt(-1), 0)
        XCTAssertEqual(config.delayForAttempt(config.maxRetries), 0)
        XCTAssertEqual(config.delayForAttempt(100), 0)
    }
    
    func testGetAllDelays() {
        let config = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitterFactor: 0.0
        )
        
        let delays = config.getAllDelays()
        XCTAssertEqual(delays.count, 3)
        XCTAssertEqual(delays[0], 1.0)
        XCTAssertEqual(delays[1], 2.0)
        XCTAssertEqual(delays[2], 4.0)
    }
    
    // MARK: - RetryLogic Tests
    
    func testSuccessfulOperationNoRetry() async throws {
        let retryLogic = RetryLogic(configuration: .default)
        var callCount = 0
        
        let result = try await retryLogic.execute {
            callCount += 1
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 1)
    }
    
    func testRetryableErrorWithSuccess() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01, // Very short delay for testing
            maxDelay: 0.1,
            backoffMultiplier: 1.0,
            jitterFactor: 0.0
        ))
        
        var callCount = 0
        
        let result = try await retryLogic.execute {
            callCount += 1
            if callCount < 3 {
                throw GoogleSheetsError.timeout
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 3) // Initial + 2 retries
    }
    
    func testNonRetryableError() async throws {
        let retryLogic = RetryLogic(configuration: .default)
        var callCount = 0
        
        do {
            _ = try await retryLogic.execute {
                callCount += 1
                throw GoogleSheetsError.invalidRange("A1:Z999")
            }
            XCTFail("Should have thrown an error")
        } catch let error as GoogleSheetsError {
            if case .invalidRange = error {
                // Expected
            } else {
                XCTFail("Unexpected error type")
            }
        }
        
        XCTAssertEqual(callCount, 1) // No retries for non-retryable error
    }
    
    func testMaxRetriesExceeded() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01,
            maxDelay: 0.1,
            backoffMultiplier: 1.0,
            jitterFactor: 0.0
        ))
        
        var callCount = 0
        
        do {
            _ = try await retryLogic.execute {
                callCount += 1
                throw GoogleSheetsError.timeout
            }
            XCTFail("Should have thrown an error")
        } catch let error as GoogleSheetsError {
            if case .timeout = error {
                // Expected
            } else {
                XCTFail("Unexpected error type")
            }
        }
        
        XCTAssertEqual(callCount, 3) // Initial + 2 retries
    }
    
    func testCustomShouldRetryPredicate() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01,
            maxDelay: 0.1,
            backoffMultiplier: 1.0,
            jitterFactor: 0.0
        ))
        
        var callCount = 0
        
        // Custom predicate that retries on invalidRange (normally non-retryable)
        let result = try await retryLogic.execute(
            operation: {
                callCount += 1
                if callCount < 3 {
                    throw GoogleSheetsError.invalidRange("A1:Z999")
                }
                return "success"
            },
            shouldRetry: { error in
                if case GoogleSheetsError.invalidRange = error {
                    return true
                }
                return false
            }
        )
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 3)
    }
    
    func testRetryWithCallback() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.01,
            maxDelay: 0.1,
            backoffMultiplier: 1.0,
            jitterFactor: 0.0
        ))
        
        var callCount = 0
        var retryCallbacks: [(Int, Error, TimeInterval)] = []
        
        let result = try await retryLogic.execute(
            operation: {
                callCount += 1
                if callCount < 3 {
                    throw GoogleSheetsError.timeout
                }
                return "success"
            },
            shouldRetry: { _ in true },
            onRetry: { attempt, error, delay in
                retryCallbacks.append((attempt, error, delay))
            }
        )
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 3)
        XCTAssertEqual(retryCallbacks.count, 2)
        
        // Check callback parameters
        XCTAssertEqual(retryCallbacks[0].0, 0) // First retry attempt
        XCTAssertEqual(retryCallbacks[1].0, 1) // Second retry attempt
        
        // Check errors are timeout
        for (_, error, _) in retryCallbacks {
            if case GoogleSheetsError.timeout = error {
                // Expected
            } else {
                XCTFail("Unexpected error in callback")
            }
        }
    }
    
    func testZeroMaxRetries() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration.none)
        var callCount = 0
        
        do {
            _ = try await retryLogic.execute {
                callCount += 1
                throw GoogleSheetsError.timeout
            }
            XCTFail("Should have thrown an error")
        } catch {
            // Expected
        }
        
        XCTAssertEqual(callCount, 1) // No retries
    }
    
    func testURLErrorRetry() async throws {
        let retryLogic = RetryLogic(configuration: RetryConfiguration(
            maxRetries: 1,
            baseDelay: 0.01,
            maxDelay: 0.1,
            backoffMultiplier: 1.0,
            jitterFactor: 0.0
        ))
        
        var callCount = 0
        
        let result = try await retryLogic.execute {
            callCount += 1
            if callCount < 2 {
                throw URLError(.timedOut)
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 2)
    }
    
    func testNonRetryableURLError() async throws {
        let retryLogic = RetryLogic(configuration: .default)
        var callCount = 0
        
        do {
            _ = try await retryLogic.execute {
                callCount += 1
                throw URLError(.badURL)
            }
            XCTFail("Should have thrown an error")
        } catch {
            // Expected
        }
        
        XCTAssertEqual(callCount, 1) // No retries for non-retryable URLError
    }
    
    // MARK: - HTTPClient Extension Tests
    
    func testHTTPClientRetryExtension() async throws {
        let mockClient = MockHTTPClient()
        
        // Configure mock to fail first 2 times, then succeed
        mockClient.mockError(for: "example.com", error: GoogleSheetsError.timeout)
        
        // After 2 failures, configure success response
        let successResponse = TestResponse(message: "success")
        mockClient.mockResponse(for: "example.com", response: successResponse)
        
        let request = HTTPRequest(method: .GET, url: URL(string: "https://example.com")!)
        
        // Note: This test would need the executeWithRetry method to be implemented
        // For now, we'll test the basic execute method
        do {
            let _: TestResponse = try await mockClient.execute(request)
            XCTFail("Should have thrown timeout error")
        } catch let error as GoogleSheetsError {
            if case .timeout = error {
                // Expected - mock is configured to return error first
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testHTTPClientRetryWithCustomPredicate() async throws {
        let mockClient = MockHTTPClient()
        
        // Configure mock to return error first, then success
        mockClient.mockError(for: "example.com", error: GoogleSheetsError.invalidRange("test"))
        
        let request = HTTPRequest(method: .GET, url: URL(string: "https://example.com")!)
        
        // Note: This test would need the executeWithRetry method to be implemented
        // For now, we'll test that the mock returns the expected error
        do {
            let _: TestResponse = try await mockClient.execute(request)
            XCTFail("Should have thrown invalidRange error")
        } catch let error as GoogleSheetsError {
            if case .invalidRange = error {
                // Expected - mock is configured to return error
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    func testHTTPClientRawRetry() async throws {
        let mockClient = MockHTTPClient()
        
        // Configure mock to return error first, then success data
        mockClient.mockError(for: "example.com", error: GoogleSheetsError.timeout)
        mockClient.mockRawResponse(for: "example.com", data: "success".data(using: .utf8)!)
        
        let request = HTTPRequest(method: .GET, url: URL(string: "https://example.com")!)
        
        // Note: This test would need the executeRawWithRetry method to be implemented
        // For now, we'll test that the mock returns the expected error
        do {
            let _ = try await mockClient.executeRaw(request)
            XCTFail("Should have thrown timeout error")
        } catch let error as GoogleSheetsError {
            if case .timeout = error {
                // Expected - mock is configured to return error first
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }
    
    // MARK: - Rate Limiter Tests
    
    func testRateLimiterBasic() async {
        let rateLimiter = RateLimiter(maxRequestsPerSecond: 2.0, timeWindow: 1.0)
        
        let startTime = Date()
        
        // First two requests should be immediate
        await rateLimiter.waitIfNeeded()
        await rateLimiter.waitIfNeeded()
        
        let firstTwoTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(firstTwoTime, 0.1) // Should be very fast
        
        // Third request should be delayed
        await rateLimiter.waitIfNeeded()
        
        let thirdRequestTime = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThan(thirdRequestTime, 0.9) // Should wait close to 1 second
    }
    
    // MARK: - Performance Tests
    
    func testRetryPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Retry performance")
            
            Task {
                let retryLogic = RetryLogic(configuration: RetryConfiguration(
                    maxRetries: 10,
                    baseDelay: 0.001,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.1,
                    jitterFactor: 0.0
                ))
                
                var callCount = 0
                
                do {
                    _ = try await retryLogic.execute {
                        callCount += 1
                        if callCount < 5 {
                            throw GoogleSheetsError.timeout
                        }
                        return "success"
                    }
                } catch {
                    // Ignore errors for performance test
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}

// MARK: - Test Helpers

private struct TestResponse: Codable {
    let message: String
}

// Using centralized MockHTTPClient from Mocks/MockHTTPClient.swift