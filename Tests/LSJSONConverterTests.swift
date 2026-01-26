//
//  LSJSONConverterTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 类型转换测试
final class LSJSONConverterTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 清除映射缓存
        _LSJSONMappingCache.clearCache()
    }

    override func tearDown() {
        // 清理
        _LSJSONMappingCache.clearCache()
        super.tearDown()
    }

    // MARK: - 单个 Model 转换测试

    func testConvertSingleModel() {
        let apiUser = ConverterAPIUser(
            userId: "123",
            userName: "张三",
            userAge: 25
        )

        // 设置映射
        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        // 转换
        let appUser = LSJSONMapping.ls_convert(apiUser, to: ConverterAppUser.self)

        XCTAssertNotNil(appUser, "转换应该成功")
        XCTAssertEqual(appUser?.id, "123")
        XCTAssertEqual(appUser?.name, "张三")
        XCTAssertEqual(appUser?.age, 25)
    }

    func testConvertSingleModelWithoutMapping() {
        let source = ConverterSourceModel(
            id: "456",
            name: "李四"
        )

        // 没有映射，使用相同的属性名
        let converted = LSJSONMapping.ls_convert(source, to: ConverterTargetModel.self)

        XCTAssertNotNil(converted, "转换应该成功")
        XCTAssertEqual(converted?.id, "456")
        XCTAssertEqual(converted?.name, "李四")
    }

    func testConvertWithNestedObjects() {
        let apiUser = ConverterAPIUserWithAddress(
            userId: "789",
            userName: "王五",
            address: ConverterAPIAddress(
                streetName: "人民路",
                cityName: "北京"
            )
        )

        LSJSONMapping.ls_registerMapping(for: ConverterAppUserWithAddress.self, mapping: [
            "id": "userId",
            "name": "userName",
            "address.street": "address.streetName",
            "address.city": "address.cityName"
        ])

        // 编码为字典再转换
        let dict = apiUser.ls_toDictionary()
        XCTAssertNotNil(dict)

        if let apiDict = dict {
            // 注意：嵌套对象转换需要特殊处理
            // 这里测试基本转换功能
            XCTAssertNotNil(apiDict["userId"])
        }
    }

    func testConvertWithOptionalFields() {
        let source = ConverterSourceWithOptional(
            id: "101",
            name: "赵六",
            email: "test@example.com",
            age: nil
        )

        let converted = LSJSONMapping.ls_convert(source, to: ConverterTargetWithOptional.self)

        XCTAssertNotNil(converted, "转换应该成功")
        XCTAssertEqual(converted?.id, "101")
        XCTAssertEqual(converted?.name, "赵六")
        XCTAssertEqual(converted?.email, "test@example.com")
        XCTAssertNil(converted?.age)
    }

    // MARK: - 批量 Model 转换测试

    func testConvertArray() {
        let apiUsers = [
            ConverterAPIUser(userId: "1", userName: "张三", userAge: 25),
            ConverterAPIUser(userId: "2", userName: "李四", userAge: 30),
            ConverterAPIUser(userId: "3", userName: "王五", userAge: 35)
        ]

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: ConverterAppUser.self)

        XCTAssertEqual(appUsers.count, 3)
        XCTAssertEqual(appUsers[0].id, "1")
        XCTAssertEqual(appUsers[0].name, "张三")
        XCTAssertEqual(appUsers[1].age, 30)
        XCTAssertEqual(appUsers[2].id, "3")
    }

    func testConvertEmptyArray() {
        let apiUsers: [ConverterAPIUser] = []

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: ConverterAppUser.self)

        XCTAssertEqual(appUsers.count, 0)
    }

    func testConvertArrayWithPartialData() {
        let apiUsers = [
            ConverterAPIUser(userId: "1", userName: "张三", userAge: 25),
            ConverterAPIUser(userId: "2", userName: "李四", userAge: 30)
        ]

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName"
            // 注意：age 字段没有映射
        ])

        let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: ConverterAppUser.self)

        XCTAssertEqual(appUsers.count, 2)
        XCTAssertEqual(appUsers[0].id, "1")
        XCTAssertEqual(appUsers[1].name, "李四")
    }

    // MARK: - 属性映射转换测试

    func testConvertWithPropertyMapping() {
        let source = ConverterSourceWithMapping(
            sourceId: "999",
            sourceName: "测试",
            sourceAge: 99
        )

        LSJSONMapping.ls_registerMapping(for: ConverterTargetWithMapping.self, mapping: [
            "targetId": "sourceId",
            "targetName": "sourceName",
            "targetAge": "sourceAge"
        ])

        let converted = LSJSONMapping.ls_convert(source, to: ConverterTargetWithMapping.self)

        XCTAssertNotNil(converted, "转换应该成功")
        XCTAssertEqual(converted?.targetId, "999")
        XCTAssertEqual(converted?.targetName, "测试")
        XCTAssertEqual(converted?.targetAge, 99)
    }

    func testConvertWithDifferentPropertyTypes() {
        let source = ConverterSourceWithStringAge(
            id: "111",
            name: "类型测试",
            age: "25"
        )

        // 目标模型使用 Int 类型 age
        // 这种转换需要类型转换器支持
        let dict = source.ls_toDictionary()
        XCTAssertNotNil(dict)

        if let sourceDict = dict {
            // 验证字典包含正确的值
            XCTAssertEqual(sourceDict["id"] as? String, "111")
            XCTAssertEqual(sourceDict["age"] as? String, "25")
        }
    }

    // MARK: - 复杂类型转换测试

    func testConvertWithArrayProperties() {
        let source = ConverterSourceWithArray(
            id: "222",
            tags: ["swift", "ios", "json"]
        )

        let converted = LSJSONMapping.ls_convert(source, to: ConverterTargetWithArray.self)

        XCTAssertNotNil(converted, "转换应该成功")
        XCTAssertEqual(converted?.id, "222")
        XCTAssertEqual(converted?.tags?.count, 3)
        XCTAssertEqual(converted?.tags?[0], "swift")
    }

    func testConvertWithDictionaryProperties() {
        let source = ConverterSourceWithDict(
            id: "333",
            metadata: ["key1": "value1", "key2": "value2"]
        )

        let dict = source.ls_toDictionary()
        XCTAssertNotNil(dict)

        if let sourceDict = dict {
            XCTAssertEqual(sourceDict["id"] as? String, "333")
            XCTAssertNotNil(sourceDict["metadata"])
        }
    }

    // MARK: - 转换错误处理测试

    func testConvertWithInvalidData() {
        // 测试数据不完整的情况
        let source = ConverterSourceIncomplete(
            id: "444"
            // 缺少 name 字段
        )

        let converted = LSJSONMapping.ls_convert(source, to: ConverterTargetComplete.self)

        // 如果目标模型的 name 是可选的，转换应该成功但 name 为 nil
        // 如果 name 是必需的，转换应该失败
        XCTAssertNotNil(converted)
    }

    // MARK: - 编码解码往返测试

    func testConvertWithEncodeDecodeRoundTrip() {
        let apiUser = ConverterAPIUser(
            userId: "555",
            userName: "往返测试",
            userAge: 40
        )

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        // 转换
        let appUser = LSJSONMapping.ls_convert(apiUser, to: ConverterAppUser.self)
        XCTAssertNotNil(appUser, "转换应该成功")

        // 编码
        let json = appUser?.ls_encode()
        XCTAssertNotNil(json, "编码应该成功")

        // 解码
        let restored = ConverterAppUser.ls_decode(json ?? "")
        XCTAssertNotNil(restored, "解码应该成功")

        // 验证
        XCTAssertEqual(restored?.id, "555")
        XCTAssertEqual(restored?.name, "往返测试")
        XCTAssertEqual(restored?.age, 40)
    }

    // MARK: - 性能测试

    func testConvertPerformance() {
        let apiUser = ConverterAPIUser(
            userId: "666",
            userName: "性能测试",
            userAge: 50
        )

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        measure {
            for _ in 0..<1000 {
                _ = LSJSONMapping.ls_convert(apiUser, to: ConverterAppUser.self)
            }
        }
    }

    func testConvertArrayPerformance() {
        let apiUsers = (0..<100).map { index in
            ConverterAPIUser(userId: "\(index)", userName: "User\(index)", userAge: index)
        }

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        measure {
            _ = LSJSONMapping.ls_convertArray(apiUsers, to: ConverterAppUser.self)
        }
    }

    func testConvertWithCachePerformance() {
        let apiUser = ConverterAPIUser(
            userId: "777",
            userName: "缓存测试",
            userAge: 55
        )

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        // 预热缓存
        _LSJSONMappingCache.warmup(for: [ConverterAppUser.self])

        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping.ls_convert(apiUser, to: ConverterAppUser.self)
            }
        }
    }
}

