//
//  LSJSONModel+MJExtension.swift
//  LSJSONModel/Sources
//
//  Created by link-start on 2026-01-26.
//  Copyright © 2026 link-start. All rights reserved.
//
//  MJExtension 风格的 API 扩展
//  方法名与 MJExtension 保持一致，仅添加 ls_ 前缀
//

import Foundation

// MARK: - LSJSONModelMJExtension

/// MJExtension 风格的 API 扩展
///
/// 提供与 MJExtension 完全一致的方法命名体验，仅添加 ls_ 前缀
public enum LSJSONModelMJExtension {

    // MARK: - 单个对象转换

    /// 从字典/JSON 字符串/JSON 数据创建对象
    ///
    /// 对应 MJExtension: `mj_objectWithKeyValues:`
    ///
    /// ```swift
    /// // 从字典
    /// let user = User.ls_objectWithKeyValues(["id": "123", "name": "张三"])
    ///
    /// // 从 JSON 字符串
    /// let user = User.ls_objectWithKeyValues("{\"id\":\"123\"}")
    ///
    /// // 从 JSON 数据
    /// let user = User.ls_objectWithKeyValues(jsonData)
    /// ```
    public static func ls_objectWithKeyValues<T: Decodable>(_ keyValues: Any) -> T? {
        switch keyValues {
        case let dict as [String: Any]:
            return T.ls_decodeFromDictionary(dict)
        case let string as String:
            return T.ls_decode(string)
        case let data as Data:
            return T.ls_decodeFromJSONData(data)
        default:
            return nil
        }
    }

    /// 从文件读取 JSON 创建对象
    ///
    /// 对应 MJExtension: `mj_objectWithFile:`
    ///
    /// ```swift
    /// let user = User.ls_objectWithFile("/path/to/user.json")
    /// ```
    public static func ls_objectWithFile<T: Decodable>(_ filePath: String) -> T? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return nil
        }
        return T.ls_decodeFromJSONData(data)
    }

    // MARK: - 数组转换

    /// 从字典数组创建对象数组
    ///
    /// 对应 MJExtension: `mj_objectArrayWithKeyValuesArray:`
    ///
    /// ```swift
    /// let users = User.ls_objectArrayWithKeyValuesArray([["id": "1"], ["id": "2"]])
    /// ```
    public static func ls_objectArrayWithKeyValuesArray<T: Decodable>(_ keyValuesArray: Any) -> [T]? {
        switch keyValuesArray {
        case let array as [[String: Any]]:
            return array.compactMap { T.ls_decodeFromDictionary($0) }
        case let string as String:
            return T.ls_decodeArrayFromJSON(string)
        case let data as Data:
            // 尝试解析 JSON 数组
            if let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
                return array.compactMap { T.ls_decodeFromDictionary($0) }
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - 对象转字典/JSON

    /// 对象转换为字典
    ///
    /// 对应 MJExtension: `mj_keyValues`
    ///
    /// ```swift
    /// let dict = user.ls_keyValues
    /// ```
    public static func ls_keyValues<T: Encodable>(_ object: T) -> [String: Any]? {
        return object.ls_toDictionary()
    }

    /// 对象转换为 JSON 字符串
    ///
    /// 对应 MJExtension: `mj_JSONString`
    ///
    /// ```swift
    /// let json = user.ls_JSONString
    /// ```
    public static func ls_JSONString<T: Encodable>(_ object: T) -> String? {
        return object.ls_encode()
    }

    /// 对象数组转换为字典数组
    ///
    /// 对应 MJExtension: `mj_keyValuesArray`
    ///
    /// ```swift
    /// let dicts = User.ls_keyValuesArray(users)
    /// ```
    public static func ls_keyValuesArray<T: Encodable>(_ objects: [T]) -> [[String: Any]]? {
        return T.ls_encodeArrayToJSON(objects).flatMap { jsonString in
            guard let data = jsonString.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return nil
            }
            return array
        }
    }

    /// 对象数组转换为 JSON 字符串
    ///
    /// 对应 MJExtension: `mj_JSONStringArray`
    ///
    /// ```swift
    /// let json = User.ls_JSONStringArray(users)
    /// ```
    public static func ls_JSONStringArray<T: Encodable>(_ objects: [T]) -> String? {
        return T.ls_encodeArrayToJSON(objects)
    }

    // MARK: - 文件操作

    /// 将对象写入 JSON 文件
    ///
    /// 对应 MJExtension: `mj_writeToFile:`
    ///
    /// ```swift
    /// let success = user.ls_writeToFile("/path/to/user.json")
    /// ```
    public static func ls_writeToFile<T: Encodable>(_ object: T, filePath: String) -> Bool {
        guard let jsonString = object.ls_encode(),
              let data = jsonString.data(using: .utf8) else {
            return false
        }

        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            return true
        } catch {
            return false
        }
    }

    // MARK: - 归档解档

    /// 归档对象到文件
    ///
    /// 对应 MJExtension: `mj_archiveToFile:`
    ///
    /// ```swift
    /// let success = User.ls_archiveToFile(user, filePath: "/path/to/user.archive")
    /// ```
    public static func ls_archiveToFile<T: LSJSONArchiverCompatible>(_ object: T, filePath: String) -> Bool {
        return object.ls_archiveFile(to: filePath)
    }

    /// 从文件解档对象
    ///
    /// 对应 MJExtension: `mj_unarchiveFromFile:`
    ///
    /// ```swift
    /// let user = User.ls_unarchiveFromFile("/path/to/user.archive")
    /// ```
    public static func ls_unarchiveFromFile<T: LSJSONUnarchivable>(_ filePath: String) -> T? {
        return T.ls_unarchive(from: filePath)
    }

    // MARK: - 属性设置 (仅 class)

    /// 设置对象的属性值
    ///
    /// 对应 MJExtension: `mj_setKeyValues:`
    ///
    /// 注意：此方法仅适用于 class 类型，struct 需要重新创建
    ///
    /// ```swift
    /// user.ls_setKeyValues(["id": "456", "name": "李四"])
    /// ```
    public static func ls_setKeyValues<T: LSJSONModelMutable>(_ object: T, keyValues: [String: Any]) -> Bool {
        return object.ls_setKeyValues(keyValues)
    }
}

