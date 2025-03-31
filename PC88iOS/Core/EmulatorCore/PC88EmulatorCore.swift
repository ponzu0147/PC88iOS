//
//  PC88EmulatorCore.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import CoreGraphics
import UIKit
import SwiftUI

// インポートはプロジェクト全体で共有されているので、明示的なインポートは不要

/// PC-88エミュレータのコア実装
class PC88EmulatorCore: EmulatorCoreManaging {
    // MARK: - プロパティ
    
    /// CPUエミュレーション
    private var cpu: CPUExecuting?
    
    /// メモリアクセス
    private var memory: MemoryAccessing?
    
    /// I/Oアクセス
    private var io: IOAccessing?
    
    /// 画面レンダリング
    private var screen: ScreenRendering?
    
    /// FDCエミュレーション
    private var fdc: FDCEmulating?
    
    /// サウンドチップエミュレーション
    private var soundChip: SoundChipEmulating?
    
    /// エミュレータの状態
    private var state: EmulatorState = .initialized
    
    /// エミュレーション速度（1.0 = 通常速度）
    private var emulationSpeed: Float = 1.0
    
    /// CPUクロック
    private var cpuClock = PC88CPUClock()
    
    /// 現在のCPUクロックモード
    private var currentClockMode: PC88CPUClock.ClockMode = .mode4MHz
    
    /// エミュレーションスレッド
    private var emulationThread: Thread?
    
    /// エミュレーションタイマー
    private var emulationTimer: Timer?
    
    /// 画面イメージ
    private var screenImage: CGImage?
    
    // MARK: - 初期化
    
    init() {
        // 各コンポーネントの初期化は initialize() メソッドで行う
    }
    
    // MARK: - EmulatorCoreManaging プロトコル実装
    
    func initialize() {
        // ROMの読み込み
        if !loadROMs() {
            print("警告: ROMの読み込みに失敗しました")
        }
        
        // リズム音源の読み込み
        if !loadRhythmSounds() {
            print("警告: リズム音源の読み込みに失敗しました")
        }
        
        // メモリの初期化
        memory = PC88Memory()
        
        // I/Oの初期化
        io = PC88IO()
        
        // CPUの初期化
        if let memory = memory, let io = io {
            cpu = Z80CPU(memory: memory, io: io)
            
            // CPUクロックモードを設定
            if let z80 = cpu as? Z80CPU {
                z80.setClockMode(currentClockMode)
            }
        }
        
        // 画面の初期化
        screen = PC88Screen()
        if let pc88Screen = screen as? PC88Screen, let memory = memory, let io = io {
            pc88Screen.connectMemory(memory)
            pc88Screen.connectIO(io)
            
            // フォントデータを設定
            setupFonts(for: pc88Screen)
        }
        
        // FDCの初期化
        fdc = PC88FDC()
        if let fdc = fdc as? PC88FDC, let io = io {
            fdc.connectIO(io)
            
            // IOとFDCを相互接続
            if let io = io as? PC88IO {
                io.connectFDC(fdc)
            }
        }
        
        // サウンドチップの初期化
        soundChip = YM2203Emulator()
        if let soundChip = soundChip as? YM2203Emulator, let io = io as? PC88IO {
            soundChip.initialize(sampleRate: 44100.0)
            io.connectSoundChip(soundChip)
        }
        
        // ROMデータをメモリに転送
        loadROMsToMemory()
        
        // テスト画面を表示
        if let pc88Screen = screen as? PC88Screen {
            pc88Screen.displayTestScreen()
            print("テスト画面を表示しました")
        }
        
        // 状態を初期化済みに変更
        state = .initialized
    }
    
