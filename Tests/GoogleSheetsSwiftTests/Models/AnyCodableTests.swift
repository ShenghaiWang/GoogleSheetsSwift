import XCTest
@testable import GoogleSheetsSwift

final class AnyCodableTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitWithNil() {
        let anyCodable = AnyCodable(nil as String?)
        XCTAssertTrue(anyCodable.isNull)
        XCTAssertTrue(anyCodable.value is NSNull)
    }
    
    func testInitWithString() {
        let anyCodable = AnyCodable("test")
        XCTAssertFalse(anyCodable.isNull)
        XCTAssertEqual(anyCodable.value as? String, "test")
    }
    
    func testInitWithInt() {
        let anyCodable = AnyCodable(42)
        XCTAssertFalse(anyCodable.isNull)
        XCTAssertEqual(anyCodable.value as? Int, 42)
    }
    
    func testInitWithDouble() {
        let anyCodable = AnyCodable(3.14)
        XCTAssertFalse(anyCodable.isNull)
        XCTAssertEqual(anyCodable.value as? Double, 3.14)
    }
    
    func testInitWithBool() {
        let anyCodable = AnyCodable(true)
        XCTAssertFalse(anyCodable.isNull)
        XCTAssertEqual(anyCodable.value as? Bool, true)
    }
    
    func testInitWithRawValue() {
        let anyCodable = AnyCodable(NSNull())
        XCTAssertTrue(anyCodable.isNull)
    }
    
    // MARK: - Type-safe Getter Tests
    
    func testGetString() {
        // String value
        let stringValue = AnyCodable("hello")
        XCTAssertEqual(stringValue.getString(), "hello")
        
        // Number to string conversion
        let numberValue = AnyCodable(42)
        XCTAssertEqual(numberValue.getString(), "42")
        
        // NSNumber to string conversion
        let nsNumberValue = AnyCodable(NSNumber(value: 3.14))
        XCTAssertEqual(nsNumberValue.getString(), "3.14")
        
        // Null value
        let nullValue = AnyCodable(nil as String?)
        XCTAssertNil(nullValue.getString())
        
        // Other types
        let boolValue = AnyCodable(true)
        XCTAssertEqual(boolValue.getString(), "true")
    }
    
    func testGetDouble() {
        // Double value
        let doubleValue = AnyCodable(3.14)
        XCTAssertEqual(doubleValue.getDouble(), 3.14)
        
        // Int to double conversion
        let intValue = AnyCodable(42)
        XCTAssertEqual(intValue.getDouble(), 42.0)
        
        // NSNumber to double conversion
        let nsNumberValue = AnyCodable(NSNumber(value: 2.5))
        XCTAssertEqual(nsNumberValue.getDouble(), 2.5)
        
        // String to double conversion
        let stringValue = AnyCodable("1.5")
        XCTAssertEqual(stringValue.getDouble(), 1.5)
        
        // Invalid string
        let invalidStringValue = AnyCodable("not a number")
        XCTAssertNil(invalidStringValue.getDouble())
        
        // Null value
        let nullValue = AnyCodable(nil as Double?)
        XCTAssertNil(nullValue.getDouble())
    }
    
    func testGetInt() {
        // Int value
        let intValue = AnyCodable(42)
        XCTAssertEqual(intValue.getInt(), 42)
        
        // Double to int conversion
        let doubleValue = AnyCodable(3.14)
        XCTAssertEqual(doubleValue.getInt(), 3)
        
        // NSNumber to int conversion
        let nsNumberValue = AnyCodable(NSNumber(value: 25))
        XCTAssertEqual(nsNumberValue.getInt(), 25)
        
        // String to int conversion
        let stringValue = AnyCodable("123")
        XCTAssertEqual(stringValue.getInt(), 123)
        
        // Invalid string
        let invalidStringValue = AnyCodable("not a number")
        XCTAssertNil(invalidStringValue.getInt())
        
        // Null value
        let nullValue = AnyCodable(nil as Int?)
        XCTAssertNil(nullValue.getInt())
    }
    
    func testGetBool() {
        // Bool value
        let boolValue = AnyCodable(true)
        XCTAssertEqual(boolValue.getBool(), true)
        
        // NSNumber to bool conversion
        let nsNumberValue = AnyCodable(NSNumber(value: 1))
        XCTAssertEqual(nsNumberValue.getBool(), true)
        
        // String to bool conversion - true cases
        XCTAssertEqual(AnyCodable("true").getBool(), true)
        XCTAssertEqual(AnyCodable("TRUE").getBool(), true)
        XCTAssertEqual(AnyCodable("yes").getBool(), true)
        XCTAssertEqual(AnyCodable("YES").getBool(), true)
        XCTAssertEqual(AnyCodable("1").getBool(), true)
        
        // String to bool conversion - false cases
        XCTAssertEqual(AnyCodable("false").getBool(), false)
        XCTAssertEqual(AnyCodable("FALSE").getBool(), false)
        XCTAssertEqual(AnyCodable("no").getBool(), false)
        XCTAssertEqual(AnyCodable("NO").getBool(), false)
        XCTAssertEqual(AnyCodable("0").getBool(), false)
        
        // Invalid string
        let invalidStringValue = AnyCodable("maybe")
        XCTAssertNil(invalidStringValue.getBool())
        
        // Null value
        let nullValue = AnyCodable(nil as Bool?)
        XCTAssertNil(nullValue.getBool())
    }
    
    func testGenericGet() {
        let stringValue = AnyCodable("test")
        XCTAssertEqual(stringValue.get() as String?, "test")
        
        let intValue = AnyCodable(42)
        XCTAssertEqual(intValue.get() as Int?, 42)
        
        let nullValue = AnyCodable(nil as String?)
        XCTAssertNil(nullValue.get() as String?)
    }
    
    // MARK: - Codable Tests
    
    func testEncodeString() throws {
        let anyCodable = AnyCodable("hello")
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "\"hello\"")
    }
    
    func testEncodeInt() throws {
        let anyCodable = AnyCodable(42)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "42")
    }
    
    func testEncodeDouble() throws {
        let anyCodable = AnyCodable(3.14)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "3.14")
    }
    
    func testEncodeBool() throws {
        let anyCodable = AnyCodable(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "true")
    }
    
    func testEncodeNull() throws {
        let anyCodable = AnyCodable(nil as String?)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "null")
    }
    
    func testEncodeArray() throws {
        let array = [AnyCodable("hello"), AnyCodable(42), AnyCodable(true)]
        let anyCodable = AnyCodable(array)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertEqual(jsonString, "[\"hello\",42,true]")
    }
    
    func testEncodeDictionary() throws {
        let dictionary = ["string": AnyCodable("hello"), "number": AnyCodable(42)]
        let anyCodable = AnyCodable(dictionary)
        let encoder = JSONEncoder()
        let data = try encoder.encode(anyCodable)
        
        // Parse back to verify structure (order may vary)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)
        XCTAssertEqual(decoded["string"]?.getString(), "hello")
        XCTAssertEqual(decoded["number"]?.getInt(), 42)
    }
    
    func testDecodeString() throws {
        let jsonData = "\"hello\"".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        XCTAssertEqual(anyCodable.getString(), "hello")
    }
    
    func testDecodeInt() throws {
        let jsonData = "42".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        XCTAssertEqual(anyCodable.getInt(), 42)
    }
    
    func testDecodeDouble() throws {
        let jsonData = "3.14".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        XCTAssertEqual(anyCodable.getDouble(), 3.14)
    }
    
    func testDecodeBool() throws {
        let jsonData = "true".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        XCTAssertEqual(anyCodable.getBool(), true)
    }
    
    func testDecodeNull() throws {
        let jsonData = "null".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        XCTAssertTrue(anyCodable.isNull)
    }
    
    func testDecodeArray() throws {
        let jsonData = "[\"hello\",42,true,null]".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        
        let array: [AnyCodable]? = anyCodable.get()
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 4)
        XCTAssertEqual(array?[0].getString(), "hello")
        XCTAssertEqual(array?[1].getInt(), 42)
        XCTAssertEqual(array?[2].getBool(), true)
        XCTAssertTrue(array?[3].isNull ?? false)
    }
    
    func testDecodeDictionary() throws {
        let jsonData = "{\"string\":\"hello\",\"number\":42,\"bool\":true,\"null\":null}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let anyCodable = try decoder.decode(AnyCodable.self, from: jsonData)
        
        let dictionary: [String: AnyCodable]? = anyCodable.get()
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?["string"]?.getString(), "hello")
        XCTAssertEqual(dictionary?["number"]?.getInt(), 42)
        XCTAssertEqual(dictionary?["bool"]?.getBool(), true)
        XCTAssertTrue(dictionary?["null"]?.isNull ?? false)
    }
    
    func testRoundTripEncoding() throws {
        let original = AnyCodable("test value")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AnyCodable.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        XCTAssertEqual(AnyCodable("hello"), AnyCodable("hello"))
        XCTAssertEqual(AnyCodable(42), AnyCodable(42))
        XCTAssertEqual(AnyCodable(3.14), AnyCodable(3.14))
        XCTAssertEqual(AnyCodable(true), AnyCodable(true))
        XCTAssertEqual(AnyCodable(nil as String?), AnyCodable(nil as Int?))
        
        XCTAssertNotEqual(AnyCodable("hello"), AnyCodable("world"))
        XCTAssertNotEqual(AnyCodable(42), AnyCodable(43))
        XCTAssertNotEqual(AnyCodable(true), AnyCodable(false))
        XCTAssertNotEqual(AnyCodable("hello"), AnyCodable(42))
    }
    
    func testArrayEquality() {
        let array1 = [AnyCodable("hello"), AnyCodable(42)]
        let array2 = [AnyCodable("hello"), AnyCodable(42)]
        let array3 = [AnyCodable("hello"), AnyCodable(43)]
        
        XCTAssertEqual(AnyCodable(array1), AnyCodable(array2))
        XCTAssertNotEqual(AnyCodable(array1), AnyCodable(array3))
    }
    
    func testDictionaryEquality() {
        let dict1 = ["key": AnyCodable("value")]
        let dict2 = ["key": AnyCodable("value")]
        let dict3 = ["key": AnyCodable("different")]
        
        XCTAssertEqual(AnyCodable(dict1), AnyCodable(dict2))
        XCTAssertNotEqual(AnyCodable(dict1), AnyCodable(dict3))
    }
    
    // MARK: - Description Tests
    
    func testDescription() {
        XCTAssertEqual(AnyCodable("hello").description, "hello")
        XCTAssertEqual(AnyCodable(42).description, "42")
        XCTAssertEqual(AnyCodable(true).description, "true")
        XCTAssertEqual(AnyCodable(nil as String?).description, "null")
    }
    
    func testDebugDescription() {
        XCTAssertEqual(AnyCodable("hello").debugDescription, "AnyCodable(hello)")
        XCTAssertEqual(AnyCodable(42).debugDescription, "AnyCodable(42)")
        XCTAssertEqual(AnyCodable(nil as String?).debugDescription, "AnyCodable(null)")
    }
    
    // MARK: - Collection Extension Tests
    
    func testArrayToStrings() {
        let array = [AnyCodable("hello"), AnyCodable(42), AnyCodable(true), AnyCodable(nil as String?)]
        let strings = array.toStrings()
        
        XCTAssertEqual(strings.count, 4)
        XCTAssertEqual(strings[0], "hello")
        XCTAssertEqual(strings[1], "42")
        XCTAssertEqual(strings[2], "true")
        XCTAssertNil(strings[3])
    }
    
    func testArrayToDoubles() {
        let array = [AnyCodable(3.14), AnyCodable(42), AnyCodable("2.5"), AnyCodable("invalid")]
        let doubles = array.toDoubles()
        
        XCTAssertEqual(doubles.count, 4)
        XCTAssertEqual(doubles[0], 3.14)
        XCTAssertEqual(doubles[1], 42.0)
        XCTAssertEqual(doubles[2], 2.5)
        XCTAssertNil(doubles[3])
    }
    
    func testArrayToInts() {
        let array = [AnyCodable(42), AnyCodable(3.14), AnyCodable("25"), AnyCodable("invalid")]
        let ints = array.toInts()
        
        XCTAssertEqual(ints.count, 4)
        XCTAssertEqual(ints[0], 42)
        XCTAssertEqual(ints[1], 3)
        XCTAssertEqual(ints[2], 25)
        XCTAssertNil(ints[3])
    }
    
    func testArrayToBools() {
        let array = [AnyCodable(true), AnyCodable("false"), AnyCodable("yes"), AnyCodable("invalid")]
        let bools = array.toBools()
        
        XCTAssertEqual(bools.count, 4)
        XCTAssertEqual(bools[0], true)
        XCTAssertEqual(bools[1], false)
        XCTAssertEqual(bools[2], true)
        XCTAssertNil(bools[3])
    }
    
    func test2DArrayToStrings() {
        let array2D = [
            [AnyCodable("hello"), AnyCodable(42)],
            [AnyCodable(true), AnyCodable(nil as String?)]
        ]
        let strings2D = array2D.toStrings()
        
        XCTAssertEqual(strings2D.count, 2)
        XCTAssertEqual(strings2D[0].count, 2)
        XCTAssertEqual(strings2D[0][0], "hello")
        XCTAssertEqual(strings2D[0][1], "42")
        XCTAssertEqual(strings2D[1][0], "true")
        XCTAssertNil(strings2D[1][1])
    }
    
    func test2DArrayToDoubles() {
        let array2D = [
            [AnyCodable(3.14), AnyCodable(42)],
            [AnyCodable("2.5"), AnyCodable("invalid")]
        ]
        let doubles2D = array2D.toDoubles()
        
        XCTAssertEqual(doubles2D.count, 2)
        XCTAssertEqual(doubles2D[0][0], 3.14)
        XCTAssertEqual(doubles2D[0][1], 42.0)
        XCTAssertEqual(doubles2D[1][0], 2.5)
        XCTAssertNil(doubles2D[1][1])
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testInvalidEncodingValue() {
        // Test with a non-encodable type
        struct NonEncodable {}
        let nonEncodable = NonEncodable()
        let anyCodable = AnyCodable(nonEncodable)
        
        let encoder = JSONEncoder()
        XCTAssertThrowsError(try encoder.encode(anyCodable)) { error in
            XCTAssertTrue(error is EncodingError)
        }
    }
    
    func testInvalidDecodingData() {
        let invalidJsonData = "invalid json".data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(AnyCodable.self, from: invalidJsonData))
    }
    
    func testComplexNestedStructure() throws {
        // Create a properly structured AnyCodable hierarchy
        let nestedDict = ["inner": AnyCodable("value")]
        let arrayValues = [AnyCodable("item1"), AnyCodable(2), AnyCodable(true)]
        
        let complexStructure: [String: AnyCodable] = [
            "string": AnyCodable("hello"),
            "number": AnyCodable(42),
            "bool": AnyCodable(true),
            "null": AnyCodable(nil as String?),
            "array": AnyCodable(arrayValues),
            "nested": AnyCodable(nestedDict)
        ]
        
        let anyCodable = AnyCodable(complexStructure)
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(anyCodable)
        let decoded = try decoder.decode(AnyCodable.self, from: data)
        
        // Verify the structure is preserved
        let decodedDict: [String: AnyCodable]? = decoded.get()
        XCTAssertNotNil(decodedDict)
        XCTAssertEqual(decodedDict?["string"]?.getString(), "hello")
        XCTAssertEqual(decodedDict?["number"]?.getInt(), 42)
        XCTAssertEqual(decodedDict?["bool"]?.getBool(), true)
        XCTAssertTrue(decodedDict?["null"]?.isNull ?? false)
        
        let decodedArray: [AnyCodable]? = decodedDict?["array"]?.get()
        XCTAssertNotNil(decodedArray)
        XCTAssertEqual(decodedArray?.count, 3)
        XCTAssertEqual(decodedArray?[0].getString(), "item1")
        XCTAssertEqual(decodedArray?[1].getInt(), 2)
        XCTAssertEqual(decodedArray?[2].getBool(), true)
        
        let decodedNested: [String: AnyCodable]? = decodedDict?["nested"]?.get()
        XCTAssertNotNil(decodedNested)
        XCTAssertEqual(decodedNested?["inner"]?.getString(), "value")
    }
}