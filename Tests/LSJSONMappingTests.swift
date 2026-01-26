//
//  LSJSONMappingTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 映射系统测试
final class LSJSONMappingTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 清除全局映射和缓存
        LSJSONMapping.ls_clearGlobalMapping()
        _LSJSONMappingCache.clearCache()
    }

    override func tearDown() {
        // 清理
        LSJSONMapping.ls_clearGlobalMapping()
        _LSJSONMappingCache.clearCache()
        super.tearDown()
    }

    // MARK: - 全局映射测试

    func testSetGlobalMapping() {
        let mapping = ["id": "user_id", "name": "user_name"]

        LSJSONMapping.ls_setGlobalMapping(mapping)

        let retrievedMapping = LSJSONMapping.ls_getGlobalMapping()
        XCTAssertEqual(retrievedMapping["id"], "user_id")
        XCTAssertEqual(retrievedMapping["name"], "user_name")
    }

    func testAddGlobalMapping() {
        // 设置初始映射
        LSJSONMapping.ls_setGlobalMapping(["id": "user_id"])

        // 添加映射
        LSJSONMapping.ls_addGlobalMapping(["name": "user_name", "age": "user_age"])

        let retrievedMapping = LSJSONMapping.ls_getGlobalMapping()
        XCTAssertEqual(retrievedMapping.count, 3)
        XCTAssertEqual(retrievedMapping["id"], "user_id")
        XCTAssertEqual(retrievedMapping["name"], "user_name")
        XCTAssertEqual(retrievedMapping["age"], "user_age")
    }

    func testClearGlobalMapping() {
        LSJSONMapping.ls_setGlobalMapping(["id": "user_id", "name": "user_name"])

        LSJSONMapping.ls_clearGlobalMapping()

        let retrievedMapping = LSJSONMapping.ls_getGlobalMapping()
        XCTAssertEqual(retrievedMapping.count, 0)
    }

    func testGetGlobalMapping() {
        LSJSONMapping.ls_setGlobalMapping(["id": "user_id"])

        let mapping = LSJSONMapping.ls_getGlobalMapping()

        XCTAssertNotNil(mapping)
        XCTAssertEqual(mapping["id"], "user_id")
    }

    // MARK: - 类型映射测试

    func testRegisterTypeMapping() {
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id",
            "name": "user_name"
        ])

        let jsonKey1 = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        let jsonKey2 = LSJSONMapping.ls_jsonKey(for: "name", in: MappingTestUser.self)

        XCTAssertEqual(jsonKey1, "user_id")
        XCTAssertEqual(jsonKey2, "user_name")
    }

    func testRemoveTypeMapping() {
        // 注册映射
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id"
        ])

        let keyBefore = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        XCTAssertEqual(keyBefore, "user_id")

        // 移除映射
        LSJSONMapping.ls_removeMapping(for: MappingTestUser.self)

        let keyAfter = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        XCTAssertEqual(keyAfter, "id", "移除后应该使用属性名")
    }

    // MARK: - 映射优先级测试

    func testMappingPriorityGlobalVsType() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping([
            "id": "global_id",
            "name": "global_name"
        ])

        // 设置类型映射
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "type_id"
        ])

        // 类型映射应该覆盖全局映射
        let idKey = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        let nameKey = LSJSONMapping.ls_jsonKey(for: "name", in: MappingTestUser.self)

        XCTAssertEqual(idKey, "type_id", "类型映射应该覆盖全局映射")
        XCTAssertEqual(nameKey, "global_name", "应该使用全局映射")
    }

    func testMappingPriorityMultipleTypes() {
        // 设置全局映射
        LSJSONMapping.ls_setGlobalMapping(["id": "global_id"])

        // 为不同类型注册不同的映射
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id"
        ])

        LSJSONMapping.ls_registerMapping(for: MappingTestProduct.self, mapping: [
            "id": "product_id"
        ])

        let userId = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        let productId = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestProduct.self)

        XCTAssertEqual(userId, "user_id")
        XCTAssertEqual(productId, "product_id")
    }

    // MARK: - Snake Case 转换测试

    func testToSnakeCase() {
        // camelCase -> snake_case
        XCTAssertEqual(LSJSONMapping._toSnakeCase("userName"), "user_name")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("userAge"), "user_age")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("createdAt"), "created_at")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("isActive"), "is_active")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("userID"), "user_id")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("URLString"), "url_string")

        // 单词
        XCTAssertEqual(LSJSONMapping._toSnakeCase("name"), "name")
        XCTAssertEqual(LSJSONMapping._toSnakeCase("id"), "id")
    }

    func testToCamelCase() {
        // snake_case -> camelCase
        XCTAssertEqual(LSJSONMapping._toCamelCase("user_name"), "userName")
        XCTAssertEqual(LSJSONMapping._toCamelCase("user_age"), "userAge")
        XCTAssertEqual(LSJSONMapping._toCamelCase("created_at"), "createdAt")
        XCTAssertEqual(LSJSONMapping._toCamelCase("is_active"), "isActive")

        // 单词
        XCTAssertEqual(LSJSONMapping._toCamelCase("name"), "name")
        XCTAssertEqual(LSJSONMapping._toCamelCase("id"), "id")
    }

    func testSnakeCaseRoundTrip() {
        let original = "userName"
        let snake = LSJSONMapping._toSnakeCase(original)
        let camel = LSJSONMapping._toCamelCase(snake)

        XCTAssertEqual(camel, original, "往返转换应该保持一致")
    }

    // MARK: - 反向映射测试

    func testReverseMapping() {
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id",
            "name": "user_name"
        ])

        let prop1 = LSJSONMapping.ls_propertyName(for: "user_id", in: MappingTestUser.self)
        let prop2 = LSJSONMapping.ls_propertyName(for: "user_name", in: MappingTestUser.self)
        let prop3 = LSJSONMapping.ls_propertyName(for: "unknown_key", in: MappingTestUser.self)

        XCTAssertEqual(prop1, "id")
        XCTAssertEqual(prop2, "name")
        XCTAssertEqual(prop3, "unknown_key", "未知键应该返回原值")
    }

    func testReverseMappingGlobal() {
        LSJSONMapping.ls_setGlobalMapping([
            "id": "global_id",
            "name": "global_name"
        ])

        let prop1 = LSJSONMapping.ls_propertyName(for: "global_id", in: MappingTestUser.self)
        let prop2 = LSJSONMapping.ls_propertyName(for: "global_name", in: MappingTestUser.self)

        XCTAssertEqual(prop1, "id")
        XCTAssertEqual(prop2, "name")
    }

    // MARK: - 映射缓存测试

    func testMappingCacheHit() {
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id"
        ])

        // 第一次查询（缓存未命中）
        let stats1 = _LSJSONMappingCache.getStats()
        let key1 = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)

        // 第二次查询（缓存命中）
        let stats2 = _LSJSONMappingCache.getStats()
        let key2 = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)

        XCTAssertEqual(key1, "user_id")
        XCTAssertEqual(key2, "user_id")
        XCTAssertEqual(stats2.hitCount, stats1.hitCount + 1, "应该有缓存命中")
    }

    func testClearMappingCache() {
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user_id"
        ])

        // 查询一次以填充缓存
        _ = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)

        // 清除缓存
        _LSJSONMappingCache.clearCache()

        let stats = _LSJSONMappingCache.getStats()
        XCTAssertEqual(stats.typeMappingCount, 0, "缓存应该被清除")
    }

    func testMappingCacheStats() {
        // 执行一些操作
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: ["id": "user_id"])
        _ = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        _ = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)

        let stats = _LSJSONMappingCache.getStats()

        XCTAssertGreaterThan(stats.hitCount, 0, "应该有缓存命中")
        XCTAssertGreaterThan(stats.typeMappingCount, 0, "应该有类型映射缓存")
    }

    // MARK: - 空值和边界测试

    func testEmptyMapping() {
        LSJSONMapping.ls_setGlobalMapping([:])

        let mapping = LSJSONMapping.ls_getGlobalMapping()
        XCTAssertEqual(mapping.count, 0)
    }

    func testNilJSONKeyWithoutMapping() {
        // 没有设置映射，应该返回属性名
        let key = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        XCTAssertEqual(key, "id")
    }

    func testEmptyPropertyName() {
        let key = LSJSONMapping.ls_jsonKey(for: "", in: MappingTestUser.self)
        XCTAssertEqual(key, "")
    }

    // MARK: - 特殊字符测试

    func testSpecialCharactersInMapping() {
        LSJSONMapping.ls_registerMapping(for: MappingTestUser.self, mapping: [
            "id": "user-id",
            "name": "user.name"
        ])

        let idKey = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
        let nameKey = LSJSONMapping.ls_jsonKey(for: "name", in: MappingTestUser.self)

        XCTAssertEqual(idKey, "user-id")
        XCTAssertEqual(nameKey, "user.name")
    }

    // MARK: - 性能测试

    func testMappingPerformance() {
        LSJSONMapping.ls_setGlobalMapping([
            "id": "user_id",
            "name": "user_name",
            "age": "user_age",
            "email": "email_address"
        ])

        // 预热缓存
        _LSJSONMappingCache.warmup(for: [MappingTestUser.self])

        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping.ls_jsonKey(for: "id", in: MappingTestUser.self)
                _ = LSJSONMapping.ls_jsonKey(for: "name", in: MappingTestUser.self)
            }
        }
    }

    func testSnakeCasePerformance() {
        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping._toSnakeCase("userName")
                _ = LSJSONMapping._toCamelCase("user_name")
            }
        }
    }
}

// MARK: - Test Models

/// 映射测试用户模型
struct MappingTestUser: Codable {
    var id: String
    var name: String
    var age: Int
}

/// 映射测试产品模型
struct MappingTestProduct: Codable {
    var id: String
    var name: String
    var price: Double
}
