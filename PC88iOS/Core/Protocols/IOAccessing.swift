//
//  IOAccessing.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// I/Oポートアクセスを担当するプロトコル
protocol IOAccessing {
    /// I/Oポートから読み込み
    func readPort(_ port: UInt8) -> UInt8
    
    /// I/Oポートに書き込み
    func writePort(_ port: UInt8, value: UInt8)
    
    /// キー入力イベントを処理
    func processInputEvent(_ event: InputEvent)
    
    /// 割り込み要求を発生させる
    func requestInterrupt()
    
    /// 特定のソースからの割り込み要求を発生させる
    func requestInterrupt(from source: PC88IO.InterruptSource)
    
    /// 割り込みコントローラの状態を取得
    func getInterruptStatus() -> UInt8
    
    /// CRTCレジスタ更新時のコールバック
    var onCRTCUpdated: ((UInt8, UInt8) -> Void)? { get set }
}
