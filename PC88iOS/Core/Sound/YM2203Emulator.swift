//
//  YM2203Emulator.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import AVFoundation

/// YM2203（OPN）サウンドチップのエミュレーション
class YM2203Emulator: SoundChipEmulating {
    // MARK: - プロトコル実装の追加メソッド
    
    /// オーディオサンプルを生成
    func generateSamples(into buffer: UnsafeMutablePointer<Float>, count: Int) {
        for i in 0..<count {
            // すべてのチャンネルからの出力を合成
            var sample: Float = 0.0
            
            // FMチャンネルの合成
            for channel in self.fmChannels {
                sample += channel.generateSample()
            }
            
            // SSGチャンネルの合成
            for channel in self.ssgChannels {
                sample += channel.generateSample()
            }
            
            // 音量調整
            sample *= 0.2
            
            buffer[i] = sample
        }
    }
    
    /// 音量設定
    func setVolume(_ volume: Float) {
        // 実装する必要があればここに追加
    }
    
    /// リセット
    func reset() {
        // レジスタをリセット
        for i in 0..<registers.count {
            registers[i] = 0
        }
        
        // チャンネル状態をリセット
        for i in 0..<fmChannels.count {
            fmChannels[i] = FMChannelState()
        }
        
        for i in 0..<ssgChannels.count {
            ssgChannels[i] = SSGChannelState()
        }
    }
    // MARK: - プロパティ
    
    /// レジスタ値
    private var registers = [UInt8](repeating: 0, count: 256)
    
    /// オーディオエンジン
    private var audioEngine: AVAudioEngine?
    
    /// オーディオノード
    private var audioNode: AVAudioSourceNode?
    
    /// サンプルレート
    private let sampleRate: Double = 44100.0
    
    /// 周波数
    private let chipFrequency: Double = 3993600.0
    
    /// FMチャンネルの状態
    private var fmChannels: [FMChannelState] = []
    
    /// SSGチャンネルの状態
    private var ssgChannels: [SSGChannelState] = []
    
    // MARK: - 初期化
    
    init() {
        // FMチャンネルの初期化（3チャンネル）
        for _ in 0..<3 {
            fmChannels.append(FMChannelState())
        }
        
        // SSGチャンネルの初期化（3チャンネル）
        for _ in 0..<3 {
            ssgChannels.append(SSGChannelState())
        }
        
        setupAudio()
    }
    
    deinit {
        stopAudio()
    }
    
    // MARK: - SoundChipEmulating プロトコル実装
    
    /// 初期化
    func initialize(sampleRate: Double) {
        // レジスタをリセット
        for i in 0..<registers.count {
            registers[i] = 0
        }
        
        // チャンネル状態をリセット
        for i in 0..<fmChannels.count {
            fmChannels[i] = FMChannelState()
        }
        
        for i in 0..<ssgChannels.count {
            ssgChannels[i] = SSGChannelState()
        }
        
        // オーディオを開始
        startAudio()
    }
    
    /// レジスタ書き込み
    func writeRegister(_ register: UInt8, value: UInt8) {
        registers[Int(register)] = value
        
        // レジスタ値に基づいてサウンドパラメータを更新
        updateSoundParameters(address: register, value: value)
    }
    
    /// レジスタ読み込み
    func readRegister(_ register: UInt8) -> UInt8 {
        return registers[Int(register)]
    }
    
    // MARK: - SoundChipEmulatingプロトコルの追加メソッド
    
