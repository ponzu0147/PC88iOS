//
//  EmulatorCoreManaging.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//  Updated by 越川将人 on 2025/04/05.
//

import Foundation
import CoreGraphics
import AVFoundation

/// PC-88エミュレータコア全体の管理を担当するプロトコル
/// 
/// このプロトコルは、PC-88エミュレータの主要な機能とライフサイクルを定義します。
/// エミュレータの初期化、実行、停止などの基本操作と、各コンポーネント（CPU、メモリ、ディスク、画面、音声）
/// 間の連携を管理します。また、エラーハンドリングとイベント通知の機構も提供します。
protocol EmulatorCoreManaging: EmulatorEventEmitting, EmulatorLogging, EmulatorMetricsCollecting {
    
    // MARK: - ライフサイクル管理
    
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
    
    /// 現在のエミュレータの状態を取得
    func getState() -> EmulatorState
    
    // MARK: - 入出力管理
    
    /// 入力イベントの処理
    /// - Parameter event: 処理する入力イベント
    func handleInputEvent(_ event: InputEvent)
    
    /// 画面の取得
    /// - Returns: 現在の画面イメージ。取得できない場合はnil
    func getScreen() -> CGImage?
    
    /// エミュレーション速度の設定
    /// - Parameter speed: エミュレーション速度（1.0が標準速度）
    func setEmulationSpeed(_ speed: Float)
    
    // MARK: - ディスク管理
    
    /// ディスクイメージのロード
    /// - Parameters:
    ///   - url: ディスクイメージのURL
    ///   - drive: ドライブ番号（0または1）
    /// - Returns: ロードが成功したかどうか
    func loadDiskImage(url: URL, drive: Int) -> Bool
    
    // MARK: - デバッグとテスト
    
    /// ビープ音生成機能へのアクセサ
    func getBeepSound() -> Any?
    
    /// ビープ音テスト機能へのアクセサ
    func getBeepTest() -> Any?
    
    // MARK: - フレームレート管理
    
    /// フレームレートの設定
    /// - Parameter fps: 設定するフレームレート
    func setFrameRate(_ fps: Double)
    
    // MARK: - ALPHA-MINI-DOS管理
    
    /// ALPHA-MINI-DOSディスクからの起動を設定
    /// - Parameter enabled: 有効にするかどうか
    func setFDDBootEnabled(_ enabled: Bool)
}

// 注意: 拡張プロトコルの定義は別ファイルに移動します
// これは将来の拡張のためのプレースホルダーです
