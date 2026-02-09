//
//  LSJSONModel+CoreData.swift
//  LSJSONModel
//
//  Created by Link on 2025/02/09.
//  Core Data 支持 - 为 NSManagedObject 提供 JSON 到 Core Data 对象的转换功能
//

#if os(iOS)

import CoreData
import Foundation

// MARK: - NSManagedObject JSON 扩展

public extension NSManagedObject {

    // MARK: 主键检测

    /// 获取实体的主键属性列表
    /// - Parameter context: Core Data 上下文
    /// - Returns: 主键属性数组
    func ls_primaryKeyAttributes(in context: NSManagedObjectContext) -> [NSAttributeDescription] {
        guard let entity = self.entity,
              let attributes = entity.attributesByName.values as? [NSAttributeDescription] else {
            return []
        }

        // 常见的主键属性名称
        let primaryKeyNames = ["id", "ID", "Id", "uuid", "UUID", "ObjectId", "objectID"]

        return attributes.filter { attribute in
            // 检查是否为主键名称
            if primaryKeyNames.contains(attribute.name) {
                return true
            }

            // 检查是否有自定义的主键标记
            if let userInfo = attribute.userInfo,
               userInfo["isPrimaryKey"] as? Bool == true {
                return true
            }

            return false
        }
    }

    // MARK: JSON 到对象转换

    /// 从 JSON 字典创建或更新 Core Data 对象
    /// - Parameters:
    ///   - dict: JSON 字典
    ///   - context: Core Data 上下文
    /// - Returns: 创建或更新后的对象
    @discardableResult
    func ls_objectWithKeyValues(_ dict: [String: Any], context: NSManagedObjectContext) throws -> Self {
        // 尝试查找已存在的对象（通过主键）
        let existingObject = try ls_fetchExistingObject(from: dict, context: context)
        let targetObject = existingObject ?? self

        // 设置属性值
        try targetObject.ls_setKeyValues(dict, context: context)

        return targetObject as! Self
    }

    /// 从 JSON 数据创建或更新 Core Data 对象
    /// - Parameters:
    ///   - jsonData: JSON 数据
    ///   - context: Core Data 上下文
    /// - Returns: 创建或更新后的对象
    @discardableResult
    func ls_fromJSON(_ jsonData: Data, context: NSManagedObjectContext) throws -> Self {
        let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        guard let jsonDict = dict else {
            throw LSJSONCoreDataError.invalidJSON
        }
        return try ls_objectWithKeyValues(jsonDict, context: context)
    }

    /// 从 JSON 字符串创建或更新 Core Data 对象
    /// - Parameters:
    ///   - jsonString: JSON 字符串
    ///   - context: Core Data 上下文
    /// - Returns: 创建或更新后的对象
    @discardableResult
    func ls_fromJSON(_ jsonString: String, context: NSManagedObjectContext) throws -> Self {
        guard let data = jsonString.data(using: .utf8) else {
            throw LSJSONCoreDataError.invalidJSON
        }
        return try ls_fromJSON(data, context: context)
    }

    // MARK: 批量操作

    /// 从 JSON 字典数组批量创建 Core Data 对象
    /// - Parameters:
    ///   - dictArray: JSON 字典数组
    ///   - context: Core Data 上下文
    /// - Returns: 创建的对象数组
    static func ls_objectsWithKeyValues(_ dictArray: [[String: Any]], context: NSManagedObjectContext) throws -> [Self] {
        var objects: [NSManagedObject] = []

        for dict in dictArray {
            let object = Self(context: context)
            if let createdObject = try? object.ls_objectWithKeyValues(dict, context: context) {
                objects.append(createdObject)
            }
        }

        return objects as! [Self]
    }

    // MARK: 私有辅助方法

    /// 通过主键查找已存在的对象
    private func ls_fetchExistingObject(from dict: [String: Any], context: NSManagedObjectContext) throws -> NSManagedObject? {
        let primaryKeyProperties = ls_primaryKeyAttributes(in: context)

        guard !primaryKeyProperties.isEmpty else {
            return nil
        }

        let entityName = NSStringFromClass(type(of: self))
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        var predicates: [NSPredicate] = []
        for property in primaryKeyProperties {
            if let value = dict[property.name] {
                predicates.append(NSPredicate(format: "%K == %@", property.name, value as! NSObject))
            }
        }

        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            fetchRequest.fetchLimit = 1

            let results = try context.fetch(fetchRequest) as? [NSManagedObject]
            return results?.first
        }

