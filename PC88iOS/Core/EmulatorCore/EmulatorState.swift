//
//  EmulatorState.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// エミュレータの状態を表す列挙型
enum EmulatorState: Equatable {
    /// 初期化前
    case uninitialized
    
    /// 初期化済み（停止中）
    case initialized
    
    /// 実行中
    case running
    
    /// 一時停止中
    case paused
    
    /// エラー状態
    case error(message: String)
    
    /// 停止処理中
    case stopping
}

/// エミュレータの詳細な状態情報
struct EmulatorStateInfo {
    /// 現在の状態
    let state: EmulatorState
    
    /// CPU使用率
    let cpuUsage: Double
    
    /// フレームレート
    let frameRate: Double
    
    /// エミュレーション速度（1.0 = 100%）
    let emulationSpeed: Double
    
    /// ディスク使用状況
    let diskDriveStatus: [DiskDriveStatus]
    
    /// 実行時間（秒）
    let runningTime: TimeInterval
    
    /// メモリ使用量（バイト）
    let memoryUsage: UInt64
}

/// ディスクドライブの状態
struct DiskDriveStatus {
    /// ドライブ番号
    let driveNumber: Int
    
    /// ディスクが挿入されているか
    let hasDisk: Bool
    
    /// ディスクの名前（挿入されている場合）
    let diskName: String?
    
    /// 書き込み保護されているか
    let isWriteProtected: Bool
    
    /// アクセス中か
    let isAccessing: Bool
}
