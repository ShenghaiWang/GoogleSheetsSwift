import XCTest
@testable import GoogleSheetsSwift

final class GoogleSheetsSwiftTests: XCTestCase {
    
    func testPackageStructure() {
        // Test that the main types are accessible
        XCTAssertNotNil(HTTPMethod.GET)
        XCTAssertNotNil(HTTPMethod.POST)
        XCTAssertNotNil(HTTPMethod.PUT)
        XCTAssertNotNil(HTTPMethod.DELETE)
    }
    
    func testHTTPRequestCreation() {
        let url = URL(string: "https://example.com")!
        let request = HTTPRequest(method: .GET, url: url)
        
        XCTAssertEqual(request.method, .GET)
        XCTAssertEqual(request.url, url)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertNil(request.body)
    }
    
    func testHTTPRequestWithHeaders() {
        let url = URL(string: "https://example.com")!
        let headers = ["Authorization": "Bearer token", "Content-Type": "application/json"]
        let request = HTTPRequest(method: .POST, url: url, headers: headers)
        
        XCTAssertEqual(request.method, .POST)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.headers, headers)
    }
    
    func testAuthResultCreation() {
        let authResult = AuthResult(accessToken: "test_token")
        
        XCTAssertEqual(authResult.accessToken, "test_token")
        XCTAssertNil(authResult.refreshToken)
        XCTAssertNil(authResult.expiresIn)
        XCTAssertEqual(authResult.tokenType, "Bearer")
        XCTAssertNil(authResult.scope)
    }
    
    func testAuthResultWithAllFields() {
        let authResult = AuthResult(
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer",
            scope: "https://www.googleapis.com/auth/spreadsheets"
        )
        
        XCTAssertEqual(authResult.accessToken, "access_token")
        XCTAssertEqual(authResult.refreshToken, "refresh_token")
        XCTAssertEqual(authResult.expiresIn, 3600)
        XCTAssertEqual(authResult.tokenType, "Bearer")
        XCTAssertEqual(authResult.scope, "https://www.googleapis.com/auth/spreadsheets")
    }
}