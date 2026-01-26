# 编码风格指南

LSJSONModel 项目的编码风格标准。

---

## 基本原则

1. **简洁** - 代码应该简洁明了
2. **安全** - 优先考虑类型安全和错误处理
3. **性能** - 注意性能影响
4. **可读** - 代码应该易于理解

---

## 文件组织

### 导入顺序

```swift
// 1. 系统框架
import Foundation

// 2. 内部模块
@testable import LSJSONModel
```

### MARK 注释

使用 `// MARK:` 分隔代码区域：

```swift
// MARK: - Public Properties

// MARK: - Private Methods

// MARK: - Nested Types
```

---

## 命名约定

### 类型和协议

```swift
// 类型名：PascalCase
public struct LSJSONDecoder { }
public protocol LSJSONMappingProvider { }

// 协议名：PascalCase，以 LS 或 LSJSON 开头
public protocol LSJSONModelOC { }

// 内部类型：前缀下划线
internal final class _LSJSONMappingCache { }
internal struct _LSPropertyMetadata { }
```

### 方法和属性

```swift
// 公开方法：ls_ 前缀，camelCase
public static func ls_decode(_ json: String) -> Self?
public func ls_encode() -> String?

// 内部方法：前缀下划线
private static func _decodeCodable() -> T?
internal func _applyMapping() -> [String: Any]

// 属性：camelCase
public static var currentMode: DecodeMode
private static var globalMapping: [String: String] = [:]
```

### 常量

```swift
// 全部大写，下划线分隔
private static let MAX_CACHE_SIZE = 100
internal let DEFAULT_TIMEOUT: TimeInterval = 30.0
```

---

## 代码格式

### 行宽

- 最大行宽：120 字符
- 超过时换行

### 缩进

- 使用 4 个空格缩进
- 不使用 Tab

### 花括号

```swift
// 左括号不换行，右括号换行
if condition {
    // 代码
}

// 闭包：单行可省略括号
users.map { $0.name }

// 多行闭包使用括号
users.map { user in
    user.name
}
```

---

## 错误处理

### 使用 guard

```swift
guard let data = json.data(using: .utf8) else {
    print("[LSJSONDecoder] ❌ JSON 字符串转 Data 失败")
    return nil
}
```

### 使用 do-catch

```swift
do {
    return try JSONDecoder().decode(T.self, from: data)
} catch {
    print("[LSJSONDecoder] ❌ Codable 解码失败: \(error)")
    return nil
}
```

---

## 注释规范

### 文件头注释

```swift
//
//  LSJSONDecoder.swift
//  LSJSONModel/Sources
//
//  Created by link-start on 2026-01-23.
//  Copyright © 2026 link-start. All rights reserved.
//
```

### MARK 注释

```swift
// MARK: - Public Methods

/// 从 JSON 字符串解码
///
/// 使用示例：
/// ```swift
/// let user = User.ls_decode(jsonString)
/// ```
///
/// - Parameter json: JSON 字符串
/// - Returns: 解码后的对象
public static func ls_decode(_ json: String) -> Self?
```

### 行内注释

```swift
// 检查缓存（使用锁保证线程安全）
lock.lock()
defer { lock.unlock() }
```

### 调试输出

```swift
#if DEBUG
print("[LSJSONDecoder] ✅ 解码成功")
#endif
```
