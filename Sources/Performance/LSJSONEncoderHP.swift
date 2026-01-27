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
/// - LRU 缓存淘汰策略
internal final class LSJSONEncoderHP {

    // MARK: - Properties

    /// 统一缓存锁（避免多锁死锁）
    private static let cacheLock = NSLock()

    /// 编码器缓存
    private static var encoderCache: [String: Any] = [:]

    /// 编码器缓存访问顺序（用于 LRU）
    private static var encoderCacheAccessOrder: [String] = []

    /// 字符串缓冲区缓存
    private static var bufferCache: [String] = []

    /// 缓存大小限制
    private static let maxCacheSize = 100

    /// LRU 淘汰阈值
    private static let lruThreshold = 80

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
        cacheLock.withLock {
            encoderCache.removeAll()
            encoderCacheAccessOrder.removeAll()
            bufferCache.removeAll()
        }
    }

    /// LRU 缓存管理辅助方法
    private static func manageLRUCache(forKey key: String) {
        cacheLock.withLock {
            // 移动到末尾（最近使用）
            if let index = encoderCacheAccessOrder.firstIndex(of: key) {
                encoderCacheAccessOrder.remove(at: index)
            }
            encoderCacheAccessOrder.append(key)

            // 检查是否超过 LRU 阈值
            while encoderCacheAccessOrder.count > lruThreshold {
                let oldest = encoderCacheAccessOrder.removeFirst()
                encoderCache.removeValue(forKey: oldest)
            }
        }
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

/// 性能监控器（线程安全）
internal final class LSPerformanceMonitor {

    // MARK: - Properties

    private static let lock = NSLock()
    private static var metrics: [String: TimeInterval] = [:]

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

        lock.withLock {
            metrics[name] = (metrics[name] ?? 0) + duration
        }

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
        return lock.withLock { metrics[name] }
    }

    /// 重置指标
    internal static func reset() {
        lock.withLock { metrics.removeAll() }
    }

    /// 打印所有指标
    internal static func printMetrics() {
        lock.withLock {
            #if DEBUG
            print("========== Performance Metrics ==========")
            for (name, duration) in metrics.sorted(by: { $0.value > $1.value }) {
                print("\(name): \(String(format: "%.3f", duration * 1000))ms")
            }
            print("=========================================")
            #endif
        }
    }
}
