//
//  PC88BeepTest.swift
//  PC88iOS
//
//  Created on 2025/03/31.
//

import Foundation

/// PC-88初期モデルのビープ音テスト用クラス
class PC88BeepTest {
    /// 再生中かどうかを示すフラグ
    private(set) var isPlaying = false
    // MARK: - 定数
    
    /// 音階の周波数（Hz）- オクターブ4
    private let noteFrequencies: [String: Double] = [
        "C4": 261.63,  // ド
        "D4": 293.66,  // レ
        "E4": 329.63,  // ミ
        "F4": 349.23,  // ファ
        "G4": 392.00,  // ソ
        "A4": 440.00,  // ラ
        "B4": 493.88,  // シ
        "C5": 523.25   // ド（オクターブ5）
    ]
    
    /// 8253 PITの入力クロック周波数（Hz）
    private let pitClock: Double = 1996800.0
    
    // MARK: - プロパティ
    
    /// I/Oアクセス
    private let inputOutput: PC88IO
    
    /// CPUクロック
    private let cpuClock: PC88CPUClock
    
    /// 音の長さ（秒）- 8MHzモード基準
    private let noteDuration: Double = 0.25
    
    // MARK: - 初期化
    
    /// 初期化
    /// - Parameters:
    ///   - cpuClock: CPUクロック
    init(inputOutput: PC88IO, cpuClock: PC88CPUClock) {
        self.inputOutput = inputOutput
        self.cpuClock = cpuClock
    }
    
    // MARK: - 公開メソッド
    
    /// ビープテストを初期化する
    func initialize() {
        // スピーカーを無効化
        let speakerControl = inputOutput.readPort(0x42)
        inputOutput.writePort(0x42, value: speakerControl & ~0x03)
        
        // 8253 PITを初期化（チャネル2、モード3、バイナリカウント）
        inputOutput.writePort(0x77, value: 0xB6)
        
        // 分周値を0に設定
        inputOutput.writePort(0x75, value: 0x00)
        inputOutput.writePort(0x75, value: 0x00)
        
        PC88Logger.sound.debug("ビープテストを初期化しました")
    }
    
    /// ビープテストを停止する
    func stop() {
        // スピーカーを無効化
        let speakerControl = inputOutput.readPort(0x42)
        inputOutput.writePort(0x42, value: speakerControl & ~0x03)
        
        PC88Logger.sound.debug("ビープテストを停止しました")
    }
    
    /// ドレミファソラシドの音階を鳴らす
    func playScale() {
        // 再生中なら何もしない
        if isPlaying {
            PC88Logger.sound.debug("すでにビープ音が再生中です")
            return
        }
        
        // 再生中フラグをセット
        isPlaying = true
        
        // 音階の順序
        let notes = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
        
        // 別スレッドで実行
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 8253 PITを初期化（チャネル2、モード3、バイナリカウント）
            self.inputOutput.writePort(0x77, value: 0xB6)
            
            // 各音階を順番に鳴らす
            for note in notes {
                // 周波数から分周値を計算
                if let frequency = self.noteFrequencies[note] {
                    let divider = UInt16(self.pitClock / frequency)
                    
                    // 分周値を下位バイト、上位バイトの順に送信
                    self.inputOutput.writePort(0x75, value: UInt8(divider & 0xFF))
                    self.inputOutput.writePort(0x75, value: UInt8(divider >> 8))
                    
                    // スピーカーを有効化
                    let speakerControl = self.inputOutput.readPort(0x42)
                    self.inputOutput.writePort(0x42, value: speakerControl | 0x03)
                    
                    // 音の長さに応じて待機
                    let duration = self.calculateDuration()
                    Thread.sleep(forTimeInterval: duration)
                }
            }
            
            // スピーカーを無効化
            let speakerControl = self.inputOutput.readPort(0x42)
            self.inputOutput.writePort(0x42, value: speakerControl & ~0x03)
            
            // 再生中フラグをリセット
            DispatchQueue.main.async {
                self.isPlaying = false
                PC88Logger.sound.debug("ビープ音の再生が完了しました")
            }
        }
    }
    
    // MARK: - 内部メソッド
    
    /// 現在のCPUクロックモードに応じた音の長さを計算
    /// - Returns: 音の長さ（秒）
    private func calculateDuration() -> Double {
        // クロックモードを確認
        let mode = cpuClock.currentMode
        PC88Logger.sound.debug("現在のクロックモード: \(mode == .mode8MHz ? "8MHz" : "4MHz")")
        
        // 8MHzモードでは0.25秒、4MHzモードでは0.5秒
        let duration = mode == .mode8MHz ? noteDuration : noteDuration * 2.0
        PC88Logger.sound.debug("音の長さ: \(duration)秒")
        return duration
    }
}
