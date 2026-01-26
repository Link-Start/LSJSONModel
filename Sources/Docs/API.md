# LSJSONModel API 文档

本文档提供 LSJSONModel 所有公开 API 的详细说明。

---

## 目录

- [解码 API](#解码-api)
- [编码 API](#编码-api)
- [映射 API](#映射-api)
- [归档解档 API](#归档解档-api)
- [类型转换 API](#类型转换-api)
- [属性包装器 API](#属性包装器-api)
- [性能优化 API](#性能优化-api)

---

## 解码 API

### Decodable 扩展方法

#### `ls_decode(_:)`

从 JSON 字符串解码为对象。

```swift
static func ls_decode(_ json: String) -> Self?
```

**参数：**
- `json`: JSON 字符串

**返回：**
- 解码后的对象，失败返回 `nil`

**示例：**
```swift
let user = User.ls_decode("{\"id\":\"123\",\"name\":\"张三\"}")
```

---

#### `ls_decodeFromJSONData(_:)`

从 JSON 数据解码为对象。

```swift
static func ls_decodeFromJSONData(_ jsonData: Data) -> Self?
```

**参数：**
- `jsonData`: JSON 数据

**返回：**
- 解码后的对象，失败返回 `nil`

---

#### `ls_decodeFromDictionary(_:)`

从字典解码为对象。

```swift
static func ls_decodeFromDictionary(_ dict: [String: Any]) -> Self?
```

**参数：**
- `dict`: JSON 字典

**返回：**
- 解码后的对象，失败返回 `nil`

---

#### `ls_decodeArrayFromJSON(_:)`

从 JSON 数组字符串解码为数组。

```swift
static func ls_decodeArrayFromJSON(_ jsonString: String) -> [Self]?
```

**参数：**
- `jsonString`: JSON 数组字符串

**返回：**
- 解码后的数组，失败返回 `nil`

---

## 编码 API

### Encodable 扩展方法

#### `ls_encode()`

将对象编码为 JSON 字符串。

```swift
func ls_encode() -> String?
```

**返回：**
- JSON 字符串，失败返回 `nil`

---

#### `ls_encodeToData()`

将对象编码为 JSON 数据。

```swift
func ls_encodeToData() -> Data?
```

**返回：**
- JSON 数据，失败返回 `nil`

---

#### `ls_toDictionary()`

将对象编码为字典。

```swift
func ls_toDictionary() -> [String: Any]?
```

**返回：**
- JSON 字典，失败返回 `nil`

---

#### `ls_encodeArrayToJSON(_:)`

将数组编码为 JSON 字符串。

```swift
static func ls_encodeArrayToJSON(_ array: [Self]) -> String?
```

**参数：**
- `array`: 要编码的数组

**返回：**
- JSON 字符串，失败返回 `nil`

---

## 映射 API

### LSJSONMapping 全局映射方法

#### `ls_setGlobalMapping(_:)`

设置全局映射，影响所有类型。

```swift
static func ls_setGlobalMapping(_ mapping: [String: String])
```

**参数：**
- `mapping`: 映射字典 `[属性名: JSON键]`

---

#### `ls_addGlobalMapping(_:)`

添加额外的全局映射。

```swift
static func ls_addGlobalMapping(_ mapping: [String: String])
```

**参数：**
- `mapping`: 要添加的映射字典

---

#### `ls_getGlobalMapping()`

获取当前全局映射。

```swift
static func ls_getGlobalMapping() -> [String: String]
```

**返回：**
- 全局映射字典

---

#### `ls_clearGlobalMapping()`

清除所有全局映射。

```swift
static func ls_clearGlobalMapping()
```

---

### LSJSONMapping 类型映射方法

#### `ls_registerMapping(for:mapping:)`

为特定类型注册映射。

```swift
static func ls_registerMapping(for type: Any.Type, mapping: [String: String])
```

**参数：**
- `type`: 目标类型
- `mapping`: 映射字典

---

#### `ls_registerMappings(_:)`

批量注册类型映射。

```swift
static func ls_registerMappings(_ mappings: [Any.Type: [String: String]])
```

**参数：**
- `mappings`: 类型到映射的字典

---

#### `ls_removeMapping(for:)`

移除特定类型的映射。

```swift
static func ls_removeMapping(for type: Any.Type)
```

**参数：**
- `type`: 要移除映射的类型

---

### LSJSONMapping 查询方法

#### `ls_jsonKey(for:in:)`

获取属性对应的 JSON 键。

```swift
static func ls_jsonKey(for propertyName: String, in type: Any.Type) -> String
```

**参数：**
- `propertyName`: 属性名
- `type`: 类型

**返回：**
- JSON 键名

---

#### `ls_propertyName(for:in:)`

获取 JSON 键对应的属性名（反向查询）。

```swift
static func ls_propertyName(for jsonKey: String, in type: Any.Type) -> String
```

**参数：**
- `jsonKey`: JSON 键名
- `type`: 类型

**返回：**
- 属性名

---

### LSJSONMapping 转换方法

#### `ls_convert(_:to:)`

跨 Model 类型转换。

```swift
static func ls_convert<T, U>(_ source: T, to target: U.Type) -> U?
```

**参数：**
- `source`: 源对象
- `target`: 目标类型

**返回：**
- 转换后的对象

---

#### `ls_convertArray(_:to:)`

批量跨 Model 类型转换。

```swift
static func ls_convertArray<T, U>(_ sources: [T], to target: U.Type) -> [U]
```

**参数：**
- `sources`: 源对象数组
- `target`: 目标类型

**返回：**
- 转换后的数组

---

### LSJSONMapping 工具方法

#### `_toSnakeCase(_:)`

将 camelCase 转换为 snake_case。

```swift
static func _toSnakeCase(_ camelCase: String) -> String
```

---

#### `_toCamelCase(_:)`

将 snake_case 转换为 camelCase。

```swift
static func _toCamelCase(_ snakeCase: String) -> String
```

---

## 归档解档 API

### LSJSONArchiverCompatible 协议

遵循此协议的类型支持归档解档功能。

#### 实例方法

##### `ls_archiveData()`

归档到 Data。

```swift
func ls_archiveData() -> Data?
```

**返回：**
- 归档数据，失败返回 `nil`

---

##### `ls_archiveFile(to:)`

归档到文件。

```swift
func ls_archiveFile(to path: String) -> Bool
```

**参数：**
- `path`: 文件路径

**返回：**
- 是否成功

---

#### 类型方法

##### `ls_unarchive(from:as:)`

从 Data 解档。

```swift
static func ls_unarchive(from data: Data, as type: T.Type = T.self) -> T?
```

**参数：**
- `data`: 归档数据
- `type`: 目标类型（可选）

**返回：**
- 解档后的对象

---

##### `ls_unarchive(from:as:)`

从文件解档。

```swift
static func ls_unarchive(from path: String, as type: T.Type = T.self) -> T?
```

**参数：**
- `path`: 文件路径
- `type`: 目标类型（可选）

**返回：**
- 解档后的对象

---

### 数组归档解档扩展

##### `ls_archiveArray()`

归档数组到 Data。

```swift
static func ls_archiveArray(_ array: [Self]) -> Data?
```

---

##### `ls_archiveArray(to:)`

归档数组到文件。

```swift
static func ls_archiveArray(_ array: [Self], to path: String) -> Bool
```

---

##### `ls_unarchiveArray(from:)`

从 Data 解档数组。

```swift
static func ls_unarchiveArray(from data: Data) -> [Self]?
```

---

##### `ls_unarchiveArray(from:)`

从文件解档数组。

```swift
static func ls_unarchiveArray(from path: String) -> [Self]?
```

---

## 属性包装器 API

### @LSDefault

默认值属性包装器。

```swift
@LSDefault("") var name: String
```

**支持类型：**
- `String` - 默认 `""`
- `Int` - 默认 `0`
- `Double` - 默认 `0.0`
- `Float` - 默认 `0.0`
- `Bool` - 默认 `false`
- `Array` - 默认 `[]`
- `Dictionary` - 默认 `[:]`

---

### @LSDateCoding

日期格式化属性包装器。

```swift
@LSDateCoding(.iso8601) var createdAt: Date
```

**支持的日期格式：**
- `.iso8601` - ISO 8601 标准格式
- `.rfc3339` - RFC 3339 格式
- `.yyyyMMddHHmmss` - 紧凑格式
- `.epochSeconds` - Unix 时间戳（秒）
- `.epochMilliseconds` - Unix 时间戳（毫秒）
- `.custom(String)` - 自定义格式

---

### @LSDateCodingOptional

可选日期格式化属性包装器。

```swift
@LSDateCodingOptional(.iso8601) var updatedAt: Date?
```

---

## 性能优化 API

### LSJSONDecoder 模式设置

#### `setMode(_:)`

设置解码器模式。

```swift
static func setMode(_ mode: DecodeMode)
```

**模式：**
- `.codable` - 使用标准 Codable（默认）
- `.performance` - 使用高性能解码器

---

### LSJSONEncoder 模式设置

#### `setMode(_:)`

设置编码器模式。

```swift
static func setMode(_ mode: EncodeMode)
```

**模式：**
- `.codable` - 使用标准 Codable（默认）
- `.performance` - 使用高性能编码器

---

### LSJSONDecoderHP 高性能方法

#### `warmup(types:)`

预热类型缓存。

```swift
static func warmup(types: [Any.Type])
```

---

#### `getCacheStats()`

获取缓存统计。

```swift
static func getCacheStats() -> MethodCacheStats
```

---

#### `printCacheStats()`

打印缓存统计（DEBUG 模式）。

```swift
static func printCacheStats()
```

---

### LSJSONMethodCache

#### `shared`

单例实例。

```swift
static let shared: LSJSONMethodCache
```

---

#### `clearAll()`

清除所有缓存。

```swift
func clearAll()
```

---

#### `getStats()`

获取缓存统计。

```swift
func getStats() -> MethodCacheStats
```

---

### _LSJSONMappingCache

#### `warmup(for:)`

预热映射缓存。

```swift
static func warmup(for types: [Any.Type])
```

---

#### `getStats()`

获取映射缓存统计。

```swift
static func getStats() -> MappingCacheStats
```

---

#### `clearCache()`

清除映射缓存。

```swift
static func clearCache()
```

---

## 数据类型

### MethodCacheStats

方法缓存统计信息。

**属性：**
- `propertyCacheCount: Int` - 属性缓存数量
- `methodCacheCount: Int` - 方法缓存数量
- `mappingCacheCount: Int` - 映射缓存数量
- `hitCount: Int` - 命中次数
- `missCount: Int` - 未命中次数
- `hitRate: Double` - 命中率

---

### MappingCacheStats

映射缓存统计信息。

**属性：**
- `typeMappingCount: Int` - 类型映射数量
- `globalMappingCount: Int` - 全局映射数量
- `hitCount: Int` - 命中次数
- `missCount: Int` - 未命中次数

---

### DateFormat

日期格式枚举。

**值：**
- `iso8601`
- `rfc3339`
- `yyyyMMddHHmmss`
- `epochSeconds`
- `epochMilliseconds`
- `custom(String)`

---

## 协议

### LSJSONArchiverCompatible

归档解档兼容协议。

**要求：**
- 类型必须遵循 `Codable`
- 对于 class，必须是 `NSObject` 子类

---

### LSJSONModelOC

Objective-C 兼容协议。

**方法：**
- `ls_decode(_:)` - 从 JSON 字符串解码
- `ls_decodeFromData(_:)` - 从 Data 解码
- `ls_decodeFromDictionary(_:)` - 从字典解码
- `ls_encode()` - 编码为 JSON 字符串
- `ls_toDictionary()` - 编码为字典

---

**版本**: v1.0
**最后更新**: 2026-01-24
**开发者**: link-start
