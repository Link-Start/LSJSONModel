//
//  LSJSONDecoder.swift
//  LSJSONModel/Sources
//
//  Created by link-start on 2026-01-23.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONDecoder

/// LSJSONModel 统一解码器
///
/// 提供统一的 ls_decode() 方法
/// 内部根据场景选择解码策略
public struct LSJSONDecoder {

    /// 解码模式
    public enum DecodeMode {
        case codable          // Codable 模式（类型安全）
        case performance      // 极致性能模式
    }

    /// 内部状态管理器（线程安全）
    private static let stateManager = _DecoderState()

    /// 当前解码模式（线程安全访问）
    public static var currentMode: DecodeMode {
        get { stateManager.getMode() }
        set {
            stateManager.setMode(newValue)
            print("[LSJSONDecoder] ✅ 解码模式切换为: \(newValue)")
        }
    }

    /// 从 JSON 字符串解码
    public static func decode<T: Decodable>(_ json: String, as type: T.Type) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return decode(data, as: type)
    }

    /// 从 JSON 数据解码
    public static func decode<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        switch currentMode {
        case .codable:
            return _decodeCodable(data, as: type)
        case .performance:
            return _decodePerformance(data, as: type)
        }
    }

    /// 从字典解码
    public static func decode<T: Decodable>(_ dict: [String: Any], as type: T.Type) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return decode(data, as: type)
    }

    /// 从 JSON 数组解码
    public static func decodeArray<T: Decodable>(_ json: String, as type: T.Type) -> [T]? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("[LSJSONDecoder] ⚠️ 数组解码失败: \(error)")
            return nil
        }
    }
}

// MARK: - Decoder State Manager

/// 解码器状态管理器（内部，线程安全）
private final class _DecoderState {
    private let lock = NSLock()
    private var _currentMode: LSJSONDecoder.DecodeMode = .codable

    func getMode() -> LSJSONDecoder.DecodeMode {
        lock.withLock { _currentMode }
    }

    func setMode(_ mode: LSJSONDecoder.DecodeMode) {
        lock.withLock { _currentMode = mode }
    }
}

// MARK: - Codable 模式解码

private extension LSJSONDecoder {

    /// Codable 模式解码（内部，统一）
    static func _decodeCodable<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[LSJSONDecoder] ❌ Codable 解码失败: \(error)")
            return nil
        }
    }
}

// MARK: - 极致性能模式解码

private extension LSJSONDecoder {

    static func _decodePerformance<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        // 极致性能模式 - 使用缓存和预计算
        // 参考 KakaJSON 的优化策略

        // 1. 首先检查是否有缓存的对象类型信息
        let typeName = String(describing: type)
        if LSJSONDecoderHP.cacheEnabled,
           let cachedInfo = LSJSONDecoderHP._getTypeCache(for: typeName) {
            // 使用缓存信息进行优化解码
            return _decodeWithCache(data, as: type, cacheInfo: cachedInfo)
        }

        // 2. 没有缓存时使用标准 Codable，并缓存类型信息
        let result = _decodeCodable(data, as: type)

        // 3. 缓存类型信息以供下次使用
        if LSJSONDecoderHP.cacheEnabled {
            LSJSONDecoderHP._cacheTypeInfo(for: type)
        }

        return result
    }

    /// 使用缓存信息进行解码
    private static func _decodeWithCache<T: Decodable>(_ data: Data, as type: T.Type, cacheInfo: _LSTypeCacheInfo) -> T? {
        // 使用反射直接设置属性值（绕过 KVC）
        // 这里提供一个基础实现
        // 实际的优化需要在编译时或通过宏实现

        // 当前使用标准 Codable
        return _decodeCodable(data, as: type)
    }
}

// MARK: - Type Cache Info

/// 类型缓存信息（用于性能优化）
internal struct _LSTypeCacheInfo {
    let propertyNames: [String]
    let propertyTypes: [String: Any.Type]
    let cached: Bool
}

// MARK: - Performance Extensions

extension LSJSONDecoderHP {

    private static let typeCacheLock = NSLock()
    private static var _typeCacheEnabled: Bool = true
    private static var _typeCache: [String: _LSTypeCacheInfo] = [:]

    /// 获取类型缓存
    internal static func _getTypeCache(for typeName: String) -> _LSTypeCacheInfo? {
        typeCacheLock.withLock { _typeCache[typeName] }
    }

    /// 缓存类型信息
    internal static func _cacheTypeInfo<T>(for type: T.Type) {
        let typeName = String(describing: type)

        // 使用反射获取类型信息
        // 注意：对于 metatype，我们只能获取有限的信息
        let propertyNames: [String] = []
        let propertyTypes: [String: Any.Type] = [:]

        // 尝试创建实例来反射（如果类型有默认初始化器）
        // 如果无法创建实例，则缓存空信息
        let cacheInfo = _LSTypeCacheInfo(
            propertyNames: propertyNames,
            propertyTypes: propertyTypes,
            cached: true
        )

        typeCacheLock.withLock { _typeCache[typeName] = cacheInfo }
    }

    /// 清除类型缓存
    internal static func _clearTypeCache() {
        typeCacheLock.withLock { _typeCache.removeAll() }
    }
}

// MARK: - Decodable Extension

extension Decodable {

    /// 从 JSON 字符串解码
    public static func ls_decode(_ json: String) -> Self? {
        guard let data = json.data(using: .utf8) else { return nil }
        return ls_decodeFromJSONData(data)
    }

    /// 从 JSON 数据解码
    public static func ls_decodeFromJSONData(_ jsonData: Data) -> Self? {
        return LSJSONDecoder.decode(jsonData, as: Self.self)
    }

    /// 从字典解码
    public static func ls_decodeFromDictionary(_ dict: [String: Any]) -> Self? {
        return LSJSONDecoder.decode(dict, as: Self.self)
    }

    /// 从 JSON 数组解码
    public static func ls_decodeArrayFromJSON(_ jsonString: String) -> [Self]? {
        return LSJSONDecoder.decodeArray(jsonString, as: Self.self)
    }
}
