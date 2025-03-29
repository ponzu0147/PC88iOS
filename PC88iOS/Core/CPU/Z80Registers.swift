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
    var a: UInt8 = 0
    var f: UInt8 = 0
    var b: UInt8 = 0
    var c: UInt8 = 0
    var d: UInt8 = 0
    var e: UInt8 = 0
    var h: UInt8 = 0
    var l: UInt8 = 0
    
    // 代替レジスタ
    var a_alt: UInt8 = 0
    var f_alt: UInt8 = 0
    var b_alt: UInt8 = 0
    var c_alt: UInt8 = 0
    var d_alt: UInt8 = 0
    var e_alt: UInt8 = 0
    var h_alt: UInt8 = 0
    var l_alt: UInt8 = 0
    
    // 特殊レジスタ
    var ix: UInt16 = 0
    var iy: UInt16 = 0
    var sp: UInt16 = 0
    var pc: UInt16 = 0
    
    // 割り込み関連レジスタ
    var i: UInt8 = 0
    var r: UInt8 = 0
    
    /// レジスタペア AF の取得・設定
    var af: UInt16 {
        get { return UInt16(a) << 8 | UInt16(f) }
        set {
            a = UInt8(newValue >> 8)
            f = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア BC の取得・設定
    var bc: UInt16 {
        get { return UInt16(b) << 8 | UInt16(c) }
        set {
            b = UInt8(newValue >> 8)
            c = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア DE の取得・設定
    var de: UInt16 {
        get { return UInt16(d) << 8 | UInt16(e) }
        set {
            d = UInt8(newValue >> 8)
            e = UInt8(newValue & 0xFF)
        }
    }
    
    /// レジスタペア HL の取得・設定
    var hl: UInt16 {
        get { return UInt16(h) << 8 | UInt16(l) }
        set {
            h = UInt8(newValue >> 8)
            l = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア AF' の取得・設定
    var af_alt_pair: UInt16 {
        get { return UInt16(a_alt) << 8 | UInt16(f_alt) }
        set {
            a_alt = UInt8(newValue >> 8)
            f_alt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア BC' の取得・設定
    var bc_alt_pair: UInt16 {
        get { return UInt16(b_alt) << 8 | UInt16(c_alt) }
        set {
            b_alt = UInt8(newValue >> 8)
            c_alt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア DE' の取得・設定
    var de_alt_pair: UInt16 {
        get { return UInt16(d_alt) << 8 | UInt16(e_alt) }
        set {
            d_alt = UInt8(newValue >> 8)
            e_alt = UInt8(newValue & 0xFF)
        }
    }
    
    /// 代替レジスタペア HL' の取得・設定
    var hl_alt_pair: UInt16 {
        get { return UInt16(h_alt) << 8 | UInt16(l_alt) }
        set {
            h_alt = UInt8(newValue >> 8)
            l_alt = UInt8(newValue & 0xFF)
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
            f |= flag
        } else {
            f &= ~flag
        }
    }
    
    /// フラグの取得
    func getFlag(_ flag: UInt8) -> Bool {
        return (f & flag) != 0
    }
    
    /// レジスタの交換（EXX命令用）
    mutating func exchangeRegisters() {
        swap(&b, &b_alt)
        swap(&c, &c_alt)
        swap(&d, &d_alt)
        swap(&e, &e_alt)
        swap(&h, &h_alt)
        swap(&l, &l_alt)
    }
    
    /// AF と AF' の交換（EX AF,AF'命令用）
    mutating func exchangeAF() {
        swap(&a, &a_alt)
        swap(&f, &f_alt)
    }
    
    /// レジスタのリセット
    mutating func reset() {
        a = 0
        f = 0
        b = 0
        c = 0
        d = 0
        e = 0
        h = 0
        l = 0
        
        a_alt = 0
        f_alt = 0
        b_alt = 0
        c_alt = 0
        d_alt = 0
        e_alt = 0
        h_alt = 0
        l_alt = 0
        
        ix = 0
        iy = 0
        sp = 0xFFFF  // スタックポインタの初期値
        pc = 0       // プログラムカウンタの初期値
        
        i = 0
        r = 0
    }
}