// MARK: - Codable 扩展 (MJExtension 风格)

public extension Decodable {

    /// 从字典/JSON 创建对象
    ///
    /// 对应 MJExtension: `mj_objectWithKeyValues:`
    static func ls_objectWithKeyValues(_ keyValues: Any) -> Self? {
        return LSJSONModelMJExtension.ls_objectWithKeyValues(keyValues)
    }

    /// 从文件创建对象
    ///
    /// 对应 MJExtension: `mj_objectWithFile:`
    static func ls_objectWithFile(_ filePath: String) -> Self? {
        return LSJSONModelMJExtension.ls_objectWithFile(filePath)
    }

    /// 从数组创建对象数组
    ///
    /// 对应 MJExtension: `mj_objectArrayWithKeyValuesArray:`
    static func ls_objectArrayWithKeyValuesArray(_ keyValuesArray: Any) -> [Self]? {
        return LSJSONModelMJExtension.ls_objectArrayWithKeyValuesArray(keyValuesArray)
    }

    /// 从文件解档
    ///
    /// 对应 MJExtension: `mj_unarchiveFromFile:`
    static func ls_unarchiveFromFile(_ filePath: String) -> Self? where Self: LSJSONArchiverCompatible {
        return LSJSONModelMJExtension.ls_unarchiveFromFile(filePath)
    }
}

public extension Encodable {

    /// 转换为字典
    ///
    /// 对应 MJExtension: `mj_keyValues`
    var ls_keyValues: [String: Any]? {
        return LSJSONModelMJExtension.ls_keyValues(self)
    }

    /// 转换为 JSON 字符串
    ///
    /// 对应 MJExtension: `mj_JSONString`
    var ls_JSONString: String? {
        return LSJSONModelMJExtension.ls_JSONString(self)
    }

    /// 写入文件
    ///
    /// 对应 MJExtension: `mj_writeToFile:`
    func ls_writeToFile(_ filePath: String) -> Bool {
        return LSJSONModelMJExtension.ls_writeToFile(self, filePath: filePath)
    }

