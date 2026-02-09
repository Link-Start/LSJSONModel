//
//  LSJSONSecureCoding.swift
//  LSJSONModel
//
//  Created by LSJSONModel on 2025/02/09.
//  NSSecureCoding 支持 - 增强归档解档安全性
//

import Foundation

// MARK: - NSSecureCoding 支持

/// 支持 NSSecureCoding 的协议
public protocol LSSecureCoding: NSObject, NSSecureCoding, Codable {
    /// 归档到 Data
    func ls_archiveData() throws -> Data

    /// 从 Data 解档
    static func ls_unarchive(from data: Data) throws -> Self

    /// 归档到文件
    func ls_archiveFile(to path: String) throws -> Bool

    /// 从文件解档
    static func ls_unarchive(from path: String) throws -> Self
}

// MARK: - 默认实现

public extension LSSecureCoding {

    /// 归档到 Data
    func ls_archiveData() throws -> Data {
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
    }

    /// 从 Data 解档
    static func ls_unarchive(from data: Data) throws -> Self {
        guard let object = try NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: data) as? Self else {
            throw LSJSONArchiveError.invalidData
        }
        return object
    }

    /// 归档到文件
    func ls_archiveFile(to path: String) throws -> Bool {
        let data = try ls_archiveData()
        try data.write(to: URL(fileURLWithPath: path))
        return true
    }

    /// 从文件解档
    static func ls_unarchive(from path: String) throws -> Self {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try ls_unarchive(from: data)
    }

    /// 检查是否支持 NSSecureCoding
    static var supportsSecureCoding: Bool {
        return true
    }
}

// MARK: - NSObject 扩展

/// NSObject 的 NSSecureCoding 支持
public extension NSObject {

    /// 声明支持 NSSecureCoding（需要在类中重写 supportsSecureCoding）
    static func ls_supportsSecureCoding() -> Bool {
        // 子类应该重写此方法
        return false
    }

    /// 安全归档到 Data
    func ls_secureArchiveData() throws -> Data {
        guard type(of: self).supportsSecureCoding() else {
            throw LSJSONArchiveError.secureCodingNotSupported
        }
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
    }

    /// 从 Data 安全解档
    static func ls_secureUnarchive(from data: Data) throws -> Self {
        guard Self.supportsSecureCoding() else {
            throw LSJSONArchiveError.secureCodingNotSupported
        }
        guard let object = try NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: data) as? Self else {
            throw LSJSONArchiveError.invalidData
        }
        return object
    }

    /// 安全归档到文件
    func ls_secureArchiveFile(to path: String) throws -> Bool {
        let data = try ls_secureArchiveData()
        try data.write(to: URL(fileURLWithPath: path))
        return true
    }

    /// 从文件安全解档
    static func ls_secureUnarchive(from path: String) throws -> Self {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try ls_secureUnarchive(from: data)
    }
}

// MARK: - Codable + NSSecureCoding 混合支持

/// 同时支持 Codable 和 NSSecureCoding 的便捷宏
@available(*, deprecated, message: "使用 LSSecureCoding 协议代替")
public typealias LSCodableSecureCoding = Codable & NSSecureCoding

// MARK: - 批量归档解档

/// 批量归档解档工具
public enum LSJSONSecureBatch {

    /// 批量归档
    /// - Parameters:
    ///   - objects: 对象数组
    ///   - requiringSecureCoding: 是否要求安全编码
    /// - Returns: 归档数据
    public static func archive<T: NSObject>(_ objects: [T], requiringSecureCoding: Bool = true) throws -> Data where T: NSSecureCoding {
        return try NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: requiringSecureCoding)
    }

    /// 批量解档
    /// - Parameters:
    ///   - data: 归档数据
    ///   - type: 对象类型
    /// - Returns: 对象数组
    public static func unarchive<T: NSObject>(_ data: Data, ofType type: T.Type) throws -> [T] where T: NSSecureCoding {
        guard let objects = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) as? [T] else {
            throw LSJSONArchiveError.invalidData
        }
        return objects
    }

    /// 批量归档到文件
    /// - Parameters:
    ///   - objects: 对象数组
    ///   - path: 文件路径
    ///   - requiringSecureCoding: 是否要求安全编码
    public static func archiveToFile<T: NSObject>(_ objects: [T], to path: String, requiringSecureCoding: Bool = true) throws where T: NSSecureCoding {
        let data = try archive(objects, requiringSecureCoding: requiringSecureCoding)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// 从文件批量解档
    /// - Parameters:
    ///   - path: 文件路径
    ///   - type: 对象类型
    /// - Returns: 对象数组
    public static func unarchiveFromFile<T: NSObject>(_ path: String, ofType type: T.Type) throws -> [T] where T: NSSecureCoding {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try unarchive(data, ofType: type)
    }
}

// MARK: - 错误定义

/// 归档错误
public enum LSJSONArchiveError: Error, LocalizedError {
    case invalidData
    case secureCodingNotSupported
    case archiveFailed(Error?)
    case unarchiveFailed(Error?)

    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "无效的归档数据"
        case .secureCodingNotSupported:
            return "该类型不支持 NSSecureCoding"
        case .archiveFailed(let error):
            return "归档失败: \(error?.localizedDescription ?? "未知错误")"
        case .unarchiveFailed(let error):
            return "解档失败: \(error?.localizedDescription ?? "未知错误")"
        }
    }
}

// MARK: - 使用示例

/*
// 定义支持 NSSecureCoding 的类
class User: NSObject, LSSecureCoding {
    var name: String
    var email: String

    init(name: String, email: String) {
        self.name = name
        self.email = email
        super.init()
    }

    // MARK: NSCoding

    required init?(coder: NSCoder) {
        self.name = coder.decodeObject(forKey: "name") as? String ?? ""
        self.email = coder.decodeObject(forKey: "email") as? String ?? ""
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(email, forKey: "email")
    }

    // MARK: NSSecureCoding

    static var supportsSecureCoding: Bool {
        return true
    }

    // Codable 支持（可选）
    enum CodingKeys: String, CodingKey {
        case name, email
    }
}

// 使用
let user = User(name: "张三", email: "zhangsan@example.com")

// 归档
let data = try user.ls_archiveData()
try user.ls_archiveFile(to: "/path/to/user.archive")

// 解档
let restoredUser = try User.ls_unarchive(from: data)
let restoredFromFile = try User.ls_unarchive(from: "/path/to/user.archive")

// 批量操作
let users = [user1, user2, user3]
let batchData = try LSJSONSecureBatch.archive(users)
let restoredUsers = try LSJSONSecureBatch.unarchive(batchData, ofType: User.self)
*/
