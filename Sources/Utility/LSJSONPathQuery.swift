//
//  LSJSONPathQuery.swift
//  LSJSONModel
//
//  Created by LSJSONModel on 2025/02/09.
//  JSON 路径查询 - 从嵌套 JSON 中提取数据
//

import Foundation

// MARK: - JSON 路径查询

/// JSON 路径查询扩展
public enum LSJSONPathError: Error, LocalizedError {
    case invalidPath
    case keyNotFound(String)
    case typeMismatch

    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "无效的 JSON 路径"
        case .keyNotFound(let key):
            return "找不到键: \(key)"
        case .typeMismatch:
            return "类型不匹配"
        }
    }
}

/// JSON 路径查询工具
public struct LSJSONPath {

    /// 从字典中获取指定路径的值
    /// - Parameters:
    ///   - dict: 源字典
    ///   - path: 路径（支持点号分隔，如 "user.profile.name"）
    /// - Returns: 获取到的值
    public static func getValue(from dict: [String: Any], path: String) throws -> Any {
        let keys = path.split(separator: ".").map { String($0) }
        return try traverse(dict: dict, keys: keys)
    }

    /// 从字典中获取指定路径的值（泛型版本）
    /// - Parameters:
    ///   - dict: 源字典
    ///   - path: 路径
    /// - Returns: 获取到的值
    public static func getValue<T>(_ dict: [String: Any], path: String) throws -> T {
        let value = try getValue(from: dict, path: path)
        guard let typedValue = value as? T else {
            throw LSJSONPathError.typeMismatch
        }
        return typedValue
    }

    /// 从字典中获取指定路径的值（带默认值）
    /// - Parameters:
    ///   - dict: 源字典
    ///   - path: 路径
    ///   - defaultValue: 默认值
    /// - Returns: 获取到的值或默认值
    public static func getValue<T>(_ dict: [String: Any], path: String, default defaultValue: T) -> T {
        do {
            return try getValue(dict, path: path) as T
        } catch {
            return defaultValue
        }
    }

    /// 遍历字典获取值
    private static func traverse(dict: [String: Any], keys: [String]) throws -> Any {
        var current: Any = dict

        for key in keys {
            // 处理数组索引（如 "users.0.name"）
            if let index = Int(key) {
                guard let array = current as? [Any] else {
                    throw LSJSONPathError.typeMismatch
                }
                guard index < array.count else {
                    throw LSJSONPathError.keyNotFound(key)
                }
                current = array[index]
            } else {
                // 处理字典键
                guard let currentDict = current as? [String: Any] else {
                    throw LSJSONPathError.typeMismatch
                }
                guard let value = currentDict[key] else {
                    throw LSJSONPathError.keyNotFound(key)
                }
                current = value
            }
        }

        return current
    }

    /// 设置字典中指定路径的值
    /// - Parameters:
    ///   - dict: 源字典（会被修改）
    ///   - path: 路径
    ///   - value: 要设置的值
    public static func setValue(_ dict: inout [String: Any], path: String, value: Any) throws {
        let keys = path.split(separator: ".").map { String($0) }
        try traverseAndSet(dict: &dict, keys: keys, value: value)
    }

    /// 遍历并设置值
    private static func traverseAndSet(dict: inout [String: Any], keys: [String], value: Any, index: Int = 0) throws {
        guard index < keys.count else { return }

        let key = keys[index]

        if index == keys.count - 1 {
            // 最后一个键，设置值
            dict[key] = value
        } else {
            // 中间键，继续遍历
            if dict[key] == nil {
                dict[key] = [:]
            }

            if var nextDict = dict[key] as? [String: Any] {
                try traverseAndSet(dict: &nextDict, keys: keys, value: value, index: index + 1)
                dict[key] = nextDict
            } else {
                throw LSJSONPathError.typeMismatch
            }
        }
    }
}

// MARK: - Dictionary 扩展

public extension Dictionary where Key == String, Value == Any {

    /// JSON 路径查询 - 链式语法
    var ls: LSJSONPathProxy {
        return LSJSONPathProxy(dictionary: self)
    }

    /// 获取指定路径的值
    /// - Parameter path: JSON 路径
    /// - Returns: 获取到的值
    func ls_value(for path: String) throws -> Any {
        return try LSJSONPath.getValue(from: self, path: path)
    }

    /// 获取指定路径的值（泛型）
    func ls_value<T>(for path: String) throws -> T {
        return try LSJSONPath.getValue(self, path: path)
    }

    /// 获取指定路径的值（带默认值）
    func ls_value<T>(for path: String, default defaultValue: T) -> T {
        return LSJSONPath.getValue(self, path: path, default: defaultValue)
    }

    /// 设置指定路径的值
    /// - Parameters:
    ///   - path: JSON 路径
    ///   - value: 要设置的值
    mutating func ls_setValue(_ value: Any, for path: String) throws {
        var mutableSelf = self
        try LSJSONPath.setValue(&mutableSelf, path: path, value: value)
        self = mutableSelf
    }
}

// MARK: - 链式代理

/// JSON 路径查询链式代理
public struct LSJSONPathProxy {
    private var dictionary: [String: Any]

    init(dictionary: [String: Any]) {
        self.dictionary = dictionary
    }

    /// 获取字符串
    public func string(for path: String, default defaultValue: String = "") -> String {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 获取整数
    public func int(for path: String, default defaultValue: Int = 0) -> Int {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 获取浮点数
    public func double(for path: String, default defaultValue: Double = 0.0) -> Double {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 获取布尔值
    public func bool(for path: String, default defaultValue: Bool = false) -> Bool {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 获取数组
    public func array(for path: String, default defaultValue: [Any] = []) -> [Any] {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 获取字典
    public func dictionary(for path: String, default defaultValue: [String: Any] = [:]) -> [String: Any] {
        return dictionary.ls_value(for: path, default: defaultValue)
    }

    /// 检查路径是否存在
    public func exists(_ path: String) -> Bool {
        do {
            _ = try dictionary.ls_value(for: path)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - KeyedDecodingContainer 扩展

extension KeyedDecodingContainer {

    /// 通过 JSON 路径解码
    /// - Parameters:
    ///   - path: JSON 路径
    ///   - type: 目标类型
    /// - Returns: 解码后的值
    public func decode<T>(_ path: String, as type: T.Type) throws -> T where T: Decodable {
        // 获取当前容器的所有数据
        let allData = try self.decode([String: Any].self)

        // 使用路径查询
        guard let value = try? LSJSONPath.getValue(from: allData, path: path) else {
            throw LSJSONPathError.keyNotFound(path)
        }

        // 将值转换为 Data
        let jsonData = try JSONSerialization.data(withJSONObject: value)

        // 解码为目标类型
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
}
