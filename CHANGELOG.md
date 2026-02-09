# 更新日志

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
