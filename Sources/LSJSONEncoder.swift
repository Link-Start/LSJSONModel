//
//  LSJSONEncoder.swift
//  LSJSONModel/Sources
//
//  Created by link-start on 2026-01-23.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONEncoder

/// LSJSONModel 统一编码器
///
/// 提供统一的 ls_encode() 方法
/// 内部根据模式选择编码策略
public struct LSJSONEncoder {

    /// 编码模式
    public enum EncodeMode {
        case codable          // Codable 模式（类型安全）
        case performance      // 极致性能模式
    }

    /// 内部状态管理器（线程安全）
    private static let stateManager = _EncoderState()

    /// 当前编码模式（线程安全访问）
    public static var currentMode: EncodeMode {
        get { stateManager.getMode() }
        set {
            stateManager.setMode(newValue)
            print("[LSJSONEncoder] ✅ 编码模式切换为: \(newValue)")
        }
    }

    /// 切换编码模式
    public static func setMode(_ mode: EncodeMode) {
        currentMode = mode
    }
}

// MARK: - Encoder State Manager

/// 编码器状态管理器（内部，线程安全）
private final class _EncoderState {
    private let lock = NSLock()
    private var _currentMode: LSJSONEncoder.EncodeMode = .codable

    func getMode() -> LSJSONEncoder.EncodeMode {
        lock.withLock { _currentMode }
    }

    func setMode(_ mode: LSJSONEncoder.EncodeMode) {
        lock.withLock { _currentMode = mode }
    }
}

// MARK: - Extension: Encodable

extension Encodable {
    
    /// 编码为 JSON 字符串
    public func ls_encode() -> String? {
        switch LSJSONEncoder.currentMode {
        case .codable:
            return _encodeCodable()
        case .performance:
            return _encodePerformance()
        }
    }
    
    /// 编码为 JSON 数据
    public func ls_encodeToData() -> Data? {
        switch LSJSONEncoder.currentMode {
        case .codable:
            return _encodeCodableToData()
        case .performance:
            return _encodePerformanceToData()
        }
    }
    
    /// 编码为字典
    public func ls_toDictionary() -> [String: Any]? {
        guard let data = ls_encodeToData() else {
            print("[LSJSONEncoder] ❌ 编码为 Data 失败")
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("[LSJSONEncoder] ❌ 编码为字典失败: \(error)")
            return nil
        }
    }
    
    /// 编码为 JSON 数组
    public static func ls_encodeArrayToJSON<T: Encodable>(_ array: [T]) -> String? {
        guard let data = try? JSONEncoder().encode(array) else {
            print("[LSJSONEncoder] ❌ 数组编码为 Data 失败")
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Codable 模式编码

private extension Encodable {
    
    /// Codable 模式编码为 JSON 字符串
    func _encodeCodable() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[LSJSONEncoder] ❌ Codable 编码失败: \(error)")
            return nil
        }
    }
    
    /// Codable 模式编码为 JSON 数据
    func _encodeCodableToData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(self)
        } catch {
            print("[LSJSONEncoder] ❌ Codable Data 编码失败: \(error)")
            return nil
        }
    }
}

// MARK: - 极致性能模式编码

private extension Encodable {

    /// 极致性能模式编码（参考 KakaJSON 优化）
    func _encodePerformance() -> String? {
        guard let data = _encodePerformanceToData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 极致性能模式编码为 JSON 数据
    func _encodePerformanceToData() -> Data? {
        // 使用反射获取属性并手动构建 JSON
        let mirror = Mirror(reflecting: self)
        var result: [String: Any] = [:]

        for child in mirror.children {
            guard let label = child.label else { continue }

            // 处理可选值 - 简化版本，不使用 OptionalProtocol
            let value: Any?
            // 检查是否为 nil
            if Mirror(reflecting: child.value).displayStyle == .optional {
                // 对于可选类型，需要检查是否为 nil
                // 使用反射来检查可选值的实际内容
                let optionalMirror = Mirror(reflecting: child.value)
                if optionalMirror.children.isEmpty {
                    // 这是 nil
                    value = nil
                } else {
                    // 有值，获取第一个子值
                    value = optionalMirror.children.first?.value
                }
            } else {
                value = child.value
            }

            if let unwrappedValue = value {
                result[label] = unwrappedValue
            }
        }

        // 使用 JSONSerialization 转换为 JSON 数据
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted]) else {
            return nil
        }

        return jsonObject
    }
}
