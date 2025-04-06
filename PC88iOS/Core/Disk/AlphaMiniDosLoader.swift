//
//  AlphaMiniDosLoader.swift
//  PC88iOS
//
//  Created on 2025/04/05.
//

import Foundation
import os.log

// 注：Swiftは同じモジュール内のファイルは自動的にインポートされるため、明示的なインポートは不要
// ここではプロトコルやクラスの再定義を避ける

// プロトコルや別の型はプロジェクト内の他のファイルで定義されているため、ここでは再定義しない

/// ALPHA-MINI-DOSディスクイメージを専用に読み込むためのクラス
/// 
/// このクラスはALPHA-MINI-DOS形式のディスクイメージからIPLとOSを抽出し、
/// メモリにロードして実行するための機能を提供します。
class AlphaMiniDosLoader {
    // MARK: - メモリアドレス定数
    
    /// IPLのロード先アドレス
    private let iplLoadAddress: UInt16 = 0x8000
    
    /// OSのロード先アドレス
    private let osLoadAddress: UInt16 = 0x0100
    
    /// OS実行開始アドレス
    private let osExecutionAddress: UInt16 = 0x0100
    
    // MARK: - サイズ定数
    
    /// IPLのサイズ（バイト）
    private let iplSize: Int = 256
    
    /// OSの最大サイズ（バイト）
    private let osMaxSize: Int = 0x3000 // 12KB
    
    // MARK: - プロパティ
    
    /// メモリアクセスインターフェース
    private let memory: MemoryAccessing
    
    /// CPU制御インターフェース（オプション）
    private let cpu: CpuControlling?
    
    /// ロギングが有効かどうか
    private let loggingEnabled: Bool
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameters:
    ///   - memory: メモリアクセスインターフェース
    ///   - cpu: CPU制御インターフェース（オプション）
    ///   - enableLogging: ロギングを有効にするかどうか（デフォルト：true）
    init(memory: MemoryAccessing, cpu: CpuControlling? = nil, enableLogging: Bool = true) {
        self.memory = memory
        self.cpu = cpu
        self.loggingEnabled = enableLogging
    }
    
    // MARK: - 公開メソッド
    
    /// ディスクイメージからIPLとOSを抽出してロードする
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: 成功したかどうか
    func loadAlphaMiniDos(from diskImage: D88DiskImage) -> Bool {
        log("ディスクイメージからIPLとOSを抽出します")
        
        // IPLをロード
        guard let iplData = extractIpl(from: diskImage) else {
            log("IPLの抽出に失敗しました", isError: true)
            return false
        }
        
        // OSをロード
        guard let osSectors = extractOs(from: diskImage) else {
            log("OSセクタの抽出に失敗しました", isError: true)
            return false
        }
        
        // メモリにロード
        loadIplToMemory(iplData)
        loadOsToMemory(osSectors)
        
        // 実行開始アドレスを設定
        setCpuStartAddress(osExecutionAddress)
        
        return true
    }
    
    // MARK: - プライベートメソッド
    
    /// ディスクイメージからIPLを抽出する
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: IPLデータ（256バイト）
    private func extractIpl(from diskImage: D88DiskImage) -> [UInt8]? {
        // トラック0、セクタ1からIPLを読み込む
        guard let iplData = diskImage.readSector(track: 0, sector: 1) else {
            log("トラック0、セクタ1の読み込みに失敗しました", isError: true)
            return nil
        }
        
        // IPLデータの検証
        if iplData.count < iplSize {
            log("IPLデータのサイズが不足しています: \(iplData.count)バイト", isError: true)
            return nil
        }
        
        log("IPLデータを抽出しました: \(iplData.count)バイト")
        
        // 最初の256バイトを返す
        return Array(iplData.prefix(iplSize))
    }
    
    /// ディスクイメージからOSを抽出する
    /// - Parameter diskImage: D88DiskImage
    /// - Returns: OSセクタデータの配列
    private func extractOs(from diskImage: D88DiskImage) -> [[UInt8]]? {
        // OSセクタを読み込む
        guard let osSectors = diskImage.loadOsSectors() else {
            log("OSセクタの読み込みに失敗しました", isError: true)
            return nil
        }
        
        // OSセクタの検証
        if osSectors.isEmpty {
            log("OSセクタが空です", isError: true)
            return nil
        }
        
        log("OSセクタを抽出しました: \(osSectors.count)セクタ")
        return osSectors
    }
    
