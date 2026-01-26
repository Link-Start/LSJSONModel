# LSJSONModel 参考库方法对应关系文档

> 本文档详细说明 LSJSONModel 中各功能参考的原库及其对应方法

**版本**: v1.0
**更新日期**: 2026-01-24
**开发者**: link-start

---

## 目录

- [参考库概述](#参考库概述)
- [MJExtension 对应关系](#mjextension-对应关系)
- [YYModel 对应关系](#yymodel-对应关系)
- [KakaJSON 对应关系](#kakajson-对应关系)
- [HandyJSON 对应关系](#handyjson-对应关系)
- [完整方法列表](#完整方法列表)

---

## 参考库概述

LSJSONModel 采用**重写而非封装**的策略，借鉴以下四个主流 JSON 库的优点：

| 库名 | 主要贡献 | 特点 |
|------|----------|------|
| **MJExtension** | 全局映射、归档解档 | 简单易用，功能全面 |
| **YYModel** | 模型转换、高性能 | 极致性能优化 |
| **KakaJSON** | 缓存系统、反射优化 | 一行代码转换 |
| **HandyJSON** | 运行时特性 | 无需继承 NSObject |

---

## MJExtension 对应关系

MJExtension 是一个功能全面的 JSON 转换库，LSJSONModel 借鉴了其**全局映射系统**和**归档解档功能**。

### 1. 全局映射系统

**MJExtension 原方法:**
```objc
// MJExtension
+ (NSDictionary *)mj_replacedKeyFromPropertyName;
```

**LSJSONModel 对应方法:**

| 方法名 | 文件 | 行号 | 说明 |
|--------|------|------|------|
| `ls_setGlobalMapping(_:)` | `_LSJSONMapping.swift` | 86 | 设置全局属性名映射 |
| `ls_addGlobalMapping(_:)` | `_LSJSONMapping.swift` | 101 | 添加全局映射 |
| `ls_getGlobalMapping()` | `_LSJSONMapping.swift` | 115 | 获取全局映射配置 |
| `ls_clearGlobalMapping()` | `_LSJSONMapping.swift` | 122 | 清除全局映射 |

**使用示例对比:**

```objc
// MJExtension
[MJExtension mj_replacedKeyFromPropertyName:@{
    @"id": @"user_id",
    @"name": @"user_name"
}];
```

```swift
// LSJSONModel
LSJSONMapping.ls_setGlobalMapping([
    "id": "user_id",
    "name": "user_name"
])
```

---

### 2. 归档/解档功能

**MJExtension 原方法:**
```objc
// MJExtension
- (NSData *)mj_archiveToData;
- (BOOL)mj_archiveToFile:(NSString *)path;
+ (id)mj_unarchiveWithData:(NSData *)data;
+ (id)mj_unarchiveWithFile:(NSString *)path;
```

**LSJSONModel 对应方法:**

| 方法名 | 文件 | 行号 | 说明 |
|--------|------|------|------|
| `ls_archiveData()` | `_LSArchiver.swift` | 37 | 归档到 Data |
| `ls_archiveFile(to:)` | `_LSArchiver.swift` | 74 | 归档到文件 |
| `ls_unarchive(from:as:)` | `_LSArchiver.swift` | 126 | 从 Data 解档 |
| `ls_unarchive(from:as:)` | `_LSArchiver.swift` | 168 | 从文件解档 |
| `ls_archiveArrayData()` | `_LSArchiver.swift` | 50 | 批量归档到 Data |
| `ls_archiveArrayFile(to:)` | `_LSArchiver.swift` | 96 | 批量归档到文件 |
| `ls_unarchiveArray(from:as:)` | `_LSArchiver.swift` | 141 | 从 Data 解档数组 |
| `ls_unarchiveArray(from:as:)` | `_LSArchiver.swift` | 184 | 从文件解档数组 |

**使用示例对比:**

```objc
// MJExtension
NSData *data = [user mj_archiveToData];
BOOL success = [user mj_archiveToFile:@"/path/to/file"];
User *restored = [User mj_unarchiveWithFile:@"/path/to/file"];
```

```swift
// LSJSONModel
let data = user.ls_archiveData()
let success = user.ls_archiveFile(to: "/path/to/file")
let restored = User.ls_unarchive(from: "/path/to/file")
```

**代码注释证据:**
```swift
// _LSArchiver.swift:28
/// 将 Model 归档为 Data
/// 类似 MJExtension 的 mj_archiveToData

// _LSArchiver.swift:62
/// 将 Model 归档到文件
/// 类似 MJExtension 的 mj_archiveToFile

// _LSArchiver.swift:115
/// 从 Data 解档 Model
/// 类似 MJExtension 的 mj_unarchiveWithData

// _LSArchiver.swift:157
/// 从文件解档 Model
/// 类似 MJExtension 的 mj_unarchiveWithFile
```

---

## YYModel 对应关系

YYModel 是一个高性能的 JSON 转换库，LSJSONModel 借鉴了其**模型转换**和**属性映射**功能。

### 1. 跨 Model 转换

**YYModel 原方法:**
```objc
// YYModel
+ (instancetype)yy_modelWithJSON:(id)json;
- (NSDictionary *)yy_modelToJSONObject;
```

**LSJSONModel 对应方法:**

| 方法名 | 文件 | 行号 | 说明 |
|--------|------|------|------|
| `ls_convert(_:to:)` | `_LSTypeConverter.swift` | 29 | 跨 Model 转换 |
| `ls_convertArray(_:to:)` | `_LSTypeConverter.swift` | 52 | 批量跨 Model 转换 |

**使用示例:**

```swift
// LSJSONModel - 单个转换
let apiUser = APIUser(userId: "123", userName: "张三")
let appUser = LSJSONMapping.ls_convert(apiUser, to: AppUser.self)

// LSJSONModel - 批量转换
let apiUsers: [APIUser] = [...]
let appUsers = LSJSONMapping.ls_convertArray(apiUsers, to: AppUser.self)
```

---

## KakaJSON 对应关系

KakaJSON 是一个追求极致性能的 JSON 转换库，LSJSONModel 借鉴了其**缓存系统**和**反射优化**策略。

### 1. 解码/编码方法

**KakaJSON 原方法:**
```swift
// KakaJSON
let user = User.kj_model(json: jsonString)
let json = user.kj_JSON()
let dict = user.ky_dictionary()
```

**LSJSONModel 对应方法:**

| 方法名 | 文件 | 行号 | 说明 |
|--------|------|------|------|
| `ls_decode(_:)` | `LSJSONDecoder.swift` | 185 | 从 JSON 字符串解码 |
| `ls_decodeFromJSONData(_:)` | `LSJSONDecoder.swift` | 191 | 从 JSON 数据解码 |
| `ls_decodeFromDictionary(_:)` | `LSJSONDecoder.swift` | 196 | 从字典解码 |
| `ls_decodeArrayFromJSON(_:)` | `LSJSONDecoder.swift` | 201 | 从 JSON 数组解码 |
| `ls_encode()` | `LSJSONEncoder.swift` | 43 | 编码为 JSON 字符串 |
| `ls_encodeToData()` | `LSJSONEncoder.swift` | 53 | 编码为 JSON 数据 |
| `ls_toDictionary()` | `LSJSONEncoder.swift` | 63 | 编码为字典 |
| `ls_encodeArrayToJSON(_:)` | `LSJSONEncoder.swift` | 77 | 编码数组为 JSON |

**使用示例对比:**

```swift
// KakaJSON
let user = User.kj_model(json: jsonString)
let json = user.kj_JSON()
let dict = user.kj_dictionary()

// LSJSONModel
let user = User.ls_decode(jsonString)
let json = user.ls_encode()
let dict = user.ls_toDictionary()
```

---

### 2. 缓存优化系统

**KakaJSON 策略:**
- 方法缓存
- 属性预计算
- 反射优化

**LSJSONModel 对应实现:**

| 功能 | 文件 | 说明 |
|------|------|------|
| `cacheEnabled` | `LSJSONDecoderHP.swift:134` | 启用/禁用类型缓存 |
| `_getTypeCache(for:)` | `LSJSONDecoderHP.swift:143` | 获取类型缓存 |
| `_cacheTypeInfo(for:)` | `LSJSONDecoderHP.swift:150` | 缓存类型信息 |
| `_clearTypeCache()` | `LSJSONDecoderHP.swift:172` | 清除类型缓存 |

**缓存系统对应:**

| 功能 | 文件 | 说明 |
|------|------|------|
| `getMapping(for:property:)` | `_LSJSONMappingCache.swift:73` | 获取映射缓存 |
| `setMapping(for:property:metadata:)` | `_LSJSONMappingCache.swift:95` | 设置映射缓存 |
| `getReverseMapping(for:jsonKey:)` | `_LSJSONMappingCache.swift:132` | 获取反向缓存 |
| `clearCache()` | `_LSJSONMappingCache.swift:209` | 清除所有缓存 |
| `warmup(for:)` | `_LSJSONMappingCache.swift:285` | 缓存预热 |
| `getStats()` | `_LSJSONMappingCache.swift:361` | 获取缓存统计 |

**代码注释证据:**
```swift
// LSJSONDecoder.swift:88
/// 极致性能模式解码（参考 KakaJSON 优化）

// LSJSONDecoder.swift:113
/// 使用缓存信息进行解码

// _LSJSONMappingCache.swift:12
/// 映射缓存系统 - 确保高性能
```

---

## HandyJSON 对应关系

HandyJSON 是一个运行时灵活的 JSON 转换库，LSJSONModel 借鉴了其**OC 兼容**和**运行时特性**。

### 1. OC 兼容协议

**HandyJSON 原方法:**
```swift
// HandyJSON
class User: HandyJSON {
    var name: String?
    required init() {}
    func mapping(mapper: HelpingMapper) {
        mapper <<<< self.name <-- "user_name"
    }
}

let user = User.deserialize(from: jsonString)
```

**LSJSONModel 对应协议:**

| 协议方法 | 文件 | 行号 | 说明 |
|----------|------|------|------|
| `ls_decode(_:)` | `LSJSONOC.swift` | 18 | 从 JSON 字符串解码 |
| `ls_decodeFromData(_:)` | `LSJSONOC.swift` | 21 | 从 JSON 数据解码 |
| `ls_decodeFromDictionary(_:)` | `LSJSONOC.swift` | 24 | 从字典解码 |
| `ls_encode()` | `LSJSONOC.swift` | 27 | 编码为 JSON 字符串 |
| `ls_encodeToData()` | `LSJSONOC.swift` | 30 | 编码为 JSON 数据 |
| `ls_toDictionary()` | `LSJSONOC.swift` | 33 | 编码为字典 |

**使用示例对比:**

```swift
// HandyJSON
let user = User.deserialize(from: jsonString)
let json = user.toJSON()

// LSJSONModel
let user = User.ls_decode(jsonString)
let json = user.ls_encode()
```

---

## 完整方法列表

### 按 LSJSONModel 方法排序

#### A. 解码方法 (Decodable Extension)

| 方法 | 参考库 | 原方法 | 文件 |
|------|--------|--------|------|
| `ls_decode(_:)` | KakaJSON | `kj_model(json:)` | `LSJSONDecoder.swift:185` |
| `ls_decodeFromJSONData(_:)` | KakaJSON | `kj_model(data:)` | `LSJSONDecoder.swift:191` |
| `ls_decodeFromDictionary(_:)` | KakaJSON | `kj_model(dict:)` | `LSJSONDecoder.swift:196` |
| `ls_decodeArrayFromJSON(_:)` | KakaJSON | `kj_modelArray()` | `LSJSONDecoder.swift:201` |

#### B. 编码方法 (Encodable Extension)

| 方法 | 参考库 | 原方法 | 文件 |
|------|--------|--------|------|
| `ls_encode()` | KakaJSON | `kj_JSON()` | `LSJSONEncoder.swift:43` |
| `ls_encodeToData()` | KakaJSON | `kj_JSONData()` | `LSJSONEncoder.swift:53` |
| `ls_toDictionary()` | KakaJSON | `kj_dictionary()` | `LSJSONEncoder.swift:63` |
| `ls_encodeArrayToJSON(_:)` | KakaJSON | `kj_JSONArray()` | `LSJSONEncoder.swift:77` |

#### C. 全局映射方法

| 方法 | 参考库 | 原方法 | 文件 |
|------|--------|--------|------|
| `ls_setGlobalMapping(_:)` | MJExtension | `mj_replacedKeyFromPropertyName` | `_LSJSONMapping.swift:86` |
| `ls_addGlobalMapping(_:)` | MJExtension | - | `_LSJSONMapping.swift:101` |
| `ls_getGlobalMapping()` | MJExtension | - | `_LSJSONMapping.swift:115` |
| `ls_clearGlobalMapping()` | MJExtension | - | `_LSJSONMapping.swift:122` |
| `ls_registerMapping(for:mapping:)` | - | - | `_LSJSONMapping.swift:146` |
| `ls_registerMappings(_:)` | - | - | `_LSJSONMapping.swift:162` |
| `ls_getMapping(for:)` | - | - | `_LSJSONMapping.swift:179` |
| `ls_clearMapping(for:)` | - | - | `_LSJSONMapping.swift:197` |
| `ls_jsonKey(for:in:)` | - | - | `_LSJSONMapping.swift:257` |
| `ls_propertyName(for:in:)` | - | - | `_LSJSONMapping.swift:283` |
| `ls_convert(_:to:)` | YYModel | `yy_modelWithJSON` | `_LSJSONMapping.swift:367` |
| `ls_convertArray(_:to:)` | YYModel | - | `_LSJSONMapping.swift:372` |

#### D. 归档/解档方法

| 方法 | 参考库 | 原方法 | 文件 |
|------|--------|--------|------|
| `ls_archiveData()` | MJExtension | `mj_archiveToData` | `_LSArchiver.swift:37` |
| `ls_archiveArrayData(_:)` | MJExtension | - | `_LSArchiver.swift:50` |
| `ls_archiveFile(to:)` | MJExtension | `mj_archiveToFile` | `_LSArchiver.swift:74` |
| `ls_archiveArrayFile(to:)` | MJExtension | - | `_LSArchiver.swift:96` |
| `ls_unarchive(from:as:)` | MJExtension | `mj_unarchiveWithData` | `_LSArchiver.swift:126` |
| `ls_unarchiveArray(from:as:)` | MJExtension | - | `_LSArchiver.swift:141` |
| `ls_unarchive(from:as:)` | MJExtension | `mj_unarchiveWithFile` | `_LSArchiver.swift:168` |
| `ls_unarchiveArray(from:as:)` | MJExtension | - | `_LSArchiver.swift:184` |

#### E. 数组扩展方法

| 方法 | 参考库 | 原方法 | 文件 |
|------|--------|--------|------|
| `Array.ls_archiveArrayData()` | MJExtension | - | `_LSArchiver.swift:254` |
| `Array.ls_archiveArrayFile(to:)` | MJExtension | - | `_LSArchiver.swift:276` |
| `Array.ls_unarchiveArray(from:as:)` | MJExtension | - | `_LSArchiver.swift:299` |
| `Array.ls_unarchiveArray(from:as:)` | MJExtension | - | `_LSArchiver.swift:303` |

---

## 设计原则说明

### 1. 命名规范

所有 LSJSONModel 的公开方法统一使用 `ls_` 前缀，**不暴露参考库的方法名**：

- ❌ **不使用**: `kj_model`, `mj_replacedKeyFromPropertyName`, `yy_modelWithJSON`, `deserialize`
- ✅ **使用**: `ls_decode`, `ls_setGlobalMapping`, `ls_convert`, `ls_archiveData`

### 2. 重写而非封装

LSJSONModel 采用**重写实现**的策略，而非简单封装第三方库：

```swift
// ✅ LSJSONModel 方式 - 自己实现
public static func ls_decode(_ json: String) -> Self? {
    guard let data = json.data(using: .utf8) else { return nil }
    return LSJSONDecoder.decode(data, as: Self.self)
}

// ❌ 不采用 - 封装第三方库
public static func ls_decode(_ json: String) -> Self? {
    return User.kj_model(json: json)  // 暴露了参考库名
}
```

### 3. 统一接口

无论底层使用何种策略（Codable/性能模式），对外暴露统一的 API：

```swift
// 用户只需调用 ls_encode，内部自动选择最优策略
let json = user.ls_encode()  // 内部可能是 Codable 或性能模式
```

---

## 参考库统计

### 按功能模块统计

| 功能模块 | 主要参考库 | 影响程度 |
|----------|-----------|----------|
| **全局映射** | MJExtension | ⭐⭐⭐⭐⭐ |
| **归档/解档** | MJExtension | ⭐⭐⭐⭐⭐ |
| **解码/编码** | KakaJSON | ⭐⭐⭐⭐ |
| **缓存优化** | KakaJSON | ⭐⭐⭐⭐⭐ |
| **模型转换** | YYModel | ⭐⭐⭐⭐ |
| **OC 兼容** | HandyJSON | ⭐⭐⭐ |

### 按方法数量统计

| 参考库 | 方法数量 |
|--------|----------|
| **MJExtension** | 12 个 |
| **KakaJSON** | 8 个 |
| **YYModel** | 2 个 |
| **HandyJSON** | 6 个 (协议) |

---

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.0 | 2026-01-24 | 初始版本，完整文档 |

---

## 附录

### A. 相关文件

| 文件 | 说明 |
|------|------|
| `Sources/LSJSONDecoder.swift` | 统一解码器 |
| `Sources/LSJSONEncoder.swift` | 统一编码器 |
| `Sources/Macros/_LSJSONMapping.swift` | 映射系统 |
| `Sources/Macros/_LSJSONMappingCache.swift` | 映射缓存 |
| `Sources/Runtime/_LSArchiver.swift` | 归档解档 |
| `Sources/Runtime/_LSTypeConverter.swift` | 类型转换 |
| `Sources/Performance/LSJSONDecoderHP.swift` | 高性能解码 |
| `Sources/Performance/LSJSONEncoderHP.swift` | 高性能编码 |
| `Sources/OC/LSJSONOC.swift` | OC 兼容 |

### B. 参考链接

- [MJExtension GitHub](https://github.com/CoderMJLee/MJExtension)
- [YYModel GitHub](https://github.com/ibireme/YYModel)
- [KakaJSON GitHub](https://github.com/kakaopensource/KakaJSON)
- [HandyJSON GitHub](https://github.com/alibaba/handyjson)