    func start() {
        guard state == .initialized || state == .paused else { return }
        
        // 一時停止中なら再開するだけ
        if state == .paused {
            state = .running
            return
        }
        
        // IPLを実行してOSを起動
        executeIPL()
        
        // エミュレーションスレッドの開始
        emulationThread = Thread { [weak self] in
            self?.emulationLoop()
        }
        emulationThread?.name = "PC88EmulationThread"
        emulationThread?.qualityOfService = .userInteractive
        emulationThread?.start()
        
        // 画面更新タイマーの開始
        // メインスレッドで画面更新を行う
        emulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        
        // サウンドチップを有効化
        if let soundChip = soundChip {
            soundChip.start()
        }
        
        print("PC-88エミュレーションを開始しました")
        
        // 状態を実行中に変更
        state = .running
    }
    
    func stop() {
        guard state == .running || state == .paused else { return }
        
        // エミュレーションスレッドの停止
        emulationThread?.cancel()
        emulationThread = nil
        
        // 画面更新タイマーの停止
        emulationTimer?.invalidate()
        emulationTimer = nil
        
        // サウンドチップの停止
        if let soundChip = soundChip {
            soundChip.stop()
        }
        
        // CPUをリセット状態に戻す
        if let cpu = cpu {
            cpu.reset()
        }
        
        print("PC-88エミュレーションを停止しました")
        
        // 状態を停止に変更
        state = .initialized
    }
    
    func pause() {
        guard state == .running else { return }
        
        // サウンドチップを一時停止
        if let soundChip = soundChip {
            soundChip.pause()
        }
        
        print("PC-88エミュレーションを一時停止しました")
        
        // 状態を一時停止に変更
        state = .paused
    }
    
    func resume() {
        guard state == .paused else { return }
        
        // サウンドチップを再開
        if let soundChip = soundChip {
            soundChip.resume()
        }
        
        print("PC-88エミュレーションを再開しました")
        
        // 状態を実行中に変更
        state = .running
    }
    
    func reset() {
        // CPUのリセット
        cpu?.reset()
        
        // 現在のクロックモードを再設定
        if let z80 = cpu as? Z80CPU {
            z80.setClockMode(currentClockMode)
        }
        
        // メモリのリセット
        if let memory = memory as? PC88Memory {
            memory.reset()
        }
        
        // I/Oのリセット
        if let io = io as? PC88IO {
            io.reset()
        }
        
        // FDCのリセット
        if let fdc = fdc as? PC88FDC {
            fdc.reset()
        }
        
        // サウンドチップのリセット
        if let soundChip = soundChip {
            soundChip.reset()
        }
        
        // ROMデータをメモリに再転送
        loadROMsToMemory()
        
        // IPLを実行してOSを起動
        executeIPL()
        
        // 状態を初期化済みに変更
        state = .initialized
    }
    
    // MARK: - EmulatorCoreManagingプロトコルの実装
    
    /// ディスクイメージのロード
    func loadDiskImage(url: URL, drive: Int) -> Bool {
        guard drive >= 0 && drive < 2 else { return false }
        guard let fdc = fdc else { return false }
        return fdc.loadDiskImage(url: url, drive: drive)
    }
    
    /// 画面の取得
    func getScreen() -> CGImage? {
        return screenImage
    }
    
    /// CPUクロックモードを設定
    func setCPUClockMode(_ mode: PC88CPUClock.ClockMode) {
        // 現在のモードと同じ場合は何もしない
        if currentClockMode == mode {
            return
        }
        
        // 現在の状態を保存
        let wasRunning = state == .running
        
        // 実行中なら一時停止
        if wasRunning {
            pause()
        }
        
        // クロックモードを変更
        currentClockMode = mode
        
        // CPUをリセット
        if let cpu = cpu {
            cpu.reset()
        }
        
        // Z80 CPUのクロックモードを設定
        if let z80 = cpu as? Z80CPU {
            z80.setClockMode(mode)
        }
        
        // エミュレーションループのメトリクスをリセットするためのフラグを設定
        shouldResetMetrics = true
        
        // 元の状態が実行中だった場合は再開
        if wasRunning {
            resume()
        }
        
        print("CPUクロックモードを変更し、リセットしました: \(mode == .mode4MHz ? "4MHz" : "8MHz")")
    }
    
