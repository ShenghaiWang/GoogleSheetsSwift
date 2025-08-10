# Implementation Plan

- [x] 1. Set up project structure and core interfaces
  - Create Swift Package Manager structure with proper platform support
  - Define core protocol interfaces for HTTPClient, OAuth2TokenManager, and service layers
  - Set up basic project configuration and module organization
  - _Requirements: 7.1, 7.2_

- [x] 2. Implement foundational data models
- [x] 2.1 Create core enum types and options
  - Implement MajorDimension, ValueRenderOption, ValueInputOption enums
  - Create DateTimeRenderOption and RecalculationInterval enums
  - Write unit tests for enum cases and string representations
  - _Requirements: 5.2_

- [x] 2.2 Implement AnyCodable type for flexible value handling
  - Create AnyCodable struct with Codable conformance
  - Implement type-safe getter methods for common types (String, Double, Bool)
  - Write comprehensive unit tests for encoding/decoding various value types
  - _Requirements: 5.2, 5.4_

- [x] 2.3 Create ValueRange and related request/response models
  - Implement ValueRange struct with proper Codable conformance
  - Create convenience initializers and value extraction methods
  - Implement UpdateValuesResponse, AppendValuesResponse, ClearValuesResponse models
  - Write unit tests for model serialization and deserialization
  - _Requirements: 3.1, 4.1, 5.2_

- [x] 2.4 Implement Spreadsheet and SpreadsheetProperties models
  - Create Spreadsheet struct with all properties from API specification
  - Implement SpreadsheetProperties, Sheet, and related nested models
  - Add proper Codable conformance and optional property handling
  - Write unit tests for complex nested model structures
  - _Requirements: 2.1, 2.2, 5.2_

- [x] 3. Create error handling system
- [x] 3.1 Implement GoogleSheetsError enum
  - Define all error cases including authentication, network, and API errors
  - Implement LocalizedError conformance with descriptive error messages
  - Add error context and recovery suggestions where appropriate
  - Write unit tests for error descriptions and error handling scenarios
  - _Requirements: 6.1, 6.2, 5.3_

- [x] 3.2 Create retry configuration and logic
  - Implement RetryConfiguration struct with exponential backoff parameters
  - Create retry logic that handles rate limiting and temporary failures
  - Add proper error classification for retryable vs non-retryable errors
  - Write unit tests for retry behavior and backoff calculations
  - _Requirements: 6.2, 6.3_

- [x] 4. Implement HTTP transport layer
- [x] 4.1 Create HTTPClient protocol and implementation
  - Define HTTPClient protocol with async execute method
  - Implement URLSession-based HTTPClient with proper error handling
  - Add request/response logging capabilities
  - Write unit tests using mock URLSession for network layer testing
  - _Requirements: 5.1, 6.4_

- [x] 4.2 Implement request building utilities
  - Create HTTPRequest struct with method, URL, headers, and body
  - Implement RequestBuilder for constructing Google Sheets API requests
  - Add proper URL encoding and parameter handling
  - Write unit tests for request construction and parameter encoding
  - _Requirements: 5.1_

- [x] 4.3 Add retry logic to HTTP client
  - Integrate retry configuration with HTTP client implementation
  - Handle rate limiting (429) responses with proper retry-after headers
  - Implement exponential backoff for server errors (5xx)
  - Write unit tests for retry scenarios and rate limit handling
  - _Requirements: 6.2, 6.3_

- [x] 5. Implement OAuth2 authentication
- [x] 5.1 Create OAuth2TokenManager protocol and implementation
  - Define OAuth2TokenManager protocol with token management methods
  - Implement GoogleOAuth2TokenManager with token storage and refresh logic
  - Add secure token storage using Keychain on iOS/macOS
  - Write unit tests for token management and refresh scenarios
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 5.2 Implement OAuth2 authentication flow
  - Create authentication flow with proper scope handling
  - Implement authorization code exchange for access tokens
  - Add automatic token refresh when tokens expire
  - Write unit tests for authentication flow and token refresh
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 5.3 Implement service account authentication
  - Create ServiceAccountKey model for JSON key file structure
  - Implement ServiceAccountTokenManager class with JWT token generation
  - Add RSA private key parsing and JWT signing functionality
  - Write unit tests for service account key parsing and JWT generation
  - _Requirements: 1.1.1, 1.1.2, 1.1.3_

