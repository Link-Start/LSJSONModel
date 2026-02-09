# 更新日志

## [1.2.0] - 2025-02-09

### 新增功能

- 🎉 **JSON 路径查询** - 从嵌套 JSON 中提取数据
  - `ls_value(for:)` - 获取指定路径的值
  - `ls` 链式代理 - 便捷的查询语法
  - 支持数组索引（如 "users.0.name"）
  - 支持默认值
  - 路径存在性检查

- 🎉 **属性过滤器** - 动态设置属性白名单/黑名单
  - `setGlobalAllowedPropertyNames()` - 全局白名单
  - `setGlobalIgnoredPropertyNames()` - 全局黑名单
  - `setAllowedPropertyNames(_:for:)` - 类型级白名单
  - `setIgnoredPropertyNames(_:for:)` - 类型级黑名单

- 🎉 **NSSecureCoding 支持** - 增强归档解档安全性
  - `LSSecureCoding` 协议 - 支持 NSSecureCoding 的便捷协议
  - `ls_archiveData()` / `ls_unarchive()` - 安全归档解档
  - `LSJSONSecureBatch` - 批量安全归档解档

### 技术改进

- ✅ 完整的类型安全
- ✅ Actor 线程安全的过滤器
- ✅ 错误处理机制

### 功能覆盖率

- **相比 MJExtension**: **100%+**
- 已实现所有核心功能，包括高级功能

### 兼容性

- iOS 13.0+
- macOS 10.15+
- Swift 6.0+
- Xcode 16.0+

---

## [1.1.0] - 2025-02-09

### 新增功能

- 🎉 **Core Data 支持** - 完整的 NSManagedObject JSON 转换支持
  - `ls_objectWithKeyValues(_:)` - 从字典创建/更新 Core Data 对象
  - `ls_fromJSON(_:)` - 从 JSON 数据/字符串创建对象
  - `ls_objectsWithKeyValues(_:)` - 批量创建对象
  - `ls_keyValues()` - 将对象转换为字典
  - `ls_JSONString()` - 将对象转换为 JSON 字符串
  - `LSJSONCoreDataHelper` - 批量操作辅助类
  - 主键自动检测（支持 `id`, `uuid`, `ObjectId` 等）
  - 关系属性支持（一对一、一对多）
  - 值类型自动转换（日期、UUID、Binary Data 等）

### 技术改进

- ✅ 支持 iOS 13+ Core Data 集成
- ✅ 线程安全的批量操作（通过 perform block）
- ✅ 类型安全的属性设置
- ✅ 完善的错误处理机制
- ✅ JSON 文件导入/导出功能

### 兼容性

- iOS 13.0+
- macOS 10.15+
- Swift 5.9+
- Xcode 16.0+

---

## [1.0.0] - 2026-01-26

### 首次发布

- ✅ 基于 Codable 的 JSON 转换
- ✅ 全局变量名映射
- ✅ 跨 Model 转换
- ✅ 归档解档功能
- ✅ MJExtension 风格 API
- ✅ Property Wrapper 支持
- ✅ 性能优化缓存
- ✅ Objective-C 兼容
