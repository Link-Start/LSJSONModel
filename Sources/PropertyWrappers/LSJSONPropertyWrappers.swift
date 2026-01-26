//
//  LSJSONPropertyWrappers.swift
//  LSJSONModel/Sources/PropertyWrappers
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

//
//  LSJSONModel Property Wrappers Module
//
//  本模块提供以下属性包装器，用于简化 JSON 解码/编码过程中的常见操作。
//
// MARK: - Property Wrappers Summary
//
// 1. @LSDefault - 默认值包装器
//    - 为解码过程中的可选属性提供默认值
//    - 支持基本类型：String, Int, Double, Float, Bool, Array, Dictionary
//    - 支持自定义类型通过 LSDefaultWritable 协议
//
// 2. @LSDateCoding - 日期格式化包装器
//    - 支持多种日期格式：ISO8601, RFC3339, Unix 时间戳等
//    - 支持自定义日期格式
//    - 支持可选日期类型 @LSDateCodingOptional
//
// 使用示例：
// ```swift
// import LSJSONModel
//
// struct User: Codable {
//     @LSDefault("") var name: String
//     @LSDefault(0) var age: Int
//     @LSDateCoding(.iso8601) var createdAt: Date
//     @LSDateCodingOptional(.yyyyMMddHHmmss) var updatedAt: Date?
// }
// ```
//

// MARK: - Module Documentation

/// LSJSONModel 属性包装器模块
///
/// 本模块提供了一组属性包装器，用于简化 JSON 解码/编码过程中的常见操作。
///
/// ## 功能概览
///
/// ### @LSDefault - 默认值包装器
///
/// 为解码过程中的可选属性提供默认值，避免处理 nil 值。
///
/// ```swift
/// struct User: Codable {
///     @LSDefault("") var name: String
///     @LSDefault(0) var age: Int
///     @LSDefault(false) var isActive: Bool
/// }
/// ```
///
/// ### @LSDateCoding - 日期格式化包装器
///
/// 为日期属性提供自定义格式的编码/解码支持。
///
/// ```swift
/// struct Event: Codable {
///     @LSDateCoding(.iso8601) var startTime: Date
///     @LSDateCoding(.yyyyMMddHHmmss) var endTime: Date
///     @LSDateCoding(.epochSeconds) var timestamp: Date
/// }
/// ```
///
/// ## 版本兼容性
///
/// - iOS 13+ / macOS 10.15+ (Swift 5.0+): 完整支持
/// - iOS 15+ / macOS 12+ (Swift 5.9+): 可选使用 Swift Macros 版本
///
/// ## 相关模块
///
/// - `LSJSONDecoder` / `LSJSONEncoder` - 核心/编码器
/// - `LSJSONMapping` - 属性映射系统
/// - `_LSArchiver` - 归档/解档功能
