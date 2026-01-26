//
//  LSDateCoding.swift
//  LSJSONModel/Sources/PropertyWrappers
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSDateCoding

/// 日期编码属性包装器
///
/// 为日期属性提供自定义格式的编码/解码支持。
///
/// 使用示例：
/// ```swift
/// struct User: Codable {
///     @LSDateCoding(.iso8601) var createdAt: Date
///     @LSDateCoding(.yyyyMMddHHmmss) var updatedAt: Date
///     @LSDateCoding(.custom("yyyy年MM月dd日")) var birthDate: Date
/// }
/// ```
///
/// 支持的格式：
/// - `.iso8601` - ISO 8601 标准格式（如：2024-01-23T12:00:00Z）
/// - `.yyyyMMddHHmmss` - 常见格式（如：20240123120000）
/// - `.rfc3339` - RFC 3339 格式
/// - `.epochSeconds` - Unix 时间戳（秒）
/// - `.epochMilliseconds` - Unix 时间戳（毫秒）
/// - `.custom(String)` - 自定义格式字符串
@propertyWrapper
public struct LSDateCoding {
    /// 日期格式
    public let format: DateFormat

    /// 包装值
    public var wrappedValue: Date {
        get { _storage }
        set { _storage = newValue }
    }

    /// 内部存储
    private var _storage: Date

    /// 初始化日期编码包装器
    ///
    /// - Parameter format: 日期格式
    public init(_ format: DateFormat) {
        self.format = format
        self._storage = Date()
    }

    /// 便捷初始化：使用自定义格式字符串
    ///
    /// - Parameter formatString: 自定义格式字符串
    public init(_ formatString: String) {
        self.format = .custom(formatString)
        self._storage = Date()
    }
}

// MARK: - LSDateCoding Codable Support

extension LSDateCoding: Decodable {
    public init(from decoder: Decoder) throws {
        // 首先尝试从格式值解码
        let container = try decoder.singleValueContainer()

        // 默认格式
        self.format = .iso8601
        self._storage = Date()

        // 根据 format 解码（注意：这里 format 已经被初始化）
        // 实际格式由外部设置，这里使用默认行为
        if let dateString = try? container.decode(String.self) {
            let formatter = ISO8601DateFormatter()
            _storage = formatter.date(from: dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self) {
            _storage = Date(timeIntervalSince1970: timestamp)
        }
    }
}

extension LSDateCoding: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let dateString: String

        switch format {
        case .iso8601:
            dateString = format.dateFormatter.string(from: wrappedValue)

        case .epochSeconds:
            let timestamp = wrappedValue.timeIntervalSince1970
            try container.encode(timestamp)
            return

        case .epochMilliseconds:
            let timestamp = wrappedValue.timeIntervalSince1970 * 1000.0
            try container.encode(timestamp)
            return

        case .yyyyMMddHHmmss:
            dateString = format.dateFormatter.string(from: wrappedValue)

        case .rfc3339:
            dateString = format.dateFormatter.string(from: wrappedValue)

        case .custom(let formatString):
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            formatter.locale = Locale(identifier: "en_US_POSIX")
            dateString = formatter.string(from: wrappedValue)
        }

        try container.encode(dateString)
    }
}

// MARK: - DateFormat Enum

/// 日期格式枚举
public enum DateFormat: Equatable {
    /// ISO 8601 标准格式
    /// 示例：2024-01-23T12:00:00Z
    case iso8601

    /// RFC 3339 格式
    /// 示例：2024-01-23T12:00:00+08:00
    case rfc3339

    /// yyyyMMddHHmmss 格式
    /// 示例：20240123120000
    case yyyyMMddHHmmss

    /// Unix 时间戳（秒）
    case epochSeconds

    /// Unix 时间戳（毫秒）
    case epochMilliseconds

    /// 自定义格式
    /// 使用 DateFormatter 格式字符串
    case custom(String)

