//
//  PC88BeepSample.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import Foundation

/// PC-8801の内蔵ビープ音サンプル
/// ドレミファソラシドを4MHzモードを基準に各音1秒ずつ鳴らす
class PC88BeepSample {
    /// I/Oポートアクセス
    private let inputOutput: IOAccessing
    
    /// CPUクロック
    private let cpuClock: PC88CPUClock
    
    /// 音階の周波数（Hz）
    private let notes: [String: Double] = [
        "ド": 261.63, // C4
        "レ": 293.66, // D4
        "ミ": 329.63, // E4
        "ファ": 349.23, // F4
        "ソ": 392.00, // G4
        "ラ": 440.00, // A4
        "シ": 493.88, // B4
        "ド高": 523.25  // C5
    ]
    
    /// 初期化
    /// - Parameters:
    ///   - io: I/Oポートアクセス
    ///   - cpuClock: CPUクロック
    init(io: IOAccessing, cpuClock: PC88CPUClock) {
        self.inputOutput = io
        self.cpuClock = cpuClock
    }
    
    /// ビープ音を鳴らす
    /// - Parameter frequency: 周波数（Hz）
    private func beep(frequency: Double) {
        // PC-8801の内蔵ビープ音はクロックを分周して生成
        // 実際のクロック値は3.9936MHz（正確には3993600Hz）
        // 現在は値を使用していないが、将来の実装のためにコメントとして残す
        // let clockFreq = 3_993_600.0 // 正確なクロック値
        
        // カウンタ値を計算
        // 参考サンプルコードによると、周波数は clockFreq / frequency で計算
        // ただし、実際のハードウェアではオーバーヘッドがあるので、それを考慮して調整
        // NoteTableの定義: dw ((3993600 / 261) - 138) / 48 のように計算されている
        // ここではシンプルに計算するため、オーバーヘッドは考慮しない
        // カウンタ値の計算（現在は使用していないが、将来の実装のためにコメントとして残す）
        // let counterValue = UInt8(min(255, max(1, Int(clockFreq / frequency / 16.0))))
        
        // I/Oポート0x40に0x20を書き込む（ビープ音ON）
        // 参考コード: ld a,$20 / out ($40),a
        inputOutput.writePort(0x40, value: 0x20)
    }
    
    /// ビープ音を停止
    private func stopBeep() {
        // ビープ音を停止するには0を書き込む
        // 参考コード: ld a,0 / out ($40),a
        inputOutput.writePort(0x40, value: 0)
    }
    
    /// 指定した時間（秒）だけ待機
    /// - Parameter seconds: 待機時間（秒）
    private func wait(seconds: Double) {
        // 現在のクロックモードに応じて待機時間を調整
        // 内蔵ビープ音はクロックに完全に影響を受けるので.fullを使用
        let adjustedSeconds = cpuClock.adjustTime(seconds, impact: .full)
        
        // 実際のアプリケーションでは、Thread.sleep()ではなく
        // タイマーやディスパッチキューを使用することを推奨
        Thread.sleep(forTimeInterval: adjustedSeconds)
    }
    
    /// ドレミファソラシドを演奏
    func playScale() {
        let noteNames = ["ド", "レ", "ミ", "ファ", "ソ", "ラ", "シ", "ド高"]
        
        // 各音を1秒ずつ鳴らす
        for noteName in noteNames {
            if let frequency = notes[noteName] {
                PC88Logger.sound.debug("演奏中: \(noteName) (\(frequency) Hz)")
                
                // ビープ音ON
                beep(frequency: frequency)
                
                // 指定時間待機
                wait(seconds: 1.0) // 4MHzモードを基準に1秒
                
                // ビープ音OFF
                stopBeep()
                
                // 音と音の間に少し間を空ける
                wait(seconds: 0.1)
            }
        }
        
        PC88Logger.sound.debug("演奏終了")
    }
}
