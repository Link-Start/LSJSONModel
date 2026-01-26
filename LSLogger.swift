//
//  LSLogger.swift
//  LSJSONModel
//
//  Created by link-start on 2026-01-24.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation
import OSLog

// MARK: - 日志级别

/// 日志级别
public enum LSLogLevel: Int, Sendable {
    case verbose = 0  // 详细日志
    case debug = 1     // 调试日志
    case info = 2      // 信息日志
    case warning = 3   // 警告日志
    case error = 4     // 错误日志
    case none = 99     // 不输出日志
}

// MARK: - 日志工具类

/// 统一日志工具类
/// 使用单例模式，全局唯一
/// 纯 Swift 实现，支持 Swift 6
public final class LSLogger: @unchecked Sendable {

    // MARK: - 单例
    public static let shared = LSLogger()

    // MARK: - 属性

    /// 当前日志级别
    private var currentLogLevel: LSLogLevel

    /// 是否启用日志
    private var isLoggingEnabled: Bool

    /// 日志前缀
    private var logPrefix: String

    /// 当前日志级别（公开，用于调试）
    public var logLevel: LSLogLevel {
        return currentLogLevel
    }

    /// 是否启用日志（公开，用于调试）
    public var loggingEnabled: Bool {
        return isLoggingEnabled
    }

    // MARK: - 初始化
    private init() {
        #if DEBUG
        self.currentLogLevel = .debug
        self.isLoggingEnabled = true
        self.logPrefix = "[LSJSONModel]"
        #else
        self.currentLogLevel = .none
        self.isLoggingEnabled = false
        self.logPrefix = "[LSJSONModel]"
        #endif
    }

    // MARK: - 公开方法

    /// 设置日志级别
    /// - Parameter level: 日志级别
    public func setLogLevel(_ level: LSLogLevel) {
        self.currentLogLevel = level
    }

    /// 启用或禁用日志
    /// - Parameter enabled: 是否启用
    public func setLoggingEnabled(_ enabled: Bool) {
        self.isLoggingEnabled = enabled
    }

    /// 设置日志前缀
    /// - Parameter prefix: 日志前缀
    public func setLogPrefix(_ prefix: String) {
        self.logPrefix = prefix
    }

    /// 使用 print 打印日志（推荐）
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志信息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func log(
        _ level: LSLogLevel,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.logInternal(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line,
            useNSLog: false
        )
    }

    /// 使用 print 打印任意类型的数据（泛型版本）
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 任意类型的数据
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func log<T>(
        _ level: LSLogLevel,
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.logInternal(
            level: level,
            message: String(describing: message),
            file: file,
            function: function,
            line: line,
            useNSLog: false
        )
    }

    /// 使用 NSLog 打印日志（兼容 NSLog 使用习惯）
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志信息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func nslog(
        _ level: LSLogLevel,
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.logInternal(
            level: level,
            message: message,
            file: file,
            function: function,
            line: line,
            useNSLog: true
        )
    }

    /// 使用 NSLog 打印任意类型的数据（泛型版本）
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 任意类型的数据
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func nslog<T>(
        _ level: LSLogLevel,
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.logInternal(
            level: level,
            message: String(describing: message),
            file: file,
            function: function,
            line: line,
            useNSLog: true
        )
    }

