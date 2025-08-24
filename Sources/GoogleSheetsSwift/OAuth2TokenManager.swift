import Foundation
#if canImport(Security)
import Security
#endif
#if canImport(CommonCrypto)
import CommonCrypto
#endif
/// Result of authentication flow
public struct AuthResult {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: TimeInterval?
    public let tokenType: String
    public let scope: String?
    
    public init(accessToken: String, refreshToken: String? = nil, expiresIn: TimeInterval? = nil, tokenType: String = "Bearer", scope: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.scope = scope
    }
}

/// Protocol for OAuth2 token management
public protocol OAuth2TokenManager {
    /// Get a valid access token, refreshing if necessary
    func getAccessToken() async throws -> String
    
    /// Refresh the access token using the refresh token
    func refreshToken() async throws -> String
    
    /// Check if the user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// Initiate the OAuth2 authentication flow
    func authenticate(scopes: [String]) async throws -> AuthResult
    
    /// Clear stored tokens (logout)
    func clearTokens() async throws
}
#if os(macOS)
/// Secure token storage using Keychain
internal class KeychainTokenStorage {
    private let service: String
    private let accessTokenKey: String
    private let refreshTokenKey: String
    private let expirationKey: String
    
    init(service: String = "GoogleSheetsSwift") {
        self.service = service
        self.accessTokenKey = "\(service).accessToken"
        self.refreshTokenKey = "\(service).refreshToken"
        self.expirationKey = "\(service).expiration"
    }
    
    func storeTokens(accessToken: String, refreshToken: String?, expiresIn: TimeInterval?) throws {
        try storeString(accessToken, forKey: accessTokenKey)
        
        if let refreshToken = refreshToken {
            try storeString(refreshToken, forKey: refreshTokenKey)
        }
        
        if let expiresIn = expiresIn {
            let expirationDate = Date().addingTimeInterval(expiresIn)
            try storeString(String(expirationDate.timeIntervalSince1970), forKey: expirationKey)
        }
    }
    
    func getAccessToken() throws -> String? {
        return try getString(forKey: accessTokenKey)
    }
    
    func getRefreshToken() throws -> String? {
        return try getString(forKey: refreshTokenKey)
    }
    
    func isTokenExpired() throws -> Bool {
        guard let expirationString = try getString(forKey: expirationKey),
              let expirationTimestamp = Double(expirationString) else {
            return true // If no expiration info, consider expired
        }
        
        let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
        return Date() >= expirationDate.addingTimeInterval(-300) // 5 minute buffer
    }
    
    func clearTokens() throws {
        try deleteItem(forKey: accessTokenKey)
        try deleteItem(forKey: refreshTokenKey)
        try deleteItem(forKey: expirationKey)
    }
    
    private func storeString(_ value: String, forKey key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw GoogleSheetsError.authenticationFailed("Failed to store token in keychain: \(status)")
        }
    }
    
    private func getString(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw GoogleSheetsError.authenticationFailed("Failed to retrieve token from keychain: \(status)")
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw GoogleSheetsError.authenticationFailed("Failed to decode token from keychain")
        }
        
        return string
    }
    
    private func deleteItem(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        // Don't throw error if item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GoogleSheetsError.authenticationFailed("Failed to delete token from keychain: \(status)")
        }
    }
}

