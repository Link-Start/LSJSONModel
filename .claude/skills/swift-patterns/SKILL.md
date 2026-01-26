# Swift 模式

iOS/Swift 开发的常见模式和最佳实践。

---

## 错误处理模式

```swift
enum LSJSONError: Error, LocalizedError {
    case invalidJSON(String)
    case decodingFailed(Error)
    case encodingFailed(Error)

    var localizedDescription: String {
        switch self {
        case .invalidJSON(let msg):
            return "JSON 无效: \(msg)"
        case .decodingFailed(let error):
            return "解码失败: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "编码失败: \(error.localizedDescription)"
        }
    }
}
```

## Result 类型

```swift
enum LSJSONResult<T> {
    case success(T)
    case failure(Error)

    var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }

    var error: Error? {
        if case .failure(let e) = self { return e }
        return nil
    }
}
```

## 单例模式

```swift
final class LSJSONMapping {
    static let shared = LSJSONMapping()

    private init() {}

    // 使用 shared 实例
    static func ls_setGlobalMapping(_ mapping: [String: String]) {
        shared.setGlobalMapping(mapping)
    }
}
```

## 工厂模式

```swift
protocol LSJSONDecodable {
    static func ls_decode(_ json: String) -> Self?
}

extension User: LSJSONDecodable {
    static func ls_decode(_ json: String) -> User? {
        // 实现
    }
}
```

## 建造者模式

```swift
class LSJSONBuilder<T> {
    private var dictionary: [String: Any] = [:]

    func field(_ key: String, _ value: Any) -> Self {
        dictionary[key] = value
        return self
    }

    func build() -> [String: Any] {
        dictionary
    }
}

// 使用
let dict = LSJSONBuilder<Any>()
    .field("name", "张三")
    .field("age", 25)
    .build()
```

## 适配器模式

```swift
class LSJSONAdapter {
    static func adapt<T: Decodable>(from dictionary: [String: Any]) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
```

## 策略模式

```swift
enum LSJSONDecodeMode {
    case codable
    case performance
}

class LSJSONDecoder {
    static func decode<T: Decodable>(_ data: Data, as type: T.Type, mode: LSJSONDecodeMode) -> T? {
        switch mode {
        case .codable:
            return try? JSONDecoder().decode(T.self, from: data)
        case .performance:
            // 性能优化解码
            return nil
        }
    }
}
```
