# LSJSONModel 参考库说明

> LSJSONModel 设计借鉴的参考库介绍

---

## 参考库

LSJSONModel 是一个全新的 JSON 转 Model 库，设计时参考了以下优秀库的优点：

### Codable (Swift 官方)

**简介**: Swift 4.0 引入的原生序列化/反序列化协议

**优点借鉴**:
- ✅ 编译时类型安全
- ✅ 无需第三方依赖
- ✅ Swift 官方支持
- ✅ 与 Swift 6 完美配合

**官方文档**: https://developer.apple.com/documentation/swift/codable

---

### HandyJSON (阿里巴巴)

**简介**: 阿里巴巴开源的 JSON 库，设计理念接近 YYModel

**优点借鉴**:
- ✅ 运行时灵活性
- ✅ 不需要继承 NSObject
- ✅ 支持复杂的嵌套对象
- ✅ 类型转换能力强

**GitHub**: https://github.com/alibaba/HandyJSON

---

### KakaJSON

**简介**: 高性能的 JSON 转换库

**优点借鉴**:
- ✅ 极致性能优化
- ✅ 方法缓存机制
- ✅ 属性预计算
- ✅ 简洁的 API 设计

**GitHub**: https://github.com/kakaopensource/KakaJSON

---

### YYModel (YYKit)

**简介**: iOS/OSX 平台的高性能 JSON 框架

**优点借鉴**:
- ✅ 全局属性映射系统
- ✅ 归档/解档功能
- ✅ 性能优化策略

**GitHub**: https://github.com/ibireme/YYModel

---

### MJExtension

**简介**: 简单易用的 JSON-Model 转换框架

**优点借鉴**:
- ✅ 简洁的全局映射 API
- ✅ 归档/解档功能
- ✅ 容易上手

**GitHub**: https://github.com/CoderMJLee/MJExtension

---

## LSJSONModel 的独特设计

虽然参考了上述库的优点，但 LSJSONModel 是**完全重新实现**的库，具有以下独特特性：

### 1. 全局映射系统

类似 MJExtension 的全局属性映射，但 API 更加简洁：

```swift
// 一处设置，全局生效
LSJSONMapping.ls_setGlobalMapping([
    "id": "user_id",
    "description": "desc"
])
```

### 2. 映射优先级

清晰的五级优先级系统，确保映射行为可预测：

1. 宏标记 (@LSMappedKey) - 最高优先级
2. 类型映射 (ls_registerMapping)
3. 全局映射 (ls_setGlobalMapping)
4. Snake Case 转换 (@LSSnakeCaseKeys)
5. 默认映射

### 3. 跨 Model 转换

支持不同 Model 类型之间的无缝转换：

```swift
let appUser = LSJSONMapping.ls_convert(apiUser, to: AppUser.self)
```

### 4. Swift Macros 支持

利用 Swift 5.9+ 的宏功能，自动生成样板代码：

```swift
@LSModel
@LSSnakeCaseKeys
struct User: Codable {
    @LSMappedKey("custom_id")
    var id: String
}
```

### 5. 高性能缓存

内置映射缓存系统，确保查询效率：

```swift
// 预热缓存
_LSJSONMappingCache.warmup(for: [User.self, Order.self])

// 查看统计
let stats = _LSJSONMappingCache.getStats()
print("命中率: \(stats.hitRate)")
```

---

## 命名规范

LSJSONModel 严格遵守命名规范，不使用参考库的方法名：

| 功能 | 参考库名称 | LSJSONModel |
|------|------------|-------------|
| 解码 | `kj_model()`, `deserialize()`, `yy_modelWithJSON:` | `ls_decode()` |
| 编码 | `kj_JSON()`, `toJSON()`, `yy_modelToJSONString` | `ls_encode()` |
| 映射 | `mj_replacedKeyFromPropertyName` | `ls_mappingKeys()` |
| 归档 | `mj_archiveToFile:` | `ls_archiveFile(to:)` |

---

## 版本兼容

| iOS 版本 | Swift 版本 | 支持功能 |
|----------|------------|----------|
| iOS 13+ | Swift 5.0+ | Property Wrapper，基础功能 |
| iOS 15+ | Swift 5.9+ | Swift Macros 全部功能 |

---

## 许可证

LSJSONModel 采用 MIT 许可证。

参考库的许可证信息请访问各自的 GitHub 页面查看。

---

**文档版本**: v1.0
**最后更新**: 2026-01-24
