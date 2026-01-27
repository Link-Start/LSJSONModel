//
//  LSJSONMetadata.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSPropertyMetadata

/// 属性元数据
///
/// 用于描述类型的属性信息，支持高性能反射操作。
///
/// 使用 @unchecked Sendable 因为 defaultValue: Any? 不是 Sendable
/// 但由于所有属性都是 let（不可变），整体结构是线程安全的
internal struct _LSPropertyMetadata: @unchecked Sendable {
    /// 属性名称
    let name: String

    /// 属性类型
    let type: Any.Type

    /// 属性偏移量（用于直接内存访问）
    let offset: Int

    /// 是否是可选类型
    let isOptional: Bool

    /// JSON 键名（映射后的键名，默认与 name 相同）
    let jsonKey: String

    /// 默认值（用于可选属性或缺失值）
    let defaultValue: Any?

    /// 是否忽略此属性（不参与编码/解码）
    let ignore: Bool

    /// 初始化属性元数据
    ///
    /// - Parameters:
    ///   - name: 属性名称
    ///   - type: 属性类型
    ///   - offset: 属性偏移量
    ///   - jsonKey: JSON 键名（默认与 name 相同）
    ///   - isOptional: 是否是可选类型
    ///   - defaultValue: 默认值
    ///   - ignore: 是否忽略此属性
    init(name: String, type: Any.Type, offset: Int, jsonKey: String = "",
         isOptional: Bool = false, defaultValue: Any? = nil, ignore: Bool = false) {
        self.name = name
        self.type = type
        self.offset = offset
        self.jsonKey = jsonKey.isEmpty ? name : jsonKey
        self.isOptional = isOptional
        self.defaultValue = defaultValue
        self.ignore = ignore
    }
}

// MARK: - LSPropertyMetadata + Equatable

extension _LSPropertyMetadata: Equatable {
    static func == (lhs: _LSPropertyMetadata, rhs: _LSPropertyMetadata) -> Bool {
        return lhs.name == rhs.name &&
               String(describing: lhs.type) == String(describing: rhs.type) &&
               lhs.offset == rhs.offset &&
               lhs.isOptional == rhs.isOptional &&
               lhs.jsonKey == rhs.jsonKey &&
               _compareAnyOptionals(lhs: lhs.defaultValue, rhs: rhs.defaultValue) &&
               lhs.ignore == rhs.ignore
    }

    /// 比较两个 Optional<Any> 值
    private static func _compareAnyOptionals(lhs: Any?, rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let l?, let r?):
            return String(describing: l) == String(describing: r)
        default:
            return false
        }
    }
}

// MARK: - LSPropertyMetadata + CustomStringConvertible

extension _LSPropertyMetadata: CustomStringConvertible {
    var description: String {
        let optionalMark = isOptional ? "?" : ""
        let ignoreMark = ignore ? " (ignored)" : ""
        let defaultMark = defaultValue != nil ? " (default: \(defaultValue!))" : ""
        return "_LSPropertyMetadata(name: \(name), type: \(type)\(optionalMark), jsonKey: \(jsonKey), offset: \(offset)\(defaultMark)\(ignoreMark))"
    }
}

// MARK: - MethodCacheStats

/// 方法缓存统计
///
/// 用于追踪和报告缓存性能指标。
internal struct MethodCacheStats: Sendable {
    /// 属性缓存数量
    let propertyCacheCount: Int

    /// 方法缓存数量
    let methodCacheCount: Int

    /// 映射缓存数量
    let mappingCacheCount: Int

    /// 命中次数
    let hitCount: Int

    /// 未命中次数
    let missCount: Int

    /// 总查询次数
    var totalCount: Int {
        return hitCount + missCount
    }

