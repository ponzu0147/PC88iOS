//
//  MemoryAccessing.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// メモリアクセスを担当するプロトコル
protocol MemoryAccessing {
    /// メモリから1バイト読み込み
    func readByte(at address: UInt16) -> UInt8
    
    /// メモリから2バイト読み込み
    func readWord(at address: UInt16) -> UInt16
    
    /// メモリに1バイト書き込み
    func writeByte(_ value: UInt8, at address: UInt16)
    
    /// メモリに2バイト書き込み
    func writeWord(_ value: UInt16, at address: UInt16)
    
    /// メモリバンクを切り替え
    func switchBank(_ bank: Int, for area: MemoryArea)
    
    /// ROM/RAM切り替え
    func setROMEnabled(_ enabled: Bool, for area: MemoryArea)
}

/// メモリ領域
enum MemoryArea {
    case mainROM      // メインROM領域
    case textRAM      // テキストRAM
    case graphicsRAM  // グラフィックRAM
    case extendedRAM  // 拡張RAM
}
