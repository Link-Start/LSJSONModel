//
//  _LSTypeConverter.swift
//  LSJSONModel/Sources/Runtime
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//
//  Swift 6 严格并发模式重构版本
//

import Foundation

// MARK: - LSTypeConverter

/// 类型转换器 - 支持跨 Model 转换
///
/// 功能：
/// - 不同 Model 类型之间的属性映射
/// - 值类型转换
/// - 批量转换处理
internal final class _LSTypeConverter {

    // MARK: - Type Conversion

    /// 将一个 Model 转换为另一个 Model
    ///
    /// - Parameters:
    ///   - source: 源对象
    ///   - destinationType: 目标类型
    /// - Returns: 转换后的对象，失败返回 nil
    internal static func ls_convert<Source, Destination>(_ source: Source, to destinationType: Destination.Type) -> Destination? {
        // 获取源对象的字典表示
        guard let sourceDict = _objectToDictionary(source) else {
            #if DEBUG
            print("[LSTypeConverter] ❌ 无法将源对象转换为字典")
            #endif
            return nil
        }

        // 应用属性映射（从源类型到目标类型）
        let sourceType = type(of: source)
        let mappedDict = _applyMapping(from: sourceDict, sourceType: sourceType, destinationType: destinationType)

        // 尝试将字典转换为目标类型
        return _dictionaryToObject(mappedDict, as: destinationType)
    }

    /// 批量转换 Model 数组
    ///
    /// - Parameters:
    ///   - sources: 源对象数组
    ///   - destinationType: 目标类型
    /// - Returns: 转换后的对象数组
    internal static func ls_convertArray<Source, Destination>(_ sources: [Source], to destinationType: Destination.Type) -> [Destination] {
        return sources.compactMap { ls_convert($0, to: destinationType) }
    }

    // MARK: - Private Helpers

    /// 将对象转换为字典（移除 OptionalProtocol，使用 Mirror）
    ///
    /// - Parameter object: 输入对象
    /// - Returns: 字典表示，失败返回 nil
    private static func _objectToDictionary<T>(_ object: T) -> [String: Any]? {
        // 如果对象已经是字典
        if let dict = object as? [String: Any] {
            return dict
        }

        // 如果对象实现了 Encodable
        if let encodable = object as? Encodable {
            return encodable.ls_toDictionary()
        }

        // 使用 Mirror 反射
        let mirror = Mirror(reflecting: object)
        var dict: [String: Any] = [:]

        for child in mirror.children {
            guard let label = child.label else { continue }

            // 使用 Mirror 检查是否为可选值
            let value = _unwrapOptional(child.value)

            // 只添加非 nil 值
            if let unwrappedValue = value {
                dict[label] = unwrappedValue
            }
        }

        return dict.isEmpty ? nil : dict
    }

    /// 解包可选值（不使用 OptionalProtocol）
    ///
    /// - Parameter value: 输入值
    /// - Returns: 解包后的值，如果是非可选值则返回原值
    private static func _unwrapOptional(_ value: Any) -> Any? {
        // 使用 Mirror 检查是否为 Optional
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            // Optional 类型，检查是否有值
            // 通过检查 children 来判断
            if mirror.children.isEmpty {
                return nil  // Optional.none
            } else {
                // Optional.some，获取值
                return mirror.children.first?.value
            }
        }
        return value
    }

    /// 应用属性映射（从源类型到目标类型）
    ///
    /// - Parameters:
    ///   - dictionary: 源字典
    ///   - sourceType: 源类型
    ///   - destinationType: 目标类型
    /// - Returns: 映射后的字典
    private static func _applyMapping<T, U>(from dictionary: [String: Any], sourceType: T.Type, destinationType: U.Type) -> [String: Any] {
        var result: [String: Any] = [:]

        // 获取目标类型的属性名
        let destinationProperties = _propertyNames(of: destinationType)

        for sourceKey in dictionary.keys {
            let sourceValue = dictionary[sourceKey]

            // 查找目标类型中对应的属性名
            // 首先尝试直接匹配
            if destinationProperties.contains(sourceKey) {
                result[sourceKey] = sourceValue
            } else {
                // 尝试通过映射查找
                let destPropertyName = _findDestinationProperty(for: sourceKey, sourceType: sourceType, destinationType: destinationType)

                if let destProp = destPropertyName {
                    result[destProp] = sourceValue
                } else {
                    // 如果找不到对应属性，保留原始键
                    result[sourceKey] = sourceValue
                }
            }
        }

        return result
    }

    /// 查找目标类型中对应的属性名
    ///
    /// - Parameters:
    ///   - sourceKey: 源键名
    ///   - sourceType: 源类型
    ///   - destinationType: 目标类型
    /// - Returns: 目标属性名，未找到返回 nil
    private static func _findDestinationProperty<T, U>(for sourceKey: String, sourceType: T.Type, destinationType: U.Type) -> String? {
        // 获取源类型的 JSON 键
        let sourceJsonKey = LSJSONMapping.ls_jsonKey(for: sourceKey, in: sourceType)

        // 在目标类型的属性中查找，看哪个属性的 JSON 键匹配
        let destProperties = _propertyNames(of: destinationType)

        for prop in destProperties {
            let propJsonKey = LSJSONMapping.ls_jsonKey(for: prop, in: destinationType)
            if propJsonKey == sourceJsonKey {
                return prop
            }
        }

        return nil
    }

    /// 将字典转换为目标类型对象
    ///
    /// - Parameters:
    ///   - dictionary: 字典
    ///   - type: 目标类型
    /// - Returns: 转换后的对象，失败返回 nil
    private static func _dictionaryToObject<T>(_ dictionary: [String: Any], as type: T.Type) -> T? {
        // 如果类型实现了 Decodable
        if let decodableType = type as? Decodable.Type {
            // 首先将字典转换为 JSON 数据
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary) else {
                return nil
            }

            // 使用 JSONDecoder 解码
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let result = try decoder.decode(decodableType, from: jsonData)
                return result as? T
            } catch {
                #if DEBUG
                print("[LSTypeConverter] 解码失败: \(error)")
                #endif
                return nil
            }
        }

        return nil
    }

    /// 获取类型的所有属性名
    ///
    /// - Parameter type: 类型
    /// - Returns: 属性名集合
    private static func _propertyNames(of type: Any.Type) -> Set<String> {
        var names: Set<String> = []

        // 使用 Mirror 获取属性
        let mirror = Mirror(reflecting: type)
        for child in mirror.children {
            if let label = child.label {
                names.insert(label)
            }
        }

        return names
    }
}
