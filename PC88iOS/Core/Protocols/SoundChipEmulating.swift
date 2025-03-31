//
//  SoundChipEmulating.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import AVFoundation

/// サウンドチップエミュレーションを担当するプロトコル
protocol SoundChipEmulating {
    /// 初期化
    func initialize(sampleRate: Double)
    
    /// レジスタに値を書き込む
    func writeRegister(_ register: UInt8, value: UInt8)
    
    /// レジスタから値を読み込む
    func readRegister(_ register: UInt8) -> UInt8
    
    /// オーディオサンプルを生成
    func generateSamples(into buffer: UnsafeMutablePointer<Float>, count: Int)
    
    /// 音量設定
    func setVolume(_ volume: Float)
    
    /// リセット
    func reset()
    
    /// サウンドチップを開始
    func start()
    
    /// サウンドチップを停止
    func stop()
    
    /// サウンドチップを一時停止
    func pause()
    
    /// サウンドチップを再開
    func resume()
    
    /// サウンドチップの更新
    func update(_ cycles: Int)
}