/// Google OAuth2 token manager implementation
public class GoogleOAuth2TokenManager: OAuth2TokenManager {
    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String
    private let tokenStorage: KeychainTokenStorage
    private let httpClient: HTTPClient
    
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private let authEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    
    public init(clientId: String, clientSecret: String, redirectURI: String, httpClient: HTTPClient? = nil) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.tokenStorage = KeychainTokenStorage()
        self.httpClient = httpClient ?? URLSessionHTTPClient()
    }
    
    public var isAuthenticated: Bool {
        do {
            guard try tokenStorage.getAccessToken() != nil else { return false }
            return !(try tokenStorage.isTokenExpired())
        } catch {
            return false
        }
    }
    
    public func getAccessToken() async throws -> String {
        // Check if we have a valid access token
        if let accessToken = try tokenStorage.getAccessToken(),
           !(try tokenStorage.isTokenExpired()) {
            return accessToken
        }
        
        // Try to refresh the token if we have a refresh token
        if try tokenStorage.getRefreshToken() != nil {
            return try await refreshToken()
        }
        
        throw GoogleSheetsError.tokenExpired
    }
    
    public func refreshToken() async throws -> String {
        guard let refreshToken = try tokenStorage.getRefreshToken() else {
            throw GoogleSheetsError.authenticationFailed("No refresh token available")
        }
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)!
        
        let request = HTTPRequest(
            method: .POST,
            url: URL(string: tokenEndpoint)!,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )
        
        let response: TokenResponse = try await httpClient.execute(request)
        
        // Store the new tokens
        try tokenStorage.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? refreshToken, // Keep existing refresh token if not provided
            expiresIn: response.expiresIn
        )
        
        return response.accessToken
    }
    
    public func authenticate(scopes: [String]) async throws -> AuthResult {
        // In a real implementation, you would:
        // 1. Generate authorization URL using buildAuthorizationURL(scopes: scopes)
        // 2. Open the authorization URL in a web view or system browser
        // 3. Handle the redirect back to your app with the authorization code
        // 4. Exchange the authorization code for tokens using exchangeAuthorizationCode()
        
        // For now, we'll throw an error indicating this needs to be implemented by the client
        throw GoogleSheetsError.authenticationFailed("Authentication flow requires manual implementation. Use buildAuthorizationURL() to get the auth URL, then call exchangeAuthorizationCode() with the received code.")
    }
    
    /// Build the authorization URL for OAuth2 flow
    public func buildAuthorizationURL(scopes: [String], state: String? = nil) -> URL {
        var components = URLComponents(string: authEndpoint)!
        
        let scopeString = scopes.joined(separator: " ")
        let stateValue = state ?? UUID().uuidString
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: stateValue)
        ]
        
        return components.url!
    }
    
    /// Exchange authorization code for access and refresh tokens
    public func exchangeAuthorizationCode(_ code: String, state: String? = nil) async throws -> AuthResult {
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)!
        
        let request = HTTPRequest(
            method: .POST,
            url: URL(string: tokenEndpoint)!,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )
        
        let response: TokenResponse = try await httpClient.execute(request)
        
        // Store the tokens
        try tokenStorage.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
        
        return AuthResult(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn,
            tokenType: response.tokenType ?? "Bearer",
            scope: response.scope
        )
    }
    
    public func clearTokens() async throws {
        try tokenStorage.clearTokens()
    }
    
    // Helper method for testing and manual token setting
    public func setTokens(accessToken: String, refreshToken: String?, expiresIn: TimeInterval?) throws {
        try tokenStorage.storeTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

#endif

// MARK: - Service Account Authentication

/// Service account key structure from Google Cloud Console JSON key file
public struct ServiceAccountKey: Codable {
    public let type: String
    public let projectId: String
    public let privateKeyId: String
    public let privateKey: String
    public let clientEmail: String
    public let clientId: String
    public let authUri: String
    public let tokenUri: String
    public let authProviderX509CertUrl: String
    public let clientX509CertUrl: String
    public let universeDomain: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case projectId = "project_id"
        case privateKeyId = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientId = "client_id"
        case authUri = "auth_uri"
        case tokenUri = "token_uri"
        case authProviderX509CertUrl = "auth_provider_x509_cert_url"
        case clientX509CertUrl = "client_x509_cert_url"
        case universeDomain = "universe_domain"
    }
    
    public init(type: String, projectId: String, privateKeyId: String, privateKey: String, clientEmail: String, clientId: String, authUri: String, tokenUri: String, authProviderX509CertUrl: String, clientX509CertUrl: String, universeDomain: String? = nil) {
        self.type = type
        self.projectId = projectId
        self.privateKeyId = privateKeyId
        self.privateKey = privateKey
        self.clientEmail = clientEmail
        self.clientId = clientId
        self.authUri = authUri
        self.tokenUri = tokenUri
        self.authProviderX509CertUrl = authProviderX509CertUrl
        self.clientX509CertUrl = clientX509CertUrl
        self.universeDomain = universeDomain
    }
}

/// JWT Claims for Google OAuth2 service account authentication
internal struct JWTClaims: Codable {
    let iss: String // Service account email
    let scope: String // Space-delimited scopes
    let aud: String // Token endpoint URL
    let exp: Int // Expiration timestamp
    let iat: Int // Issued at timestamp
    let sub: String? // Impersonation user email (optional)
    
    init(iss: String, scope: String, aud: String, exp: Int, iat: Int, sub: String? = nil) {
        self.iss = iss
        self.scope = scope
        self.aud = aud
        self.exp = exp
        self.iat = iat
        self.sub = sub
    }
}

/// JWT Generator for service account authentication
internal class JWTGenerator {
    static func generateJWT(
        serviceAccountKey: ServiceAccountKey,
        scopes: [String],
        impersonationUser: String? = nil
    ) throws -> String {
        let now = Int(Date().timeIntervalSince1970)
        let expiration = now + 3600 // 1 hour
        
        let claims = JWTClaims(
            iss: serviceAccountKey.clientEmail,
            scope: scopes.joined(separator: " "),
            aud: serviceAccountKey.tokenUri,
            exp: expiration,
            iat: now,
            sub: impersonationUser
        )
        
        // Create JWT header
        let header = JWTHeader(alg: "RS256", typ: "JWT")
        let headerData = try JSONEncoder().encode(header)
        let headerBase64 = headerData.base64URLEncodedString()
        
        // Create JWT payload
        let payloadData = try JSONEncoder().encode(claims)
        let payloadBase64 = payloadData.base64URLEncodedString()
        
        // Create signature
        let signingInput = "\(headerBase64).\(payloadBase64)"
        let signature = try signWithRSA(data: signingInput, privateKey: serviceAccountKey.privateKey)
        let signatureBase64 = signature.base64URLEncodedString()
        
        return "\(signingInput).\(signatureBase64)"
    }
    
