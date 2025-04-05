// Register8.swift
// PC88iOS
//

import Foundation

/// 8ビットレジスタを表す列挙型
enum Register8 {
    case a
    case b
    case c
    case d
    case e
    case h
    case l
    case f
    
    /// レジスタコードから8ビットレジスタを生成
    static func fromCode(_ code: UInt8) -> Register8 {
        switch code & 0x07 {
        case 0: return .b
        case 1: return .c
        case 2: return .d
        case 3: return .e
        case 4: return .h
        case 5: return .l
        case 6: return .f  // 実際はメモリ参照の場合もある
        case 7: return .a
        default: return .a // ここには到達しない
        }
    }
}
