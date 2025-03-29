//
//  SectorID.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// セクタIDを表す構造体
struct SectorID: Equatable, Hashable {
    /// セクタ番号 (C)
    let cylinder: UInt8
    
    /// ヘッド番号 (H)
    let head: UInt8
    
    /// レコード番号 (R)
    let record: UInt8
    
    /// セクタサイズ (N)
    let size: UInt8
    
    /// セクタサイズをバイト数で取得
    var sizeInBytes: Int {
        return 128 << Int(size)
    }
    
    /// 初期化
    init(cylinder: UInt8, head: UInt8, record: UInt8, size: UInt8) {
        self.cylinder = cylinder
        self.head = head
        self.record = record
        self.size = size
    }
    
    /// 文字列表現
    var description: String {
        return "C:\(cylinder) H:\(head) R:\(record) N:\(size) (\(sizeInBytes)bytes)"
    }
}
