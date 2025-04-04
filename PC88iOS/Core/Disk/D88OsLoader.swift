//
//  D88OsLoader.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// D88ディスクイメージからOSをロードして実行するためのヘルパークラス
class D88OsLoader {
    // MARK: - 定数
    
    /// OS部分のロード先アドレス（デフォルト値）
    private let defaultOsLoadAddress = 0x0100
    
    /// OS実行開始アドレス（デフォルト値）
    private let defaultOsExecAddress = 0x0100
    
    // MARK: - プロパティ
    
    /// D88ディスクイメージ
    private var diskImage: D88DiskImage
    
    /// メモリへのアクセサ（実際のエミュレータ実装では、Z80のメモリ空間にアクセスするためのオブジェクト）
    private var memoryAccessor: MemoryAccessing?
    
    /// CPU制御（実際のエミュレータ実装では、Z80 CPUを制御するためのオブジェクト）
    private var cpuController: CpuControlling?
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameter diskImage: D88ディスクイメージ
    init(diskImage: D88DiskImage) {
        self.diskImage = diskImage
    }
    
    /// メモリアクセサを設定
    /// - Parameter memoryAccessor: メモリアクセサ
    func setMemoryAccessor(_ memoryAccessor: MemoryAccessing) {
        self.memoryAccessor = memoryAccessor
    }
    
    /// CPU制御を設定
    /// - Parameter cpuController: CPU制御
    func setCpuController(_ cpuController: CpuControlling) {
        self.cpuController = cpuController
    }
    
    // MARK: - 公開メソッド
    
    /// OSをロードして実行する
    /// - Parameters:
    ///   - loadAddress: OSのロード先アドレス（省略時はデフォルト値）
    ///   - execAddress: OS実行開始アドレス（省略時はデフォルト値）
    /// - Returns: 実行開始の成否
    func loadAndExecuteOs(loadAddress: Int? = nil, execAddress: Int? = nil) -> Bool {
        PC88Logger.disk.debug("D88OsLoader.loadAndExecuteOs: OSのロードと実行を開始します")
        
        // ロード先アドレスと実行開始アドレスの設定
        let osLoadAddress = loadAddress ?? defaultOsLoadAddress
        let osExecAddress = execAddress ?? defaultOsExecAddress
        
        // OSセクタの読み込み
        guard let osSectors = diskImage.loadOsSectors() else {
            PC88Logger.disk.error("  OSセクタの読み込みに失敗しました")
            return false
        }
        
        // OSデータをメモリにロード
        if let memoryAccessor = memoryAccessor {
            // 実際のメモリにロード
            var currentAddress = osLoadAddress
            
            for (index, sectorData) in osSectors.enumerated() {
                PC88Logger.disk.debug("  セクタ\(index + 1)をメモリアドレス0x\(String(format: "%04X", currentAddress))にロード (\(sectorData.count)バイト)")
                
                // メモリに書き込み
                for (offset, byte) in sectorData.enumerated() {
                    let address = currentAddress + offset
                    memoryAccessor.writeByte(byte, at: UInt16(address))
                }
                
                // 次のセクタのアドレスを計算
                currentAddress += sectorData.count
            }
            
            PC88Logger.disk.debug("  OSデータをメモリにロード完了 (合計\(currentAddress - osLoadAddress)バイト)")
        } else {
            // メモリアクセサが設定されていない場合は、サイズのみ計算
            let totalSize = osSectors.reduce(0) { $0 + $1.count }
            PC88Logger.disk.warning("  メモリアクセサが設定されていないため、実際のメモリへのロードはスキップします (合計\(totalSize)バイト)")
        }
        
        // OSの実行開始
        if let cpuController = cpuController {
            // 実際のCPUでの実行開始
            PC88Logger.disk.debug("  OSの実行を開始します (開始アドレス: 0x\(String(format: "%04X", osExecAddress)))")
            cpuController.setProgramCounter(address: osExecAddress)
            cpuController.startExecution()
            return true
        } else {
            // CPU制御が設定されていない場合は、仮想的な実行開始
            PC88Logger.disk.warning("  CPU制御が設定されていないため、実際の実行はスキップします (開始アドレス: 0x\(String(format: "%04X", osExecAddress)))")
            return diskImage.executeOs(startAddress: osExecAddress)
        }
    }
    
    /// OSのロード先アドレスと実行開始アドレスを設定したJSONファイルから読み込む
    /// - Parameter url: JSONファイルのURL
    /// - Returns: ロード成功の場合はtrue、失敗の場合はfalse
    func loadOsInfoFromJson(url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let osInfo = try decoder.decode(OsInfo.self, from: data)
            
            PC88Logger.disk.debug("D88OsLoader.loadOsInfoFromJson: OSの情報をJSONから読み込みました")
            PC88Logger.disk.debug("  IPLサイズ: \(osInfo.ipl.size)バイト, ロード先アドレス: 0x\(String(format: "%04X", osInfo.ipl.loadAddress))")
            PC88Logger.disk.debug("  OSセクタ数: \(osInfo.os.sectorCount), 合計サイズ: \(osInfo.os.totalSize)バイト")
            PC88Logger.disk.debug("  OSロード先アドレス: 0x\(String(format: "%04X", osInfo.os.loadAddress)), 実行開始アドレス: 0x\(String(format: "%04X", osInfo.os.execAddress))")
            
            // OSのロードと実行
            return loadAndExecuteOs(loadAddress: osInfo.os.loadAddress, execAddress: osInfo.os.execAddress)
        } catch {
            PC88Logger.disk.error("D88OsLoader.loadOsInfoFromJson: JSONの読み込みに失敗しました: \(error)")
            return false
        }
    }
}

// MARK: - プロトコル定義

/// CPU制御のためのプロトコル
protocol CpuControlling {
    /// プログラムカウンタを設定する
    /// - Parameter address: 設定するアドレス
    func setProgramCounter(address: Int)
    
    /// CPU実行を開始する
    func startExecution()
    
    /// CPU実行を停止する
    func stopExecution()
}

// MARK: - JSON用のデータモデル

/// OS情報のJSONモデル
struct OsInfo: Codable {
    let ipl: IplInfo
    let os: OsData
    
    struct IplInfo: Codable {
        let size: Int
        let loadAddress: Int
        let data: String  // 16進数文字列
    }
    
    struct OsData: Codable {
        let sectorCount: Int
        let totalSize: Int
        let loadAddress: Int
        let execAddress: Int
        let sectors: [String]  // 各セクタの16進数文字列
    }
}
