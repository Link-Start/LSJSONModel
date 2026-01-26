//
//  _LSJSONMappingCache.swift
//  LSJSONModel/Sources/Macros
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start.
//

import Foundation

/// 映射缓存系统 - 确保高性能
///
/// 功能：
/// - 缓存类型映射关系
/// - 缓存反向映射关系
/// - 提供缓存预热和清除功能
internal final class _LSJSONMappingCache {

    // MARK: - Nested Types

    /// 缓存统计信息
    internal struct CacheStats {
        var typeMappingCount: Int
        var reverseMappingCount: Int
        var hitCount: Int
        var missCount: Int

        internal var hitRate: Double {
            let total = hitCount + missCount
            return total > 0 ? Double(hitCount) / Double(total) : 0
        }
    }

    // MARK: - Properties

    /// 类型映射缓存
    /// Key: "TypeName.propertyName", Value: MappingMetadata
    nonisolated(unsafe) private static var typeMappingCache: [String: LSJSONMapping.MappingMetadata] = [:]

    /// 反向映射缓存（JSON键 -> 属性名）
    /// Key: "TypeName.jsonKey", Value: propertyName
    nonisolated(unsafe) private static var reverseMappingCache: [String: String] = [:]

    /// 缓存统计
    nonisolated(unsafe) private static var stats = CacheStats(
        typeMappingCount: 0,
        reverseMappingCount: 0,
        hitCount: 0,
        missCount: 0
    )

    /// 线程安全锁
    private static let lock = NSLock()

    /// 缓存启用标志
    nonisolated(unsafe) private static var cacheEnabled = true

    // MARK: - Type Mapping Cache

    /// 获取类型映射（带缓存）
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - property: 属性名
    /// - Returns: 映射元数据，如果未缓存则返回 nil
    internal static func getMapping(for type: String, property: String) -> LSJSONMapping.MappingMetadata? {
        lock.lock()
        defer { lock.unlock() }

        guard cacheEnabled else { return nil }

        let key = "\(type).\(property)"
        if let cached = typeMappingCache[key] {
            stats.hitCount += 1
            return cached
        }

        stats.missCount += 1
        return nil
    }

    /// 设置类型映射缓存
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - property: 属性名
    ///   - metadata: 映射元数据
    internal static func setMapping(for type: String, property: String, metadata: LSJSONMapping.MappingMetadata) {
        lock.lock()
        defer { lock.unlock() }

        guard cacheEnabled else { return }

        let key = "\(type).\(property)"
        typeMappingCache[key] = metadata
        stats.typeMappingCount = typeMappingCache.count
    }

    /// 批量设置类型映射缓存
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - mappings: 属性名到元数据的映射字典
    internal static func setMappings(for type: String, mappings: [String: LSJSONMapping.MappingMetadata]) {
        lock.lock()
        defer { lock.unlock() }

        guard cacheEnabled else { return }

        for (property, metadata) in mappings {
            let key = "\(type).\(property)"
            typeMappingCache[key] = metadata
        }
        stats.typeMappingCount = typeMappingCache.count
    }

    // MARK: - Reverse Mapping Cache

    /// 获取反向映射缓存（JSON键 -> 属性名）
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - jsonKey: JSON 键名
    /// - Returns: 属性名，如果未缓存则返回 nil
    internal static func getReverseMapping(for type: String, jsonKey: String) -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard cacheEnabled else { return nil }

        let key = "\(type).\(jsonKey)"
        if let cached = reverseMappingCache[key] {
            stats.hitCount += 1
            return cached
        }