        return nil
    }

    /// 设置属性值
    private func ls_setKeyValues(_ dict: [String: Any], context: NSManagedObjectContext) throws {
        guard let entity = self.entity else {
            throw LSJSONCoreDataError.invalidEntity
        }

        // 获取所有属性
        let attributes = entity.attributesByName
        let relationships = entity.relationshipsByName

        // 设置基本属性
        for (name, value) in dict {
            if let attribute = attributes[name] {
                try ls_setAttribute(attribute, value: value)
            } else if let relationship = relationships[name] {
                try ls_setRelationship(relationship, value: value, context: context)
            }
        }
    }

    /// 设置单个属性值
    private func ls_setAttribute(_ attribute: NSAttributeDescription, value: Any) throws {
        let convertedValue = ls_convertValue(value, forAttribute: attribute)
        setValue(convertedValue, forKey: attribute.name)
    }

    /// 设置关系属性
    private func ls_setRelationship(_ relationship: NSRelationshipDescription, value: Any, context: NSManagedObjectContext) throws {
        if relationship.isToMany {
            // 一对多或多对多关系
            if let dictArray = value as? [[String: Any]] {
                let destinationEntity = relationship.destinationEntity ?? self.entity
                let entityName = destinationEntity.name!

                var relatedObjects: [NSManagedObject] = []
                for dict in dictArray {
                    if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? NSManagedObject {
                        try object.ls_setKeyValues(dict, context: context)
                        relatedObjects.append(object)
                    }
                }
                setValue(relatedObjects, forKey: relationship.name)
            }
        } else {
            // 一对一关系
            if let dict = value as? [String: Any] {
                let destinationEntity = relationship.destinationEntity ?? self.entity
                let entityName = destinationEntity.name!

                if let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? NSManagedObject {
                    try object.ls_setKeyValues(dict, context: context)
                    setValue(object, forKey: relationship.name)
                }
            }
        }
    }

    /// 值类型转换
    private func ls_convertValue(_ value: Any, forAttribute attribute: NSAttributeDescription) -> Any? {
        switch attribute.attributeType {
        case .stringAttributeType:
            return "\(value)"
        case .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
            if let intValue = value as? Int {
                return NSNumber(value: intValue)
            } else if let stringValue = value as? String, let intValue = Int(stringValue) {
                return NSNumber(value: intValue)
            }
            return value as? NSNumber ?? 0
        case .floatAttributeType, .doubleAttributeType:
            if let doubleValue = value as? Double {
                return NSNumber(value: doubleValue)
            } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
                return NSNumber(value: doubleValue)
            }
            return value as? NSNumber ?? 0.0
        case .booleanAttributeType:
            if let boolValue = value as? Bool {
                return NSNumber(value: boolValue)
            } else if let stringValue = value as? String {
                return NSNumber(value: (stringValue.lowercased() == "true" || stringValue == "1"))
            }
            return value as? NSNumber ?? false
        case .dateAttributeType:
            if let dateValue = value as? Date {
                return dateValue
            } else if let stringValue = value as? String {
                // 尝试 ISO8601 格式
                let isoFormatter = ISO8601DateFormatter()
                if let date = isoFormatter.date(from: stringValue) {
                    return date
                }
                // 尝试常见格式
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return formatter.date(from: stringValue)
            }
            return nil
        case .binaryDataAttributeType:
            if let dataValue = value as? Data {
                return dataValue
            } else if let stringValue = value as? String {
                return stringValue.data(using: .utf8)
            }
            return nil
        case .UUIDAttributeType:
            if let uuidValue = value as? UUID {
                return uuidValue
            } else if let stringValue = value as? String {
                return UUID(uuidString: stringValue)
            }
            return nil
        @unknown default:
            return value
        }
    }
}

// MARK: - Core Data 辅助类

/// Core Data 批量操作辅助类
public final class LSJSONCoreDataHelper {

    /// 批量保存 JSON 数据到 Core Data
    /// - Parameters:
    ///   - jsonArray: JSON 数组
    ///   - entityType: 实体类型
    ///   - context: Core Data 上下文
    ///   - completion: 完成回调
    public static func batchSave<T: NSManagedObject>(
        jsonArray: [[String: Any]],
        as entityType: T.Type,
        context: NSManagedObjectContext,
        completion: ((Result<Int, Error>) -> Void)? = nil
    ) {
        context.perform { [weak context] in
            guard let context = context else {
                completion?(.failure(LSJSONCoreDataError.contextDeallocated))
                return
            }

            do {
                var count = 0
                for dict in jsonArray {
                    let object = T(context: context)
                    if let _ = try? object.ls_objectWithKeyValues(dict, context: context) {
                        count += 1
                    }
                }
                try context.save()
                completion?(.success(count))
            } catch {
                completion?(.failure(error))
            }
        }
    }

    /// 批量获取并更新对象
    /// - Parameters:
    ///   - jsonArray: JSON 数组
    ///   - entityType: 实体类型
    ///   - context: Core Data 上下文
    ///   - completion: 完成回调
    public static func batchUpdate<T: NSManagedObject>(
        jsonArray: [[String: Any]],
        as entityType: T.Type,
        context: NSManagedObjectContext,
        completion: ((Result<Int, Error>) -> Void)? = nil
    ) {
        context.perform { [weak context] in
            guard let context = context else {
                completion?(.failure(LSJSONCoreDataError.contextDeallocated))
                return
            }

            do {
                var count = 0
                for dict in jsonArray {
                    let object = T(context: context)
                    if let _ = try? object.ls_objectWithKeyValues(dict, context: context) {
                        count += 1
                    }
                }
                try context.save()
                completion?(.success(count))
            } catch {
                completion?(.failure(error))
            }
        }
    }