    private static func signWithRSA(data: String, privateKey: String) throws -> Data {
        // Parse the private key
        let secKey = try parsePrivateKey(privateKey)
        
        // Create signature
        let dataToSign = data.data(using: .utf8)!
        var error: Unmanaged<CFError>?
        
        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            dataToSign as CFData,
            &error
        ) else {
            if let error = error?.takeRetainedValue() {
                throw GoogleSheetsError.authenticationFailed("Failed to sign JWT: \(error)")
            }
            throw GoogleSheetsError.authenticationFailed("Failed to sign JWT: Unknown error")
        }
        
        return signature as Data
    }
    
    private static func parsePrivateKey(_ privateKeyString: String) throws -> SecKey {
        // Remove PEM headers and whitespace
        let cleanKey = privateKeyString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        guard let keyData = Data(base64Encoded: cleanKey) else {
            throw GoogleSheetsError.authenticationFailed("Invalid private key format - base64 decoding failed")
        }
        
        // Try using SecItemImport which is more robust for PKCS#8 keys
        var importParams = SecItemImportExportKeyParameters()
        importParams.version = UInt32(SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION)
        importParams.flags = SecKeyImportExportFlags(rawValue: 0)
        importParams.passphrase = nil
        importParams.alertTitle = nil
        importParams.alertPrompt = nil
        importParams.accessRef = nil
        importParams.keyUsage = nil
        importParams.keyAttributes = nil
        
        var outItems: CFArray?
        let importStatus = SecItemImport(
            keyData as CFData,
            nil, // filename
            nil, // inputFormat (let system determine)
            nil, // itemType (let system determine)
            SecItemImportExportFlags(rawValue: 0),
            &importParams,
            nil, // keychain (use default)
            &outItems
        )
        
        if importStatus == errSecSuccess, let items = outItems as? [Any], !items.isEmpty {
            // Successfully imported, now extract the SecKey
            if let firstItem = items.first {
                // Check if it's a SecKey by comparing CFTypeIDs
                if CFGetTypeID(firstItem as CFTypeRef) == SecKeyGetTypeID() {
                    return (firstItem as! SecKey)
                }
            }
        }
        
        // If SecItemImport fails, fall back to SecKeyCreateWithData
        var error: Unmanaged<CFError>?
        
        // Try with minimal attributes
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        if let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) {
            return secKey
        }
        
        // If both methods fail, provide detailed error information
        var errorMessage = "Failed to create private key using both SecItemImport (status: \(importStatus)) and SecKeyCreateWithData"
        
        if let error = error?.takeRetainedValue() {
            let errorDescription = CFErrorCopyDescription(error)
            let errorString = errorDescription as String? ?? "Unknown CFError"
            errorMessage += ": \(errorString)"
        }
        
        let keyDataHex = keyData.prefix(20).map { String(format: "%02x", $0) }.joined()
        errorMessage += ". Key data length: \(keyData.count) bytes, starts with: \(keyDataHex)..."
        
        throw GoogleSheetsError.authenticationFailed(errorMessage)
    }
}

/// JWT Header structure
private struct JWTHeader: Codable {
    let alg: String
    let typ: String
}

/// Service Account Token Manager for server-to-server authentication
public class ServiceAccountTokenManager: OAuth2TokenManager {
    private let serviceAccountKey: ServiceAccountKey
    private let httpClient: HTTPClient
#if os(macOS)
    private let tokenStorage: KeychainTokenStorage?
#endif
    private var impersonationUser: String?
    private let tokenRefreshQueue = DispatchQueue(label: "com.googlesheets.token-refresh", qos: .userInitiated)
    private var currentRefreshTask: Task<String, Error>?
    private let useKeychain: Bool
    
    public init(serviceAccountKey: ServiceAccountKey, httpClient: HTTPClient? = nil, useKeychain: Bool = true) {
        self.serviceAccountKey = serviceAccountKey
        self.httpClient = httpClient ?? URLSessionHTTPClient()
        self.useKeychain = useKeychain
#if os(macOS)
        self.tokenStorage = useKeychain ? KeychainTokenStorage(service: "GoogleSheetsSwift.ServiceAccount.\(serviceAccountKey.clientEmail)") : nil
#else
        self.useKeychain = false
#endif

    }
    
