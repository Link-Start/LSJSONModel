//
//  _LSJSONMapping.swift
//  LSJSONModel/Sources/Macros
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONMappingProvider Protocol

/// Model 可实现此协议提供自定义映射
/// 类似 MJExtension 的 mj_replacedKeyFromPropertyName
public protocol LSJSONMappingProvider {
    /// 返回属性名到 JSON 键的映射
    static func ls_mappingKeys() -> [String: String]
}

// MARK: - LSJSONMapping

/// LSJSONModel 统一映射管理系统
/// 支持全局映射、类型映射、Snake Case 转换
/// 映射优先级（从高到低）：
/// 1. 类型映射 (ls_mappingKeys / ls_registerMapping)
/// 2. 全局映射 (ls_setGlobalMapping)
/// 3. Snake Case 转换 (ls_markSnakeCase)
/// 4. 默认映射
public final class LSJSONMapping {

    // MARK: - Nested Types

    /// 映射优先级
    public enum MappingPriority: Int {
        case type = 3           // 类型级映射（最高优先级）
        case global = 2         // 全局映射
        case snakeCase = 1      // Snake Case 转换
        case `default` = 0      // 默认映射
    }

    /// 映射元数据
    internal struct MappingMetadata {
        let jsonKey: String
        let priority: MappingPriority
        let source: String      // 映射来源（用于调试）

        init(jsonKey: String, priority: MappingPriority, source: String) {
            self.jsonKey = jsonKey
            self.priority = priority
            self.source = source
        }
    }

    // MARK: - Properties

    /// 全局映射配置 - 属性名 -> JSON 键
    nonisolated(unsafe) private static var globalMapping: [String: String] = [:]

    /// 类型级映射配置 - 类型名称 -> [属性名: JSON 键]
    nonisolated(unsafe) private static var typeMapping: [String: [String: String]] = [:]

    /// Snake Case 标记 - 启用 Snake Case 的类型集合
    nonisolated(unsafe) internal static var snakeCaseTypes: Set<String> = []

    /// 线程安全锁
    private static let lock = NSLock()

    // MARK: - Global Mapping

    /// 设置全局属性名映射
    /// 类似 MJExtension 的 mj_replacedKeyFromPropertyName
    /// 一处设置，所有 Model 都生效
    ///
    /// 使用示例：
    /// ```swift
    /// LSJSONMapping.ls_setGlobalMapping([
    ///     "id": "user_id",           // 所有 Model 的 id 属性都映射到 user_id
    ///     "description": "desc"      // 所有 Model 的 description 属性都映射到 desc
    /// ])
    /// ```
    public static func ls_setGlobalMapping(_ mapping: [String: String]) {
        lock.lock()
        defer { lock.unlock() }

        globalMapping = mapping

        #if DEBUG
        print("[LSJSONMapping] ✅ 全局映射已设置: \(mapping)")
        #endif

        // 清除缓存以应用新映射
        _LSJSONMappingCache.clearCache()
    }

    /// 添加全局属性名映射
    public static func ls_addGlobalMapping(_ mapping: [String: String]) {
        lock.lock()
        defer { lock.unlock() }

        globalMapping.merge(mapping) { _, new in new }

        #if DEBUG
        print("[LSJSONMapping] ✅ 添加全局映射: \(mapping)")
        #endif

        _LSJSONMappingCache.clearCache()
    }

