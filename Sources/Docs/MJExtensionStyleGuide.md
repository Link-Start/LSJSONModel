# LSJSONModel MJExtension 风格 API 使用指南

> 为习惯了 MJExtension 的开发者提供的无缝迁移方案

---

## 目录

- [快速对照](#快速对照)
- [基础转换](#基础转换)
- [数组操作](#数组操作)
- [文件操作](#文件操作)
- [属性映射](#属性映射)
- [归档解档](#归档解档)
- [完整对照表](#完整对照表)

---

## 快速对照

### OC (MJExtension) vs Swift (LSJSONModel)

```objc
// MJExtension (OC)
User *user = [User mj_objectWithKeyValues:dict];
NSDictionary *dict = user.mj_keyValues;
NSString *json = user.mj_JSONString;
[user mj_setKeyValues:newDict];
```

```swift
// LSJSONModel (Swift) - 方法名完全一致，仅添加 ls_ 前缀
let user = User.ls_objectWithKeyValues(dict)
let dict = user.ls_keyValues
let json = user.ls_JSONString
user.ls_setKeyValues(newDict)
```

---

## 基础转换

### 1. 从字典创建对象

```objc
// MJExtension
NSDictionary *dict = @{@"id": @"123", @"name": @"张三"};
User *user = [User mj_objectWithKeyValues:dict];
```

```swift
// LSJSONModel - 完全一致的方法名
let dict = ["id": "123", "name": "张三"]
let user = User.ls_objectWithKeyValues(dict)
```

### 2. 从 JSON 字符串创建对象

```objc
// MJExtension
NSString *json = @"{\"id\":\"123\",\"name\":\"张三\"}";
User *user = [User mj_objectWithKeyValues:json];
```

```swift
// LSJSONModel
let json = "{\"id\":\"123\",\"name\":\"张三\"}"
let user = User.ls_objectWithKeyValues(json)
```

### 3. 对象转字典

```objc
// MJExtension
NSDictionary *dict = user.mj_keyValues;
```

```swift
// LSJSONModel
let dict = user.ls_keyValues
```

### 4. 对象转 JSON 字符串

```objc
// MJExtension
NSString *json = user.mj_JSONString;
```

```swift
// LSJSONModel
let json = user.ls_JSONString
```

### 5. 设置已有对象的属性

```objc
// MJExtension
[user mj_setKeyValues:@{@"id": @"456", @"name": @"李四"}];
```

```swift
// LSJSONModel (仅 class 支持，struct 不支持)
user.ls_setKeyValues(["id": "456", "name": "李四"])
```

---

## 数组操作

### 1. 从字典数组创建对象数组

```objc
// MJExtension
NSArray *dicts = @[@{@"id": @"1"}, @{@"id": @"2"}];
NSArray *users = [User mj_objectArrayWithKeyValuesArray:dicts];
```

```swift
// LSJSONModel
let dicts = [["id": "1"], ["id": "2"]] as [[String: Any]]
let users = User.ls_objectArrayWithKeyValuesArray(dicts)
```

### 2. 对象数组转字典数组

```objc
// MJExtension
NSArray *dicts = [User mj_keyValuesArrayWithObjectArray:users];
```

```swift
// LSJSONModel
let dicts = users.ls_keyValuesArray
```

### 3. 对象数组转 JSON 字符串

```objc
// MJExtension
NSString *json = [User mj_JSONStringArrayWithObjectArray:users];
```

```swift
// LSJSONModel
let json = users.ls_JSONStringArray
```

---

## 文件操作

### 1. 从文件读取 JSON

```objc
// MJExtension
User *user = [User mj_objectWithFile:@"/path/to/user.json"];
```

```swift
// LSJSONModel
let user = User.ls_objectWithFile("/path/to/user.json")
```

### 2. 将对象写入文件

```objc
// MJExtension
[user mj_writeToFile:@"/path/to/user.json"];
```

```swift
// LSJSONModel
user.ls_writeToFile("/path/to/user.json")
```

### 3. 归档到文件

```objc
// MJExtension
[user mj_archiveToFile:@"/path/to/user.archive"];
```

```swift
// LSJSONModel
user.ls_archiveToFile("/path/to/user.archive")
```

### 4. 从文件解档

```objc
// MJExtension
User *user = [User mj_unarchiveFromFile:@"/path/to/user.archive"];
```

```swift
// LSJSONModel
let user = User.ls_unarchiveFromFile("/path/to/user.archive")
```

---

## 属性映射

### 1. 自定义属性映射

```objc
// MJExtension
@implementation User

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"userId": @"id",
        @"userName": @"name"
    };
}

@end
```

```swift
// LSJSONModel - 完全一致
class User: NSObject, LSJSONModelMappingProvider {
    var userId: String = ""
    var userName: String = ""

    static func ls_replacedKeyFromPropertyName() -> [String: String] {
        return [
            "userId": "id",
            "userName": "name"
        ]
    }
}
```

### 2. 忽略属性

```objc
// MJExtension
+ (NSArray *)mj_ignoredPropertyNames {
    return @[@"debugInfo", @"tempData"];
}
```

```swift
// LSJSONModel
static func ls_ignoredPropertyNames() -> [String] {
    return ["debugInfo", "tempData"]
}
```

### 3. 数组中的对象类型

```objc
// MJExtension
+ (NSDictionary *)mj_objectClassInArray {
    return @{
        @"friends": [User class],
        @"orders": [Order class]
    };
}
```

```swift
// LSJSONModel
static func ls_objectClassInArray() -> [String: AnyClass] {
    return [
        "friends": User.self,
        "orders": Order.self
    ]
}
```

---

## 归档解档

### 1. 归档到 Data

```objc
// MJExtension
NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user];
```

```swift
// LSJSONModel (使用 Codable)
let data = user.ls_archiveData()
```

### 2. 从 Data 解档

```objc
// MJExtension
User *user = [NSKeyedUnarchiver unarchiveObjectWithData:data];
```

```swift
// LSJSONModel
let user = User.ls_unarchive(from: data)
```

### 3. 归档到文件

```objc
// MJExtension
[user mj_archiveToFile:@"/path/to/user.archive"];
```

```swift
// LSJSONModel
user.ls_archiveToFile("/path/to/user.archive")
```

### 4. 从文件解档

```objc
// MJExtension
User *user = [User mj_unarchiveFromFile:@"/path/to/user.archive"];
```

```swift
// LSJSONModel
let user = User.ls_unarchiveFromFile("/path/to/user.archive")
```

---

## 完整对照表

| MJExtension | LSJSONModel | 参数说明 |
|-------------|-------------|----------|
| **对象创建** |||
| `mj_objectWithKeyValues:` | `ls_objectWithKeyValues(_:)` | 字典/JSON字符串/JSON数据 |
| `mj_objectWithFile:` | `ls_objectWithFile(_:)` | 文件路径 |
| **对象转换** |||
| `mj_keyValues` | `ls_keyValues` | 转换为字典 |
| `mj_JSONString` | `ls_JSONString` | 转换为JSON字符串 |
| `mj_setKeyValues:` | `ls_setKeyValues(_:)` | 设置属性值 |
| **数组操作** |||
| `mj_objectArrayWithKeyValuesArray:` | `ls_objectArrayWithKeyValuesArray(_:)` | 从数组创建 |
| `mj_keyValuesArray` | `ls_keyValuesArray` | 转换为数组 |
| `mj_JSONStringArray` | `ls_JSONStringArray` | 数组转JSON |
| **文件操作** |||
| `mj_writeToFile:` | `ls_writeToFile(_:)` | 写入文件 |
| **归档解档** |||
| `mj_archiveToFile:` | `ls_archiveToFile(_:)` | 归档到文件 |
| `mj_unarchiveFromFile:` | `ls_unarchiveFromFile(_:)` | 从文件解档 |
| **属性映射** |||
| `mj_replacedKeyFromPropertyName` | `ls_replacedKeyFromPropertyName()` | 属性映射 |
| `mj_ignoredPropertyNames` | `ls_ignoredPropertyNames()` | 忽略属性 |
| `mj_objectClassInArray` | `ls_objectClassInArray()` | 数组元素类型 |

---

## 迁移示例

### 完整的 Model 定义

```objc
// MJExtension (OC)
@interface User : NSObject
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) NSArray<User *> *friends;
@end

@implementation User

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"userId": @"user_id",
        @"userName": @"user_name"
    };
}

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"friends": [User class]};
}

@end

// 使用
NSDictionary *dict = @{@"user_id": @"123", @"user_name": @"张三", @"age": @25};
User *user = [User mj_objectWithKeyValues:dict];
NSLog(@"%@", user.mj_keyValues);
```

```swift
// LSJSONModel (Swift) - 方法名完全一致
class User: NSObject, Codable, LSJSONModelMappingProvider {
    var userId: String = ""
    var userName: String = ""
    var age: Int = 0
    var friends: [User] = []

    // MJExtension 风格的映射
    static func ls_replacedKeyFromPropertyName() -> [String: String] {
        return [
            "userId": "user_id",
            "userName": "user_name"
        ]
    }

    static func ls_objectClassInArray() -> [String: AnyClass] {
        return ["friends": User.self]
    }

    // CodingKeys (支持 Codable)
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case age
        case friends
    }
}

// 使用 - 完全一致的方法名
let dict = ["user_id": "123", "user_name": "张三", "age": 25] as [String: Any]
let user = User.ls_objectWithKeyValues(dict)
print(user.ls_keyValues ?? "")
```

---

## 注意事项

### 1. struct vs class

```swift
// struct (推荐，但不支持 ls_setKeyValues)
struct User: Codable {
    var id: String
    var name: String
}

// class (支持 ls_setKeyValues，类似 MJExtension)
class User: NSObject, Codable {
    var id: String = ""
    var name: String = ""
}
```

### 2. 可选属性

```swift
class User: NSObject, Codable {
    var id: String = ""
    var name: String?  // 可选属性
    var age: Int = 0
}

// 使用 ls_keyValues 时，可选值为 nil 的属性会自动处理
```

### 3. 嵌套对象

```swift
class Order: NSObject, Codable {
    var orderId: String = ""
    var user: User?  // 嵌套对象
}

// LSJSONModel 会自动处理嵌套对象的转换
```

---

## 总结

LSJSONModel 的 MJExtension 风格 API：

✅ **方法名完全一致** - 仅添加 `ls_` 前缀
✅ **无感迁移** - 可以直接替换 MJExtension
✅ **类型安全** - Swift 编译时检查
✅ **功能完整** - 支持所有 MJExtension 常用功能

---

**版本**: v1.0
**最后更新**: 2026-01-26
**开发者**: link-start
