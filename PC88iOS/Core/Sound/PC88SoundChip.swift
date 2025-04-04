//
//  PC88SoundChip.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import AVFoundation

/// PC-88のサウンドチップ実装
class PC88SoundChip: SoundChipEmulating {
    // MARK: - 定数
    
    /// PSGレジスタ数
    private let registerCount = 16
    
    /// チャンネル数
    private let channelCount = 3
    
    /// ノイズチャンネル
    private let noiseChannel = 3
    
    /// エンベロープ周期
    private let envelopePeriod = 16
    
    // MARK: - プロパティ
    
    /// レジスタ値
    private var registers = [UInt8](repeating: 0, count: 16)
    
    /// チャンネル周波数
    private var frequency = [UInt16](repeating: 0, count: 3)
    
    /// チャンネル音量
    private var volume = [UInt8](repeating: 0, count: 3)
    
    /// ノイズ周波数
    private var noiseFrequency: UInt8 = 0
    
    /// エンベロープ形状
    private var envelopeShape: UInt8 = 0
    
    /// エンベロープ周期
    private var envelopePeriodValue: UInt16 = 0
    
    /// サンプルレート
    private var sampleRate: Double = 44100.0
    
    /// マスター音量
    private var masterVolume: Float = 1.0
    
    /// オーディオエンジン
    private var audioEngine: AVAudioEngine?
    
    /// オーディオソースノード
    private var audioNode: AVAudioSourceNode?
    
    // MARK: - 内部メソッド
    
    /// オーディオセットアップ
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        // オーディオノードの作成
        audioNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            if let self = self {
                // サンプルを生成するバッファを作成
                var samples = [Float](repeating: 0.0, count: Int(frameCount))
                self.generateSamples(into: &samples, count: Int(frameCount))
                
                // 生成したサンプルをオーディオバッファにコピー
                for i in 0..<Int(frameCount) {
                    for buffer in ablPointer {
                        let bufferPointer = UnsafeMutableBufferPointer<Float>(
                            start: buffer.mData?.assumingMemoryBound(to: Float.self),
                            count: Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                        )
                        if i < bufferPointer.count {
                            bufferPointer[i] = samples[i]
                        }
                    }
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
            PC88Logger.sound.error("オーディオエンジンの開始に失敗: \(error)")
        }
    }
    
