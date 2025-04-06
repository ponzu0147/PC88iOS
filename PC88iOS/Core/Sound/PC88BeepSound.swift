//
//  PC88BeepSound.swift
//  PC88iOS
//
//  Created on 2025/03/31.
//

import Foundation
import AVFoundation

/// PC-88初期モデルの8253 PITを使ったビープ音生成を担当するクラス
class PC88BeepSound: SoundChipEmulating {
    /// 共有インスタンス
    static private(set) var shared: PC88BeepSound?
    
    /// 音量設定（0.0～1.0）
    static var volume: Float = 0.5 {
        didSet {
            // 変更を反映
            if let shared = shared, let engine = shared.audioEngine {
                engine.mainMixerNode.outputVolume = volume
            }
        }
    }
    // MARK: - 定数
    
    /// 8253 PIT制御レジスタポート
    private let controlRegisterPort: UInt8 = 0x77
    
    /// 8253 PITチャネル2データポート
    private let dataPort: UInt8 = 0x75
    
    /// スピーカー制御ポート
    private let speakerControlPort: UInt8 = 0x42
    
    // MARK: - プロパティ
    
    /// 現在の周波数値
    private var frequencyValue: UInt16 = 0
    
    /// スピーカーが有効かどうか
    private var speakerEnabled: Bool = false
    
    /// サンプルレート
    private var sampleRate: Double = 44100.0
    
    /// 音量
    private var volume: Float = 0.5
    
    /// 波形生成用のフェーズ
    private var phase: Double = 0.0
    
    /// 波形生成用のフェーズ増分
    private var phaseIncrement: Double = 0.0
    
    /// 前回の最後のサンプル値（ノイズ防止用）
    private var lastSampleValue: Float = 0.0
    
    /// オーディオエンジン
    private var audioEngine: AVAudioEngine?
    
    /// オーディオソースノード
    private var sourceNode: AVAudioSourceNode?
    
    /// 2バイト書き込み管理用フラグ
    private var isFirstByte: Bool = true
    
    /// 2バイト書き込み管理用下位バイト
    private var lowByte: UInt8 = 0
    
    /// 動作中かどうか
    private var isRunning: Bool = false
    
    // MARK: - 初期化
    
