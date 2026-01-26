//
//  _LSPropertyMapper.swift
//  LSJSONModel/Sources/Runtime
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSPropertyMapper

/// 属性映射器 - 处理属性名到 JSON 键的映射
///
/// 功能：
/// - 属性名映射
/// - 反向映射查找
/// - 批量映射处理
internal final class _LSPropertyMapper {

    // MARK: - Properties

    /// 属性元数据缓存
    nonisolated(unsafe) private static var propertyCache: [String: [_LSPropertyMetadata]] = [:]

    /// 线程安全锁
    private static let lock = NSLock()

    // MARK: - Nested Types

    /// 属性元数据
    internal struct _LSPropertyMetadata {
        let name: String
        let type: Any.Type
        let jsonKey: String
        let isOptional: Bool
        let defaultValue: Any?
        let ignore: Bool

        init(name: String, type: Any.Type, jsonKey: String, isOptional: Bool = false, defaultValue: Any? = nil, ignore: Bool = false) {
            self.name = name
            self.type = type
            self.jsonKey = jsonKey
            self.isOptional = isOptional
            self.defaultValue = defaultValue
            self.ignore = ignore
        }
    }

    // MARK: - Property Metadata

    /// 获取类型的所有属性元数据
    ///
    /// - Parameter type: 类型
    /// - Returns: 属性元数据数组
    internal static func properties(of type: Any.Type) -> [_LSPropertyMetadata] {
        let typeName = String(describing: type)

        // 检查缓存
        lock.lock()
        if let cached = propertyCache[typeName] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // 使用 Mirror 反射获取属性
        let metadataList: [_LSPropertyMetadata] = []

        // 对于 struct，尝试创建实例来反射
        // 这里使用一个简化的实现，直接返回空数组
        // 真正的反射需要实例，这在泛型上下文中比较困难

        return metadataList
    }

    /// 获取单个属性的元数据
    ///
    /// - Parameters:
    ///   - name: 属性名
    ///   - type: 类型
    /// - Returns: 属性元数据
    internal static func property(named name: String, of type: Any.Type) -> _LSPropertyMetadata? {
        let jsonKey = LSJSONMapping.ls_jsonKey(for: name, in: type)

        return _LSPropertyMetadata(
            name: name,
            type: type,
            jsonKey: jsonKey
        )
    }

    // MARK: - Mapping Operations

    /// 将字典的键转换为属性名
    ///
    /// - Parameters:
    ///   - dictionary: 输入字典
    ///   - type: 目标类型
    /// - Returns: 属性名到值的映射字典
    internal static func mapDictionaryToProperties(_ dictionary: [String: Any], for type: Any.Type) -> [String: Any] {
        var result: [String: Any] = [:]

        for (jsonKey, value) in dictionary {
            let propertyName = LSJSONMapping.ls_propertyName(for: jsonKey, in: type)
            result[propertyName] = value
        }

        return result
    }

    /// 将属性名字典转换为 JSON 键字典
    ///
    /// - Parameters:
    ///   - dictionary: 属性名字典
    ///   - type: 源类型
    /// - Returns: JSON 键到值的映射字典
    internal static func mapPropertiesToDictionary(_ dictionary: [String: Any], for type: Any.Type) -> [String: Any] {
        var result: [String: Any] = [:]

        for (propertyName, value) in dictionary {
            let jsonKey = LSJSONMapping.ls_jsonKey(for: propertyName, in: type)
            result[jsonKey] = value
        }

        return result
    }

    // MARK: - Reflection Helpers

    /// 获取类型的所有属性名
    ///
    /// - Parameter type: 类型
    /// - Returns: 属性名数组
    internal static func propertyNames(of type: Any.Type) -> [String] {
        var names: [String] = []

        // 对于 struct，需要创建一个实例来使用 Mirror
        // 这里使用一个简化的方法

        let mirror = Mirror(reflecting: type)
        for child in mirror.children {
            if let label = child.label {
                names.append(label)
            }
        }

        return names
    }

    /// 获取类型的所有 JSON 键名
    ///
    /// - Parameter type: 类型
    /// - Returns: JSON 键名数组
    internal static func jsonKeys(for type: Any.Type) -> [String] {
        let propertyNames = propertyNames(of: type)
        return propertyNames.map { LSJSONMapping.ls_jsonKey(for: $0, in: type) }
    }

    // MARK: - Cache Management

    /// 清除属性缓存
    internal static func clearCache() {
        lock.lock()
        defer { lock.unlock() }

        propertyCache.removeAll()

        #if DEBUG
        print("[LSPropertyMapper] ✅ 属性缓存已清除")
        #endif
    }

    /// 清除特定类型的属性缓存
    ///
    /// - Parameter type: 类型
    internal static func clearCache(for type: Any.Type) {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
        propertyCache.removeValue(forKey: typeName)

        #if DEBUG
        print("[LSPropertyMapper] ✅ 类型 [\(typeName)] 的属性缓存已清除")
        #endif
    }
}