    /// サウンドチップを開始
    func start() {
        // オーディオエンジンが実行中でなければ開始
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            startAudio()
        }
    }
    
    /// サウンドチップを停止
    func stop() {
        // オーディオエンジンを停止
        audioEngine?.stop()
        reset()
    }
    
    /// サウンドチップを一時停止
    func pause() {
        // オーディオエンジンを一時停止
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.pause()
        }
    }
    
    /// サウンドチップを再開
    func resume() {
        // オーディオエンジンが一時停止中なら再開
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            startAudio()
        }
    }
    
    /// サウンドチップの更新
    func update(_ cycles: Int) {
        // サイクル数に基づいた更新処理
        // 実際の実装では、タイミングに基づいてエンベロープや周波数を更新
    }
    
    /// 現在の品質モード
    private var qualityMode: SoundQualityMode = .medium
    
    /// 品質モードを設定
    /// - Parameter mode: 設定する品質モード
    func setQualityMode(_ mode: SoundQualityMode) {
        qualityMode = mode
        
        // 品質モードに応じた設定を適用
        switch mode {
        case .high:
            // 高品質モードの設定
            // 高いサンプリングレートや正確な波形生成を設定
            if let audioEngine = audioEngine, audioEngine.isRunning {
                // 必要に応じてオーディオエンジンを再設定
                audioEngine.stop()
                setupAudio()
                startAudio()
            }
            PC88Logger.sound.debug("サウンド品質モードを高品質に設定しました")
            
        case .medium:
            // 中品質モードの設定
            // バランスの取れた設定
            if let audioEngine = audioEngine, audioEngine.isRunning {
                // 必要に応じてオーディオエンジンを再設定
                audioEngine.stop()
                setupAudio()
                startAudio()
            }
            PC88Logger.sound.debug("サウンド品質モードを中品質に設定しました")
            
        case .low:
            // 低品質モードの設定
            // 低いサンプリングレートや簡略化された波形生成を設定
            if let audioEngine = audioEngine, audioEngine.isRunning {
                // 必要に応じてオーディオエンジンを再設定
                audioEngine.stop()
                setupAudio()
                startAudio()
            }
            PC88Logger.sound.debug("サウンド品質モードを低品質に設定しました")
        }
    }
    
    /// 現在の品質モードを取得
    func getQualityMode() -> SoundQualityMode {
        return qualityMode
    }
    
    /// チャンネルカウンター
    private var counter = [Double](repeating: 0, count: 3)
    
    /// ノイズカウンター
    private var noiseCounter: Double = 0
    
    /// ノイズシフトレジスタ
    private var noiseShiftRegister: UInt16 = 1
    
    /// エンベロープカウンター
    private var envelopeCounter: Double = 0
    
    /// エンベロープステップ
    private var envelopeStep: Int = 0
    
    /// エンベロープ値
    private var envelopeValue: UInt8 = 0
    
    // MARK: - 初期化
    
    init() {
        reset()
    }
    
    // MARK: - SoundChipEmulating プロトコル実装
    
    func initialize(sampleRate: Double) {
        self.sampleRate = sampleRate
        reset()
        setupAudio()
    }
    
    func writeRegister(_ register: UInt8, value: UInt8) {
        let reg = Int(register & 0x0F)
        registers[reg] = value
        
        switch reg {
        case 0, 1: // チャンネルA周波数（下位8ビット、上位4ビット）
            frequency[0] = UInt16(registers[0]) | (UInt16(registers[1] & 0x0F) << 8)
            
        case 2, 3: // チャンネルB周波数（下位8ビット、上位4ビット）
            frequency[1] = UInt16(registers[2]) | (UInt16(registers[3] & 0x0F) << 8)
            
        case 4, 5: // チャンネルC周波数（下位8ビット、上位4ビット）
            frequency[2] = UInt16(registers[4]) | (UInt16(registers[5] & 0x0F) << 8)
            
        case 6: // ノイズ周波数
            noiseFrequency = value & 0x1F
            
        case 7: // ミキサー/IOポート
            // ミキサー設定は後で処理
            break
            
        case 8, 9, 10: // チャンネルA、B、C音量
            let channel = reg - 8
            volume[channel] = value & 0x1F
            
        case 11, 12: // エンベロープ周期（下位8ビット、上位8ビット）
            envelopePeriodValue = UInt16(registers[11]) | (UInt16(registers[12]) << 8)
            
        case 13: // エンベロープ形状
            envelopeShape = value & 0x0F
            envelopeStep = 0
            envelopeCounter = 0
            updateEnvelopeValue()
            
        default:
            break
        }
    }
    
    func readRegister(_ register: UInt8) -> UInt8 {
        let reg = Int(register & 0x0F)
        return registers[reg]
    }
    
    func generateSamples(into buffer: UnsafeMutablePointer<Float>, count: Int) {
        // バッファをクリア
        for i in 0..<count {
            buffer[i] = 0.0
        }
        
        // 各チャンネルのサンプルを生成
        for i in 0..<count {
            var sample: Float = 0.0
            
            // トーンチャンネル
            for ch in 0..<channelCount {
                if isToneEnabled(channel: ch) {
                    // 周波数カウンターを更新
                    counter[ch] += 1.0
                    
                    // 周波数が0の場合は最大値として扱う
                    let freq = frequency[ch] == 0 ? 1024 : Double(frequency[ch])
                    
                    // 周波数に応じて波形を生成
                    let period = sampleRate / (125000.0 / freq)
                    
                    if counter[ch] >= period {
                        counter[ch] -= period
                    }
                    
                    // 矩形波生成
                    let wave: Float = counter[ch] < period / 2 ? 1.0 : -1.0
                    
                    // 音量適用
                    let vol = getChannelVolume(channel: ch)
                    sample += wave * vol
                }
            }
            
            // ノイズチャンネル
            if isNoiseEnabled() {
                // ノイズカウンターを更新
                noiseCounter += 1.0
                
                // ノイズ周波数が0の場合は最大値として扱う
                let noiseFreq = noiseFrequency == 0 ? 32 : Double(noiseFrequency)
                
                // 周波数に応じてノイズを生成
                let noisePeriod = sampleRate / (125000.0 / noiseFreq / 16.0)
                
                if noiseCounter >= noisePeriod {
                    noiseCounter -= noisePeriod
                    
                    // ノイズシフトレジスタを更新
                    let bit0 = (noiseShiftRegister & 0x0001) != 0
                    let bit3 = (noiseShiftRegister & 0x0008) != 0
                    let newBit = bit0 != bit3
                    noiseShiftRegister = (noiseShiftRegister >> 1) | (newBit ? 0x8000 : 0)
                }
                
                // ノイズ波形
                let noiseWave: Float = (noiseShiftRegister & 0x0001) != 0 ? 0.5 : -0.5
                
                // ノイズ音量適用（チャンネルAの音量を使用）
                let noiseVol = getChannelVolume(channel: 0)
                sample += noiseWave * noiseVol
            }
            
            // エンベロープ更新
            updateEnvelope()
            
            // マスター音量適用
            sample *= masterVolume
            
            // クリッピング
            sample = max(-1.0, min(1.0, sample))
            
            // バッファに書き込み
            buffer[i] = sample
        }
    }
    
    func setVolume(_ volume: Float) {
        masterVolume = max(0.0, min(1.0, volume))
    }
    
    func reset() {
        // レジスタリセット
        registers = [UInt8](repeating: 0, count: registerCount)
        
        // 周波数リセット
        frequency = [UInt16](repeating: 0, count: channelCount)
        
        // 音量リセット
        volume = [UInt8](repeating: 0, count: channelCount)
        
        // カウンターリセット
        counter = [Double](repeating: 0, count: channelCount)
        noiseCounter = 0
        
        // ノイズリセット
        noiseFrequency = 0
        noiseShiftRegister = 1
        
        // エンベロープリセット
        envelopeShape = 0
        envelopePeriodValue = 0
        envelopeCounter = 0
        envelopeStep = 0
        envelopeValue = 0
    }
    
    // MARK: - プライベートメソッド
    
    /// トーンが有効かどうか
    private func isToneEnabled(channel: Int) -> Bool {
        let mixer = registers[7]
        return (mixer & (1 << channel)) == 0
    }
    
    /// ノイズが有効かどうか
    private func isNoiseEnabled() -> Bool {
        let mixer = registers[7]
        return (mixer & (1 << (3 + 0))) == 0  // チャンネルAのノイズ
    }
    
    /// チャンネルの音量を取得
    private func getChannelVolume(channel: Int) -> Float {
        if (volume[channel] & 0x10) != 0 {
            // エンベロープ使用
            return Float(envelopeValue) / 15.0
        } else {
            // 固定音量
            return Float(volume[channel] & 0x0F) / 15.0
        }
    }
    
    /// エンベロープを更新
    private func updateEnvelope() {
        if envelopePeriodValue == 0 {
            return
        }
        
        envelopeCounter += 1.0
        
        // エンベロープ周期
        let period = sampleRate / (125000.0 / Double(envelopePeriodValue) / 16.0)
        
        if envelopeCounter >= period {
            envelopeCounter -= period
            envelopeStep = (envelopeStep + 1) % envelopePeriod
            updateEnvelopeValue()
        }
    }
    
    /// エンベロープ値を更新
    private func updateEnvelopeValue() {
        // エンベロープ形状に応じて値を設定
        switch envelopeShape {
        case 0, 1, 2, 3: // \\\\
            envelopeValue = 15 - UInt8(envelopeStep % 16)
            
        case 4, 5, 6, 7: // ////
            envelopeValue = UInt8(envelopeStep % 16)
            
        case 8, 9, 10, 11: // \\\\____
            envelopeValue = envelopeStep < 16 ? 15 - UInt8(envelopeStep) : 0
            
        case 12, 13, 14, 15: // ////----
            envelopeValue = envelopeStep < 16 ? UInt8(envelopeStep) : 15
            
        default:
            envelopeValue = 0
        }
    }
}
