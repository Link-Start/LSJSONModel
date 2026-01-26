//
//  LSJSONDecoderTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 解码器测试
final class LSJSONDecoderTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 重置解码器模式
        LSJSONDecoder.setMode(.codable)
    }

    override func tearDown() {
        // 清理
        super.tearDown()
    }

    // MARK: - Codable 模式解码测试

    func testCodableModeDecodeFromString() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        let user = DecoderTestUser.ls_decode(json)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "123")
        XCTAssertEqual(user?.name, "张三")
        XCTAssertEqual(user?.age, 25)
    }

    func testCodableModeDecodeFromData() {
        let json = """
        {
            "id": "456",
            "name": "李四",
            "age": 30
        }
        """

        guard let data = json.data(using: .utf8) else {
            XCTFail("JSON 字符串转 Data 失败")
            return
        }

        let user = DecoderTestUser.ls_decodeFromJSONData(data)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "456")
        XCTAssertEqual(user?.name, "李四")
        XCTAssertEqual(user?.age, 30)
    }

    func testCodableModeDecodeFromDictionary() {
        let dict: [String: Any] = [
            "id": "789",
            "name": "王五",
            "age": 35
        ]

        let user = DecoderTestUser.ls_decodeFromDictionary(dict)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "789")
        XCTAssertEqual(user?.name, "王五")
        XCTAssertEqual(user?.age, 35)
    }

    func testCodableModeDecodeArray() {
        let json = """
        [
            {
                "id": "1",
                "name": "张三",
                "age": 25
            },
            {
                "id": "2",
                "name": "李四",
                "age": 30
            },
            {
                "id": "3",
                "name": "王五",
                "age": 35
            }
        ]
        """

        let users = DecoderTestUser.ls_decodeArrayFromJSON(json)

        XCTAssertNotNil(users, "解码应该成功")
        XCTAssertEqual(users?.count, 3)
        XCTAssertEqual(users?[0].id, "1")
        XCTAssertEqual(users?[1].name, "李四")
        XCTAssertEqual(users?[2].age, 35)
    }

    // MARK: - 性能模式解码测试

    func testPerformanceModeDecodeFromString() {
        LSJSONDecoder.setMode(.performance)

        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        let user = DecoderTestUser.ls_decode(json)

        XCTAssertNotNil(user, "性能模式解码应该成功")
        XCTAssertEqual(user?.id, "123")
        XCTAssertEqual(user?.name, "张三")
        XCTAssertEqual(user?.age, 25)

        // 恢复默认模式
        LSJSONDecoder.setMode(.codable)
    }

    // MARK: - 错误处理测试

    func testDecodeInvalidJSON() {
        let invalidJSON = "{ invalid json }"

        let user = DecoderTestUser.ls_decode(invalidJSON)

        XCTAssertNil(user, "无效 JSON 应该返回 nil")
    }

    func testDecodeEmptyString() {
        let user = DecoderTestUser.ls_decode("")

        XCTAssertNil(user, "空字符串应该返回 nil")
    }

    func testDecodeMissingRequiredField() {
        let json = """
        {
            "id": "123"
        }
        """

        let user = DecoderTestUser.ls_decode(json)

        XCTAssertNil(user, "缺少必填字段应该返回 nil")
    }

    func testDecodeTypeMismatch() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": "invalid"
        }
        """

        let user = DecoderTestUser.ls_decode(json)

        XCTAssertNil(user, "类型不匹配应该返回 nil")
    }

    // MARK: - 嵌套对象测试

    func testDecodeNestedObject() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "address": {
                "street": "人民路",
                "city": "北京"
            }
        }
        """

        let user = DecoderTestUserWithAddress.ls_decode(json)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "123")
        XCTAssertEqual(user?.name, "张三")
        XCTAssertEqual(user?.address?.street, "人民路")
        XCTAssertEqual(user?.address?.city, "北京")
    }

    func testDecodeNestedArray() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "scores": [90, 85, 95]
        }
        """

        let user = DecoderTestUserWithScores.ls_decode(json)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "123")
        XCTAssertEqual(user?.scores?.count, 3)
        XCTAssertEqual(user?.scores?[0], 90)
    }

    // MARK: - 可选字段测试

    func testDecodeWithOptionalFields() {
        let json = """
        {
            "id": "123",
            "name": "张三"
        }
        """

        let user = DecoderTestUserOptional.ls_decode(json)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.id, "123")
        XCTAssertEqual(user?.name, "张三")
        XCTAssertNil(user?.email, "可选字段应该为 nil")
        XCTAssertNil(user?.age, "可选字段应该为 nil")
    }

    func testDecodeWithAllOptionalFields() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "email": "test@example.com",
            "age": 25
        }
        """

        let user = DecoderTestUserOptional.ls_decode(json)

        XCTAssertNotNil(user, "解码应该成功")
        XCTAssertEqual(user?.email, "test@example.com")
        XCTAssertEqual(user?.age, 25)
    }

    // MARK: - 数组解码测试

    func testDecodeEmptyArray() {
        let json = "[]"

        let users = DecoderTestUser.ls_decodeArrayFromJSON(json)

        XCTAssertNotNil(users, "解码应该成功")
        XCTAssertEqual(users?.count, 0)
    }

    func testDecodeInvalidArray() {
        let json = "[invalid]"

        let users = DecoderTestUser.ls_decodeArrayFromJSON(json)

        XCTAssertNil(users, "无效数组应该返回 nil")
    }

    // MARK: - 性能测试

    func testDecodePerformance() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        measure {
            for _ in 0..<1000 {
                _ = DecoderTestUser.ls_decode(json)
            }
        }
    }

    func testDecodeArrayPerformance() {
        let json = """
        [
            {"id": "1", "name": "张三", "age": 25},
            {"id": "2", "name": "李四", "age": 30},
            {"id": "3", "name": "王五", "age": 35},
            {"id": "4", "name": "赵六", "age": 40},
            {"id": "5", "name": "钱七", "age": 45}
        ]
        """

        measure {
            for _ in 0..<1000 {
                _ = DecoderTestUser.ls_decodeArrayFromJSON(json)
            }
        }
    }
}

// MARK: - Test Models

/// 解码测试用户模型
struct DecoderTestUser: Codable {
    let id: String
    let name: String
    let age: Int
}

/// 带地址的用户模型
struct DecoderTestUserWithAddress: Codable {
    let id: String
    let name: String
    let address: DecoderTestAddress?
}

struct DecoderTestAddress: Codable {
    let street: String
    let city: String
}

/// 带成绩的用户模型
struct DecoderTestUserWithScores: Codable {
    let id: String
    let name: String
    let scores: [Int]?
}

/// 可选字段用户模型
struct DecoderTestUserOptional: Codable {
    let id: String
    let name: String
    let email: String?
    let age: Int?
}
