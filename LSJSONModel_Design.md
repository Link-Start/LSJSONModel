# LSJSONModel 设计方案

> 基于 Codable、HandyJSON、KakaJSON 优点的 JSON 转 Model 库  
> 兼容 Swift 6 和 Objective-C  
> 版本：v1.0  
> 开发者：link-start  
> 维护者：link-start  
> 日期：2026-01-23

---

## 📋 目录

- [1. 设计原则](#1-设计原则)
- [2. 命名规范](#2-命名规范)
- [3. 架构设计](#3-架构设计)
- [4. 使用场景](#4-使用场景)
- [5. API 设计](#5-api-设计)
- [6. 核心特性](#6-核心特性)
- [7. 使用示例](#7-使用示例)
- [8. 迁移指南](#8-迁移指南)
- [9. 性能对比](#9-性能对比)

---

## 1. 设计原则

### 1.1 核心目标

#### ✅ 三种使用场景，三个最佳方案

| 场景 | 推荐方案 | 底层实现 | 性能目标 |
|------|----------|----------|----------|
| **新项目** | Codable（Swift 原生） | Swift 官方 Codable | 编译时类型安全 |
| **从 OC 迁移** | HandyJSON | 基于 YYModel 思想 | 接近 YYModel 性能 |
| **追求性能** | KakaJSON | 优化反射机制 | 极致性能 |

### 1.2 设计理念

1. **重写库，而非封装** - 不对参考库进行简单封装，而是借鉴优点重新实现
2. **渐进式迁移** - 支持 KakaJSON/HandyJSON/Codable 并存
3. **统一接口** - 提供统一的 ls_ 前缀 API
4. **向后兼容** - 支持旧代码平滑迁移
5. **方法名隐蔽** - 不使用与参考库相似的方法名

---

## 2. 命名规范

### 2.1 库名称

**LSJSONModel** ✅

理由：
- ✅ JSON 全大写符合技术规范
- ✅ "JSON" 比 "Model" 更明确说明功能
- ✅ LS 前缀符合项目规范
- ✅ Swift 和 OC 都适用

### 2.2 方法命名规范

**所有公开方法统一使用 `ls_` 前缀，不暴露参考库方法名**

**原则：**
- ❌ **不使用**：`kakaFromJSON`, `kakaToJSON`, `handyFromJSON`, `handyToJson`
- ❌ **不使用**：`yy_model`, `mj_setKeyValues`, `kj_model`, `toJSON()`
- ✅ **使用**：`ls_decode()`, `ls_encode()`, `ls_fromDictionary()`, `ls_toDictionary()`

**实现方式：**
```swift
// 对外统一 ls_ 前缀方法
extension Codable {
    // Codable 模式
    static func ls_decode(_ json: String) -> Self? {
        // 自己实现，不调用 Codable
    }
    
    // KakaJSON 模式（内部使用，不暴露）
    static func ls_decode(_ json: String) -> Self? {
        // 自己实现，不调用 KakaJSON
    }
    
    // HandyJSON 模式（内部使用，不暴露）
    static func ls_decode(_ json: String) -> Self? {
        // 自己实现，不调用 HandyJSON
    }
}
```

### 2.3 文件结构

```
LSJSONModel/
├── LSJSONModel_Design.md         # 设计文档（本文件）
├── Sources/
│   ├── LSJSONModel.swift           # 主入口文件
│   ├── Codable/
│   │   ├── LSJSONDecoder.swift       # 自己的解码实现
│   │   ├── LSJSONEncoder.swift       # 自己的编码实现
│   │   └── LSJSONCodable.swift     # Codable 扩展
│   ├── Performance/
│   │   ├── LSJSONDecoderHP.swift     # 极致性能解码器
│   │   └── LSJSONEncoderHP.swift     # 极致性能编码器
│   ├── Runtime/
│   │   ├── LSJSONReflection.swift     # 反射工具
│   │   ├── LSJSONCache.swift         # 缓存管理
│   │   └── LSJSONPropertyMeta.swift  # 属性元数据
│   └── OC/
│       └── LSJSONOC.swift           # OC 兼容层
└── Tests/
    ├── CodableTests.swift
    ├── PerformanceTests.swift
    └── MigrationTests.swift
```

### 2.4 Swift Macros（可选）

**Codable 宏前缀：** `@LS` 开头
- `@LSModel`
- `@LSSnakeCaseKeys`
- `@LSDefault`
- `@LSDateCoding`
- `@LSIgnore`

---

## 3. 架构设计

### 3.1 三层架构

```
┌───────────────────────────────────────┐
│         LSJSONModel 架构           │
├───────────────────────────────────────┤
│  Codable 层（重写实现）         │  ← 自己实现，不封装  │
├───────────────────────────────────────┤
│  性能层             │  ← 极致性能，参考优化  │
├───────────────────────────────────────┤
│  运行时层       │  ← OC 迁移，YYModel 思想  │
└───────────────────────────────────────┘
```

### 3.2 核心类图

```
Codable (Swift Protocol)
    │
    ├── Codable (官方支持）
    └── LSJSONCodable (自己的扩展）
        ├── @LSModel
        ├── @LSSnakeCaseKeys
        ├── @LSDefault
        ├── @LSDateCoding
        └── @LSIgnore

LSJSONDecoder (重写实现）
    │
    ├── 解析 JSON 字符串/数据
    ├── 属性映射
    ├── 类型转换
    └── 性能优化

LSJSONEncoder (重写实现）
    │
    ├── 编码为 JSON 字符串/数据
    ├── 日期格式化
    └── 性能优化
```

---

## 4. 使用场景

### 4.1 场景一：新项目开发

**推荐：Codable（自己重写实现）**

**优点：**
- ✅ 自己实现，完全掌控
- ✅ 编译时类型检查
- ✅ 性能足够
- ✅ 与 Swift 6 完美配合
- ✅ 参考各库优点

**适用：**
- 🎯 所有新项目
- 🎯 Swift 6 开发
- 🎯 类型安全优先

### 4.2 场景二：从 OC 迁移

**推荐：重写实现，参考 YYModel 思想**

**优点：**
- ✅ 自己实现，不依赖外部库
- ✅ YYModel 性能优化策略
- ✅ 不需要继承 NSObject
- ✅ 支持大量运行时特性

**适用：**
- 🎯 从 OC 项目迁移
- 🎯 需要 YYModel 特性
- 🎯 运行时灵活性

### 4.3 场景三：追求性能

**推荐：重写实现，参考 KakaJSON 优化**

**优点：**
- ✅ 自己实现，极致性能
- ✅ 优化的反射机制
- ✅ 方法缓存
- ✅ 一行代码转换

**适用：**
- 🎯 高频 API 解析
- 🎯 大量数据转换
- 🎯 性能敏感场景

---

## 5. API 设计

### 5.1 统一解码 API

```swift
// 文件：Sources/LSJSONDecoder.swift

/// LSJSONModel 统一解码器
public struct LSJSONDecoder {
    
    /// 从 JSON 字符串解码
    public static func decode<T: Decodable>(_ json: String, as type: T.Type) -> T? {
        // 自己实现解码逻辑
    }
    
    /// 从 JSON 数据解码
    public static func decode<T: Decodable>(_ data: Data, as type: T.Type) -> T? {
        // 自己实现解码逻辑
    }
    
    /// 从字典解码
    public static func decode<T: Decodable>(_ dict: [String: Any], as type: T.Type) -> T? {
        // 自己实现解码逻辑
    }
    
    /// 从 JSON 数组解码
    public static func decodeArray<T: Decodable>(_ json: String, as type: T.Type) -> [T]? {
        // 自己实现解码逻辑
    }
}
```

**使用方法：**
```swift
// 统一 ls_ 前缀 API
extension Decodable {
    public static func ls_decode(_ json: String) -> Self? {
        return LSJSONDecoder.decode(json, as: Self.self)
    }
}

// 使用
let user = User.ls_decode(jsonString)
let users = [User].ls_decodeArray(jsonArrayString)
```

### 5.2 统一编码 API

```swift
// 文件：Sources/LSJSONEncoder.swift

/// LSJSONModel 统一编码器
public struct LSJSONEncoder {
    
    /// 编码为 JSON 字符串
    public static func encode<T: Encodable>(_ value: T) -> String? {
        // 自己实现编码逻辑
    }
    
    /// 编码为 JSON 数据
    public static func encode<T: Encodable>(_ value: T) -> Data? {
        // 自己实现编码逻辑
    }
    
    /// 编码为字典
    public static func encode<T: Encodable>(_ value: T) -> [String: Any]? {
        // 自己实现编码逻辑
    }
    
    /// 编码为 JSON 数组
    public static func encodeArray<T: Encodable>(_ array: [T]) -> String? {
        // 自己实现编码逻辑
    }
}
```

**使用方法：**
```swift
// 统一 ls_ 前缀 API
extension Encodable {
    public func ls_encode() -> String? {
        return LSJSONEncoder.encode(self)
    }
    
    public func ls_toDictionary() -> [String: Any]? {
        return LSJSONEncoder.encode(self)
    }
}

// 使用
let jsonString = user.ls_encode()
let jsonData = user.ls_encodeToData()
let dict = user.ls_toDictionary()
```

### 5.3 极致性能模式（参考 KakaJSON）

**实现策略：**
- ✅ 直接内存写入，绕过 KVC
- ✅ Swift runtime 反射
- ✅ 方法缓存优化
- ✅ 属性预计算

```swift
// 文件：Sources/Performance/LSJSONDecoderHP.swift

internal struct _LSJSONPropertyMeta {
    var name: String
    var type: Any.Type
    var offset: Int
}

internal class _LSJSONReflection {
    static func properties(of type: Any.Type) -> [_LSJSONPropertyMeta] {
        // 自己实现反射逻辑
    }
}
```

### 5.4 运行时模式（参考 YYModel/HandyJSON）

**实现策略：**
- ✅ 运行时属性赋值
- ✅ 字典转换
- ✅ 归档/解档
- ✅ 方法动态调用
- ✅ 嵌套对象支持

```swift
// 文件：Sources/Runtime/LSJSONOC.swift

/// OC 兼容层
@objc public protocol LSJSONModelOC {
    @objc static func ls_model(with json: Any) -> Self?
    @objc func ls_toJSON() -> Any?
    @objc func ls_toJSONString() -> String?
    @objc func ls_toDictionary() -> [String: Any]?
}
```

---

## 6. 核心特性

### 6.1 自己实现的特性

#### 自动属性映射

```swift
// 自己实现，参考 Codable + KakaJSON
@LSSnakeCaseKeys
struct User: Codable {
    var userName: String  // 自动映射 user_name
    var userAge: Int    // 自动映射 user_age
}
```

#### 默认值支持

```swift
@LSDefault("")
var userName: String

@LSDefault(0)
var userAge: Int

@LSDefault(false)
var isVip: Bool
```

#### 自定义日期格式

```swift
@LSDateCoding(.iso8601)
var createdAt: Date

@LSDateCoding(.yyyyMMddHHmmss)
var lastLoginTime: Date

@LSDateCoding(.custom("yyyy-MM-dd HH:mm:ss"))
var customTime: Date
```

#### 字段忽略

```swift
@LSIgnore
var internalData: String?  // 不会编码到 JSON
```

### 6.2 性能优化特性

#### 方法缓存

```swift
// 参考 KakaJSON 的缓存策略
internal class _LSJSONMethodCache {
    static func decodeMethod(for type: Any.Type) -> Method {
        // 缓存反射方法
    }
}
```

#### 属性预计算

```swift
// 启动时计算所有属性元数据
internal class _LSJSONPropertyCache {
    static var properties: [String: _LSJSONPropertyMeta] = [:]
    
    static func register(type: Any.Type) {
        // 预计算属性
    }
}
```

### 6.3 运行时特性

#### 字典赋值

```swift
// 参考 YYModel/HandyJSON
extension LSJSONModelOC {
    func ls_setValues(for dictionary: [String: Any]) {
        // 自己实现字典赋值
    }
}
```

#### 归档/解档

```swift
// 参考 YYModel/HandyJSON
extension LSJSONModelOC {
    func ls_archive() -> Data? {
        // 自己实现归档
    }
    
    static func ls_unarchive(_ data: Data) -> Self? {
        // 自己实现解档
    }
}
```

---

## 7. 使用示例

### 7.1 新项目（推荐）

```swift
import LSJSONModel

@LSModel
@LSSnakeCaseKeys
struct User: Codable {
    @LSDefault("")
    var userName: String
    
    @LSDefault(0)
    var userAge: Int
    
    @LSDateCoding(.iso8601)
    var birthDate: Date
    
    @LSIgnore
    var internalFlag: String?
}

// 解码
let jsonString = """
{
    "user_name": "张三",
    "user_age": 25,
    "birth_date": "2000-01-01T00:00:00Z"
}
"""

// 使用 LSJSONModel API（自己实现）
let user = User.ls_decode(jsonString)
print(user.userName)  // 张三
print(user.userAge)   // 25

// 编码
if let jsonString = user.ls_encode() {
    print(jsonString)
}
```

### 7.2 从 OC 迁移

```swift
import LSJSONModel

// OC 模型
class User: NSObject, LSJSONModelOC {
    var userName: String = ""
    var userAge: Int = 0
    
    // 自己实现，不依赖 HandyJSON
    override func ls_toDictionary() -> [String: Any]? {
        return ["user_name": userName, "user_age": userAge]
    }
}

// 使用
let user = User.ls_model(with: jsonDict)
let dict = user.ls_toDictionary()
```

### 7.3 追求性能

```swift
import LSJSONModel

struct User: Codable {
    var userName: String = ""
    var userAge: Int = 0
}

// 高频 API 处理
class APIService {
    func handleResponse(_ jsonString: String) -> [User]? {
        // 极致性能解码（自己实现）
        return User.ls_decodeArray(jsonString)
    }
}
```

---

## 8. 实现计划

### 8.1 第一阶段（核心功能）

- [ ] LSJSONModel 主文件
- [ ] 统一解码器
- [ ] 统一编码器
- [ ] Swift Macros 定义
- [ ] 基础单元测试

### 8.2 第二阶段（性能优化）

- [ ] 极致性能解码器
- [ ] 极致性能编码器
- [ ] 反射工具
- [ ] 缓存管理
- [ ] 属性元数据

### 8.3 第三阶段（OC 兼容）

- [ ] OC 桥接协议
- [ ] OC 兼容层
- [ ] 归档/解档
- [ ] 运行时特性

### 8.4 第四阶段（测试和优化）

- [ ] 性能基准测试
- [ ] 功能完整性测试
- [ ] Swift 6 兼容性测试
- [ ] OC 桥接测试

---

## 9. 性能目标

### 9.1 性能对比

| 方案 | 解码速度 | 编码速度 | 内存占用 | 类型安全 | 可维护性 |
|------|----------|----------|----------|----------|----------|
| **Codable（自己实现）** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **KakaJSON** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **HandyJSON** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **YYModel** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ |
| **MJExtension** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐⭐ |

### 9.2 性能目标

**目标：**
- 解码速度：≥ KakaJSON 的 100%
- 编码速度：≥ KakaJSON 的 100%
- 内存占用：≈ KakaJSON
- 类型安全：100%
- 可维护性：100%

---

## 附录

### A. 参考库说明

**LSJSONModel 借鉴的库：**

1. **Codable** - Swift 官方协议
   - 优点：类型安全，编译时检查，官方支持
   - 借鉴：类型安全，编译时优化
   
2. **HandyJSON** - 阿里巴巴出品
   - 优点：YYModel 思想，高性能，不继承 NSObject
   - 借鉴：运行时特性，反射优化，内存直接写入
   
3. **KakaJSON** - 快速转换库
   - 优点：极致性能，一行代码，API 简洁
   - 借鉴：方法缓存，属性预计算，反射优化

### B. 实现策略

**不封装，而是重写：**
- ✅ 自己实现 JSON 解析逻辑
- ✅ 自己实现 JSON 编码逻辑
- ✅ 自己实现反射和缓存
- ✅ 自己实现属性映射

**参考但不依赖：**
- ✅ 参考性能优化策略
- ✅ 参考设计思路
- ✅ 参考 API 设计

### C. 贡献指南

欢迎提 Issue 和 PR！

---

**文档版本**：v1.0  
**最后更新**：2026-01-23  
**开发者**：link-start  
**维护者**：link-start
