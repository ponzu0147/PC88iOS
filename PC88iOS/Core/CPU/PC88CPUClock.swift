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
        
        /// クロックモードに応じたアイドル時間の値を返す
        var idleTimeMultiplier: Double {
            switch self {
            case .mode4MHz:
                return 1.5  // 4MHzモードではアイドル時間を長くする
            case .mode8MHz:
                return 1.0  // 8MHzモードでは標準のアイドル時間
            }
        }
    }
    
    /// クロックモードによる影響の種類
    enum ClockImpact {
        /// クロックに完全に比例（クロック2倍で速度も2倍）
        case full
        /// クロックに影響されない（速度不変）
        case none
        /// クロックに部分的に影響（部分的な高速化）
        case partial(factor: Double) // 高速化の割合（0.0-1.0）
    }
    
    /// 現在のクロックモード
    private(set) var currentMode: ClockMode = .mode4MHz
    
    /// クロックモード変更時のコールバック
    var onModeChanged: ((ClockMode) -> Void)?
    
    /// 4MHzモードでの追加スリープ時間（マイクロ秒）
    private var mode4MHzSleepTime: UInt32 = 500  // デフォルトは500マイクロ秒
    
    /// 4MHzモードのクロック周波数
    let frequency4MHz: Int = 4_000_000
    
    /// 8MHzモードのクロック周波数
    let frequency8MHz: Int = 8_000_000
    
    /// 現在のクロック周波数
    var currentFrequency: Int {
        return currentMode == .mode4MHz ? frequency4MHz : frequency8MHz
    }
    
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
        
        // 4MHzモードの場合はスリープ時間を設定
        if mode == .mode4MHz {
            // フレームレートに応じてスリープ時間を調整
            adjustSleepTimeForMode4MHz()
        }
        
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
    
    // MARK: - クロック影響の計算メソッド
    
    /// 指定されたクロック影響タイプに基づいて、当初のサイクル数を現在のクロックモードに合わせて調整
    /// - Parameters:
    ///   - baseCycles: 当初のサイクル数（4MHzモードを想定）
    ///   - impact: クロックの影響タイプ
    /// - Returns: 調整後のサイクル数
    func adjustCycles(_ baseCycles: Int, impact: ClockImpact) -> Int {
        // 4MHzモードの場合はサイクル数をそのまま返すが、スリープを挿入してCPU負荷を下げる
        if currentMode == .mode4MHz {
            // 4MHzモードでは定期的にスリープを挿入する
            // サイクル数が大きい場合のみスリープを挿入
            if baseCycles > 1000 {
                usleep(mode4MHzSleepTime)
            }
            return baseCycles
        }
        
        // 8MHzモードの場合
        switch impact {
        case .full:
            // 8MHzモードではサイクル数を半分にする
            // これにより、同じ呼び出し回数でも処理量が少なくなり、CPU使用率が下がる
            return baseCycles / 2
        case .none:
            // 影響を受けない（速度不変）
            return baseCycles
        case .partial(let factor):
            // 部分的に影響を受ける
            let decrease = Double(baseCycles) * factor
            return baseCycles - Int(decrease / 2.0)
        }
    }
    
    /// 指定されたクロック影響タイプに基づいて、当初の時間を現在のクロックモードに合わせて調整
    /// - Parameters:
    ///   - baseTime: 当初の時間（4MHzモードを想定）
    ///   - impact: クロックの影響タイプ
    /// - Returns: 調整後の時間
    func adjustTime(_ baseTime: Double, impact: ClockImpact) -> Double {
        // 4MHzモードならそのまま返す
        guard currentMode == .mode8MHz else { return baseTime }
        
        switch impact {
        case .full:
            // 8MHzモードでは処理時間を長くする
            // これにより、同じ呼び出し回数でも処理量が少なくなり、CPU使用率が下がる
            return baseTime * 2.0
        case .none:
            // 影響を受けない（時間不変）
            return baseTime
        case .partial(let factor):
            // 部分的に影響を受ける
            let increase = baseTime * factor
            return baseTime + increase
        }
    }
    
    /// 特定のデバイスや処理に対するクロック影響を取得
    /// - Parameter deviceType: デバイスの種類
    /// - Returns: クロック影響の種類
    func getClockImpact(for deviceType: DeviceType) -> ClockImpact {
        switch deviceType {
        case .cpu, .memory, .ioPort, .beeper:
            // CPU、メモリ、I/Oポート、内蔵ビープ音は完全に影響を受ける
            return .full
            
        case .vram:
            // VRAMアクセスはウェイトが入るため、部分的な影響
            return .partial(factor: 0.7) // 70%の高速化
            
        case .sound, .fdc, .display, .serialPort, .keyboard:
            // サウンド、FDC、ディスプレイ、シリアルポート、キーボードは影響を受けない
            return .none
        }
    }
    
    /// デバイスの種類
    enum DeviceType {
        case cpu        // CPU処理
        case memory     // メインメモリアクセス
        case vram       // VRAMアクセス
        case ioPort     // I/Oポートアクセス
        case sound      // サウンドチップ
        case beeper     // 内蔵ビープ音
        case fdc        // フロッピーディスクコントローラ
        case display    // ディスプレイ出力
        case serialPort // シリアルポート
        case keyboard   // キーボード
    }
    
    /// 現在のクロック周波数を取得（MHz単位）
    func getCurrentClockFrequency() -> Double {
        return (currentMode == .mode4MHz) ? 4.0 : 8.0
    }
    
    /// 4MHzモード用のスリープ時間を設定
    /// - Parameter frameRate: フレームレート（指定がない場合はデフォルト値を使用）
    func adjustSleepTimeForMode4MHz(frameRate: Double = 30.0) {
        // フレームレートに応じてスリープ時間を調整
        // フレームレートが低いほどスリープ時間を長くする
        let baseTime: UInt32 = 500 // ベースは500マイクロ秒
        
        if frameRate <= 15.0 {
            mode4MHzSleepTime = baseTime * 3  // 15fpsの場合はスリープ時間を長く
        } else if frameRate <= 30.0 {
            mode4MHzSleepTime = baseTime * 2  // 30fpsの場合は中程度のスリープ時間
        } else {
            mode4MHzSleepTime = baseTime  // 60fpsの場合は短めのスリープ時間
        }
    }
    
    /// 4MHzモードのスリープ時間を取得
    func getSleepTimeForMode4MHz() -> UInt32 {
        return mode4MHzSleepTime
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