    /// 便捷方法：详细日志
    public static func verbose(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.verbose, message, file: file, function: function, line: line)
    }

    /// 便捷方法：详细日志（泛型版本）
    public static func verbose<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.verbose, message, file: file, function: function, line: line)
    }

    /// 便捷方法：调试日志
    public static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }

    /// 便捷方法：调试日志（泛型版本）
    public static func debug<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, file: file, function: function, line: line)
    }

    /// 便捷方法：信息日志
    public static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, file: file, function: function, line: line)
    }

    /// 便捷方法：信息日志（泛型版本）
    public static func info<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, file: file, function: function, line: line)
    }

    /// 便捷方法：警告日志
    public static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, file: file, function: function, line: line)
    }

    /// 便捷方法：警告日志（泛型版本）
    public static func warning<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, file: file, function: function, line: line)
    }

    /// 便捷方法：错误日志
    public static func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, file: file, function: function, line: line)
    }

    /// 便捷方法：错误日志（泛型版本）
    public static func error<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：详细日志
    public static func verboseNSLog(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.verbose, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：详细日志（泛型版本）
    public static func verboseNSLog<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.verbose, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：调试日志
    public static func debugNSLog(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.debug, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：调试日志（泛型版本）
    public static func debugNSLog<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.debug, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：信息日志
    public static func infoNSLog(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.info, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：信息日志（泛型版本）
    public static func infoNSLog<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.info, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：警告日志
    public static func warningNSLog(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.warning, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：警告日志（泛型版本）
    public static func warningNSLog<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.warning, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：错误日志
    public static func errorNSLog(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.error, message, file: file, function: function, line: line)
    }

    /// NSLog 便捷方法：错误日志（泛型版本）
    public static func errorNSLog<T>(
        _ message: T,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        nslog(.error, message, file: file, function: function, line: line)
    }

    // MARK: - 私有方法

    /// 内部日志实现
    private func logInternal(
        level: LSLogLevel,
        message: String,
        file: String,
        function: String,
        line: Int,
        useNSLog: Bool
    ) {
        // 检查是否启用日志
        guard isLoggingEnabled else { return }

        // 检查日志级别
        guard level.rawValue >= currentLogLevel.rawValue else { return }

        // 获取文件名（去掉路径）
        let fileName = (file as NSString).lastPathComponent

        // 格式化日志信息
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let levelString = level.emoji
        let logMessage = "\(timestamp) \(logPrefix) [\(fileName):\(line)] \(function) | \(message)"

        if useNSLog {
            // 使用 NSLog 打印
            NSLog("%@", logMessage)
        } else {
            // 使用 print 打印
            print(logMessage)
        }
    }
}

// MARK: - 全局便捷函数

// 使用 print 的全局函数
func log(_ level: LSLogLevel, _ message: String,
         file: String = #file, function: String = #function, line: Int = #line) {
    LSLogger.log(level, message, file: file, function: function, line: line)
}

func log<T>(_ level: LSLogLevel, _ message: T,
            file: String = #file, function: String = #function, line: Int = #line) {
    LSLogger.log(level, message, file: file, function: function, line: line)
}

func nslog(_ level: LSLogLevel, _ message: String,
           file: String = #file, function: String = #function, line: Int = #line) {
    LSLogger.nslog(level, message, file: file, function: function, line: line)
}

func nslog<T>(_ level: LSLogLevel, _ message: T,
              file: String = #file, function: String = #function, line: Int = #line) {
    LSLogger.nslog(level, message, file: file, function: function, line: line)
}

// 便捷全局函数
func verbose(_ message: String,
             file: String = #file, function: String = #function, line: Int = #line) {
    log(.verbose, message, file: file, function: function, line: line)
}

func verbose<T>(_ message: T,
                file: String = #file, function: String = #function, line: Int = #line) {
    log(.verbose, message, file: file, function: function, line: line)
}

func debug(_ message: String,
           file: String = #file, function: String = #function, line: Int = #line) {
    log(.debug, message, file: file, function: function, line: line)
}

func debug<T>(_ message: T,
              file: String = #file, function: String = #function, line: Int = #line) {
    log(.debug, message, file: file, function: function, line: line)
}

func info(_ message: String,
          file: String = #file, function: String = #function, line: Int = #line) {
    log(.info, message, file: file, function: function, line: line)
}

func info<T>(_ message: T,
             file: String = #file, function: String = #function, line: Int = #line) {
    log(.info, message, file: file, function: function, line: line)
}

func warning(_ message: String,
             file: String = #file, function: String = #function, line: Int = #line) {
    log(.warning, message, file: file, function: function, line: line)
}

func warning<T>(_ message: T,
                file: String = #file, function: String = #function, line: Int = #line) {
    log(.warning, message, file: file, function: function, line: line)
}

func error(_ message: String,
           file: String = #file, function: String = #function, line: Int = #line) {
    log(.error, message, file: file, function: function, line: line)
}

func error<T>(_ message: T,
              file: String = #file, function: String = #function, line: Int = #line) {
    log(.error, message, file: file, function: function, line: line)
}

// NSLog 便捷全局函数
func verboseNSLog(_ message: String,
                  file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.verbose, message, file: file, function: function, line: line)
}

func verboseNSLog<T>(_ message: T,
                     file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.verbose, message, file: file, function: function, line: line)
}

func debugNSLog(_ message: String,
                file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.debug, message, file: file, function: function, line: line)
}

func debugNSLog<T>(_ message: T,
                   file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.debug, message, file: file, function: function, line: line)
}

func infoNSLog(_ message: String,
               file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.info, message, file: file, function: function, line: line)
}

func infoNSLog<T>(_ message: T,
                  file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.info, message, file: file, function: function, line: line)
}

func warningNSLog(_ message: String,
                  file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.warning, message, file: file, function: function, line: line)
}

func warningNSLog<T>(_ message: T,
                     file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.warning, message, file: file, function: function, line: line)
}

func errorNSLog(_ message: String,
                file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.error, message, file: file, function: function, line: line)
}

func errorNSLog<T>(_ message: T,
                   file: String = #file, function: String = #function, line: Int = #line) {
    nslog(.error, message, file: file, function: function, line: line)
}

// MARK: - 便捷别名

/// LSLogger 别名（使用 print）
public typealias LSPrint = LSLogger

/// LSLogger 别名（使用 print，小写）
public typealias lsprint = LSLogger

/// LSLogger 别名（使用 NSLog）
public typealias LSNSLog = LSLogger

/// LSLogger 别名（使用 NSLog，小写）
public typealias lsNSLog = LSLogger

// MARK: - 日志级别扩展

extension LSLogLevel {
    /// 日志级别对应的 emoji
    var emoji: String {
        switch self {
        case .verbose:
            return "🔵"
        case .debug:
            return "🟢"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .none:
            return "🚫"
        }
    }
}

// MARK: - 日期格式化扩展

private extension DateFormatter {
    /// 日志时间戳格式
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