    /// Initialize with service account key file path
    public convenience init(serviceAccountKeyPath: String, httpClient: HTTPClient? = nil) throws {
        let url = URL(fileURLWithPath: serviceAccountKeyPath)
        let data = try Data(contentsOf: url)
        let key = try JSONDecoder().decode(ServiceAccountKey.self, from: data)
        self.init(serviceAccountKey: key, httpClient: httpClient)
    }
    
    /// Set user email for domain-wide delegation
    public func setImpersonationUser(_ email: String?) {
        self.impersonationUser = email
    }
    
    /// Clear impersonation user (return to service account identity)
    public func clearImpersonationUser() {
        self.impersonationUser = nil
    }
    
    /// Get current impersonation user
    public var currentImpersonationUser: String? {
        return impersonationUser
    }
    
    public var isAuthenticated: Bool {
        // Service accounts don't store long-lived tokens, they generate them on demand
        return true
    }
    
    public func getAccessToken() async throws -> String {
#if os(macOS)
        // If keychain is disabled (server-side), always generate fresh tokens
        guard useKeychain, let tokenStorage = tokenStorage else {
            return try await performTokenRefresh()
        }
        
        // Check if we have a valid cached token
        if let accessToken = try tokenStorage.getAccessToken(),
           !(try tokenStorage.isTokenExpired()) {
            return accessToken
        }
        
        // Handle concurrent token refresh requests
        if let existingTask = currentRefreshTask {
            return try await existingTask.value
        }
        
        // Create new refresh task
        let refreshTask = Task<String, Error> {
            defer { currentRefreshTask = nil }
            return try await performTokenRefresh()
        }
        
        currentRefreshTask = refreshTask
        return try await refreshTask.value
#else
        return try await performTokenRefresh()
#endif
    }
    
    private func performTokenRefresh() async throws -> String {
#if os(macOS)
        // Double-check if token is still expired (another task might have refreshed it)
        if let tokenStorage = tokenStorage,
           let accessToken = try tokenStorage.getAccessToken(),
           !(try tokenStorage.isTokenExpired()) {
            return accessToken
        }
#endif
        // Generate JWT
        let scopes = ["https://www.googleapis.com/auth/spreadsheets"]
        let jwt = try JWTGenerator.generateJWT(
            serviceAccountKey: serviceAccountKey,
            scopes: scopes,
            impersonationUser: impersonationUser
        )
        
        // Exchange JWT for access token
        let parameters = [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt
        ]
        
        let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)!
        
        let request = HTTPRequest(
            method: .POST,
            url: URL(string: serviceAccountKey.tokenUri)!,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body
        )
        
        let response: TokenResponse = try await httpClient.execute(request)
        #if os(macOS)
        // Cache the token only if keychain is enabled
        if let tokenStorage = tokenStorage {
            try tokenStorage.storeTokens(
                accessToken: response.accessToken,
                refreshToken: nil, // Service accounts don't use refresh tokens
                expiresIn: response.expiresIn
            )
        }
        #endif
        return response.accessToken
    }
    
    public func refreshToken() async throws -> String {
        #if os(macOS)
        // Force refresh by clearing current token and generating new one
        try tokenStorage?.clearTokens()
        #endif
        return try await performTokenRefresh()
    }
    
    public func authenticate(scopes: [String]) async throws -> AuthResult {
        let accessToken = try await getAccessToken()
        return AuthResult(
            accessToken: accessToken,
            refreshToken: nil,
            expiresIn: 3600, // Service account tokens typically expire in 1 hour
            tokenType: "Bearer",
            scope: scopes.joined(separator: " ")
        )
    }
    
    public func clearTokens() async throws {
        #if os(macOS)
        try tokenStorage?.clearTokens()
        #endif
    }
    
    /// Load service account from file
    public static func loadFromFile(_ path: String, useKeychain: Bool = true) throws -> ServiceAccountTokenManager {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let key = try JSONDecoder().decode(ServiceAccountKey.self, from: data)
        return ServiceAccountTokenManager(serviceAccountKey: key, useKeychain: useKeychain)
    }
    
    /// Load service account from environment variable GOOGLE_APPLICATION_CREDENTIALS
    public static func loadFromEnvironment(useKeychain: Bool = true) throws -> ServiceAccountTokenManager {
        guard let path = ProcessInfo.processInfo.environment["GOOGLE_APPLICATION_CREDENTIALS"] else {
            throw GoogleSheetsError.authenticationFailed("GOOGLE_APPLICATION_CREDENTIALS environment variable not set")
        }
        return try loadFromFile(path, useKeychain: useKeychain)
    }
}

// MARK: - Base64URL Encoding Extension

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Token Response Model

internal struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval?
    let tokenType: String?
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}
