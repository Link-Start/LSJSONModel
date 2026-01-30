//
//  LSJSONMethodCache.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//
//  Swift 6 严格并发模式重构版本
//

import Foundation

// MARK: - LSJSONMethodCacheState (Actor)

/// 方法缓存状态管理器（Actor）
/// 使用 actor 确保所有缓存访问的线程安全
private actor LSJSONMethodCacheState {
    // MARK: - Properties

    /// 属性元数据缓存
    /// 结构：[类型名称: [属性名: 属性元数据]]
    private(set) var propertyCache: [String: [String: _LSPropertyMetadata]] = [:]

    /// 方法缓存（移除 Any 类型，改为使用具体类型或移除此功能）
    /// 注：原设计使用 Any 类型不符合 Swift 6 Sendable 标准
    /// 这里暂时移除，如需要应使用类型擦除的 Sendable 包装器
    // private var methodCache: [String: Any] = [:]

    /// 映射缓存
    /// 结构：[类型名称: [属性名: JSON键]]
    private(set) var mappingCache: [String: [String: String]] = [:]

    /// 缓存统计
    private(set) var hitCount: Int = 0
    private(set) var missCount: Int = 0

    /// 缓存大小限制
    private let maxPropertyCacheSize = 500
    private let maxMappingCacheSize = 500

    // MARK: - Property Caching

    func getProperties(forType typeName: String, propertyName: String?) -> [_LSPropertyMetadata]? {
        // 检查缓存
        if let cached = propertyCache[typeName] {
            hitCount += 1
            if let propName = propertyName {
                return cached[propName].map { [$0] }
            }
            return Array(cached.values)
        }

        missCount += 1
        return nil
    }

    func setProperties(forType typeName: String, properties: [_LSPropertyMetadata]) {
        // 存入缓存
        if propertyCache.count >= maxPropertyCacheSize {
            _evictOldestProperties()
        }

        var propertyDict: [String: _LSPropertyMetadata] = [:]
        for prop in properties {
            propertyDict[prop.name] = prop
        }
        propertyCache[typeName] = propertyDict
    }

    // MARK: - Mapping Caching

    func getMapping(forType typeName: String, propertyName: String) -> String? {
        mappingCache[typeName]?[propertyName]
    }

    func setMappings(forType typeName: String, mappings: [String: String]) {
        if mappingCache.count >= maxMappingCacheSize {
            _evictOldestMappings()
        }

        mappingCache[typeName] = mappings
    }

    func removeMappings(forType typeName: String) {
        mappingCache.removeValue(forKey: typeName)
    }

    // MARK: - Cache Management

    func clearAll() {
        propertyCache.removeAll()
        mappingCache.removeAll()
        hitCount = 0
        missCount = 0
    }

    func clearProperties() {
        propertyCache.removeAll()
    }

    func clearMappings() {
        mappingCache.removeAll()
    }

    // MARK: - Statistics

    func getStats() -> MethodCacheStats {
        MethodCacheStats(
            propertyCacheCount: propertyCache.count,
            methodCacheCount: 0,  // 已移除 methodCache
            mappingCacheCount: mappingCache.count,
            hitCount: hitCount,
            missCount: missCount
        )
    }

    func resetStats() {
        hitCount = 0
        missCount = 0
    }

    // MARK: - Private Helpers

    private func _evictOldestProperties() {
        // 简化实现：移除一半
        let keysToRemove = Array(propertyCache.keys.prefix(maxPropertyCacheSize / 2))
        for key in keysToRemove {
            propertyCache.removeValue(forKey: key)
        }
    }

    private func _evictOldestMappings() {
        let keysToRemove = Array(mappingCache.keys.prefix(maxMappingCacheSize / 2))
        for key in keysToRemove {
            mappingCache.removeValue(forKey: key)
        }
    }
}

// MARK: - LSJSONMethodCache

/// 方法缓存管理器（Swift 6 重构版）
///
/// 提供类型反射和缓存功能，优化性能。
/// 使用 actor 确保所有状态访问的线程安全。
internal final class LSJSONMethodCache {

    // MARK: - Singleton

    /// 单例实例
    internal static let shared = LSJSONMethodCache()

