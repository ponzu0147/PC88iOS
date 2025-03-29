//
//  CPUExecuting.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// CPUの実行を担当するプロトコル
protocol CPUExecuting {
    /// CPUの初期化
    func initialize()
    
    /// 1ステップ実行
    func executeStep() -> Int
    
    /// 指定サイクル数実行
    func executeCycles(_ cycles: Int) -> Int
    
    /// リセット
    func reset()
    
    /// 割り込み要求
    func requestInterrupt(_ type: InterruptType)
    
    /// 割り込み有効/無効設定
    func setInterruptEnabled(_ enabled: Bool)
}

/// 割り込みタイプ
enum InterruptType {
    case nmi    // ノンマスカブル割り込み
    case int    // 通常割り込み
}
