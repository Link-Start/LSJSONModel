//
//  LSJSONModelMJExtensionTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-26.
//  Copyright © 2026 link-start. All rights reserved.
//
//  MJExtension 风格 API 测试
//

import XCTest
@testable import LSJSONModel

// MARK: - 测试模型

class TestUserMJ: NSObject, Codable, LSJSONModelMappingProvider {
    var userId: String = ""
    var userName: String = ""
    var age: Int = 0

    // MJExtension 风格的映射
    static func ls_replacedKeyFromPropertyName() -> [String: String] {
        return [
            "userId": "user_id",
            "userName": "user_name"
        ]
    }

    // CodingKeys (支持 Codable)
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case age
    }
}

struct TestUserStructMJ: Codable {
    var userId: String
    var userName: String
    var age: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case age
    }
}

// MARK: - MJExtension 风格 API 测试

class LSJSONModelMJExtensionTests: XCTestCase {

    // MARK: - ls_objectWithKeyValues

    func testObjectWithKeyValuesFromDictionary() {
        let dict: [String: Any] = [
            "user_id": "123",
            "user_name": "张三",
            "age": 25
        ]

        // Class 类型
        let userClass = TestUserMJ.ls_objectWithKeyValues(dict)
        XCTAssertNotNil(userClass)
        XCTAssertEqual(userClass?.userId, "123")
        XCTAssertEqual(userClass?.userName, "张三")
        XCTAssertEqual(userClass?.age, 25)

        // Struct 类型
        let userStruct = TestUserStructMJ.ls_objectWithKeyValues(dict)
        XCTAssertNotNil(userStruct)
        XCTAssertEqual(userStruct?.userId, "123")
        XCTAssertEqual(userStruct?.userName, "张三")
        XCTAssertEqual(userStruct?.age, 25)
    }

