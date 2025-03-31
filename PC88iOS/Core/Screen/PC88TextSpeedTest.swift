//
//  PC88TextSpeedTest.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import Foundation
import UIKit

/// PC-88のテキスト表示速度をテストするクラス
class PC88TextSpeedTest {
    /// テスト状態
    enum TestState {
        /// 待機中
        case idle
        /// 実行中
        case running
        /// 完了
        case completed
    }
    
    /// 現在のテスト状態
    private(set) var state: TestState = .idle
    
    /// 画面
    private let screen: PC88Screen
    
    /// CPUクロック管理
    private let cpuClock: PC88CPUClock
    
    /// テキスト表示エミュレータ
    private let textDisplayEmulator: PC88TextDisplayEmulator
    
    /// テスト完了時のコールバック
    var onTestCompleted: (() -> Void)?
    
    /// テスト進捗時のコールバック
    var onTestProgress: ((Double) -> Void)?
    
    /// 初期化
    /// - Parameter screen: 表示対象の画面
    init(screen: PC88Screen) {
        self.screen = screen
        self.cpuClock = PC88CPUClock()
        self.textDisplayEmulator = PC88TextDisplayEmulator(screen: screen, cpuClock: cpuClock)
        
        // テキスト表示完了時のコールバック
        textDisplayEmulator.onDisplayCompleted = { [weak self] in
            self?.state = .completed
            self?.onTestCompleted?()
        }
        
        // 文字表示時のコールバック
        textDisplayEmulator.onCharacterDisplayed = { [weak self] _, _, _ in
            guard let self = self else { return }
            
            // 進捗率を計算（0.0〜1.0）
            let progress = Double(self.currentDisplayedCharacters) / Double(self.totalCharacters)
            self.onTestProgress?(progress)
        }
    }
    
    /// 表示済み文字数
    private var currentDisplayedCharacters: Int = 0
    
    /// 総文字数
    private var totalCharacters: Int = 0
    
    /// 4MHzモードでテストを実行
    /// - Parameter text: テスト表示するテキスト
    func runTest4MHz(text: String) {
        runTest(text: text, clockMode: .mode4MHz)
    }
    
    /// 8MHzモードでテストを実行
    /// - Parameter text: テスト表示するテキスト
    func runTest8MHz(text: String) {
        runTest(text: text, clockMode: .mode8MHz)
    }
    
    /// テストを実行
    /// - Parameters:
    ///   - text: テスト表示するテキスト
    ///   - clockMode: クロックモード
    private func runTest(text: String, clockMode: PC88CPUClock.ClockMode) {
        guard state == .idle else { return }
        
        // 画面をクリア
        screen.clear()
        
        // クロックモードを設定
        cpuClock.setClockMode(clockMode)
        
        // テスト状態を初期化
        state = .running
        currentDisplayedCharacters = 0
        totalCharacters = text.count
        
        // テキスト表示を開始
        textDisplayEmulator.startDisplay(text: text, at: 0, column: 0)
    }
    
    /// テストを停止
    func stopTest() {
        textDisplayEmulator.stopDisplay()
        state = .idle
    }
    
    /// 表示速度を設定
    /// - Parameter multiplier: 速度倍率（1.0が標準速度）
    func setDisplaySpeed(multiplier: Double) {
        textDisplayEmulator.setDisplaySpeed(multiplier: multiplier)
    }
    
    /// サンプルテキストを生成
    /// - Returns: サンプルテキスト
    static func generateSampleText() -> String {
        let header = """
        PC-88 テキスト表示速度テスト
        ============================
        このテストは、PC-88の4MHzモードと8MHzモードの
        テキスト表示速度の違いをエミュレートしています。
        
        """
        
        let body = """
        PC-8801は、日本電気（NEC）が1981年に発売した8ビットパーソナルコンピュータです。
        Z80互換CPUを搭載し、N-BASICとN88-BASICの2種類のBASICインタプリタを内蔵していました。
        N-BASICモードではCPUクロックが4MHzで動作し、N88-BASICモードでは8MHzで動作します。
        
        このエミュレータでは、実機と同じ速度でテキスト表示を行うことで、
        より本物に近い体験を提供します。IPLやOSの起動時の表示も、
        実機と同じ速度で行われます。
        
        """
        
        let footer = """
        
        テスト完了！
        """
        
        return header + body + footer
    }
}