    /// 同步批量保存（阻塞调用）
    /// - Parameters:
    ///   - jsonArray: JSON 数组
    ///   - entityType: 实体类型
    ///   - context: Core Data 上下文
    /// - Returns: 保存的对象数量
    /// - Throws: 错误信息
    public static func batchSaveSync<T: NSManagedObject>(
        jsonArray: [[String: Any]],
        as entityType: T.Type,
        context: NSManagedObjectContext
    ) throws -> Int {
        var count = 0
        for dict in jsonArray {
            let object = T(context: context)
            if let _ = try? object.ls_objectWithKeyValues(dict, context: context) {
                count += 1
            }
        }
        try context.save()
        return count
    }

    /// 从 JSON 文件导入数据
    /// - Parameters:
    ///   - fileURL: JSON 文件路径
    ///   - entityType: 实体类型
    ///   - context: Core Data 上下文
    ///   - completion: 完成回调
    public static func importFromFile<T: NSManagedObject>(
        at fileURL: URL,
        as entityType: T.Type,
        context: NSManagedObjectContext,
        completion: ((Result<Int, Error>) -> Void)? = nil
    ) {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

            if let array = jsonArray {
                batchSave(jsonArray: array, as: entityType, context: context, completion: completion)
            } else {
                completion?(.failure(LSJSONCoreDataError.invalidJSON))
            }
        } catch {
            completion?(.failure(error))
        }
    }

    /// 导出 Core Data 对象到 JSON 文件
    /// - Parameters:
    ///   - objects: Core Data 对象数组
    ///   - fileURL: 导出文件路径
    ///   - context: Core Data 上下文
    ///   - completion: 完成回调
    public static func exportToFile<T: NSManagedObject>(
        objects: [T],
        to fileURL: URL,
        context: NSManagedObjectContext,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        context.perform { [weak context] in
            guard let context = context else {
                completion?(.failure(LSJSONCoreDataError.contextDeallocated))
                return
            }

            do {
                let jsonArray = objects.compactMap { object -> [String: Any]? in
                    return object.ls_keyValues()
                }
                let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                try jsonData.write(to: fileURL)
                completion?(.success(()))
            } catch {
                completion?(.failure(error))
            }
        }
    }
}

// MARK: - NSManagedObject 扩展：导出方法

public extension NSManagedObject {

    /// 将 Core Data 对象转换为字典
    /// - Returns: 属性字典
    func ls_keyValues() -> [String: Any]? {
        guard let entity = self.entity else {
            return nil
        }

        var dict: [String: Any] = [:]

        // 获取所有属性值
        for (name, attribute) in entity.attributesByName {
            if let value = self.value(forKey: name) {
                dict[name] = ls_exportValue(value, forAttribute: attribute)
            }
        }

        // 获取关系值
        for (name, relationship) in entity.relationshipsByName {
            if let value = self.value(forKey: name) {
                if relationship.isToMany {
                    // 一对多关系
                    if let objects = value as? [NSManagedObject] {
                        dict[name] = objects.compactMap { $0.ls_keyValues() }
                    }
                } else {
                    // 一对一关系
                    if let object = value as? NSManagedObject {
                        dict[name] = object.ls_keyValues()
                    }
                }
            }
        }

        return dict
    }

    /// 导出值为 JSON 兼容格式
    private func ls_exportValue(_ value: Any, forAttribute attribute: NSAttributeDescription) -> Any {
        switch attribute.attributeType {
        case .dateAttributeType:
            if let date = value as? Date {
                let formatter = ISO8601DateFormatter()
                return formatter.string(from: date)
            }
            return value
        case .UUIDAttributeType:
            if let uuid = value as? UUID {
                return uuid.uuidString
            }
            return value
        case .binaryDataAttributeType:
            if let data = value as? Data {
                return data.base64EncodedString()
            }
            return value
        default:
            return value
        }
    }

    /// 将 Core Data 对象转换为 JSON 字符串
    /// - Returns: JSON 字符串
    func ls_JSONString() -> String? {
        guard let dict = ls_keyValues() else {
            return nil
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// 将 Core Data 对象数组转换为 JSON 字符串
    /// - Parameter objects: 对象数组
    /// - Returns: JSON 字符串
    static func ls_JSONString(from objects: [Self]) -> String? {
        let jsonArray = objects.compactMap { $0.ls_keyValues() }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - 错误定义

/// Core Data 相关错误
public enum LSJSONCoreDataError: LocalizedError {
    case invalidJSON
    case invalidEntity
    case contextDeallocated
    case conversionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "无效的 JSON 数据"
        case .invalidEntity:
            return "无效的实体"
        case .contextDeallocated:
            return "Core Data 上下文已释放"
        case .conversionFailed:
            return "值转换失败"
        }
    }
}

#endif
