//
//  LSJSONPerformance.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

//
//  LSJSONPerformance.swift
//  LSJSONModel
//
//  性能层模块导出文件
//  统一导出所有性能优化组件
//

//
//  This file re-exports all performance-related components from the Performance module.
//

// MARK: - Performance Module Summary
//
// 本模块提供高性能的 JSON 编码/解码实现：
//
// 1. LSJSONDecoderHP - 极致性能解码器
//    - 直接内存写入
//    - 方法缓存优化
//    - 属性预计算
//
// 2. LSJSONEncoderHP - 极致性能编码器
//    - 流式编码
//    - 缓冲区预分配
//    - 类型特化处理
//
// 3. LSJSONMethodCache - 方法缓存管理器
//    - 属性元数据缓存
//    - 编码/解码方法缓存
//    - 映射关系缓存
//
// 4. LSJSONMetadata - 元数据定义
//    - 属性元数据结构
//    - 缓存统计信息
//    - 类型信息
//
// 使用示例：
// ```swift
// // 使用性能模式
// LSJSONDecoder.setMode(.performance)
// LSJSONEncoder.setMode(.performance)
//
// // 预热缓存
// LSJSONDecoderHP.warmup(types: [User.self, Post.self])
//
// // 获取缓存统计
// let stats = LSJSONDecoderHP.getCacheStats()
// print("Hit rate: \(stats.hitRate)")
// ```
//

// MARK: - Module Documentation

/// LSJSONModel 性能层模块
///
/// 本模块提供了一组高性能的 JSON 编码/解码实现，用于优化性能关键路径。
///
/// ## 功能概览
///
/// ### 极致性能解码器 (LSJSONDecoderHP)
///
/// 提供比标准 Codable 更快的解码性能，特别适用于大数据量场景。
///
/// ```swift
/// // 切换到性能模式
/// LSJSONDecoder.setMode(.performance)
///
/// // 预热常用类型的缓存
/// LSJSONDecoderHP.warmup(types: [User.self, Post.self])
///
/// // 正常使用
/// let user = User.ls_decode(jsonString)
/// ```
///
/// ### 极致性能编码器 (LSJSONEncoderHP)
///
/// 提供流式编码和缓冲区预分配，优化编码性能。
///
/// ```swift
/// // 切换到性能模式
/// LSJSONEncoder.setMode(.performance)
///
/// // 正常使用
/// let json = user.ls_encode()
/// ```
///
/// ### 方法缓存管理器 (LSJSONMethodCache)
///
/// 统一管理类型反射和方法调用的缓存。
///
/// ```swift
/// // 获取缓存统计
/// let stats = LSJSONMethodCache.shared.getStats()
/// print("Hit rate: \(stats.hitRate * 100)%")
///
/// // 预热类型缓存
/// LSJSONMethodCache.warmup(types: [User.self])
/// ```
///
/// ## 性能优化策略
///
/// 1. **方法缓存**: 缓存类型反射结果，避免重复反射开销
/// 2. **JSON 解析缓存**: 缓存 JSON 字符串解析结果
/// 3. **属性预计算**: 预先计算属性偏移量，支持直接内存访问
/// 4. **流式编码**: 对大数据使用流式处理，减少内存占用
///
/// ## 版本兼容性
///
/// - iOS 13+ / macOS 10.15+ (Swift 5.0+): 完整支持
/// - 推荐在性能关键场景使用
///
/// ## 相关模块
///
/// - `LSJSONDecoder` / `LSJSONEncoder` - 核心编码/解码器
/// - `LSJSONMapping` - 属性映射系统
/// - `_LSArchiver` - 归档/解档功能
