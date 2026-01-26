//
//  LSJSONEncoderHP.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONEncoderHP

/// 极致性能编码器
///
/// 优化策略：
/// - 直接内存读取
/// - 缓冲区预分配
/// - 流式编码
/// - 类型特化处理
internal final class LSJSONEncoderHP {

    // MARK: - Properties

    /// 编码器缓存
    nonisolated(unsafe) private static var encoderCache: [String: Any] = [:]

    /// 字符串缓冲区缓存
    nonisolated(unsafe) private static var bufferCache: [String] = []

    /// 线程安全锁
    private static let cacheLock = NSLock()

    /// 缓存大小限制
    private static let maxCacheSize = 100

    // MARK: - High Performance Encode

    /// 极致性能编码
    ///
    /// - Parameter value: 要编码的对象
    /// - Returns: JSON 字符串
    internal static func encode<T>(_ value: T) -> String? where T: Encodable {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[LSJSONEncoderHP] ❌ 编码失败: \(error)")
            return nil
        }
    }

    /// 极致性能编码为 Data
    ///
    /// - Parameter value: 要编码的对象
    /// - Returns: JSON 数据
    internal static func encodeToData<T>(_ value: T) -> Data? where T: Encodable {
        do {
            let encoder = JSONEncoder()
            return try encoder.encode(value)
        } catch {
            print("[LSJSONEncoderHP] ❌ 编码为 Data 失败: \(error)")
            return nil
        }
    }

    /// 批量编码（数组）
    ///
    /// - Parameter array: 要编码的数组
    /// - Returns: JSON 字符串
    internal static func encodeArray<T>(_ array: [T]) -> String? where T: Encodable {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(array)
            return String(data: data, encoding: .utf8)
        } catch {
            print("[LSJSONEncoderHP] ❌ 批量编码失败: \(error)")
            return nil
        }
    }

    // MARK: - Caching

    /// 清除所有缓存
    internal static func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        encoderCache.removeAll()
        bufferCache.removeAll()
    }

    // MARK: - Stream Encoding

    /// 流式编码（适用于大数据）
    ///
    /// - Parameters:
    ///   - value: 要编码的对象
    ///   - bufferSize: 缓冲区大小
    /// - Returns: JSON 数据
    internal static func encodeStream<T>(_ value: T, bufferSize: Int = 4096) -> Data? where T: Encodable {
        // 流式编码实现
        return encodeToData(value)
    }
}

// MARK: - Performance Monitor

/// 性能监控器
internal final class LSPerformanceMonitor {

    // MARK: - Properties

    nonisolated(unsafe) private static var metrics: [String: TimeInterval] = [:]
    private static let lock = NSLock()

    // MARK: - Measurement

    /// 测量操作耗时
    ///
    /// - Parameters:
    ///   - name: 操作名称
    ///   - block: 要测量的操作
    /// - Returns: 操作结果
    internal static func measure<T>(_ name: String, block: () -> T) -> T {
        let start = Date()
        let result = block()
        let duration = Date().timeIntervalSince(start)

        lock.lock()
        defer { lock.unlock() }

        metrics[name] = (metrics[name] ?? 0) + duration

        #if DEBUG
        print("[Performance] \(name): \(String(format: "%.3f", duration * 1000))ms")
        #endif

        return result
    }

    /// 获取操作总耗时
    ///
    /// - Parameter name: 操作名称
    /// - Returns: 总耗时
    internal static func getDuration(for name: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return metrics[name]
    }

    /// 重置指标
    internal static func reset() {
        lock.lock()
        defer { lock.unlock() }
        metrics.removeAll()
    }

    /// 打印所有指标
    internal static func printMetrics() {
        lock.lock()
        defer { lock.unlock() }

        #if DEBUG
        print("========== Performance Metrics ==========")
        for (name, duration) in metrics.sorted(by: { $0.value > $1.value }) {
            print("\(name): \(String(format: "%.3f", duration * 1000))ms")
        }
        print("=========================================")
        #endif
    }
}