    /// 缓存命中率（0.0 - 1.0）
    var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0.0 }
        return Double(hitCount) / Double(total)
    }

    /// 缓存未命中率（0.0 - 1.0）
    var missRate: Double {
        return 1.0 - hitRate
    }

    /// 初始化缓存统计
    ///
    /// - Parameters:
    ///   - propertyCacheCount: 属性缓存数量
    ///   - methodCacheCount: 方法缓存数量
    ///   - mappingCacheCount: 映射缓存数量
    ///   - hitCount: 命中次数
    ///   - missCount: 未命中次数
    init(
        propertyCacheCount: Int,
        methodCacheCount: Int,
        mappingCacheCount: Int,
        hitCount: Int,
        missCount: Int
    ) {
        self.propertyCacheCount = propertyCacheCount
        self.methodCacheCount = methodCacheCount
        self.mappingCacheCount = mappingCacheCount
        self.hitCount = hitCount
        self.missCount = missCount
    }

    /// 空统计（初始化值）
    static let empty = MethodCacheStats(
        propertyCacheCount: 0,
        methodCacheCount: 0,
        mappingCacheCount: 0,
        hitCount: 0,
        missCount: 0
    )
}

// MARK: - MethodCacheStats + CustomStringConvertible

extension MethodCacheStats: CustomStringConvertible {
    var description: String {
        return """
        MethodCacheStats(
          Property Cache: \(propertyCacheCount)
          Method Cache: \(methodCacheCount)
          Mapping Cache: \(mappingCacheCount)
          Hit Rate: \(String(format: "%.2f%%", hitRate * 100))
          Hits: \(hitCount), Misses: \(missCount)
        )
        """
    }
}

// MARK: - LSTypeInfo

/// 类型信息
///
/// 存储类型的反射信息。
internal struct _LSTypeInfo: Sendable {
    /// 类型名称
    let typeName: String

    /// 属性列表
    let properties: [_LSPropertyMetadata]

    /// 是否是 class 类型
    let isClass: Bool

    /// 是否是 struct 类型
    let isStruct: Bool

    /// 是否是 enum 类型
    let isEnum: Bool

    /// 初始化类型信息
    ///
    /// - Parameters:
    ///   - typeName: 类型名称
    ///   - properties: 属性列表
    ///   - isClass: 是否是 class 类型
    ///   - isStruct: 是否是 struct 类型
    ///   - isEnum: 是否是 enum 类型
    init(
        typeName: String,
        properties: [_LSPropertyMetadata],
        isClass: Bool = false,
        isStruct: Bool = false,
        isEnum: Bool = false
    ) {
        self.typeName = typeName
        self.properties = properties
        self.isClass = isClass
        self.isStruct = isStruct
        self.isEnum = isEnum
    }

    /// 从 Mirror 创建类型信息
    ///
    /// - Parameter mirror: Mirror 对象
    /// - Returns: 类型信息
    static func from(mirror: Mirror) -> _LSTypeInfo {
        let typeName = String(describing: mirror.subjectType)

        var properties: [_LSPropertyMetadata] = []
        for child in mirror.children {
            guard let label = child.label else { continue }
            let propertyType = type(of: child.value)

            // 检查是否是可选类型
            let isOptional = mirror.displayStyle == .optional

            let metadata = _LSPropertyMetadata(
                name: label,
                type: propertyType,
                offset: 0,
                isOptional: isOptional
            )
            properties.append(metadata)
        }

        let isClass = mirror.displayStyle == .class
        let isStruct = mirror.displayStyle == .struct
        let isEnum = mirror.displayStyle == .enum

        return _LSTypeInfo(
            typeName: typeName,
            properties: properties,
            isClass: isClass,
            isStruct: isStruct,
            isEnum: isEnum
        )
    }
}

// MARK: - Performance Metrics

/// 性能指标
///
/// 用于测量和报告性能数据。
internal struct LSPerformanceMetrics: Sendable {
    /// 操作名称
    let operation: String

    /// 耗时（秒）
    let duration: TimeInterval

    /// 时间戳
    let timestamp: Date

    /// 初始化性能指标
    ///
    /// - Parameters:
    ///   - operation: 操作名称
    ///   - duration: 耗时（秒）
    ///   - timestamp: 时间戳
    init(operation: String, duration: TimeInterval, timestamp: Date = Date()) {
        self.operation = operation
        self.duration = duration
        self.timestamp = timestamp
    }

    /// 格式化的耗时字符串
    var formattedDuration: String {
        if duration < 0.001 {
            return String(format: "%.3f μs", duration * 1_000_000)
        } else if duration < 1.0 {
            return String(format: "%.3f ms", duration * 1000)
        } else {
            return String(format: "%.3f s", duration)
        }
    }
}
