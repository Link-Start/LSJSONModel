# JSON 模式

LSJSONModel 中常见的 JSON 数据模式。

---

## 标准 API 响应

```swift
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
    let code: Int
}
```

## 分页数据

```swift
struct PagedResponse<T: Decodable>: Decodable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}
```

## 用户模型

```swift
struct User: Codable {
    let id: String
    let username: String
    let email: String
    let createdAt: Date
    let updatedAt: Date?
}
```

## Snake Case 响应

```json
{
    "user_id": "123",
    "user_name": "张三",
    "created_at": "2024-01-23T12:00:00Z"
}
```

对应 Swift 模型：

```swift
@LSSnakeCaseKeys
struct User: Codable {
    var userId: String
    var userName: String
    var createdAt: Date
}
```

---

## 映射优先级示例

```swift
// 全局映射（最低优先级）
LSJSONMapping.ls_setGlobalMapping(["id": "user_id"])

// 类型映射
struct User: Codable, LSJSONMappingProvider {
    static func ls_mappingKeys() -> [String: String] {
        return ["name": "display_name"]
    }
}

// 宏标记（最高优先级）
@LSSnakeCaseKeys
struct User: Codable {
    @LSMappedKey("special_id")
    var id: String  // 使用 special_id

    var name: String  // 使用 display_name（类型映射）
    var email: String // 使用 email（全局映射，如果存在）
}
```
