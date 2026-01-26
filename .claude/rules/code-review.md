# 代码审查规则

LSJSONModel 项目的代码审查标准。

---

## 审查检查清单

### 功能正确性

- [ ] JSON 解码/编码是否正确处理？
- [ ] 映射优先级是否正确实现？
- [ ] 错误处理是否完善？
- [ ] 边界情况是否考虑？

### 命名规范

- [ ] 公开方法是否使用 `ls_` 前缀？
- [ ] 是否没有暴露参考库方法名？
- [ ] 宏命名是否使用 `@LS` 前缀？
- [ ] 内部实现是否正确隐藏？

### 性能

- [ ] 是否有内存泄漏风险？
- [ ] 缓存是否正确使用？
- [ ] 大数据量处理是否高效？

### Swift 6 兼容性

- [ ] 并发安全标记是否正确？
- [ ] Sendable 约束是否满足？
- [ ] @objc 兼容性是否正确？

### 代码风格

- [ ] 代码是否简洁易懂？
- [ ] 注释是否清晰？
- [ ] 文件组织是否合理？

---

## 常见问题

### 1. 暴露参考库名称

❌ **错误：**
```swift
return User.kj_model(json: jsonString)
```

✅ **正确：**
```swift
return _LSKakaJSON._internalDecode(jsonString)
```

### 2. 缺少错误处理

❌ **错误：**
```swift
let data = json.data(using: .utf8)!
return try! decoder.decode(T.self, from: data)
```

✅ **正确：**
```swift
guard let data = json.data(using: .utf8) else {
    print("[LSJSONDecoder] ❌ JSON 字符串转 Data 失败")
    return nil
}
do {
    return try decoder.decode(T.self, from: data)
} catch {
    print("[LSJSONDecoder] ❌ Codable 解码失败: \(error)")
    return nil
}
```

### 3. 硬编码类型

❌ **错误：**
```swift
let user = dict["user"] as! User
```

✅ **正确：**
```swift
guard let userDict = dict["user"] as? [String: Any],
      let user = User.ls_decodeFromDictionary(userDict) else {
    return nil
}
```

### 4. 忽略可选值

❌ **错误：**
```swift
let name = dict["name"] as! String
```

✅ **正确：**
```swift
let name = dict["name"] as? String ?? ""
```
