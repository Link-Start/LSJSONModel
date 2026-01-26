# 命名规范

LSJSONModel 项目必须严格遵守的命名规范。

---

## 核心原则

**所有公开方法统一使用 `ls_` 前缀，不暴露参考库方法名**

---

## 禁止使用的方法名

❌ **严禁使用**以下方法名（来自参考库）：

### KakaJSON
- `kj_model`
- `kj_JSON`
- `kj_fastModel`
- `kj_dictionary`
- 任何包含 `kj_` 的方法

### HandyJSON
- `deserialize`
- `serialize`
- `mapping`
- `toJSON`
- 任何包含 `handy_` 的方法

### YYModel
- `yy_modelWithJSON`
- `yy_modelToJSONObject`
- `modelCustomPropertyMapper`
- 任何包含 `yy_` 的方法

### MJExtension
- `mj_setKeyValues`
- `mj_keyValues`
- `mj_replacedKeyFromPropertyName`
- `mj_archiveToFile`
- `mj_unarchiveWithFile`
- 任何包含 `mj_` 的方法

### Codable（不作为方法名暴露）
- `decode(from:)`
- `encode(to:)`
- `init(from:)`
- 这些是协议方法，可以内部使用，但不作为公开 API 暴露

---

## 正确的命名

### 解码方法

```swift
// ✅ 正确
User.ls_decode(json)
User.ls_decodeFromJSONData(data)
User.ls_decodeFromDictionary(dict)
User.ls_decodeArrayFromJSON(jsonArray)

// ❌ 错误
User.kj_model(json: jsonString)
User.deserialize(from: jsonString)
```

### 编码方法

```swift
// ✅ 正确
user.ls_encode()
user.ls_encodeToData()
user.ls_toDictionary()

// ❌ 错误
user.kj_JSON()
user.toJSON()
```

### 映射方法

```swift
// ✅ 正确
LSJSONMapping.ls_setGlobalMapping([:])
LSJSONMapping.ls_registerMapping(for: User.self, mapping: [:])

// ❌ 错误
User.mj_replacedKeyFromPropertyName([:])
User.modelCustomPropertyMapper()
```

### 归档方法

```swift
// ✅ 正确
user.ls_archiveData()
user.ls_archiveFile(to: path)
User.ls_unarchive(from: data)
User.ls_unarchive(from: path)

// ❌ 错误
user.mj_archiveToFile(path)
user.mj_unarchiveWithFile(path)
```

---

## 内部实现命名

内部（私有）实现可以使用任何名称，只要不公开暴露：

```swift
// ✅ 内部实现 - 不对外暴露
internal struct _LSKakaJSON { ... }
internal func _kj_decode() { ... }

// ✅ 通过 ls_ 方法调用内部实现
public static func ls_decode(_ json: String) -> Self? {
    return _LSKakaJSON._internalDecode(json)
}
```

---

## 宏命名

所有公开宏使用 `@LS` 前缀：

```swift
// ✅ 正确
@LSModel
@LSSnakeCaseKeys
@LSMappedKey
@LSIgnore
@LSDefault
@LSDateCoding

// ❌ 错误（禁止使用）
@KakaModel
@HandyJSON
@YYModel
@MJExtension
```

---

## 类型命名

```swift
// ✅ 正确
LSJSONModel
LSJSONDecoder
LSJSONEncoder
LSJSONMapping
LSJSONArchiver

// ❌ 错误
KakaJSONWrapper
HandyJSONAdapter
YYModelCompat
```

---

## 检查清单

在代码审查时，检查：

- [ ] 公开 API 是否都使用 `ls_` 前缀？
- [ ] 是否有暴露参考库的方法名？
- [ ] 宏命名是否使用 `@LS` 前缀？
- [ ] 内部实现是否正确隐藏？