    func testObjectWithKeyValuesFromJSONString() {
        let jsonString = """
        {
            "user_id": "456",
            "user_name": "李四",
            "age": 30
        }
        """

        let user = TestUserMJ.ls_objectWithKeyValues(jsonString)
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, "456")
        XCTAssertEqual(user?.userName, "李四")
        XCTAssertEqual(user?.age, 30)
    }

    func testObjectWithKeyValuesFromJSONData() {
        let jsonString = """
        {
            "user_id": "789",
            "user_name": "王五",
            "age": 35
        }
        """

        if let data = jsonString.data(using: .utf8) {
            let user = TestUserMJ.ls_objectWithKeyValues(data)
            XCTAssertNotNil(user)
            XCTAssertEqual(user?.userId, "789")
            XCTAssertEqual(user?.userName, "王五")
            XCTAssertEqual(user?.age, 35)
        }
    }

    // MARK: - ls_keyValues

    func testKeyValues() {
        let user = TestUserMJ()
        user.userId = "123"
        user.userName = "张三"
        user.age = 25

        let dict = user.ls_keyValues
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["userId"] as? String, "123")
        XCTAssertEqual(dict?["userName"] as? String, "张三")
        XCTAssertEqual(dict?["age"] as? Int, 25)
    }

    // MARK: - ls_JSONString

    func testJSONString() {
        let user = TestUserMJ()
        user.userId = "123"
        user.userName = "张三"
        user.age = 25

        let jsonString = user.ls_JSONString
        XCTAssertNotNil(jsonString)

        // 验证 JSON 字符串包含正确的内容
        if let data = jsonString?.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["userId"] as? String, "123")
            XCTAssertEqual(json["userName"] as? String, "张三")
            XCTAssertEqual(json["age"] as? Int, 25)
        }
    }

    // MARK: - ls_setKeyValues (仅 class)

    func testSetKeyValues() {
        let user = TestUserMJ()
        user.userId = "000"
        user.userName = "原始"

        let dict: [String: Any] = [
            "user_id": "999",
            "user_name": "更新后",
            "age": 40
        ]

        let success = user.ls_setKeyValues(dict)
        XCTAssertTrue(success)
        XCTAssertEqual(user.userId, "999")
        XCTAssertEqual(user.userName, "更新后")
        XCTAssertEqual(user.age, 40)
    }

    // MARK: - 数组操作

    func testObjectArrayWithKeyValuesArray() {
        let array: [[String: Any]] = [
            ["user_id": "1", "user_name": "用户1", "age": 20],
            ["user_id": "2", "user_name": "用户2", "age": 25],
            ["user_id": "3", "user_name": "用户3", "age": 30]
        ]

        let users = TestUserMJ.ls_objectArrayWithKeyValuesArray(array)
        XCTAssertNotNil(users)
        XCTAssertEqual(users?.count, 3)
        XCTAssertEqual(users?[0].userId, "1")
        XCTAssertEqual(users?[1].userName, "用户2")
        XCTAssertEqual(users?[2].age, 30)
    }

    func testKeyValuesArray() {
        let users = [
            TestUserMJ().then { $0.userId = "1"; $0.userName = "用户1"; $0.age = 20 },
            TestUserMJ().then { $0.userId = "2"; $0.userName = "用户2"; $0.age = 25 }
        ]

        let dicts = users.ls_keyValuesArray
        XCTAssertNotNil(dicts)
        XCTAssertEqual(dicts?.count, 2)
        XCTAssertEqual(dicts?[0]["userId"] as? String, "1")
        XCTAssertEqual(dicts?[1]["userName"] as? String, "用户2")
    }

    func testJSONStringArray() {
        let users = [
            TestUserMJ().then { $0.userId = "1"; $0.userName = "用户1"; $0.age = 20 },
            TestUserMJ().then { $0.userId = "2"; $0.userName = "用户2"; $0.age = 25 }
        ]

        let jsonString = users.ls_JSONStringArray
        XCTAssertNotNil(jsonString)

        // 验证 JSON 数组字符串
        if let data = jsonString?.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            XCTAssertEqual(array.count, 2)
            XCTAssertEqual(array[0]["userId"] as? String, "1")
            XCTAssertEqual(array[1]["userName"] as? String, "用户2")
        }
    }

    // MARK: - 文件操作

    func testWriteToFile() {
        let user = TestUserMJ()
        user.userId = "123"
        user.userName = "张三"
        user.age = 25

        let path = NSTemporaryDirectory() + "test_user.json"

        // 写入文件
        let success = user.ls_writeToFile(path)
        XCTAssertTrue(success)

        // 读取验证
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["userId"] as? String, "123")
            XCTAssertEqual(json["userName"] as? String, "张三")
        }

        // 清理
        try? FileManager.default.removeItem(atPath: path)
    }

    func testObjectWithFile() {
        let user = TestUserMJ()
        user.userId = "456"
        user.userName = "李四"
        user.age = 30

        let path = NSTemporaryDirectory() + "test_user_read.json"

        // 先写入文件
        _ = user.ls_writeToFile(path)

        // 读取文件
        let readUser = TestUserMJ.ls_objectWithFile(path)
        XCTAssertNotNil(readUser)
        XCTAssertEqual(readUser?.userId, "456")
        XCTAssertEqual(readUser?.userName, "李四")
        XCTAssertEqual(readUser?.age, 30)

        // 清理
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - 归档解档

    func testArchiveToFile() {
        let user = TestUserMJ()
        user.userId = "789"
        user.userName = "王五"
        user.age = 35

        let path = NSTemporaryDirectory() + "test_user.archive"

        // 归档到文件
        let success = user.ls_archiveToFile(path)
        XCTAssertTrue(success)

        // 验证文件存在
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))

        // 从文件解档
        let unarchivedUser = TestUserMJ.ls_unarchiveFromFile(path)
        XCTAssertNotNil(unarchivedUser)
        XCTAssertEqual(unarchivedUser?.userId, "789")
        XCTAssertEqual(unarchivedUser?.userName, "王五")
        XCTAssertEqual(unarchivedUser?.age, 35)

        // 清理
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - 往返测试

    func testRoundTrip() {
        let original = TestUserMJ()
        original.userId = "999"
        original.userName = "测试用户"
        original.age = 99

        // 转字典
        let dict = original.ls_keyValues
        XCTAssertNotNil(dict)

        // 字典转对象
        let restored = TestUserMJ.ls_objectWithKeyValues(dict!)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.userId, original.userId)
        XCTAssertEqual(restored?.userName, original.userName)
        XCTAssertEqual(restored?.age, original.age)
    }

    func testJSONRoundTrip() {
        let original = TestUserMJ()
        original.userId = "888"
        original.userName = "JSON测试"
        original.age = 88

        // 转 JSON 字符串
        let jsonString = original.ls_JSONString
        XCTAssertNotNil(jsonString)

        // JSON 字符串转对象
        let restored = TestUserMJ.ls_objectWithKeyValues(jsonString!)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.userId, original.userId)
        XCTAssertEqual(restored?.userName, original.userName)
        XCTAssertEqual(restored?.age, original.age)
    }
}

// MARK: - 辅助方法

extension NSObject {
    @discardableResult
    func then(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}
