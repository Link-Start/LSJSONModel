//
//  LSJSONMethodCache.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONMethodCache

/// 方法缓存管理器
///
/// 提供类型反射和方法调用的缓存功能，优化性能。
///
/// 功能：
/// - 属性元数据缓存
/// - 编码/解码方法缓存
/// - 映射关系缓存
/// - 线程安全访问（使用串行队列）
internal final class LSJSONMethodCache {

    // MARK: - Singleton

    /// 单例实例
    internal static let shared = LSJSONMethodCache()

    // MARK: - Properties

    /// 串行队列，确保所有操作线程安全
    private let cacheQueue = DispatchQueue(
        label: "com.lsjsonmodel.cache"
    )

    /// 属性元数据缓存
    /// 结构：[类型名称: [属性名: 属性元数据]]
    private var propertyCache: [String: [String: _LSPropertyMetadata]] = [:]

    /// 方法缓存
    /// 结构：[类型名称 + 方法名: 方法实现]
    private var methodCache: [String: Any] = [:]

    /// 映射缓存
    /// 结构：[类型名称: [属性名: JSON键]]
    private var mappingCache: [String: [String: String]] = [:]

    /// 缓存统计
    private var hitCount: Int = 0
    private var missCount: Int = 0

    /// 缓存大小限制
    private let maxPropertyCacheSize = 500
    private let maxMethodCacheSize = 1000
    private let maxMappingCacheSize = 500

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
        return cacheQueue.sync {
            let typeName = _getTypeName(type)

            // 检查缓存
            if let cached = propertyCache[typeName] {
                hitCount += 1
                if let propName = propertyName {
                    return cached[propName].map { [$0] }
                }
                return Array(cached.values)
            }

            missCount += 1

            // 使用反射获取属性
            let properties = _extractProperties(from: type)

            // 存入缓存
            if propertyCache.count >= maxPropertyCacheSize {
                _evictOldestProperties()
            }

            var propertyDict: [String: _LSPropertyMetadata] = [:]
            for prop in properties {
                propertyDict[prop.name] = prop
            }
            propertyCache[typeName] = propertyDict

            if let propName = propertyName {
                return propertyDict[propName].map { [$0] }
            }
            return properties
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

    // MARK: - Method Caching

    /// 获取缓存的编码方法
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - methodName: 方法名
    /// - Returns: 方法实现（如果有）
    internal func getEncodingMethod(for type: Any.Type, methodName: String) -> Any? {
        let key = _makeCacheKey(type: type, method: methodName)

        return cacheQueue.sync {
            if let cached = methodCache[key] {
                hitCount += 1
                return cached
            }

            missCount += 1
            return nil
        }
    }

    /// 缓存编码方法
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - methodName: 方法名
    ///   - implementation: 方法实现
    internal func cacheEncodingMethod(for type: Any.Type, methodName: String, implementation: Any) {
        cacheQueue.sync {
            let key = _makeCacheKey(type: type, method: methodName)

            if methodCache.count >= maxMethodCacheSize {
                _evictOldestMethods()
            }

            methodCache[key] = implementation
        }
    }

    /// 获取缓存的解码方法
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - methodName: 方法名
    /// - Returns: 方法实现（如果有）
    internal func getDecodingMethod(for type: Any.Type, methodName: String) -> Any? {
        // 解码方法与编码方法使用相同的缓存
        return getEncodingMethod(for: type, methodName: methodName)
    }

    /// 缓存解码方法
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - methodName: 方法名
    ///   - implementation: 方法实现
    internal func cacheDecodingMethod(for type: Any.Type, methodName: String, implementation: Any) {
        cacheEncodingMethod(for: type, methodName: methodName, implementation: implementation)
    }

    // MARK: - Mapping Caching

    /// 获取映射缓存
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - propertyName: 属性名
    /// - Returns: JSON 键
    internal func getMapping(for type: Any.Type, propertyName: String) -> String? {
        return cacheQueue.sync {
            let typeName = _getTypeName(type)
            return mappingCache[typeName]?[propertyName]
        }
    }

    /// 缓存映射关系
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - mappings: 映射字典 [属性名: JSON键]
    internal func cacheMappings(for type: Any.Type, mappings: [String: String]) {
        cacheQueue.sync {
            let typeName = _getTypeName(type)

            if mappingCache.count >= maxMappingCacheSize {
                _evictOldestMappings()
            }

            mappingCache[typeName] = mappings
        }
    }

    /// 清除指定类型的映射缓存
    ///
    /// - Parameter type: 类型
    internal func removeMappings(for type: Any.Type) {
        cacheQueue.sync {
            let typeName = _getTypeName(type)
            mappingCache.removeValue(forKey: typeName)
        }
    }

    // MARK: - Cache Management

    /// 清除所有缓存
    internal func clearAll() {
        cacheQueue.sync {
            propertyCache.removeAll()
            methodCache.removeAll()
            mappingCache.removeAll()
            hitCount = 0
            missCount = 0
        }
    }

    /// 清除属性缓存
    internal func clearProperties() {
        cacheQueue.sync {
            propertyCache.removeAll()
        }
    }

    /// 清除方法缓存
    internal func clearMethods() {
        cacheQueue.sync {
            methodCache.removeAll()
        }
    }

    /// 清除映射缓存
    internal func clearMappings() {
        cacheQueue.sync {
            mappingCache.removeAll()
        }
    }

    // MARK: - Statistics

    /// 获取缓存统计
    ///
    /// - Returns: 统计信息
    internal func getStats() -> MethodCacheStats {
        return cacheQueue.sync {
            MethodCacheStats(
                propertyCacheCount: propertyCache.count,
                methodCacheCount: methodCache.count,
                mappingCacheCount: mappingCache.count,
                hitCount: hitCount,
                missCount: missCount
            )
        }
    }

    /// 获取缓存命中率
    ///
    /// - Returns: 命中率（0.0 - 1.0）
    internal func getHitRate() -> Double {
        return cacheQueue.sync {
            let total = hitCount + missCount
            guard total > 0 else { return 0.0 }
            return Double(hitCount) / Double(total)
        }
    }

    /// 重置统计
    internal func resetStats() {
        cacheQueue.sync {
            hitCount = 0
            missCount = 0
        }
    }

    // MARK: - Private Helpers

    /// 获取类型名称
    private func _getTypeName(_ type: Any.Type) -> String {
        return String(describing: type)
    }

    /// 创建缓存键
    private func _makeCacheKey(type: Any.Type, method: String) -> String {
        return "\(type).\(method)"
    }

    /// 从类型提取属性
    private func _extractProperties(from type: Any.Type) -> [_LSPropertyMetadata] {
        // 简化实现：返回空数组
        // 实际属性提取由 LSJSONDecoderHP 处理
        // 这里仅作为占位符
        let properties: [_LSPropertyMetadata] = []

        return properties
    }

    /// 预热常用类型
    private func _preheatCommonTypes() {
        // 预热常用类型可以减少首次使用的延迟
        // 这里我们不需要做什么，因为缓存是惰性加载的
    }

    /// 淘汰最旧的属性缓存
    private func _evictOldestProperties() {
        // 简化实现：移除一半
        let keysToRemove = Array(propertyCache.keys.prefix(maxPropertyCacheSize / 2))
        for key in keysToRemove {
            propertyCache.removeValue(forKey: key)
        }
    }

    /// 淘汰最旧的方法缓存
    private func _evictOldestMethods() {
        let keysToRemove = Array(methodCache.keys.prefix(maxMethodCacheSize / 2))
        for key in keysToRemove {
            methodCache.removeValue(forKey: key)
        }
    }

    /// 淘汰最旧的映射缓存
    private func _evictOldestMappings() {
        let keysToRemove = Array(mappingCache.keys.prefix(maxMappingCacheSize / 2))
        for key in keysToRemove {
            mappingCache.removeValue(forKey: key)
        }
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
        let stats = shared.getStats()
        print("========== Method Cache Stats ==========")
        print("Property Cache: \(stats.propertyCacheCount)")
        print("Method Cache: \(stats.methodCacheCount)")
        print("Mapping Cache: \(stats.mappingCacheCount)")
        print("Hit Rate: \(String(format: "%.2f%%", stats.hitRate * 100))")
        print("Hits: \(stats.hitCount), Misses: \(stats.missCount)")
        print("=========================================")
        #endif
    }
}
