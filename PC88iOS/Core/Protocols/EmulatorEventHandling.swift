//
//  EmulatorEventHandling.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/04/05.
//

import Foundation

/// エミュレータイベントの種類
enum EmulatorEvent {
    // ライフサイクルイベント
    case didInitialize
    case willStart
    case didStart
    case willStop
    case didStop
    case willPause
    case didPause
    case willResume
    case didResume
    case willReset
    case didReset
    
    // ディスク関連イベント
    case diskImageLoaded(drive: Int, url: URL)
    case diskImageEjected(drive: Int)
    case diskAccess(drive: Int, track: Int, sector: Int, isRead: Bool)
    
    // メモリ関連イベント
    case memoryRead(address: Int, value: UInt8)
    case memoryWrite(address: Int, value: UInt8)
    
    // CPU関連イベント
    case cpuStateChanged(pc: Int, registers: [String: UInt16])
    case instructionExecuted(address: Int, opcode: UInt8, cycles: Int)
    
    // 画面関連イベント
    case screenRefreshed
    case screenModeChanged(mode: Int)
    
    // 音声関連イベント
    case soundPlayed(frequency: Float, duration: TimeInterval)
    
    // エラー関連イベント
    case errorOccurred(error: EmulatorError, component: EmulatorComponent)
    
    // ALPHA-MINI-DOS関連イベント
    case alphaMiniDosLoaded
    case alphaMiniDosExecuted
}

/// エミュレータイベントを監視するプロトコル
protocol EmulatorEventObserving: AnyObject {
    /// イベントが発生した時に呼ばれるメソッド
    func emulatorDidEmitEvent(_ event: EmulatorEvent)
    
    /// イベントフィルタ（監視対象のイベント種別を返す）
    func observedEvents() -> [EmulatorEvent.Type]
}

/// エミュレータイベントを発行するプロトコル
protocol EmulatorEventEmitting {
    /// オブザーバーの登録
    func addObserver(_ observer: EmulatorEventObserving)
    
    /// オブザーバーの登録解除
    func removeObserver(_ observer: EmulatorEventObserving)
    
    /// イベントの発行
    func emitEvent(_ event: EmulatorEvent)
}

// デフォルト実装を提供
extension EmulatorEventEmitting {
    func addObserver(_ observer: EmulatorEventObserving) {
        // デフォルト実装は何もしない
    }
    
    func removeObserver(_ observer: EmulatorEventObserving) {
        // デフォルト実装は何もしない
    }
    
    func emitEvent(_ event: EmulatorEvent) {
        // デフォルト実装は何もしない
    }
}

/// エミュレータのログ出力を担当するプロトコル
protocol EmulatorLogging {
    /// ログメッセージの出力
    func log(level: LogLevel, component: EmulatorComponent, message: String)
    
    /// エラーのログ出力
    func logError(_ error: EmulatorError, component: EmulatorComponent)
    
    /// デバッグ情報の出力
    func debug(_ message: String, component: EmulatorComponent)
    
    /// 情報メッセージの出力
    func info(_ message: String, component: EmulatorComponent)
    
    /// 警告メッセージの出力
    func warning(_ message: String, component: EmulatorComponent)
    
    /// エラーメッセージの出力
    func error(_ message: String, component: EmulatorComponent)
}

// デフォルト実装を提供
extension EmulatorLogging {
    func log(level: LogLevel, component: EmulatorComponent, message: String) {
        // デフォルト実装は何もしない
    }
    
    func logError(_ error: EmulatorError, component: EmulatorComponent) {
        // デフォルト実装は何もしない
    }
    
    func debug(_ message: String, component: EmulatorComponent) {
        log(level: .debug, component: component, message: message)
    }
    
    func info(_ message: String, component: EmulatorComponent) {
        log(level: .info, component: component, message: message)
    }
    
    func warning(_ message: String, component: EmulatorComponent) {
        log(level: .warning, component: component, message: message)
    }
    
    func error(_ message: String, component: EmulatorComponent) {
        log(level: .error, component: component, message: message)
    }
}

/// エミュレータのパフォーマンスメトリクスを収集するプロトコル
protocol EmulatorMetricsCollecting {
    /// メトリクスの記録開始
    func startCollectingMetrics()
    
    /// メトリクスの記録停止
    func stopCollectingMetrics()
    
    /// 現在のCPU使用率を取得
    func getCpuUsage() -> Double
    
    /// 現在のメモリ使用量を取得
    func getMemoryUsage() -> UInt64
    
    /// 現在のフレームレートを取得
    func getFrameRate() -> Double
    
    /// エミュレーション速度（実機との比率）を取得
    func getEmulationSpeed() -> Double
    
    /// メトリクスレポートの生成
    func generateMetricsReport() -> String
}

// デフォルト実装を提供
extension EmulatorMetricsCollecting {
    func startCollectingMetrics() {
        // デフォルト実装は何もしない
    }
    
    func stopCollectingMetrics() {
        // デフォルト実装は何もしない
    }
    
    func getCpuUsage() -> Double {
        return 0.0
    }
    
    func getMemoryUsage() -> UInt64 {
        return 0
    }
    
    func getFrameRate() -> Double {
        return 0.0
    }
    
    func getEmulationSpeed() -> Double {
        return 1.0
    }
    
    func generateMetricsReport() -> String {
        return ""
    }
}
