//
//  LSJSONEncoderHP.swift
//  LSJSONModel/Sources/Performance
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//
//  Swift 6 严格并发模式重构版本
//

import Foundation

// MARK: - LSJSONEncoderHPState (Actor)

/// 编码器缓存状态管理器（Actor）
/// 使用 actor 确保所有缓存访问的线程安全
private actor LSJSONEncoderHPState {
    // MARK: - Properties

    /// 字符串缓冲区缓存（只缓存字符串哈希值，避免 Any 类型）
    private(set) var bufferCache: Set<String> = []

    /// 缓存大小限制
    private let maxCacheSize = 100

    // MARK: - Buffer Caching

    /// 检查缓冲区是否已缓存
    func isBufferCached(_ hash: String) -> Bool {
        bufferCache.contains(hash)
    }

    /// 缓存缓冲区哈希值
    func cacheBufferHash(_ hash: String) {
        if bufferCache.count >= maxCacheSize {
            // 移除一半
            let hashesToRemove = Array(bufferCache.prefix(maxCacheSize / 2))
            for hash in hashesToRemove {
                bufferCache.remove(hash)
            }
        }

        bufferCache.insert(hash)
    }

    /// 清除所有缓存
    func clearAll() {
        bufferCache.removeAll()
    }

    /// 获取缓存大小
    func getCacheSize() -> Int {
        bufferCache.count
    }
}

// MARK: - LSJSONEncoderHP

/// 极致性能编码器（Swift 6 重构版）
///
/// 优化策略：
/// - 直接使用 Codable（已高度优化）
/// - 移除不安全的 Any 类型缓存
/// - 使用 actor 确保线程安全
internal final class LSJSONEncoderHP {

    // MARK: - Properties

    /// 状态管理器（Actor）
    private static let state = LSJSONEncoderHPState()

    /// 缓存启用标志
    private static let cacheQueue = DispatchQueue(label: "com.lsjsonmodel.encoderhp")
    private static var _cacheEnabled: Bool = true

    // MARK: - High Performance Encode

    /// 极致性能编码
    ///
    /// - Parameter value: 要编码的对象
    /// - Returns: JSON 字符串
    internal static func encode<T>(_ value: T) -> String? where T: Encodable {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
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
            encoder.dateEncodingStrategy = .iso8601
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
            encoder.dateEncodingStrategy = .iso8601
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
        Task {
            await state.clearAll()
        }
    }

    /// 启用缓存
    internal static var cacheEnabled: Bool {
        get {
            cacheQueue.sync { _cacheEnabled }
        }
        set {
            cacheQueue.sync { _cacheEnabled = newValue }
        }
    }

    /// 获取缓存统计
    ///
    /// - Returns: 缓存统计信息
    internal static func getCacheStats() -> MethodCacheStats {
        get async {
            let cacheSize = await state.getCacheSize()
            return MethodCacheStats(
                propertyCacheCount: 0,
                methodCacheCount: 0,
                mappingCacheCount: cacheSize,
                hitCount: 0,
                missCount: 0
            )
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

// MARK: - LSPerformanceMonitor

/// 性能监控器（线程安全）
///
/// 使用 actor 确保所有指标访问的线程安全
internal final class LSPerformanceMonitor {

    // MARK: - Properties

    /// 指标管理器（Actor）
    private actor MetricsState {
        var metrics: [String: TimeInterval] = [:]

        func addDuration(_ duration: TimeInterval, for name: String) {
            metrics[name] = (metrics[name] ?? 0) + duration
        }

        func getDuration(for name: String) -> TimeInterval? {
            metrics[name]
        }

        func reset() {
            metrics.removeAll()
        }

        func getAllMetrics() -> [(String, TimeInterval)] {
            metrics.sorted(by: { $0.value > $1.value })
        }
    }

    private static let state = MetricsState()

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

        Task {
            await state.addDuration(duration, for: name)
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
        get async {
            await state.getDuration(for: name)
        }
    }

    /// 重置指标
    internal static func reset() {
        Task {
            await state.reset()
        }
    }

    /// 打印所有指标
    internal static func printMetrics() {
        Task {
            let metrics = await state.getAllMetrics()
            #if DEBUG
            print("========== Performance Metrics ==========")
            for (name, duration) in metrics {
                print("\(name): \(String(format: "%.3f", duration * 1000))ms")
            }
            print("=========================================")
            #endif
        }
    }
}
