//
//  EmulatorError.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/04/05.
//

import Foundation
import CoreGraphics

/// エミュレータ関連のエラーを表す列挙型
enum EmulatorError: Error {
    // 初期化関連のエラー
    case initializationFailed(reason: String)
    
    // メモリ関連のエラー
    case memoryAccessViolation(address: Int, operation: String)
    case memoryAllocationFailed(size: Int)
    
    // CPU関連のエラー
    case cpuExecutionError(message: String)
    case invalidOpcode(opcode: UInt8, address: Int)
    
    // ディスク関連のエラー
    case diskImageLoadFailed(url: URL, reason: String)
    case diskImageNotFound(path: String)
    case diskReadError(track: Int, sector: Int)
    case diskWriteError(track: Int, sector: Int)
    
    // ROM関連のエラー
    case romLoadFailed(name: String, reason: String)
    case romNotFound(name: String)
    
    // 入出力関連のエラー
    case ioPortAccessViolation(port: UInt16, operation: String)
    
    // 画面関連のエラー
    case screenRenderingFailed(reason: String)
    
    // 音声関連のエラー
    case soundInitializationFailed(reason: String)
    case audioOutputFailed(reason: String)
    
    // 一般的なエラー
    case notImplemented(feature: String)
    case internalError(message: String)
    case resourceNotAvailable(resource: String)
    
    // ALPHA-MINI-DOS関連のエラー
    case alphaMiniDosLoadFailed(reason: String)
}

/// エミュレータのコンポーネント種別
enum EmulatorComponent {
    case cpu
    case memory
    case disk
    case screen
    case sound
    case io
    case core
    case alphaMiniDos
    
    var description: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .disk: return "Disk"
        case .screen: return "Screen"
        case .sound: return "Sound"
        case .io: return "I/O"
        case .core: return "Core"
        case .alphaMiniDos: return "ALPHA-MINI-DOS"
        }
    }
}

/// エミュレータのログレベル
enum LogLevel {
    case debug
    case info
    case warning
    case error
    case fatal
    
    var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        }
    }
}

// 注意: EmulatorStateとInputEventの定義は既存のものと競合するため、
// ここでは定義せず、既存の定義を拡張して使用します。

/// 既存のEmulatorStateに対するエラー拡張
extension EmulatorState {
    /// エラー状態を作成
    static func error(with error: EmulatorError) -> EmulatorState {
        return .error(message: error.localizedDescription)
    }
}

/// 入力イベント型の拡張用Typealiasの定義
/// 既存のInputEventと競合を避けるため、EmulatorInputEventという名前を使用
typealias EmulatorInputEvent = InputEvent
