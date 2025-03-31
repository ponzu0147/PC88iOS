//
//  PC88CPUClock.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import Foundation

/// PC-88 CPUクロック管理クラス
class PC88CPUClock {
    /// CPUクロックモード
    enum ClockMode {
        /// 4MHz (N-BASIC)
        case mode4MHz
        /// 8MHz (N88-BASIC)
        case mode8MHz
    }
    
    /// 現在のクロックモード
    private(set) var currentMode: ClockMode = .mode4MHz
    
    /// クロックモード変更時のコールバック
    var onModeChanged: ((ClockMode) -> Void)?
    
    /// 4MHzモード時の1命令あたりの実行時間（マイクロ秒）
    private let executionTime4MHz: Double = 1.0 / 4_000_000.0 * 1_000_000.0
    
    /// 8MHzモード時の1命令あたりの実行時間（マイクロ秒）
    private let executionTime8MHz: Double = 1.0 / 8_000_000.0 * 1_000_000.0
    
    /// 1命令あたりの平均サイクル数（Z80の平均的な値）
    private let averageCyclesPerInstruction: Double = 4.0
    
    /// 速度倍率（デバッグ用：1.0が標準速度）
    var speedMultiplier: Double = 1.0
    
    /// 現在の1命令あたりの実行時間（マイクロ秒）
    var currentExecutionTimePerInstruction: Double {
        let baseTime = (currentMode == .mode4MHz) ? executionTime4MHz : executionTime8MHz
        return baseTime * averageCyclesPerInstruction / speedMultiplier
    }
    
    /// 現在の1サイクルあたりの実行時間（マイクロ秒）
    var currentExecutionTimePerCycle: Double {
        let baseTime = (currentMode == .mode4MHz) ? executionTime4MHz : executionTime8MHz
        return baseTime / speedMultiplier
    }
    
    /// 1秒あたりの命令実行回数
    var instructionsPerSecond: Double {
        return 1_000_000.0 / currentExecutionTimePerInstruction
    }
    
    /// クロックモードを設定
    func setClockMode(_ mode: ClockMode) {
        // 現在のモードと異なる場合のみ処理
        guard currentMode != mode else { return }
        
        currentMode = mode
        
        // コールバックを呼び出し
        onModeChanged?(currentMode)
        
        print("CPUクロックモードを変更: \(mode == .mode4MHz ? "4MHz" : "8MHz")")
    }
    
    /// 4MHzモードに設定
    func set4MHzMode() {
        setClockMode(.mode4MHz)
    }
    
    /// 8MHzモードに設定
    func set8MHzMode() {
        setClockMode(.mode8MHz)
    }
    
    /// クロックモードを切り替え
    func toggleClockMode() {
        let newMode = (currentMode == .mode4MHz) ? ClockMode.mode8MHz : ClockMode.mode4MHz
        setClockMode(newMode)
    }
    
    /// 現在のクロック周波数を取得（MHz単位）
    func getCurrentClockFrequency() -> Double {
        return (currentMode == .mode4MHz) ? 4.0 : 8.0
    }
    
    /// 1秒あたりのサイクル数
    var cyclesPerSecond: Double {
        return (currentMode == .mode4MHz) ? 4_000_000.0 * speedMultiplier : 8_000_000.0 * speedMultiplier
    }
    

    
    /// 指定された命令数の実行にかかる時間を計算（マイクロ秒）
    /// - Parameter instructions: 命令数
    /// - Returns: 実行時間（マイクロ秒）
    func calculateExecutionTime(forInstructions instructions: Int) -> Double {
        return Double(instructions) * currentExecutionTimePerInstruction
    }
    
    /// 指定されたサイクル数の実行にかかる時間を計算（マイクロ秒）
    /// - Parameter cycles: サイクル数
    /// - Returns: 実行時間（マイクロ秒）
    func calculateExecutionTime(forCycles cycles: Int) -> Double {
        return Double(cycles) * currentExecutionTimePerCycle
    }
    
    /// 指定された文字数の表示にかかる時間を計算（マイクロ秒）
    /// - Parameter characters: 文字数
    /// - Returns: 表示時間（マイクロ秒）
    func calculateTextDisplayTime(forCharacters characters: Int) -> Double {
        // PC-88では、1文字の表示に約10サイクル程度かかると仮定
        let cyclesPerCharacter: Double = 10.0
        return calculateExecutionTime(forCycles: Int(Double(characters) * cyclesPerCharacter))
    }
}
