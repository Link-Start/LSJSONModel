//
//  LSJSONArchiverTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 归档解档测试
final class LSJSONArchiverTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 创建临时目录用于测试
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LSJSONModelTests")
            .appendingPathComponent(UUID().uuidString)

        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        // 清理临时目录
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    private var tempDirectory: URL!

    // MARK: - 归档到 Data 测试

    func testArchiveData() {
        let user = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = user.ls_archiveData()

        XCTAssertNotNil(data, "归档应该成功")
        XCTAssertGreaterThan(data?.count ?? 0, 0, "数据应该非空")
    }

    func testArchiveDataWithAllFields() {
        let user = ArchiverTestUser(
            id: "456",
            name: "李四",
            age: 30
        )

        let data = user.ls_archiveData()

        XCTAssertNotNil(data, "归档应该成功")

        // 验证可以解档
        if let archivedData = data {
            let restored = ArchiverTestUser.ls_unarchive(from: archivedData)

            XCTAssertNotNil(restored, "解档应该成功")
            XCTAssertEqual(restored?.id, "456")
            XCTAssertEqual(restored?.name, "李四")
            XCTAssertEqual(restored?.age, 30)
        }
    }

    func testArchiveDataWithOptionalFields() {
        let user = ArchiverTestUserOptional(
            id: "789",
            name: "王五"
        )

        let data = user.ls_archiveData()

        XCTAssertNotNil(data, "归档应该成功")

        if let archivedData = data {
            let restored = ArchiverTestUserOptional.ls_unarchive(from: archivedData)

            XCTAssertNotNil(restored, "解档应该成功")
            XCTAssertEqual(restored?.id, "789")
            XCTAssertEqual(restored?.name, "王五")
            XCTAssertNil(restored?.email)
            XCTAssertNil(restored?.age)
        }
    }

    // MARK: - 从 Data 解档测试

    func testUnarchiveData() {
        let original = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = original.ls_archiveData()
        XCTAssertNotNil(data, "归档应该成功")

        if let archivedData = data {
            let restored = ArchiverTestUser.ls_unarchive(from: archivedData)

            XCTAssertNotNil(restored, "解档应该成功")
            XCTAssertEqual(restored?.id, "123")
            XCTAssertEqual(restored?.name, "张三")
            XCTAssertEqual(restored?.age, 25)
        }
    }

    func testUnarchiveInvalidData() {
        let invalidData = Data([0x00, 0x01, 0x02])

        let restored = ArchiverTestUser.ls_unarchive(from: invalidData)

        XCTAssertNil(restored, "无效数据应该返回 nil")
    }

    func testUnarchiveEmptyData() {
        let emptyData = Data()

        let restored = ArchiverTestUser.ls_unarchive(from: emptyData)

        XCTAssertNil(restored, "空数据应该返回 nil")
    }

    // MARK: - 归档到文件测试

    func testArchiveFile() {
        let user = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let filePath = tempDirectory.appendingPathComponent("user.archive")

        let success = user.ls_archiveFile(to: filePath.path)

        XCTAssertTrue(success, "归档应该成功")
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path), "文件应该存在")

        // 验证文件大小
        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath.path),
           let fileSize = attributes[.size] as? UInt64 {
            XCTAssertGreaterThan(fileSize, 0, "文件应该非空")
        }
    }

    func testArchiveFileToExistingPath() {
        let user = ArchiverTestUser(
            id: "456",
            name: "李四",
            age: 30
        )

        let filePath = tempDirectory.appendingPathComponent("user_overwrite.archive")

        // 第一次归档
        let success1 = user.ls_archiveFile(to: filePath.path)
        XCTAssertTrue(success1, "第一次归档应该成功")

        // 修改数据后再次归档
        let updatedUser = ArchiverTestUser(
            id: "789",
            name: "王五",
            age: 35
        )

        let success2 = updatedUser.ls_archiveFile(to: filePath.path)
        XCTAssertTrue(success2, "覆盖归档应该成功")

        // 验证是最新的数据
        let restored = ArchiverTestUser.ls_unarchive(from: filePath.path)
        XCTAssertEqual(restored?.id, "789", "应该是覆盖后的数据")
    }

    func testArchiveFileToInvalidPath() {
        let user = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        // 无效路径
        let invalidPath = "/invalid/path/user.archive"

        let success = user.ls_archiveFile(to: invalidPath)

        XCTAssertFalse(success, "无效路径应该归档失败")
    }

    // MARK: - 从文件解档测试

    func testUnarchiveFromFile() {
        let original = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let filePath = tempDirectory.appendingPathComponent("user_unarchive.archive")

        // 先归档
        let archiveSuccess = original.ls_archiveFile(to: filePath.path)
        XCTAssertTrue(archiveSuccess, "归档应该成功")

        // 再解档
        let restored = ArchiverTestUser.ls_unarchive(from: filePath.path)

        XCTAssertNotNil(restored, "解档应该成功")
        XCTAssertEqual(restored?.id, "123")
        XCTAssertEqual(restored?.name, "张三")
        XCTAssertEqual(restored?.age, 25)
    }

    func testUnarchiveFromNonExistentFile() {
        let filePath = tempDirectory.appendingPathComponent("non_existent.archive")

        let restored = ArchiverTestUser.ls_unarchive(from: filePath.path)

        XCTAssertNil(restored, "不存在的文件应该返回 nil")
    }

    func testUnarchiveFromCorruptedFile() {
        let filePath = tempDirectory.appendingPathComponent("corrupted.archive")

        // 创建损坏的文件
        try? "corrupted data".write(to: filePath, atomically: true, encoding: .utf8)

        let restored = ArchiverTestUser.ls_unarchive(from: filePath.path)

        XCTAssertNil(restored, "损坏的文件应该返回 nil")
    }

    // MARK: - 数组归档解档测试

    func testArchiveArray() {
        let users = [
            ArchiverTestUser(id: "1", name: "张三", age: 25),
            ArchiverTestUser(id: "2", name: "李四", age: 30),
            ArchiverTestUser(id: "3", name: "王五", age: 35)
        ]

        let data = [ArchiverTestUser].ls_archiveArray(users)

        XCTAssertNotNil(data, "数组归档应该成功")
        XCTAssertGreaterThan(data?.count ?? 0, 0)
    }

    func testUnarchiveArray() {
        let original = [
            ArchiverTestUser(id: "1", name: "张三", age: 25),
            ArchiverTestUser(id: "2", name: "李四", age: 30),
            ArchiverTestUser(id: "3", name: "王五", age: 35)
        ]

        let data = [ArchiverTestUser].ls_archiveArray(original)
        XCTAssertNotNil(data, "数组归档应该成功")

        if let archivedData = data {
            let restored = [ArchiverTestUser].ls_unarchiveArray(from: archivedData)

            XCTAssertNotNil(restored, "数组解档应该成功")
            XCTAssertEqual(restored?.count, 3)
            XCTAssertEqual(restored?[0].id, "1")
            XCTAssertEqual(restored?[1].name, "李四")
            XCTAssertEqual(restored?[2].age, 35)
        }
    }

    func testArchiveEmptyArray() {
        let users: [ArchiverTestUser] = []

        let data = [ArchiverTestUser].ls_archiveArray(users)

        XCTAssertNotNil(data, "空数组归档应该成功")
    }

    func testUnarchiveEmptyArray() {
        let data = [ArchiverTestUser].ls_archiveArray([])
        XCTAssertNotNil(data, "空数组归档应该成功")

        if let archivedData = data {
            let restored = [ArchiverTestUser].ls_unarchiveArray(from: archivedData)

            XCTAssertNotNil(restored, "空数组解档应该成功")
            XCTAssertEqual(restored?.count, 0)
        }
    }

    // MARK: - 数组文件归档解档测试

    func testArchiveArrayToFile() {
        let users = [
            ArchiverTestUser(id: "1", name: "张三", age: 25),
            ArchiverTestUser(id: "2", name: "李四", age: 30)
        ]

        let filePath = tempDirectory.appendingPathComponent("users.archive")

        let success = [ArchiverTestUser].ls_archiveArray(users, to: filePath.path)

        XCTAssertTrue(success, "数组归档到文件应该成功")
        XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path), "文件应该存在")
    }

    func testUnarchiveArrayFromFile() {
        let original = [
            ArchiverTestUser(id: "1", name: "张三", age: 25),
            ArchiverTestUser(id: "2", name: "李四", age: 30),
            ArchiverTestUser(id: "3", name: "王五", age: 35)
        ]

        let filePath = tempDirectory.appendingPathComponent("users_array.archive")

        // 先归档
        let archiveSuccess = [ArchiverTestUser].ls_archiveArray(original, to: filePath.path)
        XCTAssertTrue(archiveSuccess, "数组归档应该成功")

        // 再解档
        let restored = [ArchiverTestUser].ls_unarchiveArray(from: filePath.path)

        XCTAssertNotNil(restored, "数组解档应该成功")
        XCTAssertEqual(restored?.count, 3)
        XCTAssertEqual(restored?[0].id, "1")
        XCTAssertEqual(restored?[1].name, "李四")
        XCTAssertEqual(restored?[2].age, 35)
    }

    // MARK: - NSCoding 类型扩展测试

    func testNSCodingTypeSupport() {
        let data = "test data".data(using: .utf8)

        let archived = data.ls_archiveData()
        XCTAssertNotNil(archived, "NSCoding 类型归档应该成功")

        if let archivedData = archived {
            let restored = Data.ls_unarchive(from: archivedData) as? Data

            XCTAssertNotNil(restored, "NSCoding 类型解档应该成功")
            let restoredString = String(data: restored!, encoding: .utf8)
            XCTAssertEqual(restoredString, "test data")
        }
    }

    // MARK: - 往返测试

    func testDataRoundTrip() {
        let original = ArchiverTestUser(
            id: "999",
            name: "测试用户",
            age: 99
        )

        // 归档
        let data = original.ls_archiveData()
        XCTAssertNotNil(data, "归档应该成功")

        // 解档
        let restored = ArchiverTestUser.ls_unarchive(from: data!)
        XCTAssertNotNil(restored, "解档应该成功")

        // 验证
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.name, original.name)
        XCTAssertEqual(restored?.age, original.age)
    }

    func testFileRoundTrip() {
        let original = ArchiverTestUser(
            id: "888",
            name: "文件测试",
            age: 88
        )

        let filePath = tempDirectory.appendingPathComponent("roundtrip.archive")

        // 归档到文件
        let archiveSuccess = original.ls_archiveFile(to: filePath.path)
        XCTAssertTrue(archiveSuccess, "归档应该成功")

        // 从文件解档
        let restored = ArchiverTestUser.ls_unarchive(from: filePath.path)
        XCTAssertNotNil(restored, "解档应该成功")

        // 验证
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.name, original.name)
        XCTAssertEqual(restored?.age, original.age)
    }

    // MARK: - 性能测试

    func testArchivePerformance() {
        let user = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        measure {
            for _ in 0..<1000 {
                _ = user.ls_archiveData()
            }
        }
    }

    func testUnarchivePerformance() {
        let user = ArchiverTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = user.ls_archiveData()

        measure {
            for _ in 0..<1000 {
                _ = ArchiverTestUser.ls_unarchive(from: data!)
            }
        }
    }

    func testLargeArrayArchivePerformance() {
        let users = (0..<1000).map { index in
            ArchiverTestUser(id: "\(index)", name: "User\(index)", age: index)
        }

        measure {
            _ = [ArchiverTestUser].ls_archiveArray(users)
        }
    }
}

// MARK: - Test Models

/// 归档测试用户模型
class ArchiverTestUser: NSObject, Codable, LSJSONArchiverCompatible {
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
        super.init()
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

/// 可选字段归档测试模型
class ArchiverTestUserOptional: NSObject, Codable, LSJSONArchiverCompatible {
    var id: String
    var name: String
    var email: String?
    var age: Int?

    init(id: String, name: String, email: String? = nil, age: Int? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.age = age
        super.init()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case age
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(age, forKey: .age)
    }

    override init() {
        self.id = ""
        self.name = ""
        super.init()
    }
}
