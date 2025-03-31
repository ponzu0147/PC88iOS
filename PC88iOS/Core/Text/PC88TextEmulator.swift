//
//  PC88TextEmulator.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import Foundation
import SwiftUI

/// PC-88のテキスト表示をエミュレートするクラス
class PC88TextEmulator {
    /// 画面
    private let screen: PC88Screen
    
    /// 表示タイマー
    private var displayTimer: Timer?
    
    /// 現在の表示位置（行）
    private var currentRow: Int = 0
    
    /// 現在の表示位置（列）
    private var currentColumn: Int = 0
    
    /// 表示する文字列
    private var textToDisplay: String = ""
    
    /// 表示間隔（秒）
    private var displayInterval: TimeInterval = 0.01
    
    /// 表示完了コールバック
    var onDisplayComplete: (() -> Void)?
    
    /// 文字表示コールバック
    var onCharacterDisplayed: ((Int, Int, Character) -> Void)?
    
    /// 初期化
    init(screen: PC88Screen) {
        self.screen = screen
    }
    
    /// テキスト表示を開始
    func displayText(_ text: String, interval: TimeInterval = 0.01) {
        // 現在の表示をクリア
        stopDisplay()
        
        // 画面をクリア
        screen.clear()
        
        // 表示パラメータを設定
        textToDisplay = text
        displayInterval = interval
        currentRow = 0
        currentColumn = 0
        
        // 表示タイマーを開始
        startDisplayTimer()
    }
    
    /// 表示を停止
    func stopDisplay() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    /// 表示タイマーを開始
    private func startDisplayTimer() {
        displayTimer = Timer.scheduledTimer(withTimeInterval: displayInterval, repeats: true) { [weak self] _ in
            self?.displayNextCharacter()
        }
    }
    
    /// 次の文字を表示
    private func displayNextCharacter() {
        guard !textToDisplay.isEmpty else {
            completeDisplay()
            return
        }
        
        // 次の文字を取得
        let index = textToDisplay.startIndex
        let char = textToDisplay[index]
        textToDisplay.remove(at: index)
        
        // 改行処理
        if char == "\n" {
            currentRow += 1
            currentColumn = 0
            
            // 画面の最下行を超えた場合
            if currentRow >= 25 {
                scrollUp()
                currentRow = 24
            }
        } else {
            // 文字を表示
            displayCharacter(char, row: currentRow, column: currentColumn)
            currentColumn += 1
            
            // 行末に達した場合
            if currentColumn >= 80 {
                currentRow += 1
                currentColumn = 0
                
                // 画面の最下行を超えた場合
                if currentRow >= 25 {
                    scrollUp()
                    currentRow = 24
                }
            }
        }
        
        // 表示するテキストがなくなった場合
        if textToDisplay.isEmpty {
            completeDisplay()
        }
    }
    
    /// 文字を表示
    private func displayCharacter(_ char: Character, row: Int, column: Int) {
        // 文字コードに変換
        let charCode = UInt8(char.asciiValue ?? 0x20) // デフォルトはスペース
        
        // テキストVRAMに書き込み
        let offset = row * 80 + column
        screen.writeTextVRAM(offset: offset, value: charCode)
        
        // コールバックを呼び出し
        onCharacterDisplayed?(row, column, char)
    }
    
    /// 画面を上にスクロール
    private func scrollUp() {
        // 1行上にスクロール（単純な実装）
        for row in 0..<24 {
            for column in 0..<80 {
                let srcOffset = (row + 1) * 80 + column
                let destOffset = row * 80 + column
                let value = screen.readTextVRAM(offset: srcOffset)
                screen.writeTextVRAM(offset: destOffset, value: value)
            }
        }
        
        // 最下行をクリア
        for column in 0..<80 {
            let offset = 24 * 80 + column
            screen.writeTextVRAM(offset: offset, value: 0x20) // スペース
        }
    }
    
    /// 表示完了
    private func completeDisplay() {
        stopDisplay()
        onDisplayComplete?()
    }
}

// PC88Screenクラスにメソッドを追加済み
