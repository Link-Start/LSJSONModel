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
public final class LSJSONPropertyFilter: Sendable {

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
        Task {
            await shared.setGlobalAllowed(names)
        }
    }

    /// 设置全局忽略的属性名称
    /// - Parameter names: 忽略的属性名称数组
    public static func setGlobalIgnoredPropertyNames(_ names: [String]) {
        Task {
            await shared.setGlobalIgnored(names)
        }
    }

    /// 清除全局过滤器
    public static func clearGlobalFilters() {
        Task {
            await shared.clearGlobal()
        }
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
    public static func shouldProcess(propertyName: String, for type: Any.Type) -> Bool {
        Task {
            return await shared.shouldProcess(propertyName: propertyName, for: type)
        }.value
    }

    // MARK: - Actor 内部方法

    private actor State {
        var globalAllowedNames: Set<String>?
        var globalIgnoredNames: Set<String>?
        var allowedPropertyNames: [String: Set<String>] = [:]
        var ignoredPropertyNames: [String: Set<String>] = [:]

        func setGlobalAllowed(_ names: [String]) {
            globalAllowedNames = Set(names)
        }

        func setGlobalIgnored(_ names: [String]) {
            globalIgnoredNames = Set(names)
        }

        func clearGlobal() {
            globalAllowedNames = nil
            globalIgnoredNames = nil
        }

        func setAllowed(_ names: [String], for typeName: String) {
            allowedPropertyNames[typeName] = Set(names)
        }

        func setIgnored(_ names: [String], for typeName: String) {
            ignoredPropertyNames[typeName] = Set(names)
        }

        func clear(for typeName: String) {
            allowedPropertyNames.removeValue(forKey: typeName)
            ignoredPropertyNames.removeValue(forKey: typeName)
        }

        func shouldProcess(propertyName: String, for type: Any.Type) -> Bool {
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

    private let state = State()

    private func setGlobalAllowed(_ names: [String]) {
        Task {
            await state.setGlobalAllowed(names)
        }
    }

    private func setGlobalIgnored(_ names: [String]) {
        Task {
            await state.setGlobalIgnored(names)
        }
    }

    private func clearGlobal() {
        Task {
            await state.clearGlobal()
        }
    }

    private func setAllowed(_ names: [String], for typeName: String) {
        Task {
            await state.setAllowed(names, for: typeName)
        }
    }

    private func setIgnored(_ names: [String], for typeName: String) {
        Task {
            await state.setIgnored(names, for: typeName)
        }
    }

    private func clear(for typeName: String) {
        Task {
            await state.clear(for: typeName)
        }
    }

    private func shouldProcess(propertyName: String, for type: Any.Type) -> Bool {
        Task {
            await state.shouldProcess(propertyName: propertyName, for: type)
        }.value
    }
}

// MARK: - 使用示例

/*
// 全局配置 - 忽略所有类型的 debugInfo 属性
LSJSONPropertyFilter.setGlobalIgnoredPropertyNames(["debugInfo", "internalFlag"])

// 全局配置 - 只处理指定属性
LSJSONPropertyFilter.setGlobalAllowedPropertyNames(["id", "name", "email"])

// 类型级配置
LSJSONPropertyFilter.setAllowedPropertyNames(["id", "title"], for: Post.self)
LSJSONPropertyFilter.setIgnoredPropertyNames(["password", "token"], for: User.self)

// 清除配置
LSJSONPropertyFilter.clearGlobalFilters()
LSJSONPropertyFilter.clearFilters(for: User.self)
*/