    /// サウンドチップを開始
    func start() {
        // オーディオエンジンが実行中でなければ開始
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            startAudio()
        }
        print("YM2203サウンドチップを開始しました")
    }
    
    /// サウンドチップを停止
    func stop() {
        // オーディオエンジンを停止
        stopAudio()
        
        // レジスタをリセット
        for i in 0..<registers.count {
            registers[i] = 0
        }
        
        // チャンネル状態をリセット
        for i in 0..<fmChannels.count {
            fmChannels[i] = FMChannelState()
        }
        
        for i in 0..<ssgChannels.count {
            ssgChannels[i] = SSGChannelState()
        }
        
        print("YM2203サウンドチップを停止しました")
    }
    
    /// サウンドチップを一時停止
    func pause() {
        // オーディオエンジンを一時停止
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.pause()
        }
        print("YM2203サウンドチップを一時停止しました")
    }
    
    /// サウンドチップを再開
    func resume() {
        // オーディオエンジンが一時停止中なら再開
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            startAudio()
        }
        print("YM2203サウンドチップを再開しました")
    }
    
    /// サウンドチップの更新
    func update(_ cycles: Int) {
        // サイクル数に基づいてサウンドチップの状態を更新
        // 実際の実装では、タイミングに基づいてエンベロープやLFOなどを更新
        
        // ここでは簡易的な実装として、サイクル数は無視
    }
    
    // MARK: - 内部メソッド
    
    /// オーディオセットアップ
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        // オーディオノードの作成
        audioNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                // すべてのチャンネルからの出力を合成
                var sample: Float = 0.0
                
                // FMチャンネルの合成
                for channel in self.fmChannels {
                    sample += channel.generateSample()
                }
                
                // SSGチャンネルの合成
                for channel in self.ssgChannels {
                    sample += channel.generateSample()
                }
                
                // 音量調整
                sample *= 0.2
                
                // すべてのチャンネルに同じ値を設定
                for buffer in ablPointer {
                    let bufferPointer = UnsafeMutableBufferPointer<Float>(
                        start: buffer.mData?.assumingMemoryBound(to: Float.self),
                        count: Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                    )
                    bufferPointer[frame] = sample
                }
            }
            
            return noErr
        }
        
        // オーディオノードを接続
        if let audioNode = audioNode {
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
            audioEngine.attach(audioNode)
            audioEngine.connect(audioNode, to: audioEngine.mainMixerNode, format: format)
        }
    }
    
    /// オーディオ開始
    private func startAudio() {
        guard let audioEngine = audioEngine else { return }
        
        do {
            try audioEngine.start()
        } catch {
            print("オーディオエンジンの開始に失敗: \(error)")
        }
    }
    
    /// オーディオ停止
    private func stopAudio() {
        audioEngine?.stop()
    }
    
    /// サウンドパラメータの更新
    private func updateSoundParameters(address: UInt8, value: UInt8) {
        // レジスタアドレスに基づいてサウンドパラメータを更新
        // 実際の実装ではYM2203の仕様に従って詳細に実装する必要があります
        
        // 簡易的な実装例：
        if address < 0x10 {
            // SSGレジスタ
            let ssgChannel = Int(address) % 3
            if ssgChannel < ssgChannels.count {
                // 周波数や音量などの設定
                ssgChannels[ssgChannel].updateParameter(address: address, value: value)
            }
        } else if address >= 0x30 && address < 0xA0 {
            // FMレジスタ
            let fmChannel = (Int(address) - 0x30) % 3
            if fmChannel < fmChannels.count {
                // オペレータパラメータの設定
                fmChannels[fmChannel].updateParameter(address: address, value: value)
            }
        }
    }
}

/// FMチャンネルの状態
private struct FMChannelState {
    // 周波数
    var frequency: Float = 440.0
    
    // 音量
    var volume: Float = 0.0
    
    // 位相
    var phase: Float = 0.0
    
    // オペレータパラメータ
    var attack: Float = 0.0
    var decay: Float = 0.0
    var sustain: Float = 0.0
    var release: Float = 0.0
    
    // サンプル生成
    func generateSample() -> Float {
        // 簡易的な実装（実際にはFM合成の詳細な実装が必要）
        if volume > 0 {
            return sin(phase) * volume
        }
        return 0
    }
    
    // パラメータ更新
    mutating func updateParameter(address: UInt8, value: UInt8) {
        // 実際のYM2203の仕様に基づいてパラメータを更新
    }
}

/// SSGチャンネルの状態
private struct SSGChannelState {
    // 周波数
    var frequency: Float = 440.0
    
    // 音量
    var volume: Float = 0.0
    
    // 位相
    var phase: Float = 0.0
    
    // 波形タイプ（矩形波、ノイズなど）
    var waveType: Int = 0
    
    // サンプル生成
    func generateSample() -> Float {
        // 簡易的な実装（実際にはSSG音源の詳細な実装が必要）
        if volume > 0 {
            // 矩形波
            return (sin(phase) > 0 ? 1.0 : -1.0) * volume
        }
        return 0
    }
    
    // パラメータ更新
    mutating func updateParameter(address: UInt8, value: UInt8) {
        // 実際のYM2203の仕様に基づいてパラメータを更新
    }
}
