//
//  DataTypes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// 8ビット値（バイト）
typealias Byte = UInt8

/// 16ビット値（ワード）
typealias Word = UInt16

/// メモリアドレス
typealias Address = UInt16

/// I/Oポート
typealias Port = UInt16

/// 割り込みベクタ
typealias InterruptVector = UInt8

/// CPUレジスタ
enum CPURegister: String, CaseIterable {
    // 8ビットレジスタ
    case regA, regB, regC, regD, regE, regH, regL
    case regF  // フラグレジスタ
    
    // 16ビットレジスタペア
    case regAF, regBC, regDE, regHL
    case regIX, regIY  // インデックスレジスタ
    case regSP      // スタックポインタ
    case regPC      // プログラムカウンタ
}

/// CPUフラグ
struct CPUFlags: OptionSet {
    let rawValue: UInt8
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    // Z80のフラグ定義
    static let carry = CPUFlags(rawValue: 1 << 0)       // C: キャリーフラグ
    static let negative = CPUFlags(rawValue: 1 << 1)    // N: 減算フラグ
    static let parity = CPUFlags(rawValue: 1 << 2)      // P/V: パリティ/オーバーフローフラグ
    static let halfCarry = CPUFlags(rawValue: 1 << 4)   // H: ハーフキャリーフラグ
    static let zero = CPUFlags(rawValue: 1 << 6)        // Z: ゼロフラグ
    static let sign = CPUFlags(rawValue: 1 << 7)        // S: 符号フラグ
}
