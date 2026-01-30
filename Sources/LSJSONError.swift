//
//  LSJSONError.swift
//  LSJSONModel/Sources
//
//  Created by link-start on 2026-01-30.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONError

/// LSJSONModel 统一错误类型
///
/// 提供详细的错误信息和分类，便于调试和错误处理
public enum LSJSONError: Error, Sendable, LocalizedError {

    // MARK: - 解码错误

    /// JSON 解码失败
    case decodingFailed(Error)

    /// 无效的 JSON 数据
    case invalidJSONData

    /// JSON 字符串格式错误
    case invalidJSONString(String)

    /// 数据不是有效的 JSON
    case notJSON

    // MARK: - 编码错误

    /// JSON 编码失败
    case encodingFailed(Error)

    /// 对象无法序列化为 JSON
    case serializationFailed(Any)

    // MARK: - 类型错误

    /// 类型不匹配
    case typeMismatch(expected: String, actual: String, key: String?)

    /// 值为 nil 但属性不是可选类型
    case nilValueForNonOptional(property: String)

    /// 无法转换类型
    case typeConversionFailed(from: String, to: String)

    // MARK: - 映射错误

    /// 映射错误
    case mappingError(property: String, key: String?)

    /// 找不到属性
    case propertyNotFound(property: String)

    /// 找不到 JSON 键
    case keyNotFound(key: String)

    // MARK: - 验证错误

    /// 验证失败
    case validationFailed(reason: String)

    /// 自定义验证失败
    case customValidationFailed(property: String, reason: String)

    // MARK: - 文件错误

    /// 文件读取失败
    case fileReadFailed(path: String, Error?)

    /// 文件写入失败
    case fileWriteFailed(path: String, Error?)

    /// 文件不存在
    case fileNotFound(path: String)

    // MARK: - 系统错误

    /// 未知错误
    case unknown(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .decodingFailed(let error):
            return "JSON 解码失败: \(error.localizedDescription)"

        case .invalidJSONData:
            return "无效的 JSON 数据"

        case .invalidJSONString(let str):
            return "JSON 字符串格式错误: \(str)"

        case .notJSON:
            return "数据不是有效的 JSON"

        case .encodingFailed(let error):
            return "JSON 编码失败: \(error.localizedDescription)"

        case .serializationFailed(let obj):
            return "对象无法序列化为 JSON: \(type(of: obj))"

        case .typeMismatch(let expected, let actual, let key):
            if let key = key {
                return "类型不匹配 [\(key)]: 期望 \(expected)，实际 \(actual)"
            }
            return "类型不匹配: 期望 \(expected)，实际 \(actual)"

        case .nilValueForNonOptional(let property):
            return "属性 '\(property)' 为 nil，但不是可选类型"

        case .typeConversionFailed(let from, let to):
            return "无法从 \(from) 转换为 \(to)"

        case .mappingError(let property, let key):
            if let key = key {
                return "映射错误: 属性 '\(property)' 到键 '\(key)'"
            }
            return "映射错误: 属性 '\(property)'"

        case .propertyNotFound(let property):
            return "找不到属性: '\(property)'"

        case .keyNotFound(let key):
            return "找不到 JSON 键: '\(key)'"

        case .validationFailed(let reason):
            return "验证失败: \(reason)"

        case .customValidationFailed(let property, let reason):
            return "属性 '\(property)' 验证失败: \(reason)"

        case .fileReadFailed(let path, let error):
            if let error = error {
                return "读取文件失败 [\(path)]: \(error.localizedDescription)"
            }
            return "读取文件失败: \(path)"

        case .fileWriteFailed(let path, let error):
            if let error = error {
                return "写入文件失败 [\(path)]: \(error.localizedDescription)"
            }
            return "写入文件失败: \(path)"

        case .fileNotFound(let path):
            return "文件不存在: \(path)"

        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .decodingFailed:
            return "无法解析 JSON 数据"
        case .encodingFailed:
            return "无法序列化为 JSON"
        case .typeMismatch:
            return "JSON 类型与模型属性类型不匹配"
        case .nilValueForNonOptional:
            return "缺少必需的属性值"
        case .validationFailed:
            return "数据验证未通过"
        default:
            return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .decodingFailed:
            return "请检查 JSON 格式是否正确"
        case .encodingFailed:
            return "请确保对象实现了 Codable 协议"
        case .typeMismatch(let expected, _, _):
            return "请检查 JSON 中该字段类型是否为 \(expected)"
        case .nilValueForNonOptional(let property):
            return "请为属性 '\(property)' 提供值，或将其改为可选类型"
        case .mappingError(let property, let key):
            if let key = key {
                return "请检查 '\(property)' 的映射配置是否正确（键: '\(key)'）"
            }
            return "请检查 '\(property)' 的映射配置"
        case .fileNotFound:
            return "请确认文件路径是否正确"
        default:
            return nil
        }
    }
}

