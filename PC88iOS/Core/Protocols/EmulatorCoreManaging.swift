//
//  EmulatorCoreManaging.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import CoreGraphics
import AVFoundation

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
    
    /// 入力イベントの処理
    func handleInputEvent(_ event: InputEvent)
    
    /// 画面の取得
    func getScreen() -> CGImage?
    
    /// エミュレーション速度の設定
    func setEmulationSpeed(_ speed: Float)
    
    /// 現在のエミュレータの状態を取得
    func getState() -> EmulatorState
    
    /// ディスクイメージのロード
    func loadDiskImage(url: URL, drive: Int) -> Bool
    
    /// ビープ音生成機能へのアクセサ
    func getBeepSound() -> Any?
    
    /// ビープ音テスト機能へのアクセサ
    func getBeepTest() -> Any?
}
