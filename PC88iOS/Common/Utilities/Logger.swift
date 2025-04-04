//
//  Logger.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/04/05.
//

import Foundation
import os.log

/// PC88エミュレータ用のロガー
enum PC88Logger {
    /// OSログカテゴリー
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.ponzu0147.PC88iOS"
    
    /// アプリケーションログ
    static let app = os.Logger(subsystem: subsystem, category: "app")
    
    /// エミュレータコアログ
    static let core = os.Logger(subsystem: subsystem, category: "core")
    
    /// CPUログ
    static let cpu = os.Logger(subsystem: subsystem, category: "cpu")
    
    /// メモリログ
    static let memory = os.Logger(subsystem: subsystem, category: "memory")
    
    /// ディスクログ
    static let disk = os.Logger(subsystem: subsystem, category: "disk")
    
    /// 画面表示ログ
    static let screen = os.Logger(subsystem: subsystem, category: "screen")
    
    /// 入出力ログ
    static let io = os.Logger(subsystem: subsystem, category: "io")
    
    /// サウンドログ
    static let sound = os.Logger(subsystem: subsystem, category: "sound")
}