    /// 获取全局映射配置
    public static func ls_getGlobalMapping() -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        return globalMapping
    }

    /// 清除全局映射
    public static func ls_clearGlobalMapping() {
        lock.lock()
        defer { lock.unlock() }

        globalMapping.removeAll()

        #if DEBUG
        print("[LSJSONMapping] ✅ 全局映射已清除")
        #endif

        _LSJSONMappingCache.clearCache()
    }

    // MARK: - Type-Level Mapping

    /// 注册特定类型的映射
    ///
    /// 使用示例：
    /// ```swift
    /// LSJSONMapping.ls_registerMapping(for: User.self, mapping: [
    ///     "id": "user_id",
    ///     "userName": "user_name"
    /// ])
    /// ```
    public static func ls_registerMapping<T>(for type: T.Type, mapping: [String: String]) {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
        typeMapping[typeName] = mapping

        #if DEBUG
        print("[LSJSONMapping] ✅ 注册类型映射 [\(typeName)]: \(mapping)")
        #endif

        // 清除该类型的缓存
        _LSJSONMappingCache.clearCache(for: typeName)
    }

    /// 批量注册类型映射
    public static func ls_registerMappings(_ mappings: [(Any.Type, [String: String])]) {
        lock.lock()
        defer { lock.unlock() }

        for (type, mapping) in mappings {
            let typeName = String(describing: type)
            typeMapping[typeName] = mapping
        }

        #if DEBUG
        print("[LSJSONMapping] ✅ 批量注册 \(mappings.count) 个类型映射")
        #endif

        _LSJSONMappingCache.clearCache()
    }

    /// 获取类型的映射配置
    public static func ls_getMapping(for type: Any.Type) -> [String: String] {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)

        // 检查类型是否实现了 LSJSONMappingProvider
        if let provider = type as? LSJSONMappingProvider.Type {
            let mapping = provider.ls_mappingKeys()
            // 缓存到 typeMapping 中
            typeMapping[typeName] = mapping
            return mapping
        }

        return typeMapping[typeName] ?? [:]
    }

    /// 清除特定类型的映射
    public static func ls_clearMapping(for type: Any.Type) {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
        typeMapping.removeValue(forKey: typeName)

        #if DEBUG
        print("[LSJSONMapping] ✅ 清除类型映射: \(typeName)")
        #endif

        _LSJSONMappingCache.clearCache(for: typeName)
    }

    /// 标记类型使用 Snake Case（内部使用）
    internal static func ls_markSnakeCase<T>(for type: T.Type) {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
        snakeCaseTypes.insert(typeName)

        #if DEBUG
        print("[LSJSONMapping] ✅ 标记 Snake Case: \(typeName)")
        #endif
    }

    /// 检查类型是否使用 Snake Case
    internal static func ls_isSnakeCase<T>(for type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let typeName = String(describing: type)
        return snakeCaseTypes.contains(typeName)
    }

    // MARK: - Unified Mapping Query (Core Methods)

    /// 查找属性对应的 JSON 键名
    /// 按优先级查找：宏标记 > 类型映射 > 全局映射 > Snake Case > 默认
    ///
    /// 使用示例：
    /// ```swift
    /// let jsonKey = LSJSONMapping.ls_jsonKey(for: "id", in: User.self)
    /// ```
    public static func ls_jsonKey(for propertyName: String, in type: Any.Type) -> String {
        let metadata = ls_mappingMetadata(for: propertyName, in: type)
        return metadata.jsonKey
    }

    /// 获取属性映射的完整元数据
    internal static func ls_mappingMetadata(for propertyName: String, in type: Any.Type) -> MappingMetadata {
        let typeName = String(describing: type)

        // 1. 检查缓存
        if let cached = _LSJSONMappingCache.getMapping(for: typeName, property: propertyName) {
            return cached
        }

        lock.lock()
        defer { lock.unlock() }

        // 2. 最高优先级：类型级映射
        if let typeJsonKey = typeMapping[typeName]?[propertyName] {
            let metadata = MappingMetadata(jsonKey: typeJsonKey, priority: .type, source: "type")
            _LSJSONMappingCache.setMapping(for: typeName, property: propertyName, metadata: metadata)
            return metadata
        }

        // 3. 全局映射
        if let globalJsonKey = globalMapping[propertyName] {
            let metadata = MappingMetadata(jsonKey: globalJsonKey, priority: .global, source: "global")
            _LSJSONMappingCache.setMapping(for: typeName, property: propertyName, metadata: metadata)
            return metadata
        }

        // 4. Snake Case 转换
        if snakeCaseTypes.contains(typeName) {
            let snakeCaseKey = _toSnakeCase(propertyName)
            let metadata = MappingMetadata(jsonKey: snakeCaseKey, priority: .snakeCase, source: "snake_case")
            _LSJSONMappingCache.setMapping(for: typeName, property: propertyName, metadata: metadata)
            return metadata
        }

        // 5. 默认映射（使用属性名本身）
        let metadata = MappingMetadata(jsonKey: propertyName, priority: .default, source: "default")
        _LSJSONMappingCache.setMapping(for: typeName, property: propertyName, metadata: metadata)
        return metadata
    }

    /// 查找 JSON 键对应的属性名（反向映射）
    public static func ls_propertyName(for jsonKey: String, in type: Any.Type) -> String {
        let typeName = String(describing: type)

        // 检查反向缓存
        if let cached = _LSJSONMappingCache.getReverseMapping(for: typeName, jsonKey: jsonKey) {
            return cached
        }

        lock.lock()
        defer { lock.unlock() }

        // 1. 检查类型映射（反向查找）
        if let typeMappings = typeMapping[typeName] {
            for (prop, key) in typeMappings where key == jsonKey {
                _LSJSONMappingCache.setReverseMapping(for: typeName, jsonKey: jsonKey, property: prop)
                return prop
            }
        }

        // 2. 检查全局映射（反向查找）
        for (prop, key) in globalMapping where key == jsonKey {
            _LSJSONMappingCache.setReverseMapping(for: typeName, jsonKey: jsonKey, property: prop)
            return prop
        }

        // 3. 检查 Snake Case 转换
        if snakeCaseTypes.contains(typeName) {
            let camelCase = _toCamelCase(jsonKey)
            // 验证这个 camelCase 转回 snake_case 是否匹配
            if _toSnakeCase(camelCase) == jsonKey {
                _LSJSONMappingCache.setReverseMapping(for: typeName, jsonKey: jsonKey, property: camelCase)
                return camelCase
            }
        }

        // 4. 默认返回 JSON 键本身
        return jsonKey
    }

    // MARK: - Cross Model Conversion

    /// 将一个 Model 转换为另一个 Model
    /// 支持不同 Model 类型之间的属性映射
    ///
    /// 使用示例：
    /// ```swift
    /// let apiUser = APIUser.ls_decode(json)
    /// let appUser = LSJSONMapping.ls_convert(apiUser, to: AppUser.self)
    /// ```
    public static func ls_convert<Source, Destination>(_ source: Source, to type: Destination.Type) -> Destination? {
        return _LSTypeConverter.ls_convert(source, to: type)
    }

    /// 批量转换 Model 数组
    public static func ls_convertArray<Source, Destination>(_ sources: [Source], to type: Destination.Type) -> [Destination] {
        return sources.compactMap { ls_convert($0, to: type) }
    }

    // MARK: - Helper Methods

    /// 将 camelCase 转换为 snake_case
    internal static func _toSnakeCase(_ camelCase: String) -> String {
        let pattern = "([a-z])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: camelCase.utf16.count)
        let snakeCase = regex?.stringByReplacingMatches(in: camelCase, options: [], range: range, withTemplate: "$1_$2")
        return snakeCase?.lowercased() ?? camelCase.lowercased()
    }

    /// 将 snake_case 转换为 camelCase
    internal static func _toCamelCase(_ snakeCase: String) -> String {
        var components = snakeCase.components(separatedBy: "_")
        guard !components.isEmpty else { return snakeCase }

        // 第一个单词保持小写，后续单词首字母大写
        let first = components.removeFirst().lowercased()
        let rest = components.map { word in
            guard !word.isEmpty else { return "" }
            let first = word.prefix(1).uppercased()
            let remaining = word.dropFirst()
            return first + remaining
        }

        return first + rest.joined()
    }
}
