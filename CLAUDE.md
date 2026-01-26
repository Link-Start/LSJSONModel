# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**LSJSONModel** 是一个 JSON 转 Model 库，基于 Codable、HandyJSON、KakaJSON 的优点设计，支持 Swift 6 和 Objective-C。

### 设计理念

该项目采用**重写而非封装**的策略：
- 借鉴各库的优点重新实现，而不是简单封装第三方库
- 所有公开方法使用 `ls_` 前缀，不暴露参考库方法名
- 支持渐进式迁移和多种使用场景

### 三层架构

```
LSJSONModel 架构
├── Codable 层（类型安全，Swift 原生）
├── 性能层（参考 KakaJSON 优化）
└── 运行时层（参考 YYModel/HandyJSON 思想，OC 兼容）
```

---

## 代码结构

```
LSJSONModel/
├── Sources/
│   ├── LSJSONModel.swift           # 主入口，版本检测
│   ├── LSJSONDecoder.swift         # 统一解码器
│   ├── LSJSONEncoder.swift         # 统一编码器
│   ├── Codable/
│   │   ├── LSJSONCodable.swift     # Codable 扩展 + Property Wrappers
│   │   ├── LSJSONMacros.swift      # Swift Macros（待实现，文件为空）
│   │   └── LSCodingKeys.swift      # 编码键管理（待实现，文件为空）
│   ├── OC/
│   │   └── LSJSONOC.swift          # Objective-C 兼容协议
│   ├── Performance/                # 性能优化实现（目录为空，待实现）
│   ├── Tests/                      # 测试文件（目录为空，待实现）
│   └── Docs/
│       ├── Important.md            # 方法命名规范（重要）
│       ├── Migration.md            # 迁移指南（待实现，文件为空）
│       └── Reference.md            # 参考库说明（待实现，文件为空）
├── README.md
├── LSJSONModel_Design.md           # 完整设计文档
└── LSLogger.swift                  # 日志工具
```

---

## 关键约束：方法命名规范

**⚠️ 这是最重要的规则**

项目严禁在代码中暴露参考库的明显名称。详见 `Sources/Docs/Important.md`。

### 禁止使用的方法名

- ❌ `kakaFromJSON`, `kakaToJSON`, `kj_model`, `kj_`
- ❌ `handyFromJSON`, `handyToJSON`, `deserialize`, `hy_`
- ❌ `yy_modelWithJSON`, `yyToJSON`, `yy_model`, `yy_`
- ❌ `mj_setKeyValues`, `mjKeyValues`, `mj_`
- ❌ 任何包含 `ls_kaka`, `ls_handy`, `ls_yy`, `ls_mj` 的组合

### 正确的命名

所有公开方法统一使用 `ls_` 前缀，内部实现不暴露参考库名称：

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

---

## 核心组件

### 1. LSJSONDecoder / LSJSONEncoder

统一解码/编码器，支持两种模式：
- `codable`: 使用 Swift 原生 Codable（默认）
- `performance`: 极致性能模式（待实现）

```swift
// 切换模式
LSJSONDecoder.currentMode = .codable
LSJSONEncoder.setMode(.codable)
```

### 2. Codable 扩展

位于 `Sources/Codable/LSJSONCodable.swift`，提供便捷方法：

```swift
// 解码
Decodable.ls_decode(_ json: String) -> Self?
Decodable.ls_decodeFromJSONData(_ jsonData: Data) -> Self?
Decodable.ls_decodeFromDictionary(_ dict: [String: Any]) -> Self?
Decodable.ls_decodeArrayFromJSON(_ jsonString: String) -> [Self]?

// 编码
Encodable.ls_encode() -> String?
Encodable.ls_encodeToData() -> Data?
Encodable.ls_encodeToDictionary() -> [String: Any]?
Encodable.ls_encodeArrayToJSON(_ array: [Self]) -> String?
```

### 3. Property Wrappers

支持 iOS 13+ (Swift 5.0+)：

```swift
@LSDefault("")      // 默认值
@LSDateCoding(.iso8601)  // 日期格式化
```

### 4. OC 兼容层

位于 `Sources/OC/LSJSONOC.swift`，提供 `@objc` 协议：

```swift
@objc public protocol LSJSONModelOC {
    static func ls_decode(_ json: String) -> Self?
    static func ls_decodeFromData(_ data: Data) -> Self?
    static func ls_decodeFromDictionary(_ dict: [String: Any]) -> Self?
    func ls_encode() -> String?
    func ls_toDictionary() -> [String: Any]?
}
```

---

## 待实现功能

根据设计文档 `LSJSONModel_Design.md`，以下功能尚未实现：

### 1. Swift Macros（Swift 5.9+）
- `@LSModel` - 模型标识宏
- `@LSSnakeCaseKeys` - 自动处理 snake_case ↔ camelCase
- `@LSDefault` - 默认值宏版本
- `@LSDateCoding` - 日期格式宏版本
- `@LSIgnore` - 忽略字段

**文件**: `Sources/Codable/LSJSONMacros.swift`（当前为空）

### 2. 性能优化层
- 直接内存写入，绕过 KVC
- Swift runtime 反射
- 方法缓存优化
- 属性预计算

**目录**: `Sources/Performance/`（当前为空）

### 3. 编码键管理
- 自动属性映射
- 自定义键映射

**文件**: `Sources/Codable/LSCodingKeys.swift`（当前为空）

### 4. 测试
- 功能完整性测试
- 性能基准测试
- Swift 6 兼容性测试
- OC 桥接测试

**目录**: `Sources/Tests/`（当前为空）

---

## 开发注意事项

### 版本兼容性
- iOS 13+ (Swift 5.0+): 使用 Property Wrapper
- iOS 15+ (Swift 5.9+): 可选使用 Swift Macros
- 检测方式：`LSJSONModel.supportsMacros`

### 日志
使用私有 `ls_log()` 函数，仅在 DEBUG 模式输出。

### 错误处理
所有解码/编码方法失败时返回 `nil`，并打印错误信息到控制台。

---

## 相关文档

- `README.md` - 项目说明和使用示例
- `LSJSONModel_Design.md` - 完整设计方案
- `Sources/Docs/Important.md` - 方法命名规范（必读）
