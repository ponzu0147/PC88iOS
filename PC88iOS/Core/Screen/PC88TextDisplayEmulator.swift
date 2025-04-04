//
//  PC88TextDisplayEmulator.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import Foundation

/// PC-88のテキスト表示速度をエミュレートするクラス
class PC88TextDisplayEmulator {
    /// テキスト表示状態
    enum DisplayState {
        /// 待機中
        case idle
        /// 表示中
        case displaying
        /// 一時停止中
        case paused
    }
    
    /// 現在の表示状態
    private(set) var state: DisplayState = .idle
    
    /// CPUクロック管理
    private let cpuClock: PC88CPUClock
    
    /// 表示対象の画面
    private weak var screen: PC88ScreenBase?
    
    /// 表示するテキスト
    private var displayText: String = ""
    
    /// 表示開始位置（行）
    private var startLine: Int = 0
    
    /// 表示開始位置（列）
    private var startColumn: Int = 0
    
    /// 現在の表示位置（行）
    private var currentLine: Int = 0
    
    /// 現在の表示位置（列）
    private var currentColumn: Int = 0
    
    /// 次の文字を表示するタイミング（DispatchTimeInterval）
    private var nextCharacterTime: DispatchTime = .now()
    
    /// 表示タイマー
    private var displayTimer: DispatchSourceTimer?
    
    /// 表示キュー
    private let displayQueue = DispatchQueue(label: "com.pc88ios.textdisplay", qos: .userInteractive)
    
    /// 表示完了時のコールバック
    var onDisplayCompleted: (() -> Void)?
    
    /// 文字表示時のコールバック
    var onCharacterDisplayed: ((Character, Int, Int) -> Void)?
    
    /// 初期化
    /// - Parameters:
    ///   - screen: 表示対象の画面
    ///   - cpuClock: CPUクロック管理
    init(screen: PC88ScreenBase, cpuClock: PC88CPUClock) {
        self.screen = screen
        self.cpuClock = cpuClock
    }
    
    deinit {
        stopDisplay()
    }
    
    /// テキスト表示を開始
    /// - Parameters:
    ///   - text: 表示するテキスト
    ///   - line: 表示開始行
    ///   - column: 表示開始列
    func startDisplay(text: String, at line: Int, column: Int) {
        guard state == .idle || state == .paused else { return }
        
        displayText = text
        startLine = line
        startColumn = column
        currentLine = line
        currentColumn = column
        
        if state == .idle {
            state = .displaying
            setupDisplayTimer()
        } else {
            // 一時停止中の場合は再開
            state = .displaying
            resumeDisplay()
        }
    }
    
    /// テキスト表示を停止
    func stopDisplay() {
        displayTimer?.cancel()
        displayTimer = nil
        state = .idle
    }
    
    /// テキスト表示を一時停止
    func pauseDisplay() {
        guard state == .displaying else { return }
        
        displayTimer?.suspend()
        state = .paused
    }
    
    /// テキスト表示を再開
    func resumeDisplay() {
        guard state == .paused else { return }
        
        displayTimer?.resume()
        state = .displaying
    }
    
    /// 表示タイマーの設定
    private func setupDisplayTimer() {
        displayTimer?.cancel()
        
        let timer = DispatchSource.makeTimerSource(queue: displayQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.processNextCharacter()
        }
        
        displayTimer = timer
        timer.resume()
    }
    
    /// 次の文字を処理
    private func processNextCharacter() {
        guard state == .displaying, let screen = screen else { return }
        
        let now = DispatchTime.now()
        if now < nextCharacterTime {
            // まだ表示時間に達していない
            return
        }
        
        // 表示するテキストがなくなった場合は終了
        if displayText.isEmpty {
            stopDisplay()
            DispatchQueue.main.async {
                self.onDisplayCompleted?()
            }
            return
        }
        
        // 次の文字を取得
        let nextChar = displayText.removeFirst()
        
        // 改行の処理
        if nextChar == "\n" {
            currentLine += 1
            currentColumn = startColumn
            
            // 次の文字表示までの時間を設定（改行は通常の文字より時間がかかる）
            let displayTime = cpuClock.calculateTextDisplayTime(forCharacters: 2)
            nextCharacterTime = now + .microseconds(Int(displayTime))
            return
        }
        
        // 文字を画面に表示
        let charCode = UInt8(nextChar.asciiValue ?? 0x20) // スペースのデフォルト値
        screen.writeCharacter(charCode, atLine: currentLine, column: currentColumn)
        
        // コールバックを呼び出し
        DispatchQueue.main.async {
            self.onCharacterDisplayed?(nextChar, self.currentLine, self.currentColumn)
        }
        
        // 次の列に移動
        currentColumn += 1
        
        // 次の文字表示までの時間を設定
        let displayTime = cpuClock.calculateTextDisplayTime(forCharacters: 1)
        nextCharacterTime = now + .microseconds(Int(displayTime))
    }
    
    /// 表示速度を設定
    /// - Parameter multiplier: 速度倍率（1.0が標準速度）
    func setDisplaySpeed(multiplier: Double) {
        cpuClock.speedMultiplier = multiplier
    }
}
