//
//  AlphaMiniDosLoader.swift
//  PC88iOS
//
//  Created on 2025/04/05.
//

import Foundation

// 既存のMemoryAccessingプロトコルを使用するため、ここでの再定義は削除
// 既存のCpuControllingプロトコルも使用するため、ここでの再定義も削除

// Swiftではファイルを直接インポートするのではなく、モジュールをインポートします
// この場合、プロトコルは同じモジュール内にあるので、明示的なインポートは必要ありません

/// ALPHA-MINI-DOSディスクイメージを専用に読み込むためのクラス
class AlphaMiniDosLoader {
    // MARK: - 定数
    
    /// IPLの開始アドレス
    private let iplStartAddress: UInt16 = 0xC000
    
    /// OSの開始アドレス
    private let osStartAddress: UInt16 = 0xD000
    
    /// IPLのサイズ（バイト）
    private let iplSize: Int = 256
    
    /// OSの最大サイズ（バイト）
    private let osMaxSize: Int = 0x3000 // 12KB
    
    // MARK: - プロパティ
    
    /// メモリアクセス
    private let memory: MemoryAccessing
    
    /// CPU制御
    private let cpu: CpuControlling?
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameters:
    ///   - memory: メモリアクセス
    ///   - cpu: CPU制御（オプション）
    init(memory: MemoryAccessing, cpu: CpuControlling? = nil) {
        self.memory = memory
        self.cpu = cpu
    }
    
    // MARK: - 公開メソッド
    
    /// ディスクイメージからIPLとOSを抽出してロードする
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: 成功したかどうか
    func loadAlphaMiniDos(from diskImage: D88DiskImage) -> Bool {
        print("ALPHA-MINI-DOSローダー: ディスクイメージからIPLとOSを抽出します")
        
        // IPLをロード
        guard let iplData = extractIpl(from: diskImage) else {
            print("ALPHA-MINI-DOSローダー: IPLの抽出に失敗しました")
            return false
        }
        
        // OSをロード
        guard let osSectors = diskImage.loadOsSectors() else {
            print("ALPHA-MINI-DOSローダー: OSセクタの抽出に失敗しました")
            return false
        }
        
        // メモリにロード
        loadIplToMemory(iplData)
        loadOsToMemory(osSectors)
        
        // 実行開始アドレスを設定
        setCpuStartAddress(iplStartAddress)
        
        return true
    }
    
    // MARK: - プライベートメソッド
    
    /// ディスクイメージからIPLを抽出する
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: IPLデータ（256バイト）
    private func extractIpl(from diskImage: D88DiskImage) -> [UInt8]? {
        // トラック0、セクタ1からIPLを読み込む
        guard let iplData = diskImage.readSector(track: 0, sector: 1) else {
            print("ALPHA-MINI-DOSローダー: トラック0、セクタ1の読み込みに失敗しました")
            return nil
        }
        
        // IPLデータの検証
        if iplData.count < iplSize {
            print("ALPHA-MINI-DOSローダー: IPLデータのサイズが不足しています: \(iplData.count)バイト")
            return nil
        }
        
        // 最初の256バイトを返す
        return Array(iplData.prefix(iplSize))
    }
    
    /// IPLをメモリにロードする
    /// - Parameter iplData: IPLデータ
    private func loadIplToMemory(_ iplData: [UInt8]) {
        print("ALPHA-MINI-DOSローダー: IPLをメモリにロードします: 0x\(String(format: "%04X", iplStartAddress))")
        
        // IPLをメモリにロード
        for (offset, byte) in iplData.enumerated() {
            let address = iplStartAddress + UInt16(offset)
            memory.writeByte(byte, at: address)
        }
        
        // 最初の16バイトをログに出力
        logMemoryContents(startAddress: iplStartAddress, length: 16, label: "IPL")
    }
    
    /// OSセクタをメモリにロードする
    /// - Parameter osSectors: OSセクタのデータ
    private func loadOsToMemory(_ osSectors: [[UInt8]]) {
        print("ALPHA-MINI-DOSローダー: OSをメモリにロードします: 0x\(String(format: "%04X", osStartAddress))")
        
        // OS領域をクリア
        clearOsMemoryRegion()
        
        // OSセクタをメモリにロード
        var memoryOffset = osStartAddress
        var totalBytesLoaded = 0
        
        for (index, sectorData) in osSectors.enumerated() {
            // セクタデータのチェック
            let validData = sectorData.contains { $0 != 0 && $0 != 0xFF }
            
            // 各セクタを連続したメモリ領域にロード
            for (offset, byte) in sectorData.enumerated() {
                let address = memoryOffset + UInt16(offset)
                // UInt16の範囲を超えないように注意
                if address <= 0xFFFF {
                    memory.writeByte(byte, at: address)
                }
            }
            
            totalBytesLoaded += sectorData.count
            
            // 次のセクタ用にオフセットを更新
            let previousOffset = memoryOffset
            memoryOffset += UInt16(sectorData.count)
            
            // 最初の数セクタのみログ表示
            if index < 3 {
                print("  OSセクタ\(index+1)をメモリにロードしました: 0x\(String(format: "%04X", previousOffset))-0x\(String(format: "%04X", memoryOffset - 1)) (有効データ: \(validData ? "あり" : "なし"))")
            }
        }
        
        print("ALPHA-MINI-DOSローダー: OS部分のロードが完了しました: 0x\(String(format: "%04X", osStartAddress))-0x\(String(format: "%04X", memoryOffset - 1)) (合計: \(totalBytesLoaded) バイト)")
        
        // 最初の16バイトをログに出力
        logMemoryContents(startAddress: osStartAddress, length: 16, label: "OS")
    }
    
    /// OS領域のメモリをクリアする
    private func clearOsMemoryRegion() {
        print("ALPHA-MINI-DOSローダー: OS領域をクリアします: 0x\(String(format: "%04X", osStartAddress))-0xFFFF")
        
        // UInt16の範囲を超えないように注意
        for i in 0..<min(osMaxSize, 0x3000) {
            // 0xD000から0xFFFFまでの範囲のみクリア
            if osStartAddress + UInt16(i) <= 0xFFFF {
                let address = osStartAddress + UInt16(i)
                memory.writeByte(0x00, at: address)
            } else {
                break // UInt16の範囲を超えた場合は終了
            }
        }
    }
    
    /// CPUの実行開始アドレスを設定する
    /// - Parameter address: 開始アドレス
    private func setCpuStartAddress(_ address: UInt16) {
        guard let cpu = cpu else { return }
        
        print("ALPHA-MINI-DOSローダー: CPUの実行開始アドレスを設定します: 0x\(String(format: "%04X", address))")
        cpu.setProgramCounter(address: Int(address))
    }
    
    /// メモリ内容をログに出力する
    /// - Parameters:
    ///   - startAddress: 開始アドレス
    ///   - length: 表示するバイト数
    ///   - label: ラベル
    private func logMemoryContents(startAddress: UInt16, length: Int, label: String) {
        print("ALPHA-MINI-DOSローダー: \(label)メモリ内容確認 (0x\(String(format: "%04X", startAddress))-0x\(String(format: "%04X", startAddress + UInt16(length) - 1))):")
        
        for i in 0..<length {
            let byte = memory.readByte(at: startAddress + UInt16(i))
            print(String(format: "%02X ", byte), terminator: "")
        }
        print("")
    }
}