    /// 归档到文件
    ///
    /// 对应 MJExtension: `mj_archiveToFile:`
    func ls_archiveToFile(_ filePath: String) -> Bool where Self: LSJSONArchiverCompatible {
        return LSJSONModelMJExtension.ls_archiveToFile(self, filePath: filePath)
    }
}

public extension Array where Element: Encodable {

    /// 转换为字典数组
    ///
    /// 对应 MJExtension: `mj_keyValuesArray`
    var ls_keyValuesArray: [[String: Any]]? {
        return LSJSONModelMJExtension.ls_keyValuesArray(self)
    }

    /// 转换为 JSON 字符串
    ///
    /// 对应 MJExtension: `mj_JSONStringArray`
    var ls_JSONStringArray: String? {
        return LSJSONModelMJExtension.ls_JSONStringArray(self)
    }
}

// MARK: - 可变对象协议

/// 可修改属性的对象协议
///
/// 用于支持 `ls_setKeyValues` 方法
public protocol LSJSONModelMutable: AnyObject {
    func ls_setKeyValues(_ keyValues: [String: Any]) -> Bool
}

// MARK: - NSObject 扩展 (支持 ls_setKeyValues)

import ObjectiveC

extension NSObject: LSJSONModelMutable {

    /// 设置对象的属性值（MJExtension 风格）
    ///
    /// 对应 MJExtension: `mj_setKeyValues:`
    ///
    /// ```swift
    /// class User: NSObject {
    ///     var id: String = ""
    ///     var name: String = ""
    /// }
    ///
    /// let user = User()
    /// user.ls_setKeyValues(["id": "123", "name": "张三"])
    /// print(user.name) // "张三"
    /// ```
    public func ls_setKeyValues(_ keyValues: [String: Any]) -> Bool {
        // 遍历字典设置属性
        for (key, value) in keyValues {
            // 处理蛇形命名转驼峰
            let propertyName = _ls_camelCase(from: key)

            // 尝试设置属性
            if let propertyName = propertyName as? String {
                setValue(value, forKey: propertyName)
            }
        }
        return true
    }

    /// 蛇形命名转驼峰
    private func _ls_camelCase(from snakeCase: String) -> String {
        let components = snakeCase.split(separator: "_")
        guard components.count > 1 else { return snakeCase }

        return components.enumerated().map { index, component in
            index == 0 ? String(component) : component.capitalized
        }.joined()
    }
}

// MARK: - MJExtension 协议扩展

/// MJExtension 风格的映射协议
///
/// 对应 MJExtension 的 `mj_replacedKeyFromPropertyName`
@objc public protocol LSJSONModelMappingProvider: NSObjectProtocol {

    /// 自定义属性映射（JSON Key -> 属性名）
    ///
    /// 对应 MJExtension: `mj_replacedKeyFromPropertyName`
    ///
    /// ```swift
    /// class User: NSObject, LSJSONModelMappingProvider {
    ///     var userId: String = ""
    ///     var userName: String = ""
    ///
    ///     static func ls_replacedKeyFromPropertyName() -> [String: String] {
    ///         return ["userId": "user_id", "userName": "user_name"]
    ///     }
    /// }
    /// ```
    @objc optional static func ls_replacedKeyFromPropertyName() -> [String: String]

    /// 忽略的属性列表
    ///
    /// 对应 MJExtension: `mj_ignoredPropertyNames`
    ///
    /// ```swift
    /// static func ls_ignoredPropertyNames() -> [String] {
    ///     return ["debugInfo", "tempData"]
    /// }
    /// ```
    @objc optional static func ls_ignoredPropertyNames() -> [String]

    /// 数组属性中的对象类型映射
    ///
    /// 对应 MJExtension: `mj_objectClassInArray`
    ///
    /// ```swift
    /// class User: NSObject {
    ///     var friends: [User] = []
    ///
    ///     static func ls_objectClassInArray() -> [String: AnyClass] {
    ///         return ["friends": User.self]
    ///     }
    /// }
    /// ```
    @objc optional static func ls_objectClassInArray() -> [String: AnyClass]
}