    /// 現在のCPUクロックモードを取得
    func getCurrentClockMode() -> PC88CPUClock.ClockMode {
        return currentClockMode
    }
    
    /// エミュレーション速度の設定
    func setEmulationSpeed(_ speed: Float) {
        emulationSpeed = max(0.1, min(10.0, speed))
    }
    
    /// 現在のエミュレータの状態を取得
    func getState() -> EmulatorState {
        return state
    }
    
    func handleInputEvent(_ event: InputEvent) {
        switch event {
        case .keyDown(let key):
            // キー入力の処理
            if let io = io as? PC88IO {
                io.keyDown(key)
            }
            
        case .keyUp(let key):
            // キー入力の処理
            if let io = io as? PC88IO {
                io.keyUp(key)
            }
            
        case .joystickButton(let button, let isPressed):
            // ジョイスティックボタンの処理
            if let io = io as? PC88IO {
                io.joystickButtonChanged(button, isPressed: isPressed)
            }
            
        case .joystickDirection(let direction, let value):
            // ジョイスティック方向の処理
            if let io = io as? PC88IO {
                io.joystickDirectionChanged(direction, value: value)
            }
            
        case .mouseMove(let x, let y):
            // マウス移動の処理
            if let io = io as? PC88IO {
                io.mouseMoved(x: x, y: y)
            }
            
        case .mouseButton(let button, let isPressed):
            // マウスボタンの処理
            if let io = io as? PC88IO {
                io.mouseButtonChanged(button, isPressed: isPressed)
            }
            
        case .touchBegan(_, _), .touchMoved(_, _), .touchEnded(_, _):
            // タッチ入力はここでは処理しない（UIレイヤーで処理）
            break
        }
    }
    

    
    // MARK: - プライベートメソッド
    
    // メトリクスリセットフラグ
    private var shouldResetMetrics = false
    
