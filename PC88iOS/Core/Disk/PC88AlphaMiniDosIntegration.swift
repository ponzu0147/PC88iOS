//
//  PC88AlphaMiniDosIntegration.swift
//  PC88iOS
//
//  Created on 2025/04/05.
//

import Foundation

// 必要なファイルをインポート
// Swiftは同じモジュール内のファイルは自動的にインポートされるため、明示的なインポートは不要
// ここではプロトコルやクラスの再定義を避ける

/// PC88EmulatorCoreにAlphaMiniDosLoaderを統合するための拡張
class PC88AlphaMiniDosIntegration {
    // MARK: - プロパティ
    
    /// PC88メモリアダプタ
    private let memoryAdapter: PC88MemoryAdapter
    
    /// Z80CPUアダプタ
    private let cpuAdapter: Z80CPUAdapter
    
    /// AlphaMiniDosLoader
    private let alphaMiniDosLoader: AlphaMiniDosLoader
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameters:
    ///   - memory: PC88Memory
    ///   - cpu: Z80CPU
    init(memory: PC88Memory, cpu: Z80CPU) {
        // アダプタを作成
        self.memoryAdapter = PC88MemoryAdapter(memory: memory)
        self.cpuAdapter = Z80CPUAdapter(cpu: cpu)
        
        // AlphaMiniDosLoaderを作成
        self.alphaMiniDosLoader = AlphaMiniDosLoader(
            memory: memoryAdapter,
            cpu: cpuAdapter
        )
    }
    
    // MARK: - 公開メソッド
    
    /// ALPHA-MINI-DOSをロードする
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: 成功したかどうか
    func loadAlphaMiniDos(from diskImage: D88DiskImage) -> Bool {
        return alphaMiniDosLoader.loadAlphaMiniDos(from: diskImage)
    }
}

/// PC88MemoryをMemoryAccessingプロトコルに適合させるアダプタ
class PC88MemoryAdapter: MemoryAccessing {
    // MARK: - プロパティ
    
    /// PC88Memory
    private let memory: PC88Memory
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameter memory: PC88Memory
    init(memory: PC88Memory) {
        self.memory = memory
    }
    
    // MARK: - MemoryAccessingプロトコル実装
    
    /// メモリに1バイト書き込む
    /// - Parameters:
    ///   - value: 値
    ///   - address: アドレス
    func writeByte(_ value: UInt8, at address: UInt16) {
        memory.writeByte(value, at: address)
    }
    
    /// メモリから1バイト読み込む
    /// - Parameter address: アドレス
    /// - Returns: 値
    func readByte(at address: UInt16) -> UInt8 {
        return memory.readByte(at: address)
    }
    
    /// メモリから2バイト読み込む
    /// - Parameter address: アドレス
    /// - Returns: 値
    func readWord(at address: UInt16) -> UInt16 {
        return memory.readWord(at: address)
    }
    
    /// メモリに2バイト書き込む
    /// - Parameters:
    ///   - value: 値
    ///   - address: アドレス
    func writeWord(_ value: UInt16, at address: UInt16) {
        memory.writeWord(value, at: address)
    }
    
    /// メモリバンクを切り替え
    /// - Parameters:
    ///   - bank: バンク番号
    ///   - area: メモリ領域
    func switchBank(_ bank: Int, for area: MemoryArea) {
        memory.switchBank(bank, for: area)
    }
    
    /// ROM/RAM切り替え
    /// - Parameters:
    ///   - enabled: ROM有効化フラグ
    ///   - area: メモリ領域
    func setROMEnabled(_ enabled: Bool, for area: MemoryArea) {
        memory.setROMEnabled(enabled, for: area)
    }
}

/// Z80CPUをCpuControllingプロトコルに適合させるアダプタ
class Z80CPUAdapter: CpuControlling {
    // MARK: - プロパティ
    
    /// Z80CPU
    private let cpu: Z80CPU
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameter cpu: Z80CPU
    init(cpu: Z80CPU) {
        self.cpu = cpu
    }
    
    // MARK: - CpuControllingプロトコル実装
    
    /// プログラムカウンタを設定する
    /// - Parameter address: 設定するアドレス
    func setProgramCounter(address: Int) {
        cpu.setProgramCounter(UInt16(address))
    }
    
    /// CPUの実行開始アドレスを設定
    /// - Parameter address: 開始アドレス
    func setStartAddress(_ address: UInt16) {
        cpu.setProgramCounter(address)
    }
    
    /// CPU実行を開始する
    func startExecution() {
        // Z80CPUにはstartメソッドがないので、必要な処理を実装
        // 割り込みを有効化
        cpu.setInterruptEnabled(true)
        // ホルト状態を解除
        if cpu.isHalted() {
            // ホルト状態の場合、割り込みを発生させて再開
            cpu.requestInterrupt(.nmi)
        }
    }
    
    /// CPU実行を停止する
    func stopExecution() {
        // Z80CPUにはstopメソッドがないので、必要な処理を実装
        // 割り込みを無効化
        cpu.setInterruptEnabled(false)
        // CPUをホルト状態にする
        cpu.halt()
    }
}
