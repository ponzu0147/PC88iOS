//
//  ScreenRendering.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import SwiftUI

/// 画面描画を担当するプロトコル
protocol ScreenRendering {
    /// 画面の初期化
    func initialize()
    
    /// テキストVRAMの更新
    func updateTextVRAM(at address: UInt16, value: UInt8)
    
    /// グラフィックVRAMの更新
    func updateGraphicsVRAM(at address: UInt16, value: UInt8, plane: Int)
    
    /// 画面モード設定
    func setScreenMode(_ mode: ScreenMode)
    
    /// パレット設定
    func setPalette(index: Int, color: UInt8)
    
    /// 画面描画
    func render() -> CGImage?
    
    /// 画面のリセット
    func reset()
}

/// 画面モード
enum ScreenMode {
    case text          // テキストモード
    case graphics      // グラフィックモード
    case mixed         // 混合モード
}
