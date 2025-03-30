//
//  FDCEmulating.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// フロッピーディスクコントローラエミュレーションを担当するプロトコル
protocol FDCEmulating {
    /// FDCの初期化
    func initialize()
    
    /// コマンド送信
    func sendCommand(_ command: UInt8)
    
    /// データ送信
    func sendData(_ data: UInt8)
    
    /// ステータスレジスタ読み取り
    func readStatus() -> UInt8
    
    /// データレジスタ読み取り
    func readData() -> UInt8
    
    /// ディスクイメージをセット
    func setDiskImage(_ disk: DiskImageAccessing?, drive: Int)
    
    /// URLからディスクイメージをロード
    func loadDiskImage(url: URL, drive: Int) -> Bool
    
    /// FDCの更新処理
    func update(cycles: Int)
    
    /// リセット
    func reset()
}
