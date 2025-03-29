//
//  PC88Memory.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// PC-88のメモリ実装
class PC88Memory: MemoryAccessing {
    // MARK: - 定数
    
    /// メモリサイズ (64KB)
    private let memorySize = 0x10000
    
    /// ROM領域のサイズ (32KB)
    private let romSize = 0x8000
    
    /// テキストVRAMのベースアドレス
    private let textVRAMBase = 0xF000
    
    /// テキストVRAMのサイズ
    private let textVRAMSize = 0x1000
    
    /// グラフィックVRAMのベースアドレス
    private let graphicVRAMBase = 0xC000
    
    /// グラフィックVRAMのサイズ
    private let graphicVRAMSize = 0x4000
    
    // MARK: - プロパティ
    
    /// メインメモリ
    private var mainMemory = [UInt8](repeating: 0, count: 0x10000)
    
    /// ROM領域
    private var romEnabled = true
    
    /// ROM領域のデータ
    private var romData = [UInt8](repeating: 0, count: 0x8000)
    
    /// テキストVRAM
    private var textVRAM = [UInt8](repeating: 0, count: 0x1000)
    
    /// グラフィックVRAM (3プレーン)
    private var graphicVRAM = Array(repeating: [UInt8](repeating: 0, count: 0x4000), count: 3)
    
    /// 現在のグラフィックVRAMプレーン選択
    private var currentGraphicPlane = 0
    
    /// 拡張RAM
    private var extendedRAM = [UInt8](repeating: 0, count: 0x10000)
    
    /// 拡張RAMバンク
    private var extendedRAMBank = 0
    
    /// 拡張RAM有効フラグ
    private var extendedRAMEnabled = false
    
    // MARK: - 初期化
    
    init() {
        loadROM()
        reset()
    }
    
    // MARK: - MemoryAccessing プロトコル実装
    
    func readByte(at address: UInt16) -> UInt8 {
        let addr = Int(address)
        
        // ROM領域 (0x0000-0x7FFF)
        if addr < romSize && romEnabled {
            return romData[addr]
        }
        
        // テキストVRAM領域 (0xF000-0xFFFF)
        if addr >= textVRAMBase && addr < textVRAMBase + textVRAMSize {
            let vramOffset = addr - textVRAMBase
            return textVRAM[vramOffset]
        }
        
        // グラフィックVRAM領域 (0xC000-0xFFFF)
        if addr >= graphicVRAMBase && addr < graphicVRAMBase + graphicVRAMSize {
            let vramOffset = addr - graphicVRAMBase
            return graphicVRAM[currentGraphicPlane][vramOffset]
        }
        
        // 拡張RAM
        if extendedRAMEnabled && addr >= 0x8000 && addr < 0xC000 {
            let ramOffset = extendedRAMBank * 0x4000 + (addr - 0x8000)
            if ramOffset < extendedRAM.count {
                return extendedRAM[ramOffset]
            }
        }
        
        // 通常のメインメモリ
        return mainMemory[addr]
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        let low = readByte(at: address)
        let high = readByte(at: address &+ 1)
        return UInt16(high) << 8 | UInt16(low)
    }
    
    func writeByte(_ value: UInt8, at address: UInt16) {
        let addr = Int(address)
        
        // ROM領域には書き込めない
        if addr < romSize && romEnabled {
            return
        }
        
        // テキストVRAM領域
        if addr >= textVRAMBase && addr < textVRAMBase + textVRAMSize {
            let vramOffset = addr - textVRAMBase
            textVRAM[vramOffset] = value
            return
        }
        
        // グラフィックVRAM領域
        if addr >= graphicVRAMBase && addr < graphicVRAMBase + graphicVRAMSize {
            let vramOffset = addr - graphicVRAMBase
            graphicVRAM[currentGraphicPlane][vramOffset] = value
            return
        }
        
        // 拡張RAM
        if extendedRAMEnabled && addr >= 0x8000 && addr < 0xC000 {
            let ramOffset = extendedRAMBank * 0x4000 + (addr - 0x8000)
            if ramOffset < extendedRAM.count {
                extendedRAM[ramOffset] = value
                return
            }
        }
        
        // 通常のメインメモリ
        mainMemory[addr] = value
    }
    
    func writeWord(_ value: UInt16, at address: UInt16) {
        writeByte(UInt8(value & 0xFF), at: address)
        writeByte(UInt8(value >> 8), at: address &+ 1)
    }
    
    func switchBank(_ bank: Int, for area: MemoryArea) {
        switch area {
        case .mainROM:
            // ROM切り替えは未実装
            break
            
        case .textRAM:
            // テキストRAM切り替えは未実装
            break
            
        case .graphicsRAM:
            // グラフィックRAMプレーン切り替え
            if bank >= 0 && bank < 3 {
                currentGraphicPlane = bank
            }
            
        case .extendedRAM:
            // 拡張RAMバンク切り替え
            if bank >= 0 && bank < 4 {
                extendedRAMBank = bank
            }
        }
    }
    
    func setROMEnabled(_ enabled: Bool, for area: MemoryArea) {
        switch area {
        case .mainROM:
            romEnabled = enabled
            
        case .extendedRAM:
            extendedRAMEnabled = enabled
            
        default:
            // その他の領域は未実装
            break
        }
    }
    
    // MARK: - 追加メソッド
    
    /// メモリをリセット
    func reset() {
        // メインメモリをクリア
        mainMemory = [UInt8](repeating: 0, count: memorySize)
        
        // テキストVRAMをクリア
        textVRAM = [UInt8](repeating: 0, count: textVRAMSize)
        
        // グラフィックVRAMをクリア
        for i in 0..<3 {
            graphicVRAM[i] = [UInt8](repeating: 0, count: graphicVRAMSize)
        }
        
        // 拡張RAMをクリア
        extendedRAM = [UInt8](repeating: 0, count: 0x10000)
        
        // 状態をリセット
        romEnabled = true
        currentGraphicPlane = 0
        extendedRAMBank = 0
        extendedRAMEnabled = false
        
        // ROMデータをメインメモリにコピー
        for i in 0..<romSize {
            mainMemory[i] = romData[i]
        }
    }
    
    /// テキストVRAMの内容を取得
    func getTextVRAM() -> [UInt8] {
        return textVRAM
    }
    
    /// グラフィックVRAMの内容を取得
    func getGraphicVRAM(plane: Int) -> [UInt8]? {
        guard plane >= 0 && plane < 3 else { return nil }
        return graphicVRAM[plane]
    }
    
    // MARK: - プライベートメソッド
    
    /// ROMデータをロード
    private func loadROM() {
        // 実際の実装では、リソースからROMデータをロードする
        // ここでは仮のROMデータを生成
        
        // ROMデータの初期化
        romData = [UInt8](repeating: 0, count: romSize)
        
        // IPLのエントリポイント（仮）
        romData[0x0000] = 0x31  // LD SP, nnnn
        romData[0x0001] = 0x00
        romData[0x0002] = 0xF0
        romData[0x0003] = 0xC3  // JP nnnn
        romData[0x0004] = 0x10
        romData[0x0005] = 0x00
        
        // IPLの初期化ルーチン（仮）
        romData[0x0010] = 0x3E  // LD A, n
        romData[0x0011] = 0x01
        romData[0x0012] = 0xD3  // OUT (n), A
        romData[0x0013] = 0x30
        romData[0x0014] = 0xC3  // JP nnnn
        romData[0x0015] = 0x00
        romData[0x0016] = 0xF0
    }
}