- [x] 5.4 Add service account token management and refresh
  - Implement automatic JWT token generation when tokens expire
  - Add proper token caching with expiration handling
  - Create domain-wide delegation support for user impersonation
  - Write unit tests for token refresh and impersonation scenarios
  - _Requirements: 1.1.3, 1.1.4_

- [x] 5.5 Create service account convenience methods
  - Add loadFromFile method for loading service account keys from JSON files
  - Implement loadFromEnvironment for GOOGLE_APPLICATION_CREDENTIALS support
  - Add proper error handling for invalid service account credentials
  - Write unit tests for file loading and environment variable handling
  - _Requirements: 1.1.1, 1.1.5_

- [ ] 6. Create service layer implementations
- [x] 6.1 Implement SpreadsheetsService
  - Create SpreadsheetsService class with create, get, and batchUpdate methods
  - Implement proper parameter handling for ranges, includeGridData, field masks
  - Add request validation and error handling
  - Write unit tests using mock HTTP client for service methods
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 4.5_

- [x] 6.2 Implement ValuesService for reading operations
  - Create ValuesService class with get and batchGet methods
  - Implement ValueGetOptions for render options and major dimension
  - Add A1 notation validation and range parsing
  - Write unit tests for value reading operations with various options
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6.3 Implement ValuesService for writing operations
  - Add update, append, and clear methods to ValuesService
  - Implement ValueUpdateOptions and ValueAppendOptions
  - Add proper value input option handling (RAW vs USER_ENTERED)
  - Write unit tests for value writing operations with different input options
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 7. Create main client interface
- [x] 7.1 Implement GoogleSheetsClient
  - Create main GoogleSheetsClient class with service properties
  - Implement dependency injection for token manager and HTTP client
  - Add API key support for public read-only operations
  - Write unit tests for client initialization and service access
  - _Requirements: 5.1, 5.2_

- [x] 7.2 Add convenience methods and utilities
  - Create convenience methods for common operations (read/write ranges)
  - Add utility methods for A1 notation parsing and validation
  - Implement helper methods for batch operations
  - Write unit tests for convenience methods and utilities
  - _Requirements: 5.4_

- [x] 8. Implement comprehensive testing
- [x] 8.1 Create mock implementations for testing
  - Implement MockHTTPClient for unit testing service layers
  - Create MockOAuth2TokenManager for authentication testing
  - Add test data fixtures for common API responses
  - Write helper methods for setting up test scenarios
  - _Requirements: 5.3, 6.1_

- [x] 8.2 Add integration test framework
  - Create integration test suite that can run against real Google Sheets API
  - Implement test spreadsheet setup and cleanup
  - Add environment configuration for test credentials
  - Write integration tests for core functionality (create, read, write, update)
  - _Requirements: 2.1, 2.2, 3.1, 4.1_

- [x] 9. Add advanced features and optimizations
- [x] 9.1 Implement logging and debugging support
  - Create GoogleSheetsLogger protocol for pluggable logging
  - Add request/response logging with configurable log levels
  - Implement debug mode with detailed API interaction logging
  - Write unit tests for logging functionality
  - _Requirements: 6.4_

- [x] 9.2 Add performance optimizations
  - Implement response caching for read operations
  - Add batch operation optimizations for multiple ranges
  - Create memory-efficient handling for large datasets
  - Write performance tests and benchmarks
  - _Requirements: 5.1_

- [x] 10. Finalize package and documentation
- [x] 10.1 Complete Swift Package Manager configuration
  - Finalize Package.swift with proper platform support and dependencies
  - Add package metadata and version information
  - Create proper module exports and public API surface
  - Write unit tests for package configuration
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 10.2 Create comprehensive documentation and examples
  - Write detailed README with installation and usage instructions
  - Create code examples for common use cases
  - Add inline documentation for all public APIs
  - Write getting started guide and advanced usage examples
  - _Requirements: 7.3, 7.4_