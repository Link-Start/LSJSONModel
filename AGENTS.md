# AGENTS.md - 代理开发指南

本文文件为在此代码库中工作的 AI 代理（如你自己）提供指南。

## 📋 构建命令

**注意**：本项目当前处于开发早期阶段，暂无构建系统（无 Xcode 项目、无 Package.swift、无测试文件）。

- **编译**：暂不支持（需手动创建 Xcode 项目或 Swift Package）
- **Lint**：暂不支持
- **测试**：暂不支持（`Sources/Tests/` 目录为空）

## 📝 代码风格指南

### 文件头部注释
```swift
//
//  FileName.swift
//  LSJSONModel/Sources/Path
//
//  Created by link-start on YYYY-MM-DD.
//  Copyright © 2026 link-start. All rights reserved.
//
```

### 导入顺序
```swift
import Foundation
import OSLog  // 如需要
```

### 代码组织
- 使用 `// MARK: - SectionName` 分隔代码区域
- public 方法放在前面，private 方法放在后面
- 扩展按功能分组

### 缩进与格式
- 使用 4 空格缩进
- 大括号位置：左大括号与声明在同一行
- 行宽建议：不超过 120 字符

## 🔤 命名规范（核心约束）

### ⚠️ 严禁使用的方法名
**所有公开方法绝不能包含参考库的明显名称**：
- ❌ `kakaFromJSON`, `kakaToJSON`, `kj_model`, `kj_`
- ❌ `handyFromJSON`, `handyToJSON`, `deserialize`, `hy_`
- ❌ `yy_modelWithJSON`, `yyToJSON`, `yy_model`, `yy_`
- ❌ `mj_setKeyValues`, `mjKeyValues`, `mj_`
- ❌ `ls_kakaFromJSON`, `ls_handyFromJSON`, `ls_yyModel` 等组合

### ✅ 正确命名
所有公开方法统一使用 `ls_` 前缀：
```swift
// ✅ 正确
User.ls_decode(jsonString)
user.ls_encode()
user.ls_toDictionary()

// ❌ 错误
User.kj_model(json: jsonString)
User.deserialize(from: jsonString)
User.ls_kakaFromJSON(json)
```

### 类型命名
- 协议：`LSJSONModelOC`, `LSJSONCoding`
- 枚举：`LSLogLevel`, `LSDateFormat`
- 属性包装器：`@LSDefault`, `@LSDateCoding`
- 宏（Swift 5.9+）：`@LSModel`, `@LSSnakeCaseKeys`, `@LSIgnore`

## 🛡️ 类型安全

### 访问修饰符
- **public**：需要对外公开的 API
- **private**：内部实现细节
- **internal**（默认）：模块内部使用
- **internal struct/class**：内部实现类（私有）

### 类型注解
所有公开方法必须明确返回类型和参数类型：
```swift
public static func ls_decode(_ json: String) -> Self? { }
public func ls_encodeToData() -> Data? { }
```

### 泛型约束
```swift
public static func ls_encodeArrayToJSON<T: Encodable>(_ array: [T]) -> String? { }
```

## ❌ 错误处理

### 基本原则
- 所有解码/编码方法失败时返回 `nil`
- 使用 `ls_log()` 或 `print()` 输出错误信息（带 emoji 标识）
- 避免抛出异常（除非必要）

### 错误日志格式
```swift
// 使用 ls_log()（仅在 DEBUG 模式输出）
private func ls_log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    print("[LSJSONModel] \(file):\(line) \(function) - \(message)")
    #endif
}

// 使用场景
guard let data = json.data(using: .utf8) else {
    ls_log("❌ JSON 字符串转 Data 失败")
    return nil
}
```

### Print 错误格式
```swift
print("[LSJSONDecoder] ❌ 解码失败: \(error)")
print("[LSJSONEncoder] ⚠️ 数组编码失败: \(error)")
```

### Emoji 错误标识
- ❌ 错误
- ⚠️ 警告
- ✅ 成功

## 🏗️ 架构约束

### 三层架构
```
LSJSONModel 架构
├── 类型安全层（Swift 原生）
├── 性能层（参考第三方库优化）
└── 运行时层（参考第三方库思想，OC 兼容）
```

### 模式切换
```swift
// 解码模式
LSJSONDecoder.currentMode = .codable        // 类型安全（默认）
LSJSONDecoder.currentMode = .performance    // 极致性能（待实现）

// 编码模式
LSJSONEncoder.setMode(.codable)
LSJSONEncoder.setMode(.performance)
```

### 文件组织
```
Sources/
├── LSJSONModel.swift              # 主入口
├── LSJSONDecoder.swift            # 统一解码器
├── LSJSONEncoder.swift            # 统一编码器
├── Codable/
│   ├── LSJSONCoding.swift         # 编码扩展 + Property Wrappers
│   ├── LSJSONMacros.swift         # Swift Macros（待实现）
│   └── LSJSONKeys.swift           # 键管理（待实现）
└── OC/
    └── LSJSONOC.swift             # Objective-C 兼容协议
```

## 📅 版本兼容性

### iOS 版本支持
- **iOS 13+ (Swift 5.0+)**：使用 Property Wrapper
- **iOS 15+ (Swift 5.9+)**：可选使用 Swift Macros
- 检测方式：`LSJSONModel.supportsMacros`

### 版本检测
```swift
public struct LSJSONModel {
    /// 是否支持 Swift Macros (iOS 15+)
    public static let supportsMacros = swiftVersion >= "5.9"

    /// 是否只支持 Property Wrapper (iOS 13-14)
    public static let needsPropertyWrapper = !supportsMacros
}
```

## 📚 文档注释

### 公开 API 注释
```swift
/// 从 JSON 字符串解码
/// - Parameter json: JSON 字符串
/// - Returns: 解码后的实例，失败返回 nil
public static func ls_decode(_ json: String) -> Self? { }
```

### MARK 注释
```swift
// MARK: - Public Methods
// MARK: - Private Implementation
// MARK: - 类型安全模式解码
// MARK: - 极致性能模式编码
```

## 🔍 开发注意事项

### 日志使用
- 私有方法使用 `ls_log()`（仅在 DEBUG 模式）
- 公开方法使用 `print()` 输出错误信息
- 统一使用 emoji 标识日志级别

### Property Wrappers
- iOS 13+ 使用 `@propertyWrapper`
- 默认值：`@LSDefault("")`
- 日期格式：`@LSDateCoding(.iso8601)`

### Swift Macros（Swift 5.9+）
待实现，位于 `Sources/Codable/LSJSONMacros.swift`

## 🚫 禁止操作

1. **绝不可**在公开 API 中暴露参考库名称（kaka、handy、yy、mj）
2. **绝不可**使用 `as any` 或 `@ts-ignore` 抑制类型错误
3. **绝不可**修改现有 API 签名（除非文档明确要求）
4. **绝不可**直接调用第三方库的公开方法（必须内部封装）
5. **绝不可**提交未经验证的代码（必须通过编译）

## ✅ 代码审查清单

提交代码前检查：
- [ ] 所有公开方法使用 `ls_` 前缀
- [ ] 无参考库名称暴露（kaka、handy、yy、mj）
- [ ] 文件头部包含版权声明
- [ ] 使用 MARK 注释分隔代码区域
- [ ] 错误处理使用 ls_log() 或 print()
- [ ] 返回类型明确（使用 `?` 表示可选）
- [ ] 无类型警告或错误
- [ ] 遵循 4 空格缩进

---

**文档版本**：v1.0
**最后更新**：2026-01-24
**开发者**：link-start
