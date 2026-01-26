#
#  Be sure to run `pod spec lint LSJSONModel.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = 'LSJSONModel'
  s.version          = '1.0.0'
  s.summary          = '基于 Codable 优点的 JSON 转 Model 库，支持 Swift 6 和 Objective-C'
  s.description      = <<-DESC
LSJSONModel 是一个基于 Codable 优点的 JSON 转 Model 库，支持 Swift 6 和 Objective-C。

主要特性：
- 全局变量名映射 - 一处设置，全局生效
- 跨 Model 转换 - 不同 Model 类型之间无缝转换
- 归档解档 - 类似 MJExtension 的归档/解档功能
- 映射优先级 - 类型映射 > 全局映射 > Snake Case
- 高性能缓存 - 映射查询缓存，确保高效
- Objective-C 兼容 - 支持 @objc 协议
- MJExtension 风格 API - 提供熟悉的 API 命名
- Property Wrapper - @LSDefault, @LSDateCoding 等便捷包装器
                   DESC

  s.homepage         = 'https://github.com/Link-Start/LSJSONModel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'link-start' => 'link-start@example.com' }
  s.source           = { :git => 'https://github.com/Link-Start/LSJSONModel.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.9'

  s.source_files = 'Sources/**/*.swift'
  
  # Exclude documentation and test files
  s.exclude_files = 'Sources/Docs/**/*', 'Sources/Tests/**/*'
  
  # If you need to specify any resources, add them here
  # s.resource_bundles = {
  #   'LSJSONModel' => ['Sources/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end