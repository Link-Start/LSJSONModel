# Package.swift 宏配置模板

> 此文件记录了 Swift Macros 的 Package.swift 配置
> 当宏实现与 swift-syntax API 兼容后可启用

---

## 当前状态

**宏模块状态**: 暂时注释
**原因**: 宏实现代码与 swift-syntax 509/600 API 不兼容
**影响**: 宏声明存在但实现不可用（编译时警告）

---

## 已知 API 兼容性问题

### swift-syntax 509.1.1 与实现的差异

1. **`ExpressibleByArgument`** - 不存在
   - 位置: `LSJSONMacros.swift`, `LSIgnoreMacro.swift`
   - 解决: 需要自定义或移除此协议

2. **`AttributeSyntax.argumentList`** - 不存在
   - 位置: `LSMappedKeyMacro.swift:45`, `LSIgnoreMacro.swift:82,159`
   - 解决: 使用 `AttributeSyntax.arguments` 替代

3. **`DictionaryExprSyntax.Content.dictionary`** - 不存在
   - 位置: `LSModelMacro.swift:117`
   - 解决: 使用新的 content API

4. **字符串插值 `\(raw:)`** - 不支持
   - 位置: `LSModelMacro.swift:139`
   - 解决: 使用 `StringLiteralExprSyntax` 手动构建

5. **`DeclGroupSyntax.name`** - 不存在
   - 位置: `LSModelMacro.swift:35`
   - 解决: 需要遍历成员查找名称

---

## 启用宏配置的步骤

### 步骤 1: 更新宏实现代码

将 `LSJSONModelMacros/` 中的代码更新为兼容 swift-syntax 509/600 的版本。

### 步骤 2: 取消注释 Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LSJSONModel",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "LSJSONModel", targets: ["LSJSONModel"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        // 宏实现模块
        .target(
            name: "LSJSONModelMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "LSJSONModelMacros"
        ),
        // 主库模块
        .target(
            name: "LSJSONModel",
            dependencies: ["LSJSONModelMacros"],  // 启用依赖
            path: "Sources",
            exclude: ["Docs"]
        ),
        // 测试模块
        .testTarget(
            name: "LSJSONModelTests",
            dependencies: ["LSJSONModel"],
            path: "Tests"
        )
    ]
)
```

### 步骤 3: 验证构建

```bash
swift build
```

---

## 宏实现文件清单

| 文件 | 状态 | 问题 |
|------|------|------|
| `LSJSONModelMacroPlugin.swift` | ✅ OK | - |
| `_LSMacroExpansionHelper.swift` | ⚠️ API | 需要更新 |
| `LSModelMacro.swift` | ⚠️ API | 需要更新 (5 处) |
| `LSSnakeCaseKeysMacro.swift` | ⚠️ API | 需要更新 |
| `LSMappedKeyMacro.swift` | ⚠️ API | 需要更新 (1 处) |
| `LSIgnoreMacro.swift` | ⚠️ API | 需要更新 (4 处) |

---

## 替代方案

### 方案 A: 使用旧版 swift-syntax

尝试使用更早的 swift-syntax 版本，但可能不支持 Swift 5.9+ 的宏特性。

### 方案 B: 等待 swift-syntax 稳定

等待 swift-syntax 600+ 稳定发布后再更新宏实现。

### 方案 C: 重写宏实现

根据 swift-syntax 509 的 API 完全重写宏实现（推荐）。

---

## 参考资源

- [Swift Syntax GitHub](https://github.com/swiftlang/swift-syntax)
- [Swift Macros Proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0382-expression-macros.md)
- [Writing Macro Documentation](https://swiftpackageindex.com/swiftlang/swift-syntax/documentation/swiftsyntax/writing-macros)

---

**最后更新**: 2026-01-24
**维护者**: link-start
