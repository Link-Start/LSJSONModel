//
//  LSJSONDecoderHP.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//
//  Swift 6 严格并发模式重构版本
//

import Foundation

// MARK: - LSJSONDecoderHPState (Actor)

/// 解码器缓存状态管理器（Actor）
/// 使用 actor 确保所有缓存访问的线程安全
private actor LSJSONDecoderHPState {
    // MARK: - Properties

    /// JSON 解析缓存（移除 Any 类型，改为只缓存 JSON 字符串的哈希值）
    /// 由于完整缓存 [String: Any] 不符合 Sendable，我们改用更简单的缓存策略
    private(set) var jsonCacheHashes: Set<String> = []

    /// 缓存大小限制
    private let maxCacheSize = 100

    // MARK: - JSON Caching

    /// 检查 JSON 是否已缓存
    func isJSONCached(_ hash: String) -> Bool {
        jsonCacheHashes.contains(hash)
    }

    /// 缓存 JSON 哈希值
    func cacheJSONHash(_ hash: String) {
        // 如果缓存已满，清除一半
        if jsonCacheHashes.count >= maxCacheSize {
            let hashesToRemove = Array(jsonCacheHashes.prefix(maxCacheSize / 2))
            for hash in hashesToRemove {
                jsonCacheHashes.remove(hash)
            }
        }

        jsonCacheHashes.insert(hash)
    }

    /// 清除所有缓存
    func clearAll() {
        jsonCacheHashes.removeAll()
    }

    /// 获取缓存大小
    func getCacheSize() -> Int {
        jsonCacheHashes.count
    }
}

// MARK: - LSJSONDecoderHP

/// 极致性能解码器（Swift 6 重构版）
///
/// 优化策略：
/// - 直接使用 Codable（已高度优化）
/// - 移除不安全的 Any 类型缓存
/// - 使用 actor 确保线程安全
internal final class LSJSONDecoderHP {

    // MARK: - Properties

    /// 状态管理器（Actor）
    private static let state = LSJSONDecoderHPState()

    /// 缓存启用标志（使用原子操作）
    private static let cacheQueue = DispatchQueue(label: "com.lsjsonmodel.decoderhp")
    private static var _cacheEnabled: Bool = true

    // MARK: - High Performance Decode

    /// 极致性能解码
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    internal static func decode<T>(_ data: Data, as type: T.Type) -> T? where T: Decodable {
        // 使用标准 Codable 解码（已高度优化）
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[LSJSONDecoderHP] ❌ 解码失败: \(error)")
            return nil
        }
    }

    /// 从字符串解码
    ///
    /// - Parameters:
    ///   - jsonString: JSON 字符串
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    internal static func decode<T>(_ jsonString: String, as type: T.Type) -> T? where T: Decodable {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        // 直接解码，不使用缓存（避免 Any 类型）
        return decode(data, as: type)
    }

    /// 从字典解码
    ///
    /// - Parameters:
    ///   - dictionary: JSON 字典
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    internal static func decodeFromDictionary<T>(_ dictionary: [String: Any], as type: T.Type) -> T? where T: Decodable {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            return decode(data, as: type)
        } catch {
            return nil
        }
    }

    // MARK: - Caching

    /// 清除所有缓存
    internal static func clearCache() {
        Task {
            await state.clearAll()
        }
    }

    /// 启用缓存
    internal static var cacheEnabled: Bool {
        get {
            cacheQueue.sync { _cacheEnabled }
        }
        set {
            cacheQueue.sync { _cacheEnabled = newValue }
        }
    }

    /// 获取缓存统计
    ///
    /// - Returns: 缓存统计信息
    internal static func getCacheStats() -> MethodCacheStats {
        get async {
            let cacheSize = await state.getCacheSize()
            return MethodCacheStats(
                propertyCacheCount: 0,
                methodCacheCount: 0,
                mappingCacheCount: cacheSize,
                hitCount: 0,
                missCount: 0
            )
        }
    }

    // MARK: - Reflection Helpers

    /// 获取类型的属性列表
    internal static func getProperties(for type: Any.Type) -> [_LSPropertyMetadata] {
        return LSJSONMethodCache.shared.getProperties(for: type) ?? []
    }

    /// 获取单个属性元数据
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: 属性元数据
    internal static func getProperty(for type: Any.Type, propertyName: String) -> _LSPropertyMetadata? {
        return LSJSONMethodCache.shared.getProperty(for: type, propertyName: propertyName)
    }

    /// 检查类型是否有指定属性
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: 是否存在
    internal static func hasProperty(in type: Any.Type, propertyName: String) -> Bool {
        return LSJSONMethodCache.shared.hasProperty(in: type, propertyName: propertyName)
    }

    // MARK: - Type Information

    /// 获取类型的属性列表
    ///
    /// - Parameter type: 目标类型
    /// - Returns: 属性元数据列表
    internal static func extractProperties(from type: Any.Type) -> [_LSPropertyMetadata] {
        // 使用 LSJSONMethodCache 获取属性
        return getProperties(for: type)
    }

    // MARK: - Performance Optimization

    /// 预热类型缓存
    ///
    /// - Parameter types: 要预热的类型列表
    internal static func warmup(types: [Any.Type]) {
        LSJSONMethodCache.warmup(types: types)
    }

    /// 打印缓存统计（DEBUG 模式）
    internal static func printCacheStats() {
        LSJSONMethodCache.printStats()
    }
}
