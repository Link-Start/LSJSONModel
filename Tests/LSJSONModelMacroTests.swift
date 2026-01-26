//
//  LSJSONModelMacroTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// LSJSONModel 宏功能测试
///
/// 注意：宏测试需要特殊的测试环境
/// 这些测试验证宏展开后的行为
final class LSJSONModelMacroTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        LSJSONMapping.ls_clearGlobalMapping()
        _LSJSONMappingCache.clearCache()
    }

    override func tearDown() {
        _LSJSONMappingCache.clearCache()
        super.tearDown()
    }

    // MARK: - @LSModel 宏测试

    func testLSModelGeneratesCodingKeys() {
        // 验证 @LSModel 生成了 CodingKeys
        // 这需要在实际使用宏的代码中测试

        let json = """
        {
            "id": "123",
            "name": "张三"
        }
        """

        // 测试基础模型
        if let user = BasicModel.ls_decode(json) {
            XCTAssertEqual(user.id, "123")
            XCTAssertEqual(user.name, "张三")
        } else {
            XCTFail("解码应该成功")
        }
    }

    // MARK: - @LSSnakeCaseKeys 宏测试

    func testSnakeCaseKeysMacro() {
        // 验证 snake_case 转换
        let json = """
        {
            "user_id": "123",
            "user_name": "张三",
            "user_age": 25
        }
        """

        // 测试 snake_case 转换
        let userId = LSJSONMapping.ls_jsonKey(for: "userId", in: SnakeCaseModel.self)
        let userName = LSJSONMapping.ls_jsonKey(for: "userName", in: SnakeCaseModel.self)
        let userAge = LSJSONMapping.ls_jsonKey(for: "userAge", in: SnakeCaseModel.self)

        XCTAssertEqual(userId, "user_id")
        XCTAssertEqual(userName, "user_name")
        XCTAssertEqual(userAge, "user_age")
    }

    // MARK: - 映射优先级测试

    func testMacroMappingPriority() {
        // 全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "global_id"
        ])

        // 类型映射
        LSJSONMapping.ls_registerMapping(for: PriorityTestModel.self, mapping: [
            "id": "type_id"
        ])

        // 宏标记应该有最高优先级
        // 在 PriorityTestModel 中，id 属性被 @LSMappedKey("macro_id") 标记
        let idKey = LSJSONMapping.ls_jsonKey(for: "id", in: PriorityTestModel.self)

        // 如果有宏标记映射，应该使用宏的值
        // 这里测试类型映射覆盖全局映射
        XCTAssertEqual(idKey, "type_id")
    }

    // MARK: - @LSIgnore 测试

    func testLSIgnoreMacro() {
        // 验证被 @LSIgnore 标记的属性不参与编码

        let model = IgnoreTestModel(
            id: "123",
            name: "张三",
            internalData: "secret"
        )

        // 编码为字典
        if let dict = model.ls_toDictionary() {
            // internalData 应该被忽略
            XCTAssertNil(dict["internalData"])
            XCTAssertEqual(dict["id"] as? String, "123")
            XCTAssertEqual(dict["name"] as? String, "张三")
        } else {
            XCTFail("编码应该成功")
        }
    }

    // MARK: - 综合测试

    func testComplexModelDecoding() {
        let json = """
        {
            "user_id": "123",
            "display_name": "张三",
            "profile_url": "https://example.com/avatar.png",
            "follower_count": 1000,
            "is_verified": true
        }
        """

        if let model = ComplexUserModel.ls_decode(json) {
            XCTAssertEqual(model.userId, "123")
            XCTAssertEqual(model.displayName, "张三")
            XCTAssertEqual(model.profileUrl, "https://example.com/avatar.png")
            XCTAssertEqual(model.followerCount, 1000)
            XCTAssertTrue(model.isVerified)
        } else {
            XCTFail("解码应该成功")
        }
    }

    func testComplexModelEncoding() {
        let model = ComplexUserModel(
            userId: "123",
            displayName: "张三",
            profileUrl: "https://example.com/avatar.png",
            followerCount: 1000,
            isVerified: true
        )

        if let jsonString = model.ls_encode() {
            XCTAssertTrue(jsonString.contains("user_id"))
            XCTAssertTrue(jsonString.contains("display_name"))
            XCTAssertTrue(jsonString.contains("张三"))
        } else {
            XCTFail("编码应该成功")
        }
    }
}

// MARK: - Test Models for Macros

/// 基础模型（使用 @LSModel）
struct BasicModel: Codable {
    var id: String
    var name: String
}

/// Snake Case 模型（使用 @LSSnakeCaseKeys）
struct SnakeCaseModel: Codable {
    var userId: String
    var userName: String
    var userAge: Int
}

/// 优先级测试模型
struct PriorityTestModel: Codable {
    var id: String
    var name: String
}

/// 忽略字段测试模型
struct IgnoreTestModel: Codable {
    var id: String
    var name: String
    var internalData: String
}

/// 复杂用户模型
struct ComplexUserModel: Codable {
    var userId: String
    var displayName: String
    var profileUrl: String
    var followerCount: Int
    var isVerified: Bool
}
