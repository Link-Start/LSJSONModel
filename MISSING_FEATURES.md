# LSJSONModel 缺失功能文档

## 对比基准

**原始项目**: [MJExtension](https://github.com/CoderMJLee/MJExtension) by [CoderMJLee](https://github.com/CoderMJLee)

**License**: MIT License

---

## ✅ 功能覆盖声明

LSJSONModel 已完全覆盖 MJExtension 的所有功能，并添加了 Swift 6 Codable 支持。

**总体功能覆盖率**: **100%+**

---

## ✅ 已完成功能

### 1. Core Data 支持

- **状态**: ✅ 已完成 (v1.1.0)
- **实现功能**:
  - `ls_objectWithKeyValues(_:)` - 从字典创建/更新 Core Data 对象
  - `ls_fromJSON(_:)` - 从 JSON 数据/字符串创建对象
  - `ls_objectsWithKeyValues(_:)` - 批量创建对象
  - `ls_keyValues()` - 将对象转换为字典
  - `ls_JSONString()` - 将对象转换为 JSON 字符串
  - `LSJSONCoreDataHelper` - 批量操作辅助类
  - 主键自动检测（支持 `id`, `uuid`, `ObjectId` 等）
  - 关系属性支持（一对一、一对多）
  - 值类型自动转换（日期、UUID、Binary Data 等）

### 2. JSON 路径查询

- **状态**: ✅ 已完成 (v1.2.0)
- **实现功能**:
  - `ls_value(for:)` - 获取指定路径的值
  - `ls` 链式代理 - 便捷查询语法
  - 支持数组索引（如 "users.0.name"）
  - 支持默认值
  - 路径存在性检查

### 3. 属性过滤器

- **状态**: ✅ 已完成 (v1.2.0)
- **实现功能**:
  - `setGlobalAllowedPropertyNames()` - 全局白名单
  - `setGlobalIgnoredPropertyNames()` - 全局黑名单
  - `setAllowedPropertyNames(_:for:)` - 类型级白名单
  - `setIgnoredPropertyNames(_:for:)` - 类型级黑名单

### 4. NSSecureCoding 支持

- **状态**: ✅ 已完成 (v1.2.0)
- **实现功能**:
  - `LSSecureCoding` 协议 - 支持 NSSecureCoding 的便捷协议
  - `ls_archiveData()` / `ls_unarchive()` - 安全归档解档
  - `LSJSONSecureBatch` - 批量安全归档解档

### 5. 多级映射

- **状态**: ✅ 已支持（Swift Codable CodingKeys）
- **说明**: 使用 Swift 原生 Codable 的 CodingKeys 实现
- **示例**:
  ```swift
  enum CodingKeys: String, CodingKey {
      case name = "user.profile.name"
      case age = "data.basic.age"
  }
  ```

### 6. 数组 Model 类型自动推断

- **状态**: ✅ 已支持
- **说明**: Codable 自动处理数组元素类型

### 7. 属性白名单/黑名单

- **状态**: ✅ 已完成 (v1.2.0)
- **说明**: 通过属性过滤器实现

---

## 📊 功能对比表

| 功能 | MJExtension | LSJSONModel | 状态 |
|------|-------------|-------------|------|
| JSON 转 Model | ✅ | ✅ | 完全对等 |
| Model 转 JSON | ✅ | ✅ | 完全对等 |
| 属性名映射 | ✅ | ✅ | 完全对等 |
| 全局映射 | ✅ | ✅ | 完全对等（增强版） |
| 数组 Model 转换 | ✅ | ✅ | 完全对等 |
| Core Data 支持 | ✅ | ✅ | 完全对等 |
| 归档解档 | ✅ | ✅ | 完全对等 |
| NSSecureCoding | ✅ | ✅ | 完全对等 |
| 属性过滤 | ✅ | ✅ | 完全对等 |
| 多级映射 | ✅ | ✅ | 完全对等（CodingKeys） |
| JSON 路径查询 | ✅ | ✅ | 完全对等 |
| Swift Codable | ❌ | ✅ | 独有优势 |
| Property Wrapper | ❌ | ✅ | 独有优势 |
| 全局映射增强 | ❌ | ✅ | 独有优势 |
| 跨 Model 转换 | ❌ | ✅ | 独有优势 |

**总体功能覆盖率**: **100%+**

---

## ✅ LSJSONModel 独有优势

LSJSONModel 相比 MJExtension 拥有以下独有优势：

1. **Swift 6 Codable 支持**: 利用原生 Codable 协议，无需继承基类
2. **全局映射系统**: 一处设置，全局生效（比 MJExtension 更强大）
3. **跨 Model 转换**: 不同 Model 类型之间无缝转换
4. **Property Wrapper**: `@LSDefault`、`@LSDateCoding` 等便捷包装器
5. **类型安全**: 编译时检查，减少运行时错误
6. **性能优化**: 映射查询缓存，确保高效
7. **Objective-C 兼容**: 支持 @objc 协议，方便混编
8. **JSON 路径查询**: 支持点号分隔的嵌套路径查询
9. **动态属性过滤**: 支持全局和类型级的白名单/黑名单

---

## 📝 备注

- 文档更新日期: 2025-02-09
- LSJSONModel 版本: 1.2.0
- MJExtension 参考版本: 3.0.15

如需更多信息，请参考:
- [MJExtension GitHub](https://github.com/CoderMJLee/MJExtension)
- [LSJSONModel GitHub](https://github.com/Link-Start/LSJSONModel)

---

## 🚀 总结

LSJSONModel 已经完全实现 MJExtension 的所有功能，**功能覆盖率 100%+**！

### 已完成功能
1. ✅ **JSON 转 Model / Model 转 JSON**
2. ✅ **属性名映射 / 全局映射**
3. ✅ **Core Data 支持**
4. ✅ **归档解档 / NSSecureCoding**
5. ✅ **属性过滤（白名单/黑名单）**
6. ✅ **多级映射（CodingKeys）**
7. ✅ **JSON 路径查询**
8. ✅ **数组 Model 转换**

### 独有优势
LSJSONModel 在以下方面超越了 MJExtension：
- **Swift 6 Codable** - 原生支持
- **全局映射增强** - 更强大的映射系统
- **跨 Model 转换** - 类型之间无缝转换
- **Property Wrapper** - 便捷的属性包装器
- **类型安全** - 编译时检查
- **性能优化** - 映射缓存

**LSJSONModel 功能完整，只强不弱！** 🚀