// MARK: - 使用示例

/*
 ## MJExtension 风格 API 使用示例

 ### 1. 基础转换（与 MJExtension 完全一致的命名）

 ```swift
 // MJExtension
 User *user = [User mj_objectWithKeyValues:dict];
 NSDictionary *dict = user.mj_keyValues;
 NSString *json = user.mj_JSONString;

 // LSJSONModel (完全一致的方法名，仅添加 ls_ 前缀)
 let user = User.ls_objectWithKeyValues(dict)
 let dict = user.ls_keyValues
 let json = user.ls_JSONString
 ```

 ### 2. 数组操作

 ```swift
 // MJExtension
 NSArray *users = [User mj_objectArrayWithKeyValuesArray:array];
 NSArray *dicts = [User mj_keyValuesArrayWithObjectArray:users];
 NSString *json = [User mj_JSONStringArrayWithObjectArray:users];

 // LSJSONModel
 let users = User.ls_objectArrayWithKeyValuesArray(array)
 let dicts = users.ls_keyValuesArray
 let json = users.ls_JSONStringArray
 ```

 ### 3. 文件操作

 ```swift
 // MJExtension
 User *user = [User mj_objectWithFile:path];
 [user mj_writeToFile:path];
 [user mj_archiveToFile:path];
 User *user2 = [User mj_unarchiveFromFile:path];

 // LSJSONModel
 let user = User.ls_objectWithFile(path)
 user.ls_writeToFile(path)
 user.ls_archiveToFile(path)
 let user2 = User.ls_unarchiveFromFile(path)
 ```

 ### 4. 属性映射

 ```swift
 // MJExtension
 + (NSDictionary *)mj_replacedKeyFromPropertyName {
     return @{@"userId": @"id", @"userName": @"name"};
 }

 + (NSArray *)mj_ignoredPropertyNames {
     return @[@"debugInfo"];
 }

 // LSJSONModel (完全一致)
 class User: NSObject, LSJSONModelMappingProvider {
     var userId: String = ""
     var userName: String = ""

     static func ls_replacedKeyFromPropertyName() -> [String: String] {
         return ["userId": "id", "userName": "name"]
     }

     static func ls_ignoredPropertyNames() -> [String] {
         return ["debugInfo"]
     }
 }
 ```

 ### 5. 设置已有对象的属性

 ```swift
 // MJExtension
 [user mj_setKeyValues:dict];

 // LSJSONModel (完全一致)
 user.ls_setKeyValues(dict)
 ```

 ## 完整对照表

 | MJExtension | LSJSONModel | 说明 |
 |-------------|-------------|------|
 | `mj_objectWithKeyValues:` | `ls_objectWithKeyValues(_:)` | 从字典/JSON创建对象 |
 | `mj_objectWithFile:` | `ls_objectWithFile(_:)` | 从文件创建对象 |
 | `mj_keyValues` | `ls_keyValues` | 转换为字典 |
 | `mj_JSONString` | `ls_JSONString` | 转换为JSON字符串 |
 | `mj_setKeyValues:` | `ls_setKeyValues(_:)` | 设置属性值 |
 | `mj_writeToFile:` | `ls_writeToFile(_:)` | 写入文件 |
 | `mj_archiveToFile:` | `ls_archiveToFile(_:)` | 归档到文件 |
 | `mj_unarchiveFromFile:` | `ls_unarchiveFromFile(_:)` | 从文件解档 |
 | `mj_objectArrayWithKeyValuesArray:` | `ls_objectArrayWithKeyValuesArray(_:)` | 数组转换 |
 | `mj_keyValuesArray` | `ls_keyValuesArray` | 转换为数组 |
 | `mj_JSONStringArray` | `ls_JSONStringArray` | 数组转JSON |
 | `mj_replacedKeyFromPropertyName` | `ls_replacedKeyFromPropertyName()` | 属性映射 |
 | `mj_ignoredPropertyNames` | `ls_ignoredPropertyNames()` | 忽略属性 |
 | `mj_objectClassInArray` | `ls_objectClassInArray()` | 数组元素类型 |
 */
