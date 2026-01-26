# ⚠️ 重要提醒：方法命名规范

**请严格遵循以下规则，避免在代码中出现参考库的明显名称！**

## ❌ 禁止使用的方法名（参考库明显名称）

### KakaJSON 相关
- ❌ kakaFromJSON
- ❌ kakaToJSON
- ❌ kakaModel
- ❌ ls_kakaFromJSON
- ❌ ls_kakaToJSON

### HandyJSON 相关
- ❌ handyFromJSON
- ❌ handyToJSON
- ❌ handyModel
- ❌ ls_handyFromJSON
- ❌ ls_handyToJSON

### YYModel 相关
- ❌ yyModel
- ❌ yyFromJSON
- ❌ yyToJSON
- ❌ yy_modelWithJSON
- ❌ yy_modelToJSONString

### MJExtension 相关
- ❌ mjSetKeyValues
- ❌ mjKeyValues
- ❌ mj_setKeyValues

## ✅ 推荐使用的方法名（隐蔽内部实现）

### Codable 模式
- `ls_decode(_:)`
- `ls_encode()`
- `ls_encodeToData()`
- `ls_decodeFromJSONData(_:)`
- `ls_encodeToDictionary()`

### 性能模式
- `ls_decode(_:)`
- `ls_encode()`

### 运行时模式
- `ls_decode(_:)`
- `ls_encode()`

## 📋 实现原则

1. **不封装参考库** - 不对 KakaJSON、HandyJSON 进行简单封装
2. **不暴露参考库名** - 不使用 kaka、handy、yy 等作为方法名的一部分
3. **自己实现** - 借鉴各库的优点重新实现
4. **统一 ls_ 前缀** - 所有公开方法使用 `ls_` 前缀

## 🎯 方法命名示例

### ❌ 错误示例（不要这样命名）
```swift
// 直接调用参考库
let user = User.kj_model(json: jsonString)      // ❌ 暴露了 kaka
let user = User.deserialize(from: jsonString)    // ❌ 暴露了 handy
let user = User.yy_modelWithJSON(json)     // ❌ 暴露了 yy

// 封装调用（仍然暴露参考库名）
let user = User.ls_kakaFromJSON(json)        // ❌ kaka 明显
let user = User.ls_handyFromJSON(json)        // ❌ handy 明显
```

### ✅ 正确示例（应该这样命名）
```swift
// 直接调用原生 Codable
let user = try? JSONDecoder().decode(User.self, from: jsonData)

// 自己实现的 ls_ 前缀方法
let user = User.ls_decode(jsonString)
let jsonString = user.ls_encode()

// 内部实现（私有类，不暴露参考库名）
internal struct _LSJSONDecoder {
    // 内部调用参考库优化，但不暴露方法名
}
```

## ⚠️ 违反检查

### 代码审查清单

在代码审查时，检查以下项：
- [ ] 是否包含 `kaka` 或 `kj_`
- [ ] 是否包含 `handy` 或 `hy_`
- [ ] 是否包含 `yy_model` 或 `yy_`
- [ ] 是否包含 `mj_setKey` 或 `mjKey`
- [ ] 是否直接调用参考库的明显方法

### 如果发现违例：

1. 重命名方法，使用内部私有实现
2. 将参考库调用封装到 `_LSJSON` 私有类中
3. 确保所有公开方法都使用 `ls_` 前缀

---

**请所有开发人员在提交代码前检查本清单！**
