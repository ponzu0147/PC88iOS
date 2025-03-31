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
        
        // オーディオエンジンをセットアップ
        setupAudioEngine()
    }
    
    // MARK: - SoundChipEmulating プロトコル実装
    
    /// レジスタに値を書き込む
    func writeRegister(_ register: UInt8, value: UInt8) {
        switch register {
        case controlRegisterPort:
            // 制御レジスタ - モード設定など
            // 0xB6 = 10110110B (チャネル2、モード3、バイナリカウント)
            print("制御レジスタ書き込み: 0x\(String(format: "%02X", value))")
            break
            
        case dataPort:
            // 2バイト書き込みを管理するインスタンス変数
            if self.isFirstByte {
                // 下位バイトを保存
                self.lowByte = value
                self.isFirstByte = false
                print("データポート下位バイト書き込み: 0x\(String(format: "%02X", value))")
            } else {
                // 上位バイトと組み合わせて周波数値を設定
                let highByte = value
                frequencyValue = UInt16(highByte) << 8 | UInt16(self.lowByte)
                print("データポート上位バイト書き込み: 0x\(String(format: "%02X", value)), 周波数値: \(frequencyValue)")
                updateFrequency()
                self.isFirstByte = true
            }
            
        case speakerControlPort:
            // スピーカー制御ポート
            // ビット0と1が1の場合、スピーカーが有効
            let newState = (value & 0x03) == 0x03
            if speakerEnabled != newState {
                speakerEnabled = newState
                print("スピーカー状態変更: \(speakerEnabled ? "有効" : "無効")")
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
        // スピーカーが無効な場合や再生中でない場合は無音を出力（冗長チェックだが安全のため）
        if !speakerEnabled || !isRunning {
            for i in 0..<count {
                buffer[i] = 0.0
            }
            return
        }
        
        // 現在の音量を取得
        let currentVolume = PC88BeepSound.volume
        
        // 矩形波を生成
        for i in 0..<count {
            // 矩形波生成（フェーズに基づく）
            let value: Float = phase < 0.5 ? volume : -volume
            buffer[i] = value * currentVolume // 音量を適用
            
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
            print("オーディオエンジンの開始に失敗しました: \(error)")
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
        
        print("周波数を更新: \(frequency)Hz, 分周器値: \(frequencyValue)")
    }
    
    /// オーディオエンジンのセットアップ
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        // オーディオフォーマットの設定
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        
        // ソースノードの作成
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            // デフォルトは無音を出力
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            if let buffer = ablPointer.first, let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) {
                // 再生中でない場合は無音を出力
                if !self.isRunning || !self.speakerEnabled {
                    for frame in 0..<Int(frameCount) {
                        ptr[frame] = 0.0 // 無音を出力
                    }
                    return noErr
                }
                
                // 再生中の場合のみサンプル生成
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
            
            // 初期音量を設定
            audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume
            
            // エンジンの準備
            do {
                // マニュアルレンダリングモードを無効化
                // try audioEngine.enableManualRenderingMode(.realtime, format: format, maximumFrameCount: 4096)
                
                // オーディオセッションの設定
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // 初期音量を0に設定してからエンジンを開始（ノイズ防止）
                audioEngine.mainMixerNode.outputVolume = 0.0
                
                // エンジンを開始
                try audioEngine.start()
                
                // エンジン起動後に徐々に音量を上げる（0.5秒かけて目標音量まで）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 遅延後に音量を設定
                    audioEngine.mainMixerNode.outputVolume = PC88BeepSound.volume
                }
                
                print("オーディオエンジンが正常に起動しました")
            } catch {
                print("オーディオエンジンの準備に失敗: \(error.localizedDescription)")
            }
        }
    }
}
