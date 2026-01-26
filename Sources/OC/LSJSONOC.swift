//
//  LSJSONOC.swift
//  LSJSONModel/Sources/OC
//
//  Created by link-start on 2026-01-23.
//  Copyright © 2026 link-start. All rights reserved.
//

import Foundation

// MARK: - LSJSONModelOC Protocol

/// OC 兼容协议
/// 注意：使用此协议的类型需要继承 NSObject 并实现 NSCoding
@objc public protocol LSJSONModelOC: NSObjectProtocol {

    /// 从 JSON 字符串解码
    @objc static func ls_decode(_ json: String) -> Self?

    /// 从 JSON 数据解码
    @objc static func ls_decodeFromData(_ data: Data) -> Self?

    /// 从字典解码
    @objc static func ls_decodeFromDictionary(_ dict: [String: Any]) -> Self?

    /// 编码为 JSON 字符串
    @objc func ls_encode() -> String?

    /// 编码为 JSON 数据
    @objc func ls_encodeToData() -> Data?

    /// 编码为字典
    @objc func ls_toDictionary() -> [String: Any]?
}

// MARK: - OC Compatible Extensions

// Decodable 和 Encodable 的扩展已在 LSJSONDecoder.swift 和 LSJSONEncoder.swift 中实现
// 此文件仅保留 OC 协议定义