// MARK: - LSJSONError + CustomStringConvertible

extension LSJSONError: CustomStringConvertible {
    public var description: String {
        return errorDescription ?? "Unknown error"
    }
}

// MARK: - Convenience Initializers

extension LSJSONError {
    /// 从系统 DecodingError 创建 LSJSONError
    static func from(_ error: DecodingError) -> LSJSONError {
        let context = error.context
        switch error {
        case .typeMismatch(let type, let context):
            return .typeMismatch(
                expected: String(describing: type),
                actual: "unknown",
                key: context.codingPath.map { $0.stringValue }.joined(separator: ".")
            )
        case .valueNotFound(let type, let context):
            return .nilValueForNonOptional(
                property: context.codingPath.map { $0.stringValue }.joined(separator: ".") ?? String(describing: type)
            )
        case .keyNotFound(let key, let context):
            return .keyNotFound(
                key: context.codingPath.map { $0.stringValue + "." }.joined() + key.stringValue
            )
        case .dataCorrupted(let context):
            return .invalidJSONData
        @unknown default:
            return .decodingFailed(error)
        }
    }

    /// 从系统 EncodingError 创建 LSJSONError
    static func from(_ error: EncodingError) -> LSJSONError {
        return .encodingFailed(error)
    }
}

// MARK: - Result Extensions

extension Result where Failure == LSJSONError {
    /// 创建成功结果
    static func success(_ value: Success) -> Result {
        return .success(value)
    }

    /// 创建失败结果
    static func failure(_ error: LSJSONError) -> Result {
        return .failure(error)
    }

    /// 从 Decodable 创建结果
    static func fromDecoding<T: Decodable>(_ type: T.Type, from json: String) -> Result<T, LSJSONError> {
        do {
            let decoder = LSJSONDecoder()
            let result = try decoder.decode(T.self, from: json.data(using: .utf8) ?? Data())
            return .success(result)
        } catch let error as LSJSONError {
            return .failure(error)
        } catch let decodingError as DecodingError {
            return .failure(.from(decodingError))
        } catch {
            return .failure(.decodingFailed(error))
        }
    }

    /// 从 Encodable 创建 JSON 结果
    static func fromEncoding<T: Encodable>(_ value: T) -> Result<String, LSJSONError> {
        do {
            let encoder = LSJSONEncoder()
            let result = try encoder.encode(value)
            return .success(result)
        } catch let error as LSJSONError {
            return .failure(error)
        } catch {
            return .failure(.encodingFailed(error))
        }
    }
}

// MARK: - LSJSONError + CustomNSError (macOS/iOS)

#if canImport(Foundation)
extension LSJSONError: CustomNSError {
    public static var errorDomain: String {
        return "com.lsjsonmodel.error"
    }

    public var errorCode: Int {
        switch self {
        case .decodingFailed: return 1001
        case .invalidJSONData: return 1002
        case .invalidJSONString: return 1003
        case .notJSON: return 1004
        case .encodingFailed: return 2001
        case .serializationFailed: return 2002
        case .typeMismatch: return 3001
        case .nilValueForNonOptional: return 3002
        case .typeConversionFailed: return 3003
        case .mappingError: return 4001
        case .propertyNotFound: return 4002
        case .keyNotFound: return 4003
        case .validationFailed: return 5001
        case .customValidationFailed: return 5002
        case .fileReadFailed: return 6001
        case .fileWriteFailed: return 6002
        case .fileNotFound: return 6003
        case .unknown: return 9000
        }
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [
            NSLocalizedDescriptionKey: errorDescription ?? "Unknown error"
        ]

        if let failureReason = failureReason {
            info[NSLocalizedFailureReasonErrorKey] = failureReason
        }

        if let recoverySuggestion = recoverySuggestion {
            info[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
        }

        return info
    }
}
#endif
