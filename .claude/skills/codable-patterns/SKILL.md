# Codable 模式

Swift Codable 的最佳实践和常见模式。

---

## 基础 Codable 模型

```swift
struct User: Codable {
    let id: String
    let name: String
    let age: Int
}
```

## 自定义 CodingKeys

```swift
struct User: Codable {
    let userId: String
    let userName: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
    }
}
```

## 可选属性处理

```swift
struct User: Codable {
    let id: String
    let name: String
    let bio: String?
    let website: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case website
    }
}
```

## 嵌套对象

```swift
struct User: Codable {
    let id: String
    let profile: UserProfile

    struct UserProfile: Codable {
        let avatar: String
        let location: String
    }
}
```

## 数组处理

```swift
struct Response: Codable {
    let users: [User]

    struct User: Codable {
        let id: String
        let name: String
    }
}
```

## 日期格式

```swift
struct User: Codable {
    let createdAt: Date
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// 使用时
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
```

## 默认值

```swift
struct User: Codable {
    let id: String
    let name: String
    let age: Int
    let isActive: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }
}
```

## 忽略字段

```swift
struct User: Codable {
    let id: String
    let name: String
    let internalFlag: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
```