        stats.missCount += 1
        return nil
    }

    /// 设置反向映射缓存
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - jsonKey: JSON 键名
    ///   - property: 属性名
    internal static func setReverseMapping(for type: String, jsonKey: String, property: String) {
        lock.lock()
        defer { lock.unlock() }

        guard cacheEnabled else { return }

        let key = "\(type).\(jsonKey)"
        reverseMappingCache[key] = property
        stats.reverseMappingCount = reverseMappingCache.count
    }

    // MARK: - Cache Management

    /// 清除所有缓存
    internal static func clearCache() {
        lock.lock()
        defer { lock.unlock() }

        typeMappingCache.removeAll()
        reverseMappingCache.removeAll()

        // 重置统计
        stats.hitCount = 0
        stats.missCount = 0
        stats.typeMappingCount = 0
        stats.reverseMappingCount = 0

        #if DEBUG
        print("[LSJSONMappingCache] ✅ 所有缓存已清除")
        #endif
    }

    /// 清除特定类型的缓存
    ///
    /// - Parameter type: 类型名称
    internal static func clearCache(for type: String) {
        lock.lock()
        defer { lock.unlock() }

        let prefix = "\(type)."

        // 清除类型映射缓存
        typeMappingCache = typeMappingCache.filter { !$0.key.hasPrefix(prefix) }

        // 清除反向映射缓存
        reverseMappingCache = reverseMappingCache.filter { !$0.key.hasPrefix(prefix) }

        stats.typeMappingCount = typeMappingCache.count
        stats.reverseMappingCount = reverseMappingCache.count

        #if DEBUG
        print("[LSJSONMappingCache] ✅ 类型 [\(type)] 的缓存已清除")
        #endif
    }

    /// 清除特定属性的缓存
    ///
    /// - Parameters:
    ///   - type: 类型名称
    ///   - property: 属性名
    internal static func clearCache(for type: String, property: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = "\(type).\(property)"

        typeMappingCache.removeValue(forKey: key)
        reverseMappingCache.removeValue(forKey: key)

        stats.typeMappingCount = typeMappingCache.count
        stats.reverseMappingCount = reverseMappingCache.count

        #if DEBUG
        print("[LSJSONMappingCache] ✅ [\(type).\(property)] 的缓存已清除")
        #endif
    }

    // MARK: - Cache Warmup

    /// 预热缓存 - 启动时调用
    ///
    /// - Parameter types: 需要预热的类型列表
    internal static func warmup(for types: [Any.Type]) {
        lock.lock()
        defer { lock.unlock() }

        #if DEBUG
        print("[LSJSONMappingCache] 🔥 开始预热缓存，共 \(types.count) 个类型")
        #endif

        for type in types {
            let typeName = String(describing: type)

            // 获取类型映射并缓存
            let mappings = LSJSONMapping.ls_getMapping(for: type)
            for (property, jsonKey) in mappings {
                let metadata = LSJSONMapping.MappingMetadata(
                    jsonKey: jsonKey,
                    priority: LSJSONMapping.MappingPriority.type,
                    source: "warmup"
                )
                setMapping(for: typeName, property: property, metadata: metadata)
            }
        }

        #if DEBUG
        print("[LSJSONMappingCache] ✅ 缓存预热完成")
        printStats()
        #endif
    }

    /// 预热特定类型的缓存
    ///
    /// - Parameter type: 需要预热的类型
    internal static func warmup(for type: Any.Type) {
        warmup(for: [type])
    }

    // MARK: - Cache Control

    /// 启用缓存
    internal static func enableCache() {
        lock.lock()
        defer { lock.unlock() }

        cacheEnabled = true

        #if DEBUG
        print("[LSJSONMappingCache] ✅ 缓存已启用")
        #endif
    }

    /// 禁用缓存
    internal static func disableCache() {
        lock.lock()
        defer { lock.unlock() }

        cacheEnabled = false

        #if DEBUG
        print("[LSJSONMappingCache] ⚠️ 缓存已禁用")
        #endif
    }

    /// 检查缓存是否启用
    ///
    /// - Returns: true 表示启用，false 表示禁用
    internal static func isCacheEnabled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cacheEnabled
    }

    // MARK: - Statistics

    /// 获取缓存统计信息
    ///
    /// - Returns: 缓存统计信息
    internal static func getStats() -> CacheStats {
        lock.lock()
        defer { lock.unlock() }
        return stats
    }

    /// 打印缓存统计信息（仅在 DEBUG 模式）
    internal static func printStats() {
        #if DEBUG
        lock.lock()
        defer { lock.unlock() }

        print("========== LSJSONMappingCache 统计 ==========")
        print("类型映射缓存: \(stats.typeMappingCount)")
        print("反向映射缓存: \(stats.reverseMappingCount)")
        print("缓存命中次数: \(stats.hitCount)")
        print("缓存未命中次数: \(stats.missCount)")
        print("缓存命中率: \(String(format: "%.2f%%", stats.hitRate * 100))")
        print("===========================================")
        #endif
    }

    /// 重置统计信息
    internal static func resetStats() {
        lock.lock()
        defer { lock.unlock() }

        stats.hitCount = 0
        stats.missCount = 0

        #if DEBUG
        print("[LSJSONMappingCache] ✅ 统计信息已重置")
        #endif
    }
}
