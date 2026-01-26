# LSJSONModel

> 基于 Codable 优点的 JSON 转 Model 库，支持 Swift 6 和 Objective-C
>
> 特性：全局变量名映射、跨 Model 转换、归档解档

---

## 目录

- [特性](#特性)
- [快速开始](#快速开始)
- [MJExtension 风格 API](#mjextension-风格-api) 🆕
- [核心功能](#核心功能)
- [Property Wrapper](#property-wrapper)
- [全局映射系统](#全局映射系统)
- [跨 Model 转换](#跨-model-转换)
- [归档解档](#归档解档)
- [性能优化](#性能优化)
- [API 参考](#api-参考)
- [迁移指南](#迁移指南)

---

## 特性

- ✅ **全局变量名映射** - 一处设置，全局生效
- ✅ **跨 Model 转换** - 不同 Model 类型之间无缝转换
- ✅ **归档解档** - 类似 MJExtension 的归档/解档功能
- ✅ **映射优先级** - 类型映射 > 全局映射 > Snake Case
- ✅ **高性能缓存** - 映射查询缓存，确保高效
- ✅ **Objective-C 兼容** - 支持 @objc 协议

---

## 快速开始

### 安装

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LSJSONModel.git", from: "1.0.0")
]
```

### 基础使用

```swift
import LSJSONModel

// 定义模型
struct User: Codable {
    var userId: String
    var userName: String
    var userEmail: String
}

// 解码
let json = """
{
    "userId": "123",
    "userName": "张三",
    "userEmail": "zhangsan@example.com"
}
"""
let user = User.ls_decode(json)
print(user.userName)  // "张三"

// 编码
if let jsonString = user.ls_encode() {
    print(jsonString)
}
```

---

## MJExtension 风格 API

> 如果你习惯了 MJExtension 的 API，LSJSONModel 提供了完全一致的使用体验！

### 快速对照

| MJExtension | LSJSONModel | 说明 |
|-------------|-------------|------|
| `mj_objectWithKeyValues:` | `ls_objectWithKeyValues(_:)` | 从字典/JSON创建 |
| `mj_keyValues` | `ls_keyValues` | 转为字典 |
| `mj_JSONString` | `ls_JSONString` | 转为JSON字符串 |
| `mj_setKeyValues:` | `ls_setKeyValues(_:)` | 设置属性 |
| `mj_objectWithFile:` | `ls_objectWithFile(_:)` | 从文件读取 |
| `mj_writeToFile:` | `ls_writeToFile(_:)` | 写入文件 |
| `mj_archiveToFile:` | `ls_archiveToFile(_:)` | 归档到文件 |
| `mj_unarchiveFromFile:` | `ls_unarchiveFromFile(_:)` | 从文件解档 |

### 使用示例

```swift
// 与 MJExtension 完全一致的 API 命名
let user = User.ls_objectWithKeyValues(dict)
let dict = user.ls_keyValues
let json = user.ls_JSONString

// 设置已有对象的属性（仅 class 支持）
user.ls_setKeyValues(["id": "456", "name": "李四"])

// 数组操作
let users = User.ls_objectArrayWithKeyValuesArray(array)
let dicts = users.ls_keyValuesArray

// 文件操作
let user = User.ls_objectWithFile("/path/to/user.json")
user.ls_writeToFile("/path/to/user.json")

// 归档解档
user.ls_archiveToFile("/path/to/user.archive")
let user = User.ls_unarchiveFromFile("/path/to/user.archive")
```

### 属性映射（与 MJExtension 一致）

```swift
class User: NSObject, Codable, LSJSONModelMappingProvider {
    var userId: String = ""
    var userName: String = ""

    // 与 MJExtension 完全一致的方法名
    static func ls_replacedKeyFromPropertyName() -> [String: String] {
        return ["userId": "user_id", "userName": "user_name"]
    }

    static func ls_ignoredPropertyNames() -> [String] {
        return ["debugInfo"]
    }

    static func ls_objectClassInArray() -> [String: AnyClass] {
        return ["friends": User.self]
    }
}
```

**详细文档**: [MJExtension 风格 API 使用指南](Sources/Docs/MJExtensionStyleGuide.md)

---

## Property Wrapper

LSJSONModel 提供了便捷的属性包装器，简化常见操作。

### @LSDefault - 默认值包装器

为解码过程中的属性提供默认值，避免处理 nil 值：

```swift
struct User: Codable {
    @LSDefault("") var name: String
    @LSDefault(0) var age: Int
    @LSDefault(false) var isActive: Bool
    @LSDefault([]) var tags: [String]
}

// 当 JSON 中缺少这些字段时，会自动使用默认值
let json = """
{
    "name": "张三"
}
"""
let user = User.ls_decode(json)
print(user.name)      // "张三"
print(user.age)       // 0（默认值）
print(user.isActive)  // false（默认值）
print(user.tags)      // []（默认值）
```

### @LSDateCoding - 日期格式化包装器

支持多种日期格式的编码/解码：

```swift
struct Event: Codable {
    @LSDateCoding(.iso8601) var startTime: Date
    @LSDateCoding(.yyyyMMddHHmmss) var endTime: Date
    @LSDateCoding(.epochSeconds) var timestamp: Date
    @LSDateCoding(.custom("yyyy年MM月dd日")) var displayDate: Date
}

// 支持的日期格式
// - .iso8601: ISO 8601 标准格式（2024-01-23T12:00:00Z）
// - .rfc3339: RFC 3339 格式
// - .yyyyMMddHHmmss: 紧凑格式（20240123120000）
// - .epochSeconds: Unix 时间戳（秒）
// - .epochMilliseconds: Unix 时间戳（毫秒）
// - .custom(String): 自定义格式字符串
```

### 可选日期支持

```swift
struct Post: Codable {
    @LSDateCodingOptional(.iso8601) var publishedAt: Date?
    @LSDateCodingOptional(.yyyyMMddHHmmss) var updatedAt: Date?
}
```

---

## 核心功能

### 全局变量名映射

类似 MJExtension 的全局映射功能，一处设置，所有 Model 都生效：

```swift
// App 启动时设置
LSJSONMapping.ls_setGlobalMapping([
    "id": "user_id",
    "description": "desc",
    "createTime": "created_at"
])

// 之后所有 Model 都自动应用
struct User: Codable {
    var id: String          // 自动映射到 user_id
    var description: String  // 自动映射到 desc
}

struct Order: Codable {
    var id: String          // 自动映射到 user_id
    var createTime: Date    // 自动映射到 created_at
}
```

### 映射优先级

从高到低的优先级：

1. **类型映射** `ls_registerMapping(for:)` - 单个类型
2. **全局映射** `ls_setGlobalMapping()` - 影响所有类型
3. **Snake Case** 自动转换（通过映射配置）
4. **默认映射** - 属性名直接作为 JSON 键

---

## 全局映射系统

### 设置全局映射

```swift
// 设置全局映射
LSJSONMapping.ls_setGlobalMapping([
    "id": "user_id",
    "name": "display_name"
])

// 添加额外映射
LSJSONMapping.ls_addGlobalMapping([
    "email": "email_address"
])

// 获取全局映射
let mapping = LSJSONMapping.ls_getGlobalMapping()

// 清除全局映射
LSJSONMapping.ls_clearGlobalMapping()
```

### 类型级映射

```swift
// 方式 1：实现协议
struct User: Codable, LSJSONMappingProvider {
    var id: String

    static func ls_mappingKeys() -> [String: String] {
        return ["id": "user_id"]
    }
}

// 方式 2：注册映射
LSJSONMapping.ls_registerMapping(for: User.self, mapping: [
    "id": "user_id",
    "name": "user_name"
])

// 批量注册
LSJSONMapping.ls_registerMappings([
    User.self: ["id": "user_id"],
    Order.self: ["orderId": "order_id"]
])
```

### 查询映射

```swift
// 获取属性对应的 JSON 键
let jsonKey = LSJSONMapping.ls_jsonKey(for: "id", in: User.self)

// 获取 JSON 键对应的属性名（反向）
let propName = LSJSONMapping.ls_propertyName(for: "user_id", in: User.self)
```

---

## 跨 Model 转换

### 单个转换

```swift
// API 返回的数据模型
struct APIUser: Codable {
    var userId: String
    var userName: String
    var userAge: Int
}

// App 内部使用的模型
struct AppUser: Codable {
    var id: String
    var name: String
    var age: Int
}

// 设置映射
LSJSONMapping.ls_registerMapping(for: AppUser.self, mapping: [
    "id": "userId",
    "name": "userName",
    "age": "userAge"
])

// 一键转换
let apiUser = APIUser(userId: "123", userName: "张三", userAge: 25)
let appUser = LSJSONMapping.ls_convert(apiUser, to: AppUser.self)

print(appUser.id)    // "123"
print(appUser.name)  // "张三"
print(appUser.age)   // 25
```

### 批量转换

```swift
let apiUsers: [APIUser] = [...]

let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: AppUser.self)
```

---

## 归档解档

类似 MJExtension 的归档/解档功能：

### 归档到 Data

```swift
let user = TestUser(id: "123", name: "张三")

// 归档到 Data
if let data = user.ls_archiveData() {
    print("归档成功，数据大小: \(data.count) bytes")
}
```

### 归档到文件

```swift
// 归档到文件
let path = NSTemporaryDirectory() + "user.archive"
if user.ls_archiveFile(to: path) {
    print("归档到文件成功")
}
```

### 从 Data 解档

```swift
// 从 Data 解档
if let data = user.ls_archiveData(),
   let restored = TestUser.ls_unarchive(from: data) {
    print(restored.name)  // "张三"
}
```

### 从文件解档

```swift
// 从文件解档
if let fileUser = TestUser.ls_unarchive(from: path) {
    print(fileUser.name)  // "张三"
}
```

### 批量归档/解档

```swift
let users = [user1, user2, user3]

// 批量归档
if let arrayData = users.ls_archiveArrayData() {
    // 批量解档
    if let restoredUsers = TestUser.ls_unarchiveArray(from: arrayData) {
        print(restoredUsers.count)  // 3
    }
}
```

---

## API 参考

### Decodable 扩展

```swift
extension Decodable {
    // 从 JSON 字符串解码
    static func ls_decode(_ json: String) -> Self?

    // 从 JSON 数据解码
    static func ls_decodeFromJSONData(_ jsonData: Data) -> Self?

    // 从字典解码
    static func ls_decodeFromDictionary(_ dict: [String: Any]) -> Self?

    // 从 JSON 数组解码
    static func ls_decodeArrayFromJSON(_ jsonString: String) -> [Self]?
}
```

### Encodable 扩展

```swift
extension Encodable {
    // 编码为 JSON 字符串
    func ls_encode() -> String?

    // 编码为 JSON 数据
    func ls_encodeToData() -> Data?

    // 编码为字典
    func ls_encodeToDictionary() -> [String: Any]?

    // 编码数组为 JSON
    static func ls_encodeArrayToJSON(_ array: [Self]) -> String?
}
```

---

## 迁移指南

### 从 Codable 迁移

无需修改现有代码，直接使用 `ls_` 前缀方法：

```swift
// 旧代码
let user = try? JSONDecoder().decode(User.self, from: data)

// 新代码（功能相同，API 更简洁）
let user = User.ls_decodeFromJSONData(data)
```

### 从 MJExtension 迁移

```swift
// 旧代码 (MJExtension)
user.mj_setKeyValues(["id": "123"])
let dict = user.mj_keyValues()

// 新代码 (LSJSONModel)
let user = User.ls_decodeFromDictionary(["id": "123"])
let dict = user.ls_toDictionary()

// 归档/解档
user.ls_archiveFile(to: path)
let restored = User.ls_unarchive(from: path)
```

### 从 KakaJSON 迁移

```swift
// 旧代码 (KakaJSON)
let user = User.kj_model(json: jsonString)
let json = user.kj_JSON()

// 新代码 (LSJSONModel)
let user = User.ls_decode(jsonString)
let json = user.ls_encode()
```

---

## 性能优化

### 缓存预热

```swift
// 启动时预热常用类型的缓存
_LSJSONMappingCache.warmup(for: [
    User.self,
    Order.self,
    Product.self
])
```

### 缓存管理

```swift
// 查看缓存统计
let stats = _LSJSONMappingCache.getStats()
print("命中率: \(stats.hitRate)")

// 清除缓存
_LSJSONMappingCache.clearCache()

// 清除特定类型缓存
_LSJSONMappingCache.clearCache(for: User.self)
```

---

## 项目结构

```
LSJSONModel/
├── Package.swift
├── Sources/
│   ├── LSJSONModel.swift           # 主入口
│   ├── LSJSONDecoder.swift         # 解码器
│   ├── LSJSONEncoder.swift         # 编码器
│   ├── Macros/                     # 映射系统
│   │   ├── _LSJSONMapping.swift    # 统一映射系统
│   │   └── _LSJSONMappingCache.swift # 映射缓存
│   ├── PropertyWrappers/           # 属性包装器
│   │   ├── LSDefault.swift         # 默认值包装器
│   │   ├── LSDateCoding.swift      # 日期格式化包装器
│   │   └── LSJSONPropertyWrappers.swift
│   ├── Runtime/                    # 运行时支持
│   │   ├── _LSPropertyMapper.swift # 属性映射器
│   │   ├── _LSTypeConverter.swift  # 类型转换器
│   │   └── _LSArchiver.swift       # 归档解档
│   ├── Performance/                # 性能优化
│   │   ├── LSJSONDecoderHP.swift   # 高性能解码器
│   │   ├── LSJSONEncoderHP.swift   # 高性能编码器
│   │   ├── LSJSONMethodCache.swift # 方法缓存
│   │   ├── LSJSONMetadata.swift    # 元数据定义
│   │   └── LSJSONPerformance.swift # 性能层导出
│   ├── OC/
│   │   └── LSJSONOC.swift          # OC 兼容
│   └── Docs/                       # 文档
│       ├── Important.md            # 命名规范
│       ├── Reference.md            # 参考库说明
│       └── CompletionStatus.md     # 完成状态
└── Tests/
    ├── LSJSONModelTests.swift      # 基础功能测试
    ├── LSJSONDecoderTests.swift    # 解码器测试
    ├── LSJSONEncoderTests.swift    # 编码器测试
    ├── LSJSONMappingTests.swift    # 映射系统测试
    ├── LSJSONArchiverTests.swift   # 归档解档测试
    ├── LSJSONConverterTests.swift  # 类型转换测试
    └── LSJSONPerformanceTests.swift # 性能测试
```

---

## 许可证

MIT License

---

**版本**: v1.0
**最后更新**: 2026-01-24
**开发者**: link-start