    /// 初期化
    func initialize(sampleRate: Double) {
        self.sampleRate = sampleRate
        PC88BeepSound.shared = self
        
        // 初期化時は必ず無音状態から始める
        self.isRunning = false
        self.speakerEnabled = false
        self.frequencyValue = 0
        self.phase = 0.0
        self.phaseIncrement = 0.0
        self.lastSampleValue = 0.0
        self.isFirstByte = true  // データポートの初期状態をリセット
        self.lowByte = 0         // 下位バイトも初期化
        
        // オーディオエンジンをセットアップ
        setupAudioEngine()
        
        // 初期状態では音量をユーザー設定値に設定
        // PC88BeepSound.volumeは別途設定される
        
        // 起動直後に音が鳴らないようにするための処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 起動直後にスピーカーを無効化
            self.writeRegister(0x61, value: 0x00)
        }
    }
    
    // MARK: - SoundChipEmulating プロトコル実装
    
    /// レジスタに値を書き込む
    func writeRegister(_ register: UInt8, value: UInt8) {
        switch register {
        case controlRegisterPort:
            // 制御レジスタ - モード設定など
            // 0xB6 = 10110110B (チャネル2、モード3、バイナリカウント)
            PC88Logger.sound.debug("制御レジスタ書き込み: 0x\(String(format: "%02X", value))")
            break
            
        case dataPort:
            // 2バイト書き込みを管理するインスタンス変数
            if self.isFirstByte {
                // 下位バイトを保存
                self.lowByte = value
                self.isFirstByte = false
                PC88Logger.sound.debug("データポート下位バイト書き込み: 0x\(String(format: "%02X", value))")
            } else {
                // 上位バイトと組み合わせて周波数値を設定
                let highByte = value
                self.frequencyValue = UInt16(highByte) << 8 | UInt16(self.lowByte)
                PC88Logger.sound.debug("データポート上位バイト書き込み: 0x\(String(format: "%02X", value)), 周波数値: \(self.frequencyValue)")
                updateFrequency()
                self.isFirstByte = true
            }
            
        case speakerControlPort:
            // スピーカー制御ポート
            // ビット0と1が1の場合、スピーカーが有効
            let newState = (value & 0x03) == 0x03
            
            // 周波数値が0の場合はスピーカーを有効にしない
            // これにより8秒おきのプツっという音を防止
            if self.frequencyValue == 0 && newState {
                PC88Logger.sound.debug("周波数値が0のためスピーカーを有効にしません")
                return
            }
            
            if speakerEnabled != newState {
                // 状態変更時にノイズ防止のための処理
                if newState {
                    // オンになる場合は位相を0からスタート
                    phase = 0.0
                    lastSampleValue = 0.0 // 最初は無音から開始
                    
                    // フェードインのためにボリュームを一時的に下げる
                    let originalVolume = PC88BeepSound.volume
                    PC88BeepSound.volume = 0.0
                    // 徐々に音量を上げる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        PC88BeepSound.volume = originalVolume * 0.3
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            PC88BeepSound.volume = originalVolume * 0.6
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                PC88BeepSound.volume = originalVolume
                            }
                        }
                    }
                } else {
                    // オフになる場合はフェードアウトは自動的に行われる
                    // generateSamplesメソッド内で処理される
                }
                
                self.speakerEnabled = newState
                PC88Logger.sound.debug("スピーカー状態変更: \(self.speakerEnabled ? "有効" : "無効")")
            }
            break
            
        default:
            break
        }
    }
    
    /// レジスタから値を読み込む
    func readRegister(_ register: UInt8) -> UInt8 {
        switch register {
        case speakerControlPort:
            // スピーカー制御ポートの現在の値を返す
            return speakerEnabled ? 0x03 : 0x00
        default:
            return 0
        }
    }
    
    /// オーディオサンプルを生成
    func generateSamples(into buffer: UnsafeMutablePointer<Float>, count: Int) {
        // スピーカーが無効な場合、再生中でない場合、または周波数値が0の場合は徐々に音量を下げる
        if !speakerEnabled || !isRunning || frequencyValue == 0 {
            for i in 0..<count {
                // 徐々に音量を下げる（ポップノイズ防止）
                lastSampleValue *= 0.95 // フェードアウト係数
                buffer[i] = lastSampleValue
                if abs(lastSampleValue) < 0.001 {
                    lastSampleValue = 0.0 // 十分小さくなったらゼロに
                }
            }
            return
        }
        
        // 現在の音量を取得
        let currentVolume = PC88BeepSound.volume
        
        // 矩形波を生成（スムージング処理を追加）
        for i in 0..<count {
            // 矩形波生成（フェーズに基づく）
            let targetValue: Float = phase < 0.5 ? volume : -volume
            
            // 急激な変化を避けるためのスムージング
            lastSampleValue = lastSampleValue * 0.9 + targetValue * 0.1
            buffer[i] = lastSampleValue * currentVolume // 音量を適用
            
            // フェーズを更新
            phase += phaseIncrement
            if phase >= 1.0 {
                phase -= 1.0
            }
        }
    }
    
    /// サウンドチップを開始
    func start() {
        isRunning = true
        speakerEnabled = true  // スピーカーを有効化
        startAudioEngine()
    }
    
    /// サウンドチップを停止
    func stop() {
        isRunning = false
        stopAudioEngine()
        reset()
    }
    
    /// サウンドチップを一時停止
    func pause() {
        isRunning = false
    }
    
    /// サウンドチップを再開
    func resume() {
        isRunning = true
        startAudioEngine()
    }
    
    /// サウンドチップの更新
    func update(_ cycles: Int) {
        // 現在の実装では特に処理は必要ない
    }
    
    /// 音量設定
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
    }
    
    /// リセット
    func reset() {
        frequencyValue = 0
        speakerEnabled = false
        phase = 0.0
        phaseIncrement = 0.0
        isFirstByte = true
        lowByte = 0
    }
    
    /// 品質モードを設定
    func setQualityMode(_ mode: SoundQualityMode) {
        // 品質モードに応じて設定を変更
        switch mode {
        case .high:
            // 高品質モードの設定
            break
        case .medium:
            // 中品質モードの設定
            break
        case .low:
            // 低品質モードの設定
            break
        }
    }
    
    /// 現在の品質モードを取得
    func getQualityMode() -> SoundQualityMode {
        // デフォルトでは中品質モードを返す
        return .medium
    }
    
    // MARK: - 内部メソッド
    
    /// オーディオエンジンを開始
    private func startAudioEngine() {
        if audioEngine?.isRunning == true {
            return
        }
        
        do {
            try audioEngine?.start()
        } catch {
            PC88Logger.sound.debug("オーディオエンジンの開始に失敗しました: \(error)")
        }
    }
    
    /// オーディオエンジンを停止
    private func stopAudioEngine() {
        if audioEngine?.isRunning == true {
            audioEngine?.stop()
        }
    }
    
    /// 周波数を更新
    private func updateFrequency() {
        if frequencyValue == 0 {
            // 0除算を防ぐ
            phaseIncrement = 0.0
            return
        }
        
        // 8253 PITの周波数計算
        // PITの入力クロックは1.9968MHz
        let pitClock: Double = 1996800.0
        let divider = Double(frequencyValue)
        let frequency = pitClock / divider
        
        // 位相増分を計算
        phaseIncrement = frequency / sampleRate
        
        PC88Logger.sound.debug("周波数を更新: \(frequency)Hz, 分周器値: \(self.frequencyValue)")
    }
    
    /// オーディオエンジンのセットアップ
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        // 初期化時は必ず無音状態から始める
        lastSampleValue = 0.0
        phase = 0.0
        
        // オーディオフォーマットの設定
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        
        // ソースノードの作成
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            // デフォルトは無音を出力
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            if let buffer = ablPointer.first, let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) {
                // 再生中でない場合はフェードアウトを適用
                if !self.isRunning || !self.speakerEnabled {
                    for frame in 0..<Int(frameCount) {
                        // 徐々に音量を下げる（ポップノイズ防止）
                        self.lastSampleValue *= 0.95
                        ptr[frame] = self.lastSampleValue
                        if abs(self.lastSampleValue) < 0.001 {
                            self.lastSampleValue = 0.0
                        }
                    }
                    return noErr
                }
                
                // 再生中の場合はスムージングを適用したサンプル生成
                for frame in 0..<Int(frameCount) {
                    self.generateSamples(into: ptr.advanced(by: frame), count: 1)
                }
            }
            return noErr
        }
        
        // ノードの接続
        if let sourceNode = sourceNode, let format = format, let audioEngine = audioEngine {
            audioEngine.attach(sourceNode)
            audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)
            
            // 初期音量を0に設定（ノイズ防止）
            audioEngine.mainMixerNode.outputVolume = 0.0
            
            // エンジンの準備
            do {
                // オーディオセッションの設定
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
                try audioSession.setPreferredIOBufferDuration(0.005) // バッファサイズを大きめに設定
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // エンジンを開始
                try audioEngine.start()
                
                // エンジン起動後に徐々に音量を上げる（より慢く、段階的に）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume * 0.1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume * 0.3
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume * 0.6
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume
                            }
                        }
                    }
                }
                
                PC88Logger.sound.debug("オーディオエンジンが正常に起動しました")
            } catch {
                PC88Logger.sound.debug("オーディオエンジンの準備に失敗: \(error.localizedDescription)")
            }
        }
    }
}