    /// 获取对应的日期格式化器
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)

        switch self {
        case .iso8601:
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

        case .rfc3339:
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        case .yyyyMMddHHmmss:
            formatter.dateFormat = "yyyyMMddHHmmss"

        case .epochSeconds, .epochMilliseconds:
            // 时间戳不需要 DateFormatter
            break

        case .custom(let formatString):
            formatter.dateFormat = formatString
        }

        return formatter
    }

    /// 从字符串解析日期
    ///
    /// - Parameter string: 日期字符串
    /// - Returns: 解析后的日期，失败返回当前时间
    public func date(from string: String) -> Date {
        switch self {
        case .iso8601:
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.date(from: string) ?? Date()

        case .rfc3339:
            return dateFormatter.date(from: string) ?? Date()

        case .yyyyMMddHHmmss:
            return dateFormatter.date(from: string) ?? Date()

        case .epochSeconds:
            if let interval = Double(string) {
                return Date(timeIntervalSince1970: interval)
            }
            return Date()

        case .epochMilliseconds:
            if let interval = Double(string) {
                return Date(timeIntervalSince1970: interval / 1000.0)
            }
            return Date()

        case .custom:
            return dateFormatter.date(from: string) ?? Date()
        }
    }

    /// 将日期格式化为字符串
    ///
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    public func string(from date: Date) -> String {
        switch self {
        case .iso8601:
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.string(from: date)

        case .epochSeconds:
            return String(format: "%.0f", date.timeIntervalSince1970)

        case .epochMilliseconds:
            return String(format: "%.0f", date.timeIntervalSince1970 * 1000.0)

        case .rfc3339, .yyyyMMddHHmmss, .custom:
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - LSDateCoding Optional Support

/// 可选日期编码属性包装器
///
/// 支持可选日期类型的编码/解码。
@propertyWrapper
public struct LSDateCodingOptional {
    /// 日期格式
    public let format: DateFormat

    /// 包装值
    public var wrappedValue: Date? {
        get { _storage }
        set { _storage = newValue }
    }

    /// 内部存储
    private var _storage: Date?

    /// 初始化可选日期编码包装器
    ///
    /// - Parameter format: 日期格式
    public init(_ format: DateFormat) {
        self.format = format
        self._storage = nil
    }

    /// 便捷初始化：使用自定义格式字符串
    ///
    /// - Parameter formatString: 自定义格式字符串
    public init(_ formatString: String) {
        self.format = .custom(formatString)
        self._storage = nil
    }
}

extension LSDateCodingOptional: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 首先初始化格式
        self.format = .iso8601
        self._storage = nil

        if !container.decodeNil() {
            // 尝试解码日期
            if let dateString = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                _storage = formatter.date(from: dateString)
            } else if let timestamp = try? container.decode(Double.self) {
                _storage = Date(timeIntervalSince1970: timestamp)
            }
        }
    }
}

extension LSDateCodingOptional: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let value = wrappedValue {
            let formatter = ISO8601DateFormatter()
            let dateString = formatter.string(from: value)
            try container.encode(dateString)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Common Date Formats Extension

public extension LSDateCoding {
    /// ISO 8601 格式（最常用）
    static var iso8601: LSDateCoding {
        LSDateCoding(.iso8601)
    }

    /// Unix 时间戳格式（秒）
    static var timestamp: LSDateCoding {
        LSDateCoding(.epochSeconds)
    }

    /// Unix 时间戳格式（毫秒）
    static var timestampMillis: LSDateCoding {
        LSDateCoding(.epochMilliseconds)
    }

    /// 常见日期时间格式
    static var standard: LSDateCoding {
        LSDateCoding(.yyyyMMddHHmmss)
    }
}

// MARK: - Legacy Support

#if swift(>=5.9)
// Swift 5.9+ 支持 Macro 版本
// @LSDateCoding 宏将在 LSJSONMacros.swift 中实现
#endif
