//
//  _LSArchiver.swift
//  LSJSONModel/Sources/Runtime
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONArchiver

/// LSJSONModel 归档/解档管理器
/// 类似 MJExtension 的归档/解档功能
///
/// 功能：
/// - 对象归档到 Data
/// - 对象归档到文件
/// - 从 Data 解档
/// - 从文件解档
/// - 批量归档/解档
public final class LSJSONArchiver {

    // MARK: - Archive to Data

    /// 将 Model 归档为 Data
    /// 类似 MJExtension 的 mj_archiveToData
    ///
    /// 使用示例：
    /// ```swift
    /// let user = User(id: "123", name: "张三")
    /// let data = user.ls_archiveData()
    /// ```
    ///
    /// - Parameter object: 要归档的对象
    /// - Returns: 归档数据，失败返回 nil
    public static func ls_archiveData<T>(_ object: T) -> Data? where T: NSObject & NSCoding {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        } catch {
            print("[LSJSONArchiver] ❌ 归档到 Data 失败: \(error)")
            return nil
        }
    }

    /// 批量归档 Model 数组到 Data
    ///
    /// - Parameter objects: 要归档的对象数组
    /// - Returns: 归档数据，失败返回 nil
    public static func ls_archiveArrayData<T>(_ objects: [T]) -> Data? where T: NSObject & NSCoding {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: false)
        } catch {
            print("[LSJSONArchiver] ❌ 批量归档到 Data 失败: \(error)")
            return nil
        }
    }

    // MARK: - Archive to File

    /// 将 Model 归档到文件
    /// 类似 MJExtension 的 mj_archiveToFile
    ///
    /// 使用示例：
    /// ```swift
    /// let user = User(id: "123", name: "张三")
    /// let success = user.ls_archiveFile("/path/to/user.archive")
    /// ```
    ///
    /// - Parameters:
    ///   - object: 要归档的对象
    ///   - path: 文件路径
    /// - Returns: true 表示成功，false 表示失败
    public static func ls_archiveFile<T>(_ object: T, to path: String) -> Bool where T: NSObject & NSCoding {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: path))

            #if DEBUG
            print("[LSJSONArchiver] ✅ 归档到文件成功: \(path)")
            #endif

            return true
        } catch {
            print("[LSJSONArchiver] ❌ 归档到文件失败 [\(path)]: \(error)")
            return false
        }
    }

    /// 批量归档 Model 数组到文件
    ///
    /// - Parameters:
    ///   - objects: 要归档的对象数组
    ///   - path: 文件路径
    /// - Returns: true 表示成功，false 表示失败
    public static func ls_archiveArrayFile<T>(_ objects: [T], to path: String) -> Bool where T: NSObject & NSCoding {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: path))

            #if DEBUG
            print("[LSJSONArchiver] ✅ 批量归档到文件成功: \(path) (\(objects.count) 个对象)")
            #endif

            return true
        } catch {
            print("[LSJSONArchiver] ❌ 批量归档到文件失败 [\(path)]: \(error)")
            return false
        }
    }

    // MARK: - Unarchive from Data

    /// 从 Data 解档 Model
    /// 类似 MJExtension 的 mj_unarchiveWithData
    ///
    /// 使用示例：
    /// ```swift
    /// let user = User.ls_unarchive(from: data)
    /// ```
    ///
    /// - Parameters:
    ///   - data: 归档数据
    ///   - type: 目标类型
    /// - Returns: 解档后的对象，失败返回 nil
    public static func ls_unarchive<T>(from data: Data, as type: T.Type) -> T? where T: NSObject, T: NSCoding {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: type, from: data)
        } catch {
            print("[LSJSONArchiver] ❌ 从 Data 解档失败: \(error)")
            return nil
        }
    }

    /// 从 Data 解档 Model 数组
    ///
    /// - Parameters:
    ///   - data: 归档数据
    ///   - type: 目标类型
    /// - Returns: 解档后的对象数组，失败返回 nil
    public static func ls_unarchiveArray<T>(from data: Data, as type: T.Type) -> [T]? where T: NSObject, T: NSCoding {
        do {
            guard let objects = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, type], from: data) as? [T] else {
                print("[LSJSONArchiver] ❌ 解档数据类型不匹配")
                return nil
            }
            return objects
        } catch {
            print("[LSJSONArchiver] ❌ 从 Data 解档数组失败: \(error)")
            return nil
        }
    }

    // MARK: - Unarchive from File

    /// 从文件解档 Model
    /// 类似 MJExtension 的 mj_unarchiveWithFile
    ///
    /// 使用示例：
    /// ```swift
    /// let user = User.ls_unarchive(from: "/path/to/user.archive")
    /// ```
    ///
    /// - Parameters:
    ///   - path: 文件路径
    ///   - type: 目标类型
    /// - Returns: 解档后的对象，失败返回 nil
    public static func ls_unarchive<T>(from path: String, as type: T.Type) -> T? where T: NSObject, T: NSCoding {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return ls_unarchive(from: data, as: type)
        } catch {
            print("[LSJSONArchiver] ❌ 从文件解档失败 [\(path)]: \(error)")
            return nil
        }
    }

    /// 从文件解档 Model 数组
    ///
    /// - Parameters:
    ///   - path: 文件路径
    ///   - type: 目标类型
    /// - Returns: 解档后的对象数组，失败返回 nil
    public static func ls_unarchiveArray<T>(from path: String, as type: T.Type) -> [T]? where T: NSObject, T: NSCoding {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return ls_unarchiveArray(from: data, as: type)
        } catch {
            print("[LSJSONArchiver] ❌ 从文件解档数组失败 [\(path)]: \(error)")
            return nil
        }
    }
}