    /// IPLをメモリにロードする
    /// - Parameter iplData: IPLデータ
    private func loadIplToMemory(_ iplData: [UInt8]) {
        log("IPLをメモリにロードします: 0x\(String(format: "%04X", iplLoadAddress))")
        
        // IPLをメモリにロード
        for (offset, byte) in iplData.enumerated() {
            let address = iplLoadAddress + UInt16(offset)
            memory.writeByte(byte, at: address)
        }
        
        // 最初の16バイトをログに出力
        logMemoryContents(startAddress: iplLoadAddress, length: 16, label: "IPL")
    }
    
    /// OSセクタをメモリにロードする
    /// - Parameter osSectors: OSセクタのデータ
    private func loadOsToMemory(_ osSectors: [[UInt8]]) {
        log("OSをメモリにロードします: 0x\(String(format: "%04X", osLoadAddress))")
        
        // OS領域をクリア
        clearOsMemoryRegion()
        
        // OSセクタをメモリにロード
        var memoryOffset = osLoadAddress
        var totalBytesLoaded = 0
        
        for (index, sectorData) in osSectors.enumerated() {
            // セクタデータのチェック - 有効なデータが含まれているか
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
                let rangeStr = "0x\(String(format: "%04X", previousOffset))-0x\(String(format: "%04X", memoryOffset - 1))"
                let dataStr = "(有効データ: \(validData ? "あり" : "なし"))"
                log("  OSセクタ\(index+1)をメモリにロードしました: \(rangeStr) \(dataStr)")
            }
        }
        
        let addressRange = "0x\(String(format: "%04X", osLoadAddress))-0x\(String(format: "%04X", memoryOffset - 1))"
        log("OS部分のロードが完了しました: \(addressRange) (合計: \(totalBytesLoaded) バイト)")
        
        // 最初の16バイトをログに出力
        logMemoryContents(startAddress: osLoadAddress, length: 16, label: "OS")
    }
    
    /// OS領域のメモリをクリアする
    private func clearOsMemoryRegion() {
        log("OS領域をクリアします: 0x\(String(format: "%04X", osLoadAddress))-0x\(String(format: "%04X", osLoadAddress + UInt16(osMaxSize) - 1))")
        
        // UInt16の範囲を超えないように注意
        for i in 0..<osMaxSize {
            // アドレス範囲チェック
            if osLoadAddress + UInt16(i) <= 0xFFFF {
                let address = osLoadAddress + UInt16(i)
                memory.writeByte(0x00, at: address)
            } else {
                log("  メモリアドレスが範囲外になったためクリアを中断します: 0x\(String(format: "%04X", osLoadAddress + UInt16(i)))")
                break // UInt16の範囲を超えた場合は終了
            }
        }
    }
    
    /// CPUの実行開始アドレスを設定する
    /// - Parameter address: 開始アドレス
    private func setCpuStartAddress(_ address: UInt16) {
        guard let cpu = cpu else { 
            log("CPU制御が設定されていないため、実行開始アドレスを設定できません", isError: true)
            return 
        }
        
        log("CPUの実行開始アドレスを設定します: 0x\(String(format: "%04X", address))")
        cpu.setProgramCounter(address: Int(address))
    }
    
    /// メモリ内容をログに出力する
    /// - Parameters:
    ///   - startAddress: 開始アドレス
    ///   - length: 表示するバイト数
    ///   - label: ラベル
    private func logMemoryContents(startAddress: UInt16, length: Int, label: String) {
        guard loggingEnabled else { return }
        
        let addrRange = "0x\(String(format: "%04X", startAddress))-0x\(String(format: "%04X", startAddress + UInt16(length) - 1))"
        var logMessage = "\(label)メモリ内容確認 (\(addrRange)): "
        
        for i in 0..<length {
            let byte = memory.readByte(at: startAddress + UInt16(i))
            logMessage += String(format: "%02X ", byte)
        }
        
        log(logMessage)
    }
    
    /// ログメッセージを出力する
    /// - Parameters:
    ///   - message: メッセージ
    ///   - isError: エラーメッセージかどうか
    private func log(_ message: String, isError: Bool = false) {
        guard loggingEnabled else { return }
        
        let prefix = isError ? "ALPHA-MINI-DOSローダー [エラー]: " : "ALPHA-MINI-DOSローダー: "
        // PC88Loggerを使用してロギング
        if isError {
            PC88Logger.disk.error("\(prefix)\(message)")
        } else {
            PC88Logger.disk.debug("\(prefix)\(message)")
        }
    }
}
