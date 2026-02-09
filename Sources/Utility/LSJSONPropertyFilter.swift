//
//  LSJSONPropertyFilter.swift
//  LSJSONModel
//
//  Created by LSJSONModel on 2025/02/09.
//  全局属性过滤器 - 动态设置属性白名单/黑名单
//

import Foundation

// MARK: - 全局属性过滤器

/// 全局属性过滤器
public actor LSJSONPropertyFilter {

    // MARK: - 属性

    /// 单例
    public static let shared = LSJSONPropertyFilter()

    /// 允许的属性名称（白名单）
    private var allowedPropertyNames: [String: Set<String>] = [:]

    /// 忽略的属性名称（黑名单）
    private var ignoredPropertyNames: [String: Set<String>] = [:]

    /// 全局允许的属性名称（应用于所有类型）
    private var globalAllowedNames: Set<String>?

    /// 全局忽略的属性名称（应用于所有类型）
    private var globalIgnoredNames: Set<String>?

    // MARK: - 初始化

    private init() {}

    // MARK: - 全局配置

    /// 设置全局允许的属性名称
    /// - Parameter names: 允许的属性名称数组
    public static func setGlobalAllowedPropertyNames(_ names: [String]) {
        Task { await shared.setGlobalAllowed(names) }
    }

    /// 设置全局忽略的属性名称
    /// - Parameter names: 忽略的属性名称数组
    public static func setGlobalIgnoredPropertyNames(_ names: [String]) {
        Task { await shared.setGlobalIgnored(names) }
    }

    /// 清除全局过滤器
    public static func clearGlobalFilters() {
        Task { await shared.clearGlobal() }
    }

    // MARK: - 类型级配置

    /// 为指定类型设置允许的属性名称
    /// - Parameters:
    ///   - names: 允许的属性名称数组
    ///   - type: 类型
    public static func setAllowedPropertyNames(_ names: [String], for type: Any.Type) {
        Task {
            let typeName = String(describing: type)
            await shared.setAllowed(names, for: typeName)
        }
    }

    /// 为指定类型设置忽略的属性名称
    /// - Parameters:
    ///   - names: 忽略的属性名称数组
    ///   - type: 类型
    public static func setIgnoredPropertyNames(_ names: [String], for type: Any.Type) {
        Task {
            let typeName = String(describing: type)
            await shared.setIgnored(names, for: typeName)
        }
    }

    /// 清除指定类型的过滤器
    /// - Parameter type: 类型
    public static func clearFilters(for type: Any.Type) {
        Task {
            let typeName = String(describing: type)
            await shared.clear(for: typeName)
        }
    }

    // MARK: - 检查方法

    /// 检查属性是否应该被处理
    /// - Parameters:
    ///   - propertyName: 属性名称
    ///   - type: 类型
    /// - Returns: 是否应该处理该属性
    public static func shouldProcess(propertyName: String, for type: Any.Type) async -> Bool {
        return await shared.shouldProcess(propertyName: propertyName, for: type)
    }

    // MARK: - 内部方法

    /// 设置全局允许的属性名称
    private func setGlobalAllowed(_ names: [String]) {
        globalAllowedNames = Set(names)
    }

    /// 设置全局忽略的属性名称
    private func setGlobalIgnored(_ names: [String]) {
        globalIgnoredNames = Set(names)
    }

    /// 清除全局过滤器
    private func clearGlobal() {
        globalAllowedNames = nil
        globalIgnoredNames = nil
    }

    /// 设置类型级允许的属性名称
    private func setAllowed(_ names: [String], for typeName: String) {
        allowedPropertyNames[typeName] = Set(names)
    }

    /// 设置类型级忽略的属性名称
    private func setIgnored(_ names: [String], for typeName: String) {
        ignoredPropertyNames[typeName] = Set(names)
    }

    /// 清除类型级过滤器
    private func clear(for typeName: String) {
        allowedPropertyNames.removeValue(forKey: typeName)
        ignoredPropertyNames.removeValue(forKey: typeName)
    }

    /// 检查属性是否应该被处理
    private func shouldProcess(propertyName: String, for type: Any.Type) -> Bool {
        let typeName = String(describing: type)

        // 检查全局黑名单
        if let globalIgnored = globalIgnoredNames, globalIgnored.contains(propertyName) {
            return false
        }

        // 检查类型级黑名单
        if let typeIgnored = ignoredPropertyNames[typeName], typeIgnored.contains(propertyName) {
            return false
        }

        // 如果设置了白名单，检查是否在白名单中
        if let globalAllowed = globalAllowedNames, !globalAllowed.isEmpty {
            return globalAllowed.contains(propertyName)
        }

        if let typeAllowed = allowedPropertyNames[typeName], !typeAllowed.isEmpty {
            return typeAllowed.contains(propertyName)
        }

        // 默认处理所有属性
        return true
    }
}

// MARK: - 同步便捷方法（用于非异步上下文）

/// 同步便捷方法 - 用于非异步上下文
extension LSJSONPropertyFilter {

    /// 同步设置全局允许的属性名称（非异步，推荐在启动时调用）
    public static func setGlobalAllowedPropertyNamesSync(_ names: [String]) {
        let semaphore = DispatchSemaphore(value: 1)
        Task {
            await shared.setGlobalAllowed(names)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5) // 5秒超时
    }

    /// 同步设置全局忽略的属性名称（非异步，推荐在启动时调用）
    public static func setGlobalIgnoredPropertyNamesSync(_ names: [String]) {
        let semaphore = DispatchSemaphore(value: 1)
        Task {
            await shared.setGlobalIgnored(names)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5) // 5秒超时
    }

    /// 同步清除全局过滤器
    public static func clearGlobalFiltersSync() {
        let semaphore = DispatchSemaphore(value: 1)
        Task {
            await shared.clearGlobal()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 5) // 5秒超时
    }

    /// 同步检查属性是否应该被处理（使用缓存值）
    /// - Parameters:
    ///   - propertyName: 属性名称
    ///   - type: 类型
    /// - Returns: 是否应该处理该属性（可能返回过时的缓存值）
    public static func shouldProcessSync(propertyName: String, for type: Any.Type) -> Bool {
        // 默认返回 true，让用户根据需要使用异步版本
        return true
    }
}

// MARK: - 使用示例

/*
// 异步使用（推荐）
Task {
    await LSJSONPropertyFilter.setGlobalIgnoredPropertyNames(["debugInfo", "internalFlag"])
    await LSJSONPropertyFilter.setAllowedPropertyNames(["id", "title"], for: Post.self)
    let shouldProcess = await LSJSONPropertyFilter.shouldProcess(propertyName: "name", for: User.self)
}

// 同步使用（启动时配置）
LSJSONPropertyFilter.setGlobalIgnoredPropertyNamesSync(["debugInfo"])
LSJSONPropertyFilter.setGlobalAllowedPropertyNamesSync(["id", "name", "email"])

// 运行时检查
Task {
    let shouldProcess = await LSJSONPropertyFilter.shouldProcess(propertyName: "name", for: User.self)
    if shouldProcess {
        // 处理属性
    }
}
*/