// MARK: - LSJSONArchiverCompatible Protocol

/// 归档/解档便捷方法协议
public protocol LSJSONArchiverCompatible: AnyObject {

    /// 归档到 Data
    func ls_archiveData() -> Data?

    /// 归档到文件
    func ls_archiveFile(to path: String) -> Bool
}

// MARK: - Default Implementation for NSObject & NSCoding

/// 为 NSCoding 对象提供归档便捷方法
public protocol LSJSONArchivable: NSObject {
    func ls_archiveData() -> Data?
    func ls_archiveFile(to path: String) -> Bool
}

extension LSJSONArchivable where Self: NSCoding {

    /// 归档到 Data
    public func ls_archiveData() -> Data? {
        return LSJSONArchiver.ls_archiveData(self)
    }

    /// 归档到文件
    public func ls_archiveFile(to path: String) -> Bool {
        return LSJSONArchiver.ls_archiveFile(self, to: path)
    }
}

// MARK: - NSCoding Unarchive Extension

/// 为 NSCoding 对象提供解档方法
public protocol LSJSONUnarchivable: NSObject {
    static func ls_unarchive(from data: Data) -> Self?
    static func ls_unarchive(from path: String) -> Self?
}

extension LSJSONUnarchivable where Self: NSObject & NSCoding {

    /// 从 Data 解档
    public static func ls_unarchive(from data: Data) -> Self? {
        return LSJSONArchiver.ls_unarchive(from: data, as: self)
    }

    /// 从文件解档
    public static func ls_unarchive(from path: String) -> Self? {
        return LSJSONArchiver.ls_unarchive(from: path, as: self)
    }
}

// MARK: - Array Extensions

/// 数组批量归档扩展 - 直接实现，避免泛型约束问题
public extension Array {

    /// 批量归档到 Data
    /// 仅支持 NSObject & NSCoding 类型的元素
    func ls_archiveArrayData() -> Data? {
        // 验证所有元素都遵循 NSCoding
        for element in self {
            guard let _ = element as? NSObject, element is NSCoding else {
                print("[LSJSONArchiver] ❌ 数组元素不支持 NSCoding")
                return nil
            }
        }

        // 使用 NSKeyedArchiver 直接归档
        do {
            // 将数组转换为 NSArray (Cocoa 框架会处理类型转换)
            let nsArray = self as NSArray
            return try NSKeyedArchiver.archivedData(withRootObject: nsArray, requiringSecureCoding: false)
        } catch {
            print("[LSJSONArchiver] ❌ 数组归档失败: \(error)")
            return nil
        }
    }

    /// 批量归档到文件
    /// 仅支持 NSObject & NSCoding 类型的元素
    func ls_archiveArrayFile(to path: String) -> Bool {
        guard let data = ls_archiveArrayData() else {
            return false
        }

        do {
            try data.write(to: URL(fileURLWithPath: path))
            #if DEBUG
            print("[LSJSONArchiver] ✅ 数组归档到文件成功: \(path) (\(self.count) 个对象)")
            #endif
            return true
        } catch {
            print("[LSJSONArchiver] ❌ 数组归档到文件失败 [\(path)]: \(error)")
            return false
        }
    }
}

/// 数组批量解档 - 需要类型遵循 NSObject 和 NSCoding
public extension Array {

    /// 从 Data 解档数组
    static func ls_unarchiveArray<T>(from data: Data, as type: T.Type) -> [T]? where T: NSObject & NSCoding {
        return LSJSONArchiver.ls_unarchiveArray(from: data, as: type)
    }

    /// 从文件解档数组
    static func ls_unarchiveArray<T>(from path: String, as type: T.Type) -> [T]? where T: NSObject & NSCoding {
        return LSJSONArchiver.ls_unarchiveArray(from: path, as: type)
    }
}
