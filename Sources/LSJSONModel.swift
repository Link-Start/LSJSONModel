//
//  LSJSONModel.swift
//  LSJSONModel
//
//  Created by link-start on 2026-01-23.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONModel Main Entry Point

/// LSJSONModel - 混合方案 JSON 转 Model 库
///
/// 支持三种场景：
/// 1. 新项目 - 使用 Codable（Swift 原生）
/// 2. 从 OC 迁移 - 使用 HandyJSON 封装（内部调用，不暴露参考库方法名）
/// 3. 追求性能 - 使用 KakaJSON 封装（内部调用，不暴露参考库方法名）
///
/// 版本支持：
/// - iOS 13+ (Swift 5.0+): 使用 Property Wrapper，不使用宏
/// - iOS 15+ (Swift 5.9+): 可选使用 Swift Macros
///
/// MJExtension 风格 API：
/// - 使用 `ls_objectWithKeyValues(_:)` 替代 `mj_objectWithKeyValues:`
/// - 使用 `ls_keyValues` 替代 `mj_keyValues`
/// - 使用 `ls_JSONString` 替代 `mj_JSONString`
/// - 使用 `ls_setKeyValues(_:)` 替代 `mj_setKeyValues:`
/// - 完整对照表见 `LSJSONModel+MJExtension.swift`
///
/// 开发者：link-start
/// 维护者：link-start

public struct LSJSONModel {

    /// 当前 Swift 版本（基于编译时配置）
    #if swift(>=6.0)
    public static let swiftVersion = "6.0"
    #elseif swift(>=5.9)
    public static let swiftVersion = "5.9"
    #else
    public static let swiftVersion = "5.8"
    #endif

    /// 当前 iOS 版本
    public static let iOSVersion = ProcessInfo.processInfo.operatingSystemVersionString

    /// 是否支持 Swift Macros (iOS 15+)
    public static let supportsMacros = swiftVersion >= "5.9"

    /// 是否只支持 Property Wrapper (iOS 13-14)
    public static let needsPropertyWrapper = !supportsMacros
}

// MARK: - Version Detection

extension LSJSONModel {

    /// 检查是否支持指定 iOS 版本
    /// 支持格式： "13.0", "13.1", "13.2.1" 等
    public static func supports(iOSVersion: String) -> Bool {
        // 使用 ProcessInfo 进行准确的版本比较
        let requiredComponents = iOSVersion.split(separator: ".").compactMap { Int($0) }
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion

        guard requiredComponents.count <= 3 else { return false }

        // 分段比较版本号
        let components = [currentVersion.majorVersion, currentVersion.minorVersion, currentVersion.patchVersion]

        for (index, required) in requiredComponents.enumerated() {
            if index >= components.count { return false }
            if components[index] < required {
                return false
            } else if components[index] > required {
                return true
            }
        }

        return true
    }
}

// MARK: - Logging

private func ls_log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    print("[LSJSONModel] \(file):\(line) \(function) - \(message)")
    #endif
}