    // MARK: - Properties

    /// 状态管理器（Actor）
    private let state = LSJSONMethodCacheState()

    // MARK: - Initialization

    private init() {
        // 预热常用类型
        _preheatCommonTypes()
    }

    // MARK: - Property Caching

    /// 获取类型的属性元数据
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名（可选）
    /// - Returns: 属性元数据数组或单个属性元数据
    internal func getProperties(for type: Any.Type, propertyName: String? = nil) -> [_LSPropertyMetadata]? {
        let typeName = _getTypeName(type)

        return get async {
            await state.getProperties(forType: typeName, propertyName: propertyName)
        }
    }

    /// 获取单个属性元数据
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: 属性元数据
    internal func getProperty(for type: Any.Type, propertyName: String) -> _LSPropertyMetadata? {
        return getProperties(for: type, propertyName: propertyName)?.first
    }

    /// 检查属性是否存在
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: 是否存在
    internal func hasProperty(in type: Any.Type, propertyName: String) -> Bool {
        return getProperty(for: type, propertyName: propertyName) != nil
    }

    // MARK: - Mapping Caching

    /// 获取映射缓存
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: JSON 键
    internal func getMapping(for type: Any.Type, propertyName: String) -> String? {
        let typeName = _getTypeName(type)

        return get async {
            await state.getMapping(forType: typeName, propertyName: propertyName)
        }
    }

    /// 缓存映射关系
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - mappings: 映射字典 [属性名: JSON键]
    internal func cacheMappings(for type: Any.Type, mappings: [String: String]) {
        let typeName = _getTypeName(type)

        Task {
            await state.setMappings(forType: typeName, mappings: mappings)
        }
    }

    /// 清除指定类型的映射缓存
    ///
    /// - Parameter type: 类型
    internal func removeMappings(for type: Any.Type) {
        let typeName = _getTypeName(type)

        Task {
            await state.removeMappings(forType: typeName)
        }
    }

    // MARK: - Cache Management

    /// 清除所有缓存
    internal func clearAll() {
        Task {
            await state.clearAll()
        }
    }

    /// 清除属性缓存
    internal func clearProperties() {
        Task {
            await state.clearProperties()
        }
    }

    /// 清除映射缓存
    internal func clearMappings() {
        Task {
            await state.clearMappings()
        }
    }

    // MARK: - Statistics

    /// 获取缓存统计
    ///
    /// - Returns: 统计信息
    internal func getStats() -> MethodCacheStats {
        get async {
            await state.getStats()
        }
    }

    /// 获取缓存命中率
    ///
    /// - Returns: 命中率（0.0 - 1.0）
    internal func getHitRate() -> Double {
        get async {
            let stats = await state.getStats()
            return stats.hitRate
        }
    }

    /// 重置统计
    internal func resetStats() {
        Task {
            await state.resetStats()
        }
    }

    // MARK: - Private Helpers

    /// 获取类型名称
    private func _getTypeName(_ type: Any.Type) -> String {
        return String(describing: type)
    }

    /// 预热常用类型
    private func _preheatCommonTypes() {
        // 预热常用类型可以减少首次使用的延迟
        // 这里我们不需要做什么，因为缓存是惰性加载的
    }
}

// MARK: - Convenience Extensions

extension LSJSONMethodCache {

    /// 预热指定类型的缓存
    ///
    /// - Parameter types: 要预热的类型列表
    internal static func warmup(types: [Any.Type]) {
        let cache = shared

        for type in types {
            // 预热属性缓存
            _ = cache.getProperties(for: type)
        }
    }

    /// 打印缓存统计（DEBUG 模式）
    internal static func printStats() {
        #if DEBUG
        Task {
            let stats = await shared.getStats()
            print("========== Method Cache Stats ==========")
            print("Property Cache: \(stats.propertyCacheCount)")
            print("Method Cache: \(stats.methodCacheCount)")
            print("Mapping Cache: \(stats.mappingCacheCount)")
            print("Hit Rate: \(String(format: "%.2f%%", stats.hitRate * 100))")
            print("Hits: \(stats.hitCount), Misses: \(stats.missCount)")
            print("=========================================")
        }
        #endif
    }
}