    /// エミュレーションのメインループ
    private func emulationLoop() {
        // 定数定義
        let targetFPS: Double = 60.0
        
        // 高精度なタイミング用の変数
        var lastFrameTime = CACurrentMediaTime()
        var frameCounter: UInt = 0
        var cyclesRemainder: Int = 0
        
        // パフォーマンスメトリクス
        var frameTimeAccumulator: Double = 0
        var frameCount: Int = 0
        var lastMetricsTime = CACurrentMediaTime()
        
        // クロックモードに基づくサイクル数を記録
        var currentMode = currentClockMode // 現在のモードを記録
        
        // クロックモードに基づく1フレームあたりのサイクル数を計算
        var baseCyclesPerSecond: Int = currentMode == .mode4MHz ? 4_000_000 : 8_000_000
        var cyclesPerFrame: Int = Int(Double(baseCyclesPerSecond) / targetFPS)
        
        print("クロックモード: \(currentMode), サイクル数/フレーム: \(cyclesPerFrame)")
        
        while !Thread.current.isCancelled {
            // 一時停止中は処理をスキップ
            if state == .paused {
                Thread.sleep(forTimeInterval: 0.01)
                lastFrameTime = CACurrentMediaTime() // 再開時にタイミングをリセット
                continue
            }
            
            // クロックモードが変更された場合、サイクル数を再計算
            if currentMode != currentClockMode || shouldResetMetrics {
                currentMode = currentClockMode
                baseCyclesPerSecond = currentMode == .mode4MHz ? 4_000_000 : 8_000_000
                cyclesPerFrame = Int(Double(baseCyclesPerSecond) / targetFPS)
                
                // メトリクスをリセット
                frameTimeAccumulator = 0
                frameCount = 0
                lastMetricsTime = CACurrentMediaTime()
                lastFrameTime = CACurrentMediaTime()
                cyclesRemainder = 0
                shouldResetMetrics = false
                
                print("クロックモード変更検出: \(currentMode), サイクル数/フレーム: \(cyclesPerFrame)")
            }
            
            // 1フレーム分のCPUサイクルを実行
            let adjustedCycles = Int(Double(cyclesPerFrame) * Double(emulationSpeed)) + cyclesRemainder
            var executedCycles = 0
            
            // サイクル単位で実行し、割り込みを適切に処理
            if let cpu = cpu {
                // 大きなサイクル数を小分けして実行
                let chunkSize = 1000 // 一度に実行するサイクル数
                var remainingCycles = adjustedCycles
                
                while remainingCycles > 0 && !Thread.current.isCancelled && state == .running {
                    let cyclesToExecute = min(remainingCycles, chunkSize)
                    let executed = cpu.executeCycles(cyclesToExecute)
                    executedCycles += executed
                    remainingCycles -= executed
                    
                    // FDCの定期更新
                    if let fdc = fdc {
                        fdc.update(cycles: executed)
                    }
                    
                    // サウンドチップの定期更新
                    if let soundChip = soundChip {
                        soundChip.update(executed)
                    }
                }
            }
            
            // 実行されたサイクル数と目標サイクル数の差を次のフレームに持ち越す
            cyclesRemainder = adjustedCycles - executedCycles
            
            // 垂直同期割り込みの処理（60Hz）
            frameCounter += 1
            if frameCounter % 1 == 0 { // 毎フレーム
                // 垂直同期割り込みを発生させる
                cpu?.requestInterrupt(.int)
                
                // 垂直同期割り込みをIOに通知
                if let io = io as? PC88IO {
                    io.requestInterrupt(from: .vblank)
                }
            }
            
            // パフォーマンスメトリクスの収集
            let now = CACurrentMediaTime()
            let frameTime = now - lastFrameTime
            
            // フレームレート調整（エミュレーション速度を考慮）
            let targetFrameTime = 1.0 / (targetFPS * Double(emulationSpeed))
            if frameTime < targetFrameTime {
                let sleepTime = targetFrameTime - frameTime
                Thread.sleep(forTimeInterval: sleepTime)
            }
            
            // 次のフレームの測定のために時間を更新
            let actualFrameTime = CACurrentMediaTime() - lastFrameTime
            lastFrameTime = CACurrentMediaTime()
            
            // メトリクスに実際のフレーム時間を追加
            frameTimeAccumulator += actualFrameTime
            frameCount += 1
            
            // 5秒ごとにパフォーマンスメトリクスを表示
            if now - lastMetricsTime > 5.0 && frameCount > 0 {
                let avgFrameTime = frameTimeAccumulator / Double(frameCount)
                let fps = 1.0 / avgFrameTime
                let clockMode = currentClockMode == .mode4MHz ? "4MHz" : "8MHz"
                print("[クロックモード: \(clockMode)] FPS: \(String(format: "%.2f", fps)), 平均フレーム時間: \(String(format: "%.2f", avgFrameTime * 1000)) ms, サイクル数/フレーム: \(cyclesPerFrame)")
                
                // メトリクスをリセット
                frameTimeAccumulator = 0
                frameCount = 0
                lastMetricsTime = now
            }
        }
    }
    
    /// 画面の更新
    private func updateScreen() {
        if let screen = screen {
            // 画面の描画処理
            screenImage = screen.render()
            
            // メモリとI/Oの状態を画面に反映
            // 画面の更新処理は、PC88Screenのrender()メソッド内で行われる
        }
    }
    
    // MARK: - ROM関連
    
    /// ROMを読み込む
    private func loadROMs() -> Bool {
        return PC88ROMLoader.shared.loadAllROMs()
    }
    
