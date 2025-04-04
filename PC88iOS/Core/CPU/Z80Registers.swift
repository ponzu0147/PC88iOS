//
//  Z80Registers.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// Z80 CPUのレジスタセット
struct Z80Registers {
    // メインレジスタ
    var regA: UInt8 = 0
    var regF: UInt8 = 0
    var regB: UInt8 = 0
    var regC: UInt8 = 0
    var regD: UInt8 = 0
    var regE: UInt8 = 0
    var regH: UInt8 = 0
    var regL: UInt8 = 0
    
    // 代替レジスタ
    var regAAlt: UInt8 = 0
    var regFAlt: UInt8 = 0
    var regBAlt: UInt8 = 0
    var regCAlt: UInt8 = 0
    var regDAlt: UInt8 = 0
    var regEAlt: UInt8 = 0
    var regHAlt: UInt8 = 0
    var regLAlt: UInt8 = 0
    
    // 特殊レジスタ
    var regIX: UInt16 = 0
    var regIY: UInt16 = 0
    var regSP: UInt16 = 0
    var regPC: UInt16 = 0
    
    // 割り込み関連レジスタ
    var regI: UInt8 = 0
    var regR: UInt8 = 0
    
    /// レジスタペア AF の取得・設定
    var regAF: UInt16 {
        get { return UInt16(regA) << 8 | UInt16(regF) }
        set {
            regA = UInt8(newValue >> 8)
            regF = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア BC の取得・設定
    var regBC: UInt16 {
        get { return UInt16(regB) << 8 | UInt16(regC) }
        set {
            regB = UInt8(newValue >> 8)
            regC = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア DE の取得・設定
    var regDE: UInt16 {
        get { return UInt16(regD) << 8 | UInt16(regE) }
        set {
            regD = UInt8(newValue >> 8)
            regE = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア HL の取得・設定
    var regHL: UInt16 {
        get { return UInt16(regH) << 8 | UInt16(regL) }
        set {
            regH = UInt8(newValue >> 8)
            regL = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア AF' の取得・設定
    var regAFAlt: UInt16 {
        get { return UInt16(regAAlt) << 8 | UInt16(regFAlt) }
        set {
            regAAlt = UInt8(newValue >> 8)
            regFAlt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア BC' の取得・設定
    var regBCAlt: UInt16 {
        get { return UInt16(regBAlt) << 8 | UInt16(regCAlt) }
        set {
            regBAlt = UInt8(newValue >> 8)
            regCAlt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア DE' の取得・設定
    var regDEAlt: UInt16 {
        get { return UInt16(regDAlt) << 8 | UInt16(regEAlt) }
        set {
            regDAlt = UInt8(newValue >> 8)
            regEAlt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア HL' の取得・設定
    var regHLAlt: UInt16 {
        get { return UInt16(regHAlt) << 8 | UInt16(regLAlt) }
        set {
            regHAlt = UInt8(newValue >> 8)
            regLAlt = UInt8(newValue & 0xFF)
        }
    }
    
    // フラグ定義
    struct Flags {
        static let sign: UInt8 = 0x80      // S: 符号フラグ
        static let zero: UInt8 = 0x40      // Z: ゼロフラグ
        static let halfCarry: UInt8 = 0x10 // H: ハーフキャリーフラグ
        static let parity: UInt8 = 0x04    // P/V: パリティ/オーバーフローフラグ
        static let subtract: UInt8 = 0x02  // N: 減算フラグ
        static let carry: UInt8 = 0x01     // C: キャリーフラグ
    }
    
    /// フラグの設定
    mutating func setFlag(_ flag: UInt8, value: Bool) {
        if value {
            regF |= flag
        } else {
            regF &= ~flag
        }
    }
    
    /// フラグの取得
    func getFlag(_ flag: UInt8) -> Bool {
        return (regF & flag) != 0
    }
    
    /// レジスタの交換（EXX命令用）
    mutating func exchangeRegisters() {
        swap(&regB, &regBAlt)
        swap(&regC, &regCAlt)
        swap(&regD, &regDAlt)
        swap(&regE, &regEAlt)
        swap(&regH, &regHAlt)
        swap(&regL, &regLAlt)
    }
    
    /// AF と AF' の交換（EX AF,AF'命令用）
    mutating func exchangeAF() {
        swap(&regA, &regAAlt)
        swap(&regF, &regFAlt)
    }
    
    /// レジスタのリセット
    mutating func reset() {
        regA = 0
        regF = 0
        regB = 0
        regC = 0
        regD = 0
        regE = 0
        regH = 0
        regL = 0
        
        regAAlt = 0
        regFAlt = 0
        regBAlt = 0
        regCAlt = 0
        regDAlt = 0
        regEAlt = 0
        regHAlt = 0
        regLAlt = 0
        
        regIX = 0
        regIY = 0
        regSP = 0xFFFF  // スタックポインタの初期値
        regPC = 0       // プログラムカウンタの初期値
        
        regI = 0
        regR = 0
    }
}
