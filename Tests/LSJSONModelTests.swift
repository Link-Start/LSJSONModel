//
//  LSJSONModelTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// LSJSONModel 基础测试
final class LSJSONModelTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 每个测试前清除全局映射
        LSJSONMapping.ls_clearGlobalMapping()
    }

    override func tearDown() {
        // 每个测试后清除缓存
        _LSJSONMappingCache.clearCache()
        super.tearDown()
    }

    // MARK: - 全局映射测试

    func testGlobalMapping() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "user_id"
        ])

        // 验证映射
        let jsonKey = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)
        XCTAssertEqual(jsonKey, "user_id", "全局映射应该生效")
    }

    func testGlobalMappingDecode() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "user_id",
            "name": "user_name"
        ])

        let json = """
        {
            "user_id": "123",
            "user_name": "张三"
        }
        """

        // 注意：这需要 Codable 实现，这里测试映射系统
        let jsonKey1 = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)
        let jsonKey2 = LSJSONMapping.ls_jsonKey(for: "name", in: TestUser.self)

        XCTAssertEqual(jsonKey1, "user_id")
        XCTAssertEqual(jsonKey2, "user_name")
    }

    // MARK: - 类型映射测试

    func testTypeMapping() {
        // 注册类型映射
        LSJSONMapping.ls_registerMapping(for: TestUser.self, mapping: [
            "id": "user_id",
            "name": "user_name"
        ])

        let jsonKey1 = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)
        let jsonKey2 = LSJSONMapping.ls_jsonKey(for: "name", in: TestUser.self)

        XCTAssertEqual(jsonKey1, "user_id")
        XCTAssertEqual(jsonKey2, "user_name")
    }

    // MARK: - 优先级测试

    func testMappingPriority() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "global_id",
            "name": "global_name"
        ])

        // 设置类型映射
        LSJSONMapping.ls_registerMapping(for: TestUser.self, mapping: [
            "id": "type_id",
            "age": "user_age"
        ])

        // 类型映射应该覆盖全局映射
        let idKey = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)
        let nameKey = LSJSONMapping.ls_jsonKey(for: "name", in: TestUser.self)
        let ageKey = LSJSONMapping.ls_jsonKey(for: "age", in: TestUser.self)

        XCTAssertEqual(idKey, "type_id", "类型映射应该覆盖全局映射")
        XCTAssertEqual(nameKey, "global_name", "应该使用全局映射")
        XCTAssertEqual(ageKey, "user_age", "应该使用类型映射")
    }

    // MARK: - Snake Case 转换测试

    func testSnakeCaseConversion() {
        // camelCase -> snake_case
        let snake1 = LSJSONMapping._toSnakeCase("userName")
        XCTAssertEqual(snake1, "user_name")

        let snake2 = LSJSONMapping._toSnakeCase("userAge")
        XCTAssertEqual(snake2, "user_age")

        let snake3 = LSJSONMapping._toSnakeCase("createdAt")
        XCTAssertEqual(snake3, "created_at")

        // snake_case -> camelCase
        let camel1 = LSJSONMapping._toCamelCase("user_name")
        XCTAssertEqual(camel1, "userName")

        let camel2 = LSJSONMapping._toCamelCase("created_at")
        XCTAssertEqual(camel2, "createdAt")
    }

    // MARK: - 反向映射测试

    func testReverseMapping() {
        LSJSONMapping.ls_registerMapping(for: TestUser.self, mapping: [
            "id": "user_id",
            "name": "user_name"
        ])

        let prop1 = LSJSONMapping.ls_propertyName(for: "user_id", in: TestUser.self)
        let prop2 = LSJSONMapping.ls_propertyName(for: "user_name", in: TestUser.self)
        let prop3 = LSJSONMapping.ls_propertyName(for: "unknown_key", in: TestUser.self)

        XCTAssertEqual(prop1, "id")
        XCTAssertEqual(prop2, "name")
        XCTAssertEqual(prop3, "unknown_key", "未知键应该返回原值")
    }

    // MARK: - 跨 Model 转换测试

    func testCrossModelConversion() {
        // 创建 APIUser
        let apiUser = APIUser(
            userId: "123",
            userName: "张三",
            userAge: 25
        )

        // 设置映射
        LSJSONMapping.ls_registerMapping(for: AppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        // 转换为 AppUser
        let appUser = LSJSONMapping.ls_convert(apiUser, to: AppUser.self)

        XCTAssertNotNil(appUser, "转换应该成功")
        XCTAssertEqual(appUser?.id, "123")
        XCTAssertEqual(appUser?.name, "张三")
        XCTAssertEqual(appUser?.age, 25)
    }

    func testCrossModelArrayConversion() {
        let apiUsers = [
            APIUser(userId: "1", userName: "张三", userAge: 25),
            APIUser(userId: "2", userName: "李四", userAge: 30)
        ]

        LSJSONMapping.ls_registerMapping(for: AppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: AppUser.self)

        XCTAssertEqual(appUsers.count, 2)
        XCTAssertEqual(appUsers[0].id, "1")
        XCTAssertEqual(appUsers[0].name, "张三")
        XCTAssertEqual(appUsers[1].id, "2")
        XCTAssertEqual(appUsers[1].name, "李四")
    }

    // MARK: - 映射缓存测试

    func testMappingCache() {
        // 注册映射
        LSJSONMapping.ls_registerMapping(for: TestUser.self, mapping: [
            "id": "user_id"
        ])

        // 第一次查询（缓存未命中）
        let key1 = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)

        // 第二次查询（缓存命中）
        let key2 = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)

        XCTAssertEqual(key1, "user_id")
        XCTAssertEqual(key2, "user_id")

        // 检查缓存统计
        let stats = _LSJSONMappingCache.getStats()
        XCTAssertGreaterThan(stats.hitCount, 0, "应该有缓存命中")
    }

    func testClearCache() {
        LSJSONMapping.ls_registerMapping(for: TestUser.self, mapping: [
            "id": "user_id"
        ])

        // 查询一次以填充缓存
        _ = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)

        // 清除缓存
        _LSJSONMappingCache.clearCache()

        let stats = _LSJSONMappingCache.getStats()
        XCTAssertEqual(stats.typeMappingCount, 0, "缓存应该被清除")
    }

    // MARK: - 归档解档测试

    func testArchiveData() {
        let user = TestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = user.ls_archiveData()

        XCTAssertNotNil(data, "归档应该成功")
        XCTAssertGreaterThan(data?.count ?? 0, 0, "数据应该非空")
    }

    func testUnarchiveData() {
        let original = TestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = original.ls_archiveData()
        XCTAssertNotNil(data, "归档应该成功")

        if let archivedData = data {
            let restored = TestUser.ls_unarchive(from: archivedData)

            XCTAssertNotNil(restored, "解档应该成功")
            XCTAssertEqual(restored?.id, "123")
            XCTAssertEqual(restored?.name, "张三")
            XCTAssertEqual(restored?.age, 25)
        }
    }

    // MARK: - 性能测试

    func testMappingPerformance() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "user_id",
            "name": "user_name",
            "age": "user_age",
            "email": "email_address"
        ])

        // 预热缓存
        _LSJSONMappingCache.warmup(for: [TestUser.self])

        // 测量查询性能
        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping.ls_jsonKey(for: "id", in: TestUser.self)
                _ = LSJSONMapping.ls_jsonKey(for: "name", in: TestUser.self)
            }
        }
    }
}

// MARK: - Test Models

/// 测试用用户模型
class TestUser: NSObject, Codable, LSJSONArchiverCompatible {
    var id: String
    var name: String
    var age: Int

    init(id: String, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
    }

    override init() {
        self.id = ""
        self.name = ""
        self.age = 0
        super.init()
    }
}

/// API 返回的用户模型
struct APIUser: Codable {
    var userId: String
    var userName: String
    var userAge: Int
}

/// App 内部使用的用户模型
struct AppUser: Codable {
    var id: String
    var name: String
    var age: Int
}