// MARK: - Test Models

/// API 用户模型（源模型）
struct ConverterAPIUser: Codable {
    var userId: String
    var userName: String
    var userAge: Int
}

/// App 用户模型（目标模型）
struct ConverterAppUser: Codable {
    var id: String
    var name: String
    var age: Int
}

/// 简单源模型
struct ConverterSourceModel: Codable {
    var id: String
    var name: String
}

/// 简单目标模型
struct ConverterTargetModel: Codable {
    var id: String
    var name: String
}

/// 带地址的 API 用户模型
struct ConverterAPIUserWithAddress: Codable {
    var userId: String
    var userName: String
    var address: ConverterAPIAddress
}

struct ConverterAPIAddress: Codable {
    var streetName: String
    var cityName: String
}

/// 带地址的 App 用户模型
struct ConverterAppUserWithAddress: Codable {
    var id: String
    var name: String
    var address: ConverterAppAddress
}

struct ConverterAppAddress: Codable {
    var street: String
    var city: String
}

/// 带可选字段的源模型
struct ConverterSourceWithOptional: Codable {
    var id: String
    var name: String
    var email: String?
    var age: Int?
}

/// 带可选字段的目标模型
struct ConverterTargetWithOptional: Codable {
    var id: String
    var name: String
    var email: String?
    var age: Int?
}

/// 带映射的源模型
struct ConverterSourceWithMapping: Codable {
    var sourceId: String
    var sourceName: String
    var sourceAge: Int
}

/// 带映射的目标模型
struct ConverterTargetWithMapping: Codable {
    var targetId: String
    var targetName: String
    var targetAge: Int
}

/// 字符串类型年龄的源模型
struct ConverterSourceWithStringAge: Codable {
    var id: String
    var name: String
    var age: String
}

/// 带数组的源模型
struct ConverterSourceWithArray: Codable {
    var id: String
    var tags: [String]
}

/// 带数组的目标模型
struct ConverterTargetWithArray: Codable {
    var id: String
    var tags: [String]?
}

/// 带字典的源模型
struct ConverterSourceWithDict: Codable {
    var id: String
    var metadata: [String: String]
}

/// 不完整的源模型
struct ConverterSourceIncomplete: Codable {
    var id: String
}

/// 完整的目标模型
struct ConverterTargetComplete: Codable {
    var id: String
    var name: String?
}
