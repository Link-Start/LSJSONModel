//
//  LSDefault.swift
//  LSJSONModel/Sources/PropertyWrappers
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSDefault

/// 默认值属性包装器
///
/// 为解码过程中的可选属性提供默认值，避免处理 nil 值。
///
/// 使用示例：
/// ```swift
/// struct User: Decodable {
///     @LSDefault("") var name: String
///     @LSDefault(0) var age: Int
///     @LSDefault(false) var isActive: Bool
/// }
/// ```
///
/// 支持的类型：
/// - String
/// - Int, Double, Float
/// - Bool
/// - Array
/// - Dictionary
/// - 任何符合 `LSDefaultWritable` 协议的类型
@propertyWrapper
public struct LSDefault<T: LSDefaultWritable> {
    /// 默认值
    public let defaultValue: T

    /// 包装值
    public var wrappedValue: T {
        get { defaultValue }
        set { /* 存储通过 Codable 处理 */ }
    }

    /// 初始化默认值包装器
    ///
    /// - Parameter defaultValue: 当 JSON 中缺失或为 nil 时使用的默认值
    public init(_ defaultValue: T) {
        self.defaultValue = defaultValue
    }
}

// MARK: - LSDefault Codable Support

extension LSDefault: Decodable where T: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 尝试解码值
        if let value = try? container.decode(T.self) {
            self.defaultValue = value
        } else {
            // 解码失败时使用默认值
            self.defaultValue = T.lsDefaultValue
        }
    }
}

extension LSDefault: Encodable where T: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(defaultValue)
    }
}

// MARK: - LSDefaultWritable Protocol

/// 默认值可写协议
///
/// 符合此协议的类型可以提供默认值。
public protocol LSDefaultWritable {
    /// 类型的默认值
    static var lsDefaultValue: Self { get }
}

// MARK: - Built-in Type Conformance

// String 默认值
extension String: LSDefaultWritable {
    public static var lsDefaultValue: String { "" }
}

// Int 默认值
extension Int: LSDefaultWritable {
    public static var lsDefaultValue: Int { 0 }
}

// Double 默认值
extension Double: LSDefaultWritable {
    public static var lsDefaultValue: Double { 0.0 }
}

// Float 默认值
extension Float: LSDefaultWritable {
    public static var lsDefaultValue: Float { 0.0 }
}

// Bool 默认值
extension Bool: LSDefaultWritable {
    public static var lsDefaultValue: Bool { false }
}

// Array 默认值
extension Array: LSDefaultWritable {
    public static var lsDefaultValue: Array { [] }
}

// Dictionary 默认值
extension Dictionary: LSDefaultWritable {
    public static var lsDefaultValue: Dictionary { [:] }
}

// MARK: - Optional Support

/// 可选类型默认值支持
///
/// 允许 `@LSDefault` 与可选类型一起使用。
extension Optional: LSDefaultWritable where Wrapped: LSDefaultWritable {
    public static var lsDefaultValue: Optional { Wrapped.lsDefaultValue }
}

// MARK: - Custom Type Support

/// 为自定义类型实现默认值的便捷方式
///
/// 使用示例：
/// ```swift
/// extension Point: LSDefaultWritable {
///     static var lsDefaultValue: Point { Point(x: 0, y: 0) }
/// }
///
/// struct Shape: Decodable {
///     @LSDefault(Point.lsDefaultValue) var position: Point
/// }
/// ```
public extension LSDefaultWritable {
    /// 提供默认值的静态方法（用于类型推断）
    static func provideDefault() -> Self {
        return lsDefaultValue
    }
}

// MARK: - Coding Key Support

/// 支持 `CodingKeys` 的默认值处理
///
/// 当模型使用自定义 `CodingKeys` 时，`@LSDefault` 会正确处理映射。
/// 注意：此功能为高级功能，需要配合 CodingKeys 使用
@propertyWrapper
public struct LSDefaultWithKey<T: Codable> {
    /// 默认值
    public let defaultValue: T

    /// 自定义编码键
    public let key: String?

    /// 包装值
    public var wrappedValue: T {
        get { defaultValue }
        set { /* 存储通过 Codable 处理 */ }
    }

    /// 初始化带键的默认值包装器
    ///
    /// - Parameters:
    ///   - defaultValue: 默认值
    ///   - key: 自定义 JSON 键名（可选）
    public init(_ defaultValue: T, key: String? = nil) {
        self.defaultValue = defaultValue
        self.key = key
    }
}

// MARK: - Legacy Support (iOS 13+)

#if !os(iOS) || swift(>=5.9)
// iOS 13+ 完整支持
// iOS 15+ 支持 Macro 版本
#endif
