//
//  EmulatorCoreManaging.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import CoreGraphics

/// エミュレータコア全体の管理を担当するプロトコル
protocol EmulatorCoreManaging {
    /// エミュレータの初期化
    func initialize()
    
    /// エミュレーションの開始
    func start()
    
    /// エミュレーションの停止
    func stop()
    
    /// エミュレーションの一時停止
    func pause()
    
    /// エミュレーションの再開
    func resume()
    
    /// エミュレーションのリセット
    func reset()
    
    /// ディスクイメージのロード
    func loadDiskImage(url: URL, drive: Int) -> Bool
    
    /// 入力イベントの処理
    func handleInputEvent(_ event: InputEvent)
    
    /// 画面の取得
    func getScreen() -> CGImage?
    
    /// エミュレーション速度の設定
    func setEmulationSpeed(_ speed: Float)
    
    /// 現在のエミュレータの状態を取得
    func getState() -> EmulatorState
}
