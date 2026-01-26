//
//  LSJSONEncoderTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 编码器测试
final class LSJSONEncoderTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 重置编码器模式
        LSJSONEncoder.setMode(.codable)
    }

    override func tearDown() {
        // 清理
        super.tearDown()
    }

    // MARK: - Codable 模式编码测试

    func testCodableModeEncodeToString() {
        let user = EncoderTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let json = user.ls_encode()

        XCTAssertNotNil(json, "编码应该成功")

        // 验证 JSON 格式
        if let jsonData = json?.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            XCTAssertEqual(dict["id"] as? String, "123")
            XCTAssertEqual(dict["name"] as? String, "张三")
            XCTAssertEqual(dict["age"] as? Int, 25)
        } else {
            XCTFail("编码结果不是有效的 JSON")
        }
    }

    func testCodableModeEncodeToData() {
        let user = EncoderTestUser(
            id: "456",
            name: "李四",
            age: 30
        )

        let data = user.ls_encodeToData()

        XCTAssertNotNil(data, "编码应该成功")
        XCTAssertGreaterThan(data?.count ?? 0, 0, "数据应该非空")

        // 验证可以解析回对象
        if let encodedData = data,
           let dict = try? JSONSerialization.jsonObject(with: encodedData) as? [String: Any] {
            XCTAssertEqual(dict["id"] as? String, "456")
            XCTAssertEqual(dict["name"] as? String, "李四")
        }
    }

    func testCodableModeEncodeToDictionary() {
        let user = EncoderTestUser(
            id: "789",
            name: "王五",
            age: 35
        )

        let dict = user.ls_toDictionary()

        XCTAssertNotNil(dict, "编码应该成功")
        XCTAssertEqual(dict?["id"] as? String, "789")
        XCTAssertEqual(dict?["name"] as? String, "王五")
        XCTAssertEqual(dict?["age"] as? Int, 35)
    }

    func testCodableModeEncodeArray() {
        let users = [
            EncoderTestUser(id: "1", name: "张三", age: 25),
            EncoderTestUser(id: "2", name: "李四", age: 30),
            EncoderTestUser(id: "3", name: "王五", age: 35)
        ]

        let json = EncoderTestUser.ls_encodeArrayToJSON(users)

        XCTAssertNotNil(json, "编码应该成功")

        // 验证 JSON 数组格式
        if let jsonData = json?.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
            XCTAssertEqual(array.count, 3)
            XCTAssertEqual(array[0]["id"] as? String, "1")
            XCTAssertEqual(array[1]["name"] as? String, "李四")
            XCTAssertEqual(array[2]["age"] as? Int, 35)
        } else {
            XCTFail("编码结果不是有效的 JSON 数组")
        }
    }

    // MARK: - 性能模式编码测试

    func testPerformanceModeEncodeToString() {
        LSJSONEncoder.setMode(.performance)

        let user = EncoderTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let json = user.ls_encode()

        XCTAssertNotNil(json, "性能模式编码应该成功")

        // 验证 JSON 格式
        if let jsonData = json?.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            XCTAssertEqual(dict["id"] as? String, "123")
        }

        // 恢复默认模式
        LSJSONEncoder.setMode(.codable)
    }

    // MARK: - 嵌套对象编码测试

    func testEncodeNestedObject() {
        let user = EncoderTestUserWithAddress(
            id: "123",
            name: "张三",
            address: EncoderTestAddress(
                street: "人民路",
                city: "北京"
            )
        )

        let dict = user.ls_toDictionary()

        XCTAssertNotNil(dict, "编码应该成功")
        XCTAssertEqual(dict?["id"] as? String, "123")
        XCTAssertEqual(dict?["name"] as? String, "张三")

        if let addressDict = dict?["address"] as? [String: Any] {
            XCTAssertEqual(addressDict["street"] as? String, "人民路")
            XCTAssertEqual(addressDict["city"] as? String, "北京")
        } else {
            XCTFail("嵌套对象编码失败")
        }
    }

    func testEncodeNestedArray() {
        let user = EncoderTestUserWithScores(
            id: "123",
            name: "张三",
            scores: [90, 85, 95]
        )

        let dict = user.ls_toDictionary()

        XCTAssertNotNil(dict, "编码应该成功")
        XCTAssertEqual(dict?["id"] as? String, "123")

        if let scores = dict?["scores"] as? [Int] {
            XCTAssertEqual(scores.count, 3)
            XCTAssertEqual(scores[0], 90)
        } else {
            XCTFail("嵌套数组编码失败")
        }
    }

    // MARK: - 可选字段编码测试

    func testEncodeWithNilOptionalFields() {
        let user = EncoderTestUserOptional(
            id: "123",
            name: "张三",
            email: nil,
            age: nil
        )

        let dict = user.ls_toDictionary()

        XCTAssertNotNil(dict, "编码应该成功")
        XCTAssertEqual(dict?["id"] as? String, "123")
        XCTAssertEqual(dict?["name"] as? String, "张三")
        // 可选字段为 nil 时，默认不包含在输出中
        XCTAssertNil(dict?["email"])
        XCTAssertNil(dict?["age"])
    }

    func testEncodeWithAllOptionalFields() {
        let user = EncoderTestUserOptional(
            id: "123",
            name: "张三",
            email: "test@example.com",
            age: 25
        )

        let dict = user.ls_toDictionary()

        XCTAssertNotNil(dict, "编码应该成功")
        XCTAssertEqual(dict?["email"] as? String, "test@example.com")
        XCTAssertEqual(dict?["age"] as? Int, 25)
    }

    // MARK: - 数组编码测试

    func testEncodeEmptyArray() {
        let users: [EncoderTestUser] = []

        let json = EncoderTestUser.ls_encodeArrayToJSON(users)

        XCTAssertNotNil(json, "编码应该成功")

        // 验证空数组
        if let jsonData = json?.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
            XCTAssertEqual(array.count, 0)
        }
    }

    // MARK: - 编码解码往返测试

    func testEncodeDecodeRoundTrip() {
        let original = EncoderTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        // 编码
        let json = original.ls_encode()
        XCTAssertNotNil(json, "编码应该成功")

        // 解码
        let restored = EncoderTestUser.ls_decode(json ?? "")
        XCTAssertNotNil(restored, "解码应该成功")

        // 验证数据一致性
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.name, original.name)
        XCTAssertEqual(restored?.age, original.age)
    }

    func testDictionaryEncodeDecodeRoundTrip() {
        let original = EncoderTestUser(
            id: "456",
            name: "李四",
            age: 30
        )

        // 编码为字典
        let dict = original.ls_toDictionary()
        XCTAssertNotNil(dict, "编码应该成功")

        // 从字典解码
        let restored = EncoderTestUser.ls_decodeFromDictionary(dict ?? [:])
        XCTAssertNotNil(restored, "解码应该成功")

        // 验证数据一致性
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.name, original.name)
        XCTAssertEqual(restored?.age, original.age)
    }

    func testArrayEncodeDecodeRoundTrip() {
        let original = [
            EncoderTestUser(id: "1", name: "张三", age: 25),
            EncoderTestUser(id: "2", name: "李四", age: 30),
            EncoderTestUser(id: "3", name: "王五", age: 35)
        ]

        // 编码数组
        let json = EncoderTestUser.ls_encodeArrayToJSON(original)
        XCTAssertNotNil(json, "编码应该成功")

        // 解码数组
        let restored = EncoderTestUser.ls_decodeArrayFromJSON(json ?? "")
        XCTAssertNotNil(restored, "解码应该成功")
        XCTAssertEqual(restored?.count, 3)

        // 验证数据一致性
        XCTAssertEqual(restored?[0].id, "1")
        XCTAssertEqual(restored?[1].name, "李四")
        XCTAssertEqual(restored?[2].age, 35)
    }

    // MARK: - 性能测试

    func testEncodePerformance() {
        let user = EncoderTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        measure {
            for _ in 0..<1000 {
                _ = user.ls_encode()
            }
        }
    }

    func testEncodeArrayPerformance() {
        let users = [
            EncoderTestUser(id: "1", name: "张三", age: 25),
            EncoderTestUser(id: "2", name: "李四", age: 30),
            EncoderTestUser(id: "3", name: "王五", age: 35),
            EncoderTestUser(id: "4", name: "赵六", age: 40),
            EncoderTestUser(id: "5", name: "钱七", age: 45)
        ]

        measure {
            for _ in 0..<1000 {
                _ = EncoderTestUser.ls_encodeArrayToJSON(users)
            }
        }
    }

    func testDictionaryEncodePerformance() {
        let user = EncoderTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        measure {
            for _ in 0..<1000 {
                _ = user.ls_toDictionary()
            }
        }
    }
}

// MARK: - Test Models

/// 编码测试用户模型
struct EncoderTestUser: Codable {
    let id: String
    let name: String
    let age: Int
}

/// 带地址的用户模型
struct EncoderTestUserWithAddress: Codable {
    let id: String
    let name: String
    let address: EncoderTestAddress?
}

struct EncoderTestAddress: Codable {
    let street: String
    let city: String
}

/// 带成绩的用户模型
struct EncoderTestUserWithScores: Codable {
    let id: String
    let name: String
    let scores: [Int]?
}

/// 可选字段用户模型
struct EncoderTestUserOptional: Codable {
    let id: String
    let name: String
    let email: String?
    let age: Int?
}
