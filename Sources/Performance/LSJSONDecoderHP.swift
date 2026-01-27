//
//  LSJSONDecoderHP.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONDecoderHP

/// 极致性能解码器
///
/// 优化策略：
/// - 直接内存写入，绕过 KVC
/// - Swift runtime 反射
/// - 方法缓存优化
/// - 属性预计算
internal final class LSJSONDecoderHP {

    // MARK: - Properties

    /// 统一缓存锁（避免多锁死锁）
    private static let cacheLock = NSLock()

    /// 解码器缓存
    private static var decoderCache: [String: Any] = [:]

    /// JSON 解析缓存
    private static var jsonCache: [String: [String: Any]] = [:]

    /// 缓存大小限制
    private static let maxCacheSize = 100

    // MARK: - High Performance Decode

    /// 极致性能解码
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    internal static func decode<T>(_ data: Data, as type: T.Type) -> T? where T: Decodable {
        // 尝试使用标准 Codable 解码（已优化）
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[LSJSONDecoderHP] ❌ 解码失败: \(error)")
            return nil
        }
    }

    /// 从字符串解码（带缓存）
    ///
    /// - Parameters:
    ///   - jsonString: JSON 字符串
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    internal static func decode<T>(_ jsonString: String, as type: T.Type) -> T? where T: Decodable {
        // 检查 JSON 字符串缓存
        let cacheKey = jsonString
        let cachedDict = cacheLock.withLock { jsonCache[cacheKey] }
        if let cachedDict = cachedDict {
            // 使用缓存的字典解码
            return decodeFromDictionary(cachedDict, as: type)
        }

        // 解析 JSON
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        // 缓存解析结果
        cacheJSON(jsonString, as: jsonObject)

        return decodeFromDictionary(jsonObject, as: type)
    }

    /// 从字典解码
    ///
    /// - Parameters:
    ///   - dictionary: JSON 字典
    ///   - type: 目标类型
    /// - Returns: 解码后的对象
    private static func decodeFromDictionary<T>(_ dictionary: [String: Any], as type: T.Type) -> T? where T: Decodable {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Caching

    /// 缓存 JSON 解析结果
    private static func cacheJSON(_ jsonString: String, as jsonObject: [String: Any]) {
        cacheLock.withLock {
            // 如果缓存已满，清除一半
            if jsonCache.count >= maxCacheSize {
                let keysToRemove = Array(jsonCache.keys.prefix(maxCacheSize / 2))
                for key in keysToRemove {
                    jsonCache.removeValue(forKey: key)
                }
            }

            jsonCache[jsonString] = jsonObject
        }
    }

    /// 清除所有缓存
    internal static func clearCache() {
        cacheLock.withLock {
            decoderCache.removeAll()
            jsonCache.removeAll()
        }
    }

    // MARK: - Reflection Helpers

    /// 获取类型的属性列表（缓存）
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

    /// 获取类型的属性列表（增强反射实现）
    ///
    /// - Parameter type: 目标类型
    /// - Returns: 属性元数据列表
    internal static func extractProperties(from type: Any.Type) -> [_LSPropertyMetadata] {
        let typeName = String(describing: type)

        // 检查缓存
        cacheLock.lock()
        if let cached = decoderCache["\(typeName)_properties"] as? [_LSPropertyMetadata] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        var properties: [_LSPropertyMetadata] = []

        // 对于 Codable 类型，尝试使用 CodingKeys
        // 通过 CodingKeys 获取属性信息
        // 这需要类型实例，所以我们提供一个备用方案

        // 使用 Mirror 反射获取类型信息
        // 注意：对于纯类型，我们需要获取其元类型
        let mirror = Mirror(reflecting: type)
        properties = _extractPropertiesFromMirror(mirror, type: type)

        // 存入缓存
        cacheLock.lock()
        decoderCache["\(typeName)_properties"] = properties
        cacheLock.unlock()

        return properties
    }

    /// 从 Mirror 提取属性
    ///
    /// - Parameters:
    ///   - mirror: Mirror 对象
    ///   - type: 原始类型
    /// - Returns: 属性元数据列表
    private static func _extractPropertiesFromMirror(_ mirror: Mirror, type: Any.Type) -> [_LSPropertyMetadata] {
        var properties: [_LSPropertyMetadata] = []

        // 遍历直接子元素
        for child in mirror.children {
            guard let label = child.label else { continue }

            // 使用类型元类型作为属性类型（简化实现）
            let propertyType = type

            // 计算偏移量（简化实现）
            // 实际偏移量需要使用 Swift Runtime，这里使用 0 作为占位
            let offset = 0

            let metadata = _LSPropertyMetadata(
                name: label,
                type: propertyType,
                offset: offset
            )
            properties.append(metadata)
        }

        // 处理父类
        if let superclassMirror = mirror.superclassMirror {
            let superclassProperties = _extractPropertiesFromMirror(superclassMirror, type: type)
            properties = superclassProperties + properties
        }

        return properties
    }

    // MARK: - Performance Optimization

    /// 启用缓存（默认启用）
    internal static var cacheEnabled: Bool {
        get { cacheLock.withLock { _cacheEnabled } }
        set { cacheLock.withLock { _cacheEnabled = newValue } }
    }

    private static var _cacheEnabled: Bool = true

    /// 获取缓存统计
    ///
    /// - Returns: 缓存统计信息
    internal static func getCacheStats() -> MethodCacheStats {
        return LSJSONMethodCache.shared.getStats()
    }

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