    /// フォントを設定
    private func setupFonts(for screen: PC88Screen) {
        print("フォントデータの読み込みを開始します...")
        
        // フォントローダーを初期化
        let fontLoaded = PC88FontLoader.shared.loadFonts()
        print("フォントデータの読み込み結果: \(fontLoaded ? "成功" : "失敗")")
        
        // フォントデータを画面に設定
        var successCount = 0
        var failureCount = 0
        
        // テスト用に重要な文字コードを確認
        let testChars: [UInt8] = [0x41, 0x42, 0x43, 0x50, 0x38, 0x2D] // A, B, C, P, 8, -
        
        for testChar in testChars {
            if let fontData = PC88FontLoader.shared.getFontBitmap8x16(charCode: testChar) {
                print("文字コード \(testChar) (\(String(format: "%c", testChar))) のフォントデータ: \(fontData.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))...")
            } else {
                print("文字コード \(testChar) のフォントデータが取得できません")
            }
        }
        
        // すべての文字コードに対してフォントデータを設定
        for charCode in 0..<256 {
            if let fontData = PC88FontLoader.shared.getFontBitmap8x16(charCode: UInt8(charCode)) {
                screen.setFontData(charCode: UInt8(charCode), data: fontData)
                successCount += 1
            } else {
                failureCount += 1
            }
        }
        
        print("フォントデータを画面に設定しました (成功: \(successCount), 失敗: \(failureCount))")
        
        // 画面のフォントデータを確認
        for testChar in testChars {
            // フォントデータを直接PC88FontLoaderから取得して表示
            if let fontData = PC88FontLoader.shared.getFontBitmap8x16(charCode: testChar) {
                print("画面の文字コード \(testChar) (\(String(format: "%c", testChar))) のフォントデータ: \(fontData.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))...")
            }
        }
    }
    
    /// IPLを実行してOSを起動
    private func executeIPL() {
        print("IPLを実行します...")
        
        // CPUが初期化されているか確認
        if cpu == nil {
            print("CPUが初期化されていません")
            return
        }
        
        // Z80 CPUのレジスタを初期化
        if let z80 = cpu as? Z80CPU {
            // PCを0x0000に設定（BIOSのエントリーポイント）
            z80.setPC(0x0000)
            
            // スタックポインタを初期化
            z80.setSP(0xF380) // PC-88の一般的なスタック初期値
            
            // 割り込みを有効化
            z80.setInterruptEnabled(true)
            
            print("Z80 CPUレジスタを初期化しました: PC=0x0000, SP=0xF380")
        }
        
        // I/Oポートの初期化
        if let pc88IO = io as? PC88IO {
            // 割り込みコントローラの初期化
            pc88IO.writePort(0xE4, value: 0x00) // 割り込みコントロールレジスタ
            pc88IO.writePort(0xE6, value: 0x00) // 割り込みマスクレジスタ
            
            // CRTCの初期化（必要に応じて実装）
            print("I/Oポートを初期化しました")
        }
        
        // 画面モードの初期化
        if let pc88Screen = screen as? PC88Screen {
            // テキストモードを設定
            pc88Screen.writeIO(port: 0x30, value: 0x00) // テキストモード有効、グラフィックモード無効
            print("画面モードを初期化しました: テキストモード有効")
        }
        
        // ディスクがセットされているか確認
        if fdc is PC88FDC {
            // ディスクがセットされていればIPLを実行
            print("ディスクからのIPLを実行します")
        } else {
            print("ディスクがセットされていません")
        }
    }
    
    /// ROMデータをメモリに転送
    private func loadROMsToMemory() {
        guard let memory = memory as? PC88Memory else { return }
        
        // N88-BASIC ROM
        if let n88ROM = PC88ROMLoader.shared.loadROM(.n88) {
            memory.loadROM(data: n88ROM, address: 0x0000)
        }
        
        // N88-V2モードROM
        if let n88nROM = PC88ROMLoader.shared.loadROM(.n88n) {
            memory.loadROM(data: n88nROM, address: 0x8000)
        }
        
        // フォントROM
        if let n880ROM = PC88ROMLoader.shared.loadROM(.n880) {
            memory.loadROM(data: n880ROM, address: 0xC000)
        }
        
        // ディスクROM
        if let diskROM = PC88ROMLoader.shared.loadROM(.disk) {
            memory.loadROM(data: diskROM, address: 0xE000)
        }
    }
    
    // MARK: - リズム音源関連
    
    /// リズム音源を読み込む
    private func loadRhythmSounds() -> Bool {
        return PC88RhythmSound.shared.loadRhythmSounds()
    }
}
