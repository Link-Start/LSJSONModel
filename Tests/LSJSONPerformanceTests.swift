//
//  LSJSONPerformanceTests.swift
//  LSJSONModelTests
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import XCTest
@testable import LSJSONModel

/// 性能测试
final class LSJSONPerformanceTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 清理缓存
        _LSJSONMappingCache.clearCache()
        LSJSONDecoderHP.clearCache()
    }

    override func tearDown() {
        // 清理
        _LSJSONMappingCache.clearCache()
        LSJSONDecoderHP.clearCache()
        super.tearDown()
    }

    // MARK: - 缓存性能测试

    func testMappingCacheHitRate() {
        // 设置映射
        LSJSONMapping.ls_registerMapping(for: PerformanceTestUser.self, mapping: [
            "id": "user_id",
            "name": "user_name",
            "age": "user_age"
        ])

        // 预热缓存
        _LSJSONMappingCache.warmup(for: [PerformanceTestUser.self])

        let statsBefore = _LSJSONMappingCache.getStats()

        // 执行查询
        for _ in 0..<1000 {
            _ = LSJSONMapping.ls_jsonKey(for: "id", in: PerformanceTestUser.self)
            _ = LSJSONMapping.ls_jsonKey(for: "name", in: PerformanceTestUser.self)
        }

        let statsAfter = _LSJSONMappingCache.getStats()

        // 验证缓存命中率
        let hitRate = Double(statsAfter.hitCount - statsBefore.hitCount) /
                     Double(statsAfter.hitCount - statsBefore.hitCount + statsAfter.missCount - statsBefore.missCount)

        XCTAssertGreaterThan(hitRate, 0.9, "缓存命中率应该超过 90%")
    }

    func testDecoderCacheEffectiveness() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        // 第一次解码（缓存未命中）
        _ = PerformanceTestUser.ls_decode(json)

        // 后续解码应该利用缓存
        measure {
            for _ in 0..<1000 {
                _ = PerformanceTestUser.ls_decode(json)
            }
        }
    }

    // MARK: - 解码性能测试

    func testDecodePerformanceSmallObject() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        measure {
            for _ in 0..<10000 {
                _ = PerformanceTestUser.ls_decode(json)
            }
        }
    }

    func testDecodePerformanceMediumObject() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25,
            "email": "test@example.com",
            "phone": "13800138000",
            "address": "北京市朝阳区",
            "city": "北京",
            "country": "中国",
            "zipCode": "100000"
        }
        """

        measure {
            for _ in 0..<10000 {
                _ = PerformanceTestUserFull.ls_decode(json)
            }
        }
    }

    func testDecodePerformanceLargeObject() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25,
            "email": "test@example.com",
            "phone": "13800138000",
            "address": "北京市朝阳区",
            "city": "北京",
            "country": "中国",
            "zipCode": "100000",
            "company": "测试公司",
            "title": "工程师",
            "department": "技术部",
            "salary": 10000.0,
            "startDate": "2020-01-01",
            "isActive": true,
            "score": 95.5,
            "level": 5
        }
        """

        measure {
            for _ in 0..<10000 {
                _ = PerformanceTestUserLarge.ls_decode(json)
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
                _ = PerformanceTestUser.ls_decodeArrayFromJSON(json)
            }
        }
    }

    func testDecodeLargeArrayPerformance() {
        let users = (0..<100).map { index in
            "{\"id\":\"\(index)\",\"name\":\"User\(index)\",\"age\":\(index % 100)}"
        }
        let json = "[\(users.joined(separator: ","))]"

        measure {
            for _ in 0..<100 {
                _ = PerformanceTestUser.ls_decodeArrayFromJSON(json)
            }
        }
    }

    // MARK: - 编码性能测试

    func testEncodePerformanceSmallObject() {
        let user = PerformanceTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        measure {
            for _ in 0..<10000 {
                _ = user.ls_encode()
            }
        }
    }

    func testEncodePerformanceMediumObject() {
        let user = PerformanceTestUserFull(
            id: "123",
            name: "张三",
            age: 25,
            email: "test@example.com",
            phone: "13800138000",
            address: "北京市朝阳区",
            city: "北京",
            country: "中国",
            zipCode: "100000"
        )

        measure {
            for _ in 0..<10000 {
                _ = user.ls_encode()
            }
        }
    }

    func testEncodeArrayPerformance() {
        let users = (0..<100).map { index in
            PerformanceTestUser(id: "\(index)", name: "User\(index)", age: index % 100)
        }

        measure {
            for _ in 0..<1000 {
                _ = [PerformanceTestUser].ls_encodeArrayToJSON(users)
            }
        }
    }

    // MARK: - 模式对比测试

    func testCodableVsPerformanceModeDecode() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        // Codable 模式
        LSJSONDecoder.setMode(.codable)
        let codableTime = measureTime {
            for _ in 0..<1000 {
                _ = PerformanceTestUser.ls_decode(json)
            }
        }

        // Performance 模式
        LSJSONDecoder.setMode(.performance)
        let performanceTime = measureTime {
            for _ in 0..<1000 {
                _ = PerformanceTestUser.ls_decode(json)
            }
        }

        #if DEBUG
        print("[Performance] Codable模式: \(codableTime)ms, Performance模式: \(performanceTime)ms")
        #endif

        // 恢复默认模式
        LSJSONDecoder.setMode(.codable)
    }

    func testCodableVsPerformanceModeEncode() {
        let user = PerformanceTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        // Codable 模式
        LSJSONEncoder.setMode(.codable)
        let codableTime = measureTime {
            for _ in 0..<1000 {
                _ = user.ls_encode()
            }
        }

        // Performance 模式
        LSJSONEncoder.setMode(.performance)
        let performanceTime = measureTime {
            for _ in 0..<1000 {
                _ = user.ls_encode()
            }
        }

        #if DEBUG
        print("[Performance] Codable模式编码: \(codableTime)ms, Performance模式编码: \(performanceTime)ms")
        #endif

        // 恢复默认模式
        LSJSONEncoder.setMode(.codable)
    }

    // MARK: - 映射性能测试

    func testMappingPerformance() {
        LSJSONMapping.ls_setGlobalMapping([
            "id": "user_id",
            "name": "user_name",
            "age": "user_age"
        ])

        // 预热缓存
        _LSJSONMappingCache.warmup(for: [PerformanceTestUser.self])

        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping.ls_jsonKey(for: "id", in: PerformanceTestUser.self)
                _ = LSJSONMapping.ls_jsonKey(for: "name", in: PerformanceTestUser.self)
                _ = LSJSONMapping.ls_jsonKey(for: "age", in: PerformanceTestUser.self)
            }
        }
    }

    func testSnakeCaseConversionPerformance() {
        measure {
            for _ in 0..<10000 {
                _ = LSJSONMapping._toSnakeCase("userName")
                _ = LSJSONMapping._toCamelCase("user_name")
            }
        }
    }

    // MARK: - 类型转换性能测试

    func testTypeConversionPerformance() {
        let apiUser = ConverterAPIUser(
            userId: "123",
            userName: "张三",
            userAge: 25
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

    func testArrayTypeConversionPerformance() {
        let apiUsers = (0..<100).map { index in
            ConverterAPIUser(userId: "\(index)", userName: "User\(index)", userAge: index % 100)
        }

        LSJSONMapping.ls_registerMapping(for: ConverterAppUser.self, mapping: [
            "id": "userId",
            "name": "userName",
            "age": "userAge"
        ])

        measure {
            for _ in 0..<100 {
                _ = LSJSONMapping.ls_convertArray(apiUsers, to: ConverterAppUser.self)
            }
        }
    }

    // MARK: - 归档解档性能测试

    func testArchivePerformance() {
        let user = PerformanceTestUser(
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
        let user = PerformanceTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        let data = user.ls_archiveData()

        measure {
            for _ in 0..<1000 {
                _ = PerformanceTestUser.ls_unarchive(from: data!)
            }
        }
    }

    func testArrayArchivePerformance() {
        let users = (0..<100).map { index in
            PerformanceTestUser(id: "\(index)", name: "User\(index)", age: index % 100)
        }

        measure {
            for _ in 0..<100 {
                _ = [PerformanceTestUser].ls_archiveArray(users)
            }
        }
    }

    // MARK: - 内存压力测试

    func testDecodeMemoryPressure() {
        let users = (0..<1000).map { index in
            "{\"id\":\"\(index)\",\"name\":\"User\(index)\",\"age\":\(index % 100)}"
        }
        let json = "[\(users.joined(separator: ","))]"

        measure {
            _ = PerformanceTestUser.ls_decodeArrayFromJSON(json)
        }
    }

    func testEncodeMemoryPressure() {
        let users = (0..<1000).map { index in
            PerformanceTestUser(id: "\(index)", name: "User\(index)", age: index % 100)
        }

        measure {
            _ = [PerformanceTestUser].ls_encodeArrayToJSON(users)
        }
    }

    // MARK: - 并发性能测试

    func testConcurrentDecodePerformance() {
        let json = """
        {
            "id": "123",
            "name": "张三",
            "age": 25
        }
        """

        measure {
            let queue = DispatchQueue.global(qos: .userInitiated)
            let group = DispatchGroup()

            for _ in 0..<100 {
                group.enter()
                queue.async {
                    _ = PerformanceTestUser.ls_decode(json)
                    group.leave()
                }
            }

            group.wait()
        }
    }

    func testConcurrentEncodePerformance() {
        let user = PerformanceTestUser(
            id: "123",
            name: "张三",
            age: 25
        )

        measure {
            let queue = DispatchQueue.global(qos: .userInitiated)
            let group = DispatchGroup()

            for _ in 0..<100 {
                group.enter()
                queue.async {
                    _ = user.ls_encode()
                    group.leave()
                }
            }

            group.wait()
        }
    }

    // MARK: - 辅助方法

    private func measureTime(block: () -> Void) -> TimeInterval {
        let start = Date()
        block()
        return Date().timeIntervalSince(start) * 1000
    }
}

// MARK: - Test Models

/// 性能测试用户模型
struct PerformanceTestUser: Codable {
    var id: String
    var name: String
    var age: Int
}

/// 完整性能测试用户模型
struct PerformanceTestUserFull: Codable {
    var id: String
    var name: String
    var age: Int
    var email: String
    var phone: String
    var address: String
    var city: String
    var country: String
    var zipCode: String
}

/// 大型性能测试用户模型
struct PerformanceTestUserLarge: Codable {
    var id: String
    var name: String
    var age: Int
    var email: String
    var phone: String
    var address: String
    var city: String
    var country: String
    var zipCode: String
    var company: String
    var title: String
    var department: String
    var salary: Double
    var startDate: String
    var isActive: Bool
    var score: Double
    var level: Int
}

/// 类型转换测试模型
struct ConverterAPIUser: Codable {
    var userId: String
    var userName: String
    var userAge: Int
}

struct ConverterAppUser: Codable {
    var id: String
    var name: String
    var age: Int
}
