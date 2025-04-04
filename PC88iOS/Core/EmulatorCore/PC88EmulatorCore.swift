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
import os.log

// 必要なプロトコルを明示的にインポート
// これにより型の曖昧さを解消
// Swiftではファイルを直接インポートするのではなく、モジュールをインポートします
// この場合、プロトコルは同じモジュール内にあるので、明示的なインポートは必要ありません

/// PC-88エミュレータのコア実装
class PC88EmulatorCore: EmulatorCoreManaging {
    // MARK: - プロパティ
    
    /// エミュレータの状態
    private var state: EmulatorState = .uninitialized
    
    /// ターゲットフレームレート
    private var targetFPS: Double = 30.0 // デフォルトは30fpsに設定
    
    /// FDDブートが有効かどうか
    private var fddBootEnabled: Bool = false
    
    /// CPUエミュレーション
    private var cpu: CPUExecuting?
    
    /// メモリアクセス
    private var memory: PC88iOS.MemoryAccessing?
    
    /// I/Oアクセス
    private var io: IOAccessing?
    
    /// 画面レンダリング
    internal var screen: ScreenRendering?
    
    /// FDCエミュレーション
    private var fdc: FDCEmulating?
    
    /// サウンドチップエミュレーション
    private var soundChip: SoundChipEmulating?
    
    /// 初期モデル用ビープ音生成
    private var beepSound: PC88BeepSound?
    
    /// ビープ音テスト用クラス
    private var beepTest: PC88BeepTest?
    

    

    
    /// ビープ音生成機能へのアクセサ
    func getBeepSound() -> Any? {
        return beepSound
    }
    
    /// ビープ音テスト機能へのアクセサ
    func getBeepTest() -> Any? {
        return beepTest
    }
    
    /// 画面の取得
    func getScreen() -> CGImage? {
        // 画面イメージがnullの場合はテスト画面を表示して再生成を試みる
        if screenImage == nil {
            PC88Logger.screen.warning("PC88EmulatorCore.getScreen() - screenImageがnullです。テスト画面を表示して再生成します")
            
            // テスト画面を表示
            if let pc88Screen = screen as? PC88ScreenBase {
                pc88Screen.displayTestScreen()
                
                // 画面を再描画し、レンダリング結果を取得
                screenImage = pc88Screen.render()
            }
        }
        
        return screenImage
    }
    

    

    
    /// エミュレーション速度（1.0 = 通常速度）
    private var emulationSpeed: Float = 1.0
    
    /// CPUクロック
    private var cpuClock = PC88CPUClock()
    
    /// 現在のCPUクロックモード
    private var currentClockMode: PC88CPUClock.ClockMode = .mode4MHz // デフォルトは4MHz
    

    
    /// ログ表示用タイマー
    private var logTimer: Timer?
    
    /// エミュレーションスレッド
    private var emulationThread: Thread?
    
    /// エミュレーションタイマー
    private var emulationTimer: Timer?
    

    
    /// 画面イメージ
    private var screenImage: CGImage?
    
    /// フレームスキップ設定（0=スキップなし、1=1フレームごとに描画、2=2フレームごとに描画...）
    private var frameSkip: Int = 0
    
    /// 省電力モード
    private var powerSavingMode: Bool = true // デフォルトで省電力モードを有効化
    
    /// フレームカウンタ（フレームスキップ用）
    private var frameCounter: UInt = 0
    
    /// メトリクスリセットフラグ
    private var shouldResetMetrics: Bool = false
    
    // MARK: - 初期化
    
    init() {
        // 各コンポーネントの初期化は initialize() メソッドで行う
    }
    
    // MARK: - EmulatorCoreManaging プロトコル実装
    
    /// エミュレータの初期化を行う
    func initialize() {
        // 各コンポーネントの初期化
        initializeROM()
        initializeMemoryAndIO()
        initializeCPU()
        initializeScreen()
        initializeFDC()
        initializeSoundComponents()
        
        // ROMデータをメモリに転送
        loadROMsToMemory()
        
        // ディスクイメージの読み込みと初期画面表示
        setupInitialDiskAndScreen()
        
        // FDDブートを有効化
        setFDDBootEnabled(true)
        
        // ブートセクタをロード
        loadBootSector()
        
        // 状態を初期化済みに変更
        state = .initialized
    }
    
    /// ROMとリズム音源の初期化
    private func initializeROM() {
        // ROMの読み込み
        if !loadROMs() {
            PC88Logger.core.warning("ROMの読み込みに失敗しました")
        }
        
        // リズム音源の読み込み
        if !loadRhythmSounds() {
            PC88Logger.sound.warning("リズム音源の読み込みに失敗しました")
        }
    }
    
    /// メモリとI/Oの初期化
    private func initializeMemoryAndIO() {
        // メモリの初期化
        memory = PC88Memory()
        
        // I/Oの初期化
        io = PC88IO()
    }
    
    /// CPUの初期化
    private func initializeCPU() {
        guard let memory = memory, let io = io else { return }
        
        cpu = Z80CPU(memory: memory, io: io)
        
        // CPUクロックモードを設定
        if let z80 = cpu as? Z80CPU {
            z80.setClockMode(currentClockMode)
            
            // アイドル検出を有効化（デフォルトで有効）
            z80.setIdleDetectionEnabled(true)
        }
    }
    
    /// 画面の初期化
    private func initializeScreen() {
        screen = PC88ScreenBase()
        
        guard let pc88Screen = screen as? PC88ScreenBase,
              let memory = memory,
              let io = io else { return }
        
        pc88Screen.connectMemory(memory)
        pc88Screen.connectIO(io)
        
        // フォントデータを設定
        setupFonts(for: pc88Screen)
    }
    
    /// FDC（フロッピーディスクコントローラ）の初期化
    private func initializeFDC() {
        fdc = PC88FDC()
        
        guard let fdc = fdc as? PC88FDC,
              let io = io else { return }
        
        fdc.connectIO(io)
        
        // IOとFDCを相互接続
        if let io = io as? PC88IO {
            io.connectFDC(fdc)
        }
    }
    
    /// サウンド関連コンポーネントの初期化
    private func initializeSoundComponents() {
        initializeYM2203SoundChip()
        initializeBeepSound()
    }
    
    /// YM2203サウンドチップの初期化
    private func initializeYM2203SoundChip() {
        soundChip = YM2203Emulator()
        
        guard let soundChip = soundChip as? YM2203Emulator,
              let io = io as? PC88IO else { return }
        
        soundChip.initialize(sampleRate: 44100.0)
        // デフォルトで中品質モードに設定
        soundChip.setQualityMode(SoundQualityMode.medium)
        io.connectSoundChip(soundChip)
    }
    
    /// ビープ音生成の初期化
    private func initializeBeepSound() {
        beepSound = PC88BeepSound()
        
        guard let beepSound = beepSound,
              let io = io as? PC88IO else { return }
        
        beepSound.initialize(sampleRate: 44100.0)
        io.connectBeepSound(beepSound)
        
        // ビープ音テスト機能の初期化
        beepTest = PC88BeepTest(io: io, cpuClock: cpuClock)
    }
    
    /// 初期ディスクイメージの読み込みと初期画面表示
    private func setupInitialDiskAndScreen() {
        // ALPHA-MINI-DOSディスクイメージを読み込む
        loadDefaultDiskImage()
        
        // ディスクに基づいて初期画面を表示するか判断
        shouldDisplayTestScreen()
    }
    
    /// テスト画面を表示するか判断する
    private func shouldDisplayTestScreen() {
        // ALPHA-MINI-DOSディスクが読み込まれているか確認
        if let pc88FDC = fdc as? PC88FDC {
            let diskName = pc88FDC.getDiskName(drive: 0) ?? ""
            if diskName.contains("ALPHA-MINI") {
                // ALPHA-MINI-DOSの場合はテスト画面を表示しない
                PC88Logger.core.debug("ALPHA-MINI-DOSディスクが読み込まれているため、テスト画面をスキップします")
                return
            }
        }
        
        // ディスクがないか、ALPHA-MINI-DOS以外の場合はテスト画面を表示
        if let pc88Screen = screen as? PC88ScreenBase {
            pc88Screen.displayTestScreen()
            PC88Logger.screen.debug("テスト画面を表示しました")
        }
    }
    
    func start() {
        guard state == .initialized || state == .paused else { 
            PC88Logger.core.warning("エミュレータの状態が開始可能ではありません: \(state)")
            return 
        }
        
        // 既存のログタイマーを停止（再開始のため）
        stopLogTimer()
        
        // 一時停止中なら再開するだけ
        if state == .paused {
            changeState(to: .running)
            
            // 一時停止からの再開時にも画面を更新
            updateScreen()
            return
        }
        
        // テストテキストを表示（エミュレーション開始前に実行）
        if let pc88Screen = screen as? PC88ScreenBase {
            pc88Screen.displayTestScreen()
            PC88Logger.screen.debug("テスト画面を表示しました")
            
            // 画面更新を強制的に行う
            updateScreen()
        }
        
        // IPLを実行してOSを起動
        executeIPL()
        PC88Logger.core.debug("IPLを実行しました")
        
        // クロックモードの設定を確認してログ出力
        let frequency = currentClockMode == .mode4MHz ? 4_000_000 : 8_000_000
        let cyclesPerFrame = Int(Double(frequency) / targetFPS)
        let clockModeStr = currentClockMode == .mode4MHz ? "4MHz" : "8MHz"
        
        // 起動直後からパフォーマンス情報を表示
        let startupLog = "[クロックモード: \(clockModeStr)] FPS: \(String(format: "%.2f", targetFPS)), 平均フレーム時間: \(String(format: "%.2f", (1.0/targetFPS) * 1000)) ms, サイクル数/フレーム: \(cyclesPerFrame), 周波数: \(frequency) Hz"
        
        // コンソールにログを出力
        PC88Logger.core.debug("\n\n\(startupLog)\n")
        fflush(stdout)
        
        // システムログにも出力
        NSLog("PC88 Startup: %@", startupLog)
        
        // 既存のログタイマーを停止
        stopLogTimer()
        
        // エミュレーションスレッドの開始
        emulationThread = Thread { [weak self] in
            self?.emulationLoop()
        }
        emulationThread?.name = "PC88EmulationThread"
        emulationThread?.qualityOfService = .userInteractive
        emulationThread?.start()
        
        // 状態を実行中に変更
        state = .running
        PC88Logger.core.debug("エミュレーションを開始しました（PC88EmulatorCore.start()）")
        
        // 定期的にパフォーマンス情報を表示するタイマーを設定（状態変更後に設定）
        startLogTimer()
        
        // 開始後に再度画面を更新
        updateScreen()
        PC88Logger.screen.debug("エミュレーション開始後に画面を更新しました")
        
        // 画面更新タイマーの開始
        updateEmulationTimer()
        
        // サウンドチップを有効化
        if let soundChip = soundChip {
            soundChip.start()
            // サウンド品質を中品質に設定
            soundChip.setQualityMode(SoundQualityMode.medium)
        }
        
        // 初期モデル用ビープ音生成を有効化
        if let beepSound = beepSound {
            beepSound.start()
        }
        
        // 省電力モードを有効化
        setPowerSavingMode(true)
        
        // フレームスキップを設定（2フレームに1回描画）
        setFrameSkip(1)
        
        PC88Logger.core.debug("PC-88エミュレーションを開始しました（最適化設定適用済み）")
        
        // 状態を実行中に変更
        changeState(to: .running)
    }
    
    func stop() {
        guard state == .running || state == .paused else { return }
        
        // エミュレーションスレッドの停止
        // Threadクラスにはcancelメソッドがないため、状態変数を使用してスレッドの終了を管理する
        state = .stopping
        // スレッドが自然に終了するのを待つ
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
        
        // 状態を初期化済みに変更
        changeState(to: .initialized)
    }
    
    /// エミュレータの状態を変更する
    /// - Parameter newState: 新しい状態
    private func changeState(to newState: EmulatorState) {
        // 同じ状態なら何もしない
        if state == newState { return }
        
        let oldState = state
        state = newState
        
        switch (oldState, newState) {
        case (.running, .paused):
            // 実行中から一時停止に変更
            if let soundChip = soundChip {
                soundChip.pause()
            }
            PC88Logger.core.debug("PC-88エミュレーションを一時停止しました")
            
        case (.paused, .running):
            // 一時停止から実行中に変更
            if let soundChip = soundChip {
                soundChip.resume()
            }
            logPerformanceMetrics(forceLog: true)
            startLogTimer()
            PC88Logger.core.debug("PC-88エミュレーションを再開しました")
            
            // ログタイマーの開始を冗長化（信頼性向上のため）
            scheduleLogTimerStarts()
            
        case (_, .initialized):
            // 任意の状態から初期化済みに変更
            if let soundChip = soundChip {
                soundChip.pause()
            }
            PC88Logger.core.debug("PC-88エミュレーションを停止しました")
            
        case (.initialized, .running):
            // 初期化済みから実行中に変更
            PC88Logger.core.debug("PC-88エミュレーションを開始しました")
            
        default:
            break
        }
    }
    
    /// ログタイマーの開始を冗長化する（信頼性向上のため）
    private func scheduleLogTimerStarts() {
        // 別のタイミングでも試行（万が一のための冗長化）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.state == .running else { return }
            if self.logTimer == nil {
                self.startLogTimer()
            }
        }
        
        // さらに別のタイミングでも試行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, self.state == .running else { return }
            if self.logTimer == nil {
                self.startLogTimer()
            }
        }
    }
    
    func pause() {
        guard state == .running else { return }
        changeState(to: .paused)
    }
    
    func resume() {
        guard state == .paused else { return }
        changeState(to: .running)
    }
    
    /// オーディオをミュート（バックグラウンド移行時に呼び出される）
    func muteAudio() {
        // ビープ音をミュート
        if beepSound != nil {
            // 現在の音量を0に設定
            PC88BeepSound.volume = 0.0
        }
        
        // サウンドチップをミュート
        if let soundChip = soundChip {
            soundChip.setVolume(0.0)
        }
        
        PC88Logger.sound.debug("バックグラウンド移行によりオーディオをミュートしました")
    }
    
    /// オーディオのミュート解除（フォアグラウンド復帰時に呼び出される）
    func unmuteAudio() {
        // ビープ音のミュート解除
        if beepSound != nil {
            // 音量を元に戻す（デフォルト値または保存されていた値）
            PC88BeepSound.volume = 0.5 // デフォルト値
        }
        
        // サウンドチップのミュート解除
        if let soundChip = soundChip {
            soundChip.setVolume(1.0) // デフォルト音量
        }
        
        PC88Logger.sound.debug("フォアグラウンド復帰によりオーディオのミュートを解除しました")
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
        guard fdc != nil else { return false }
        return loadDiskImage(from: url, drive: drive, tempFileName: "user_disk.d88", reloadBootSector: fddBootEnabled)
    }

    
    /// CPUクロックモードを設定
    func setCPUClockMode(_ mode: PC88CPUClock.ClockMode) {
        // 現在のモードと同じ場合は何もしない
        if currentClockMode == mode {
            return
        }
        
        PC88Logger.cpu.debug("\nクロックモード変更開始: \(currentClockMode) -> \(mode)\n")
        
        // 現在の状態を保存
        let wasRunning = state == .running
        
        // 実行中なら一時停止
        if wasRunning {
            // 状態を一時停止に変更
            changeState(to: .paused)
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
        
        // 4MHzモードの場合はスリープ時間を調整
        if mode == .mode4MHz {
            cpuClock.adjustSleepTimeForMode4MHz(frameRate: targetFPS)
        }
        
        // ROMを再ロード
        loadROMsToMemory()
        
        // IPLを実行
        executeIPL()
        
        // エミュレーションループのメトリクスをリセットするためのフラグを設定
        shouldResetMetrics = true
        
        // クロックモード変更後の情報を表示（強制的に表示）
        logPerformanceMetrics(forceLog: true)
        
        // 元の状態が実行中だった場合は再開
        if wasRunning {
            // 状態を実行中に変更
            changeState(to: .running)
        }
    }
    
    /// 現在のCPUクロックモードを取得
    func getCurrentClockMode() -> PC88CPUClock.ClockMode {
        return currentClockMode
    }
    
    /// エミュレーション速度の設定
    func setEmulationSpeed(_ speed: Float) {
        emulationSpeed = max(0.1, min(10.0, speed))
        shouldResetMetrics = true
    }
    
    /// フレームスキップを設定
    func setFrameSkip(_ skip: Int) {
        frameSkip = max(0, min(skip, 10)) // 0〜10の範囲に制限
        PC88Logger.core.debug("フレームスキップを設定: \(frameSkip)")
        shouldResetMetrics = true
    }
    
    /// 省電力モードを設定
    func setPowerSavingMode(_ enabled: Bool) {
        powerSavingMode = enabled
        
        // 省電力モードの設定に基づいて各種パラメータを調整
        if powerSavingMode {
            // 省電力モード有効時の設定
            // フレームレートに応じてフレームスキップを設定
            if targetFPS <= 15.0 {
                setFrameSkip(3) // 15fpsの場合は4フレームに1回描画
            } else if targetFPS <= 30.0 {
                setFrameSkip(1) // 30fpsの場合は2フレームに1回描画
            } else {
                setFrameSkip(0) // 60fpsの場合は毎フレーム描画
            }
            
            // Z80 CPUのアイドル検出を有効化し、スリープ時間を設定
            if let z80 = cpu as? Z80CPU {
                z80.setIdleDetectionEnabled(true)
                
                // フレームレートに応じたスリープ時間を設定
                let idleSleepTime = 1.0 / targetFPS * 0.5
                z80.setIdleSleepTime(idleSleepTime)
            }
            
            // サウンドチップの品質を中品質に設定
            if let soundChip = soundChip {
                soundChip.setQualityMode(SoundQualityMode.medium)
            }
            
            PC88Logger.core.debug("省電力モードを有効化しました（フレームレート: \(targetFPS)fps）")
        } else {
            // 省電力モード無効時の設定
            setFrameSkip(0) // すべてのフレームを描画
            
            // Z80 CPUのアイドル検出は維持するが、スリープ時間を短く設定
            if let z80 = cpu as? Z80CPU {
                z80.setIdleSleepTime(0.0001) // 最小値に設定
            }
            
            // サウンドチップの品質を上げる
            if let soundChip = soundChip {
                soundChip.setQualityMode(SoundQualityMode.high)
            }
            
            PC88Logger.core.debug("省電力モードを無効化しました")
        }
    }
    
    /// 現在の省電力モード設定を取得
    func isPowerSavingModeEnabled() -> Bool {
        return powerSavingMode
    }
    
    /// フレームレートを設定
    /// - Parameter fps: 設定するフレームレート（60, 30, 15のいずれか）
    func setFrameRate(_ fps: Double) {
        // 有効な値かチェック
        guard fps == 60.0 || fps == 30.0 || fps == 15.0 else {
            PC88Logger.core.warning("無効なフレームレート値: \(fps)")
            return
        }
        
        // フレームレートを設定
        targetFPS = fps
        
        // メトリクスをリセットしてサイクル数を再計算させる
        shouldResetMetrics = true
        
        // エミュレーションタイマーを更新
        updateEmulationTimer()
        
        // Z80 CPUのアイドル状態でのスリープ時間を調整
        if let z80 = cpu as? Z80CPU {
            // フレームレートが低いほどスリープ時間を長くする
            let idleSleepTime = 1.0 / fps * 0.5 // フレーム間の半分の時間をスリープに充てる
            z80.setIdleSleepTime(idleSleepTime)
            
            // フレームレートに応じてフレームスキップを調整
            if fps <= 15.0 {
                setFrameSkip(3) // 15fpsの場合は4フレームに1回描画
            } else if fps <= 30.0 {
                setFrameSkip(1) // 30fpsの場合は2フレームに1回描画
            } else {
                setFrameSkip(0) // 60fpsの場合は毎フレーム描画
            }
            
            // フレームレートに応じてアイドル検出の閾値を調整
            // フレームレートが低いほどアイドル検出を積極的に行う
            let idleDetectionThreshold = fps <= 30.0 ? 3 : 5
            z80.setIdleDetectionThreshold(idleDetectionThreshold)
        }
        
        // 4MHzモードの場合はスリープ時間を調整
        if cpuClock.currentMode == .mode4MHz {
            cpuClock.adjustSleepTimeForMode4MHz(frameRate: fps)
        }
        
        PC88Logger.core.debug("フレームレートを\(fps)fpsに設定しました")
    }
    
    /// エミュレーションタイマーを更新
    private func updateEmulationTimer() {
        // 既存のタイマーを停止
        emulationTimer?.invalidate()
        
        // 新しい間隔でタイマーを再開始
        let screenUpdateInterval = 1.0/targetFPS
        emulationTimer = Timer.scheduledTimer(withTimeInterval: screenUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        RunLoop.current.add(emulationTimer!, forMode: .common)
    }
    
    /// 現在のフレームレートを取得
    func getFrameRate() -> Double {
        return targetFPS
    }
    
    /// フレームレートを切り替え
    /// 60fps -> 30fps -> 15fps -> 60fpsの順に切り替わる
    func cycleFrameRate() {
        switch targetFPS {
        case 60.0:
            setFrameRate(30.0)
        case 30.0:
            setFrameRate(15.0)
        default: // 15fpsまたはその他
            setFrameRate(60.0)
        }
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
    
    /// ブートセクタをメモリにロード
    private func loadBootSector() {
        guard let pc88FDC = fdc as? PC88FDC,
              let pc88Memory = memory as? PC88Memory else {
            PC88Logger.core.error("FDCまたはメモリが初期化されていません")
            return
        }
        
        // 必要な前提条件を確認
        if !isBootSectorLoadable(pc88FDC: pc88FDC) {
            return
        }
        
        // ディスクイメージの種類を確認
        let diskName = pc88FDC.getDiskName(drive: 0) ?? ""
        let isAlphaMiniDos = diskName.contains("ALPHA-MINI")
        
        if isAlphaMiniDos {
            loadAlphaMiniDosBootSector(pc88FDC: pc88FDC, pc88Memory: pc88Memory)
        } else {
            loadStandardBootSector(pc88FDC: pc88FDC, pc88Memory: pc88Memory)
        }
    }
    
    /// ブートセクタがロード可能か確認する
    private func isBootSectorLoadable(pc88FDC: PC88FDC) -> Bool {
        // FDDブートが有効でない場合は何もしない
        if !fddBootEnabled {
            PC88Logger.disk.warning("FDDブートが無効です")
            return false
        }
        
        // ドライブ1にディスクイメージがセットされているか確認
        if !pc88FDC.hasDiskImage(drive: 0) {
            PC88Logger.disk.warning("ドライブ1にディスクイメージがセットされていません")
            return false
        }
        
        return true
    }
    
    /// ALPHA-MINI-DOSのブートセクタをロードする
    private func loadAlphaMiniDosBootSector(pc88FDC: PC88FDC, pc88Memory: PC88Memory) {
        PC88Logger.disk.debug("ALPHA-MINI-DOSを検出しました。特別処理を実行します。")
        
        // D88DiskImageを取得
        guard let d88DiskImage = pc88FDC.getDiskImage(drive: 0) as? D88DiskImage else {
            PC88Logger.disk.error("ALPHA-MINI-DOSのディスクイメージの取得に失敗しました")
            return
        }
        
        // CPUを取得
        guard let z80CPU = cpu as? Z80CPU else {
            PC88Logger.cpu.error("CPUが初期化されていません")
            return
        }
        
        // AlphaMiniDosIntegrationを使用してロード
        let integration = PC88AlphaMiniDosIntegration(memory: pc88Memory, cpu: z80CPU)
        
        if integration.loadAlphaMiniDos(from: d88DiskImage) {
            PC88Logger.disk.debug("ALPHA-MINI-DOSのロードに成功しました")
        } else {
            PC88Logger.disk.error("ALPHA-MINI-DOSのロードに失敗しました")
            
            // 失敗した場合は従来の方法で再試行
            if let iplData = d88DiskImage.readSector(track: 0, sector: 1) {
                // メモリの0xC000にIPLをロード (256バイト)
                loadDataToMemory(data: iplData, startAddress: 0xC000, pc88Memory: pc88Memory)
                PC88Logger.disk.debug("ALPHA-MINI-DOSのIPLをメモリにロードしました: 0xC000-0xC0FF")
                
                // OS部分もロード
                loadAlphaMiniDosOs()
            } else {
                PC88Logger.disk.error("ALPHA-MINI-DOSのIPLの読み込みに失敗しました")
            }
        }
    }
    
    /// 標準的なブートセクタをロードする
    private func loadStandardBootSector(pc88FDC: PC88FDC, pc88Memory: PC88Memory) {
        PC88Logger.disk.debug("IPLをロード中: ドライブ1、トラック0、セクタ1")
        
        // ブートセクタを読み込む (トラック0、セクタ1)
        if let sectorData = pc88FDC.readSector(drive: 0, track: 0, sector: 1) {
            // メモリの0x8000にIPLをロード (256バイト)
            loadDataToMemory(data: sectorData, startAddress: 0x8000, pc88Memory: pc88Memory)
            PC88Logger.disk.debug("IPLをメモリにロードしました: 0x8000-0x80FF")
        } else {
            PC88Logger.disk.error("IPLの読み込みに失敗しました")
        }
    }
    
    /// データをメモリにロードするヘルパーメソッド
    private func loadDataToMemory(data: [UInt8], startAddress: UInt16, pc88Memory: PC88Memory) {
        for (offset, byte) in data.enumerated() {
            pc88Memory.writeByte(byte, at: startAddress + UInt16(offset))
        }
    }
    
    /// ALPHA-MINI-DOSのOS部分をロードする
    private func loadAlphaMiniDosOs() {
        guard let pc88FDC = fdc as? PC88FDC,
              let pc88Memory = memory as? PC88Memory else {
            PC88Logger.core.error("FDCまたはメモリが初期化されていません")
            return
        }
        
        PC88Logger.disk.debug("ALPHA-MINI-DOSのOS部分をロードします")
        
        // OS領域をクリア
        clearOsMemoryRegion(pc88Memory: pc88Memory)
        
        // OSセクタをロード
        loadOsSectors(pc88FDC: pc88FDC, pc88Memory: pc88Memory)
    }
    
    /// OS領域のメモリをクリアする
    private func clearOsMemoryRegion(pc88Memory: PC88Memory) {
        let osStartAddress: UInt16 = 0xD000
        let osClearSize: Int = 0x3000 // 12KBクリア
        
        PC88Logger.disk.debug("OS領域をクリアします: 0xD000-0xFFFF")
        
        // UInt16の範囲を超えないように注意
        for i in 0..<min(osClearSize, 0x3000) {
            // 0xD000から0xFFFFまでの範囲のみクリア
            if osStartAddress + UInt16(i) <= 0xFFFF {
                let address = osStartAddress + UInt16(i)
                pc88Memory.writeByte(0x00, at: address)
            } else {
                break // UInt16の範囲を超えた場合は終了
            }
        }
    }
    
    /// OSセクタをメモリにロードする
    private func loadOsSectors(pc88FDC: PC88FDC, pc88Memory: PC88Memory) {
        // D88DiskImageからOSセクタを取得
        if let d88DiskImage = pc88FDC.getDiskImage(drive: 0) as? D88DiskImage,
           let osSectors = d88DiskImage.loadOsSectors() {
            
            PC88Logger.disk.debug("ALPHA-MINI-DOSのOS部分をロードします: \(osSectors.count)セクタ")
            
            // OS部分を0xD000からロード
            _ = loadOsSectorsToMemory(osSectors: osSectors, pc88Memory: pc88Memory)
            
            // メモリ内容を確認してログに出力
            verifyOsMemoryContents(pc88Memory: pc88Memory)
        } else {
            PC88Logger.disk.error("ALPHA-MINI-DOSのOSセクタの読み込みに失敗しました")
        }
    }
    
    /// OSセクタをメモリにロードし、最終オフセットを返す
    private func loadOsSectorsToMemory(osSectors: [[UInt8]], pc88Memory: PC88Memory) -> UInt16 {
        var memoryOffset: UInt16 = 0xD000
        var totalBytesLoaded = 0
        
        for (index, sectorData) in osSectors.enumerated() {
            // セクタデータのチェック
            let validData = sectorData.contains { $0 != 0 && $0 != 0xFF }
            
            // 各セクタを連続したメモリ領域にロード
            loadDataToMemory(data: sectorData, startAddress: memoryOffset, pc88Memory: pc88Memory)
            
            totalBytesLoaded += sectorData.count
            
            // 次のセクタ用にオフセットを更新
            let previousOffset = memoryOffset
            memoryOffset += UInt16(sectorData.count)
            
            // 最初の数セクタのみログ表示
            if index < 5 {
                logSectorLoad(index: index, sectorData: sectorData, startAddress: previousOffset, endAddress: memoryOffset - 1, validData: validData)
            }
        }
        
        PC88Logger.disk.debug("ALPHA-MINI-DOSのOS部分のロードが完了しました: 0xD000-0x\(String(format: "%04X", memoryOffset - 1)) (合計: \(totalBytesLoaded) バイト)")
        
        return memoryOffset
    }
    
    /// セクタロードの情報をログに出力
    private func logSectorLoad(index: Int, sectorData: [UInt8], startAddress: UInt16, endAddress: UInt16, validData: Bool) {
        PC88Logger.disk.debug("  OSセクタ\(index+1)をメモリにロードしました: 0x\(String(format: "%04X", startAddress))-0x\(String(format: "%04X", endAddress)) (有効データ: \(validData ? "あり" : "なし"))")
        
        // 最初のセクタの内容を表示
        if index == 0 {
            PC88Logger.disk.debug("  最初のセクタの内容 (16バイト):")
            for i in 0..<min(16, sectorData.count) {
                PC88Logger.disk.debug(String(format: "%02X ", sectorData[i]), terminator: "")
            }
            PC88Logger.disk.debug("")
        }
    }
    
    /// メモリ内容を確認してログに出力
    private func verifyOsMemoryContents(pc88Memory: PC88Memory) {
        // メモリに正しく書き込まれたか確認
        PC88Logger.core.debug("OSメモリ内容確認 (0xD000-0xD00F):")
        var memoryContent = ""
        for i in 0..<16 {
            let byte = pc88Memory.readByte(at: 0xD000 + UInt16(i))
            memoryContent += String(format: "%02X ", byte)
        }
        PC88Logger.core.debug(memoryContent)
        
        // ジャンプテーブルを確認
        PC88Logger.core.debug("OSジャンプテーブル確認 (0xD100-0xD10F):")
        memoryContent = ""
        for i in 0..<16 {
            let byte = pc88Memory.readByte(at: 0xD100 + UInt16(i))
            memoryContent += String(format: "%02X ", byte)
        }
        PC88Logger.core.debug(memoryContent)
    }
    
    /// ディスクイメージをロードする共通メソッド
    /// - Parameters:
    ///   - url: ディスクイメージのURL
    ///   - drive: ドライブ番号（0または1）
    ///   - tempFileName: 一時ファイル名
    /// - Returns: 成功したかどうか
    private func loadDiskImageInternal(from url: URL, drive: Int, tempFileName: String) -> Bool {
        guard let pc88FDC = fdc as? PC88FDC else { 
            PC88Logger.core.error("FDCが初期化されていません")
            return false 
        }
        
        // ディスクイメージデータを読み込む
        guard let diskImage = createDiskImageFromURL(url: url, tempFileName: tempFileName) else {
            return false
        }
        
        // ディスクイメージをFDCにセット
        pc88FDC.setDiskImage(diskImage, drive: drive)
        PC88Logger.disk.debug("ディスクイメージをドライブ\(drive + 1)に読み込みました: \(url.lastPathComponent)")
        
        // ALPHA-MINI-DOSかどうかをログに出力
        if let d88DiskImage = diskImage as? D88DiskImage, d88DiskImage.isAlphaMiniDos() {
            PC88Logger.disk.debug("ALPHA-MINI-DOSディスクイメージを検出しました: \(url.lastPathComponent)")
        }
        
        return true
    }
    
    /// URLからディスクイメージを作成する
    /// - Parameters:
    ///   - url: ディスクイメージのURL
    ///   - tempFileName: 一時ファイル名
    /// - Returns: 作成されたディスクイメージ、失敗した場合はnil
    private func createDiskImageFromURL(url: URL, tempFileName: String) -> DiskImageAccessing? {
        do {
            // ディスクイメージデータを読み込む
            let diskImageData = try Data(contentsOf: url)
            let diskImage = D88DiskImage()
            
            // 一時ファイルに保存してからロード
            let tempURL = createTempFileURL(fileName: tempFileName)
            try diskImageData.write(to: tempURL)
            
            // ディスクイメージをロード
            if diskImage.loadDiskImage(from: tempURL) {
                // 一時ファイルを削除
                cleanupTempFile(at: tempURL)
                return diskImage
            } else {
                PC88Logger.disk.error("ディスクイメージのフォーマットが無効です: \(url.lastPathComponent)")
                cleanupTempFile(at: tempURL)
                return nil
            }
        } catch {
            PC88Logger.disk.error("ディスクイメージの読み込みエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 一時ファイルのURLを作成する
    /// - Parameter fileName: ファイル名
    /// - Returns: 一時ファイルのURL
    private func createTempFileURL(fileName: String) -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    /// 一時ファイルを削除する
    /// - Parameter url: 削除する一時ファイルのURL
    private func cleanupTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// デフォルトのALPHA-MINI-DOSディスクイメージをロードする
    private func loadDefaultDiskImage() {
        // リソースからALPHA-MINI-DOSディスクイメージを取得
        guard let diskImageURL = Bundle.main.url(forResource: "ALPHA-MINI-DOS", withExtension: "d88") else {
            PC88Logger.disk.warning("ALPHA-MINI-DOSディスクイメージが見つかりません")
            return
        }
        
        // ディスクイメージをロードし、結果をログに出力
        let result = loadDiskImage(url: diskImageURL, drive: 0)
        
        if result {
            print("ALPHA-MINI-DOSディスクイメージを正常に読み込みました")
        } else {
            print("ALPHA-MINI-DOSディスクイメージの読み込みに失敗しました")
        }
    }
    
    /// 外部からディスクイメージをロード（内部使用のみ）
    private func loadDiskImage(from url: URL, drive: Int, tempFileName: String, reloadBootSector: Bool) -> Bool {
        // ディスクイメージをロード
        let result = loadDiskImageInternal(from: url, drive: drive, tempFileName: tempFileName)
        
        // 成功した場合、ドライブ0にロードされた場合はブートセクタを再ロード
        if result && reloadBootSector && drive == 0 {
            print("ディスクイメージがロードされたため、ブートセクタを再ロードします")
            loadBootSector()
        }
        
        return result
    }
    

    
    /// FDDブートの有効/無効を設定
    func setFDDBootEnabled(_ enabled: Bool) {
        fddBootEnabled = enabled
        print("FDDブートを\(enabled ? "有効" : "無効")にしました")
        
        // 設定が変更された場合、ブートセクタを再ロード
        if enabled {
            loadBootSector()
        }
    }
    
    /// FDDブートが有効かどうかを取得
    func isFDDBootEnabled() -> Bool {
        return fddBootEnabled
    }
    
    /// ログタイマーを停止
    private func stopLogTimer() {
        // タイマーが存在する場合のみ停止する
        if let timer = logTimer {
            timer.invalidate()
            logTimer = nil
        }
    }
    
    /// ログ表示用のタイマーを開始
    private func startLogTimer() {
        // 既存のタイマーがあれば何もしない
        if logTimer != nil {
            return
        }
        
        // 即時にログを表示
        logPerformanceMetrics(forceLog: true)
        
        // タイマーを作成し、5秒ごとにログを表示
        logTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 実行中か一時停止中に関わらずログを表示
            self.logPerformanceMetrics(forceLog: true)
        }
    }
    

    
    /// CPUサイクルを実行し、周辺デバイスを更新する
    private func executeCPUCycles(adjustedCycles: Int) -> Int {
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
                
                updatePeripherals(executedCycles: executed)
            }
        }
        
        return executedCycles
    }
    
    /// 周辺デバイスを更新する
    private func updatePeripherals(executedCycles: Int) {
        // FDCの定期更新 - クロックの影響を受けない
        // 実行されたサイクル数をそのまま渡す
        if let fdc = fdc {
            fdc.update(cycles: executedCycles)
        }
        
        // サウンドチップの定期更新 - クロックの影響を受けない
        // YM2203/YM2608は独自のクロックで動作するため
        if let soundChip = soundChip {
            soundChip.update(executedCycles)
        }
        
        // ディスプレイ更新はクロックの影響を受けない
        // 60Hzの垂直同期はクロックモードに関わらず一定
    }
    
    /// 垂直同期割り込みを発生させる
    private func generateVBlankInterrupt() {
        // クロックモードに関わらず常に60Hzで発生
        frameCounter += 1
        
        // 垂直同期割り込みを発生させる
        cpu?.requestInterrupt(.int)
        
        // 垂直同期割り込みをIOに通知
        if let io = io as? PC88IO {
            io.requestInterrupt(from: .vblank)
        }
    }
    
    /// フレームレートを調整し、パフォーマンスメトリクスを収集する
    private func adjustFrameRate(lastFrameTime: inout CFTimeInterval,
                               frameTimeAccumulator: inout Double,
                               frameCount: inout Int,
                               lastMetricsTime: inout CFTimeInterval) {
        // パフォーマンスメトリクスの収集
        let now = CACurrentMediaTime()
        let frameTime = now - lastFrameTime
        
        // フレームレート調整（エミュレーション速度を考慮）
        let targetFrameTime = 1.0 / (targetFPS * Double(emulationSpeed))
        if frameTime < targetFrameTime {
            let sleepTime = targetFrameTime - frameTime
            
            // 省電力モードの場合は、さらに長めにスリープして消費電力を抑える
            let adjustedSleepTime = powerSavingMode ? sleepTime * 1.1 : sleepTime
            Thread.sleep(forTimeInterval: adjustedSleepTime)
        }
        
        // 次のフレームの測定のために時間を更新
        let actualFrameTime = CACurrentMediaTime() - lastFrameTime
        lastFrameTime = CACurrentMediaTime()
        
        // メトリクスに実際のフレーム時間を追加
        frameTimeAccumulator += actualFrameTime
        frameCount += 1
        
        // メトリクスの計算のみを行い、ログ出力は別のタイマーで実行
        if now - lastMetricsTime > 5.0 && frameCount > 0 {
            // メトリクスをリセット
            frameTimeAccumulator = 0
            frameCount = 0
            lastMetricsTime = now
        }
    }
    
    /// クロックモード変更時の設定を更新
    private func updateClockModeSettings(currentMode: inout PC88CPUClock.ClockMode,
                                        baseCyclesPerSecond: inout Int,
                                        cyclesPerFrame: inout Int,
                                        frameTimeAccumulator: inout Double,
                                        frameCount: inout Int,
                                        lastMetricsTime: inout CFTimeInterval,
                                        lastFrameTime: inout CFTimeInterval,
                                        cyclesRemainder: inout Int) {
        currentMode = currentClockMode
        
        // PC88CPUClockから現在の周波数を取得
        if let z80 = cpu as? Z80CPU {
            baseCyclesPerSecond = z80.cpuClock.currentFrequency
        } else {
            // フォールバック値
            baseCyclesPerSecond = currentMode == .mode4MHz ? 4_000_000 : 8_000_000
        }
        
        cyclesPerFrame = Int(Double(baseCyclesPerSecond) / targetFPS)
        
        // メトリクスをリセット
        frameTimeAccumulator = 0
        frameCount = 0
        lastMetricsTime = CACurrentMediaTime()
        lastFrameTime = CACurrentMediaTime()
        cyclesRemainder = 0
        shouldResetMetrics = false
        
        PC88Logger.core.debug("クロックモード変更検出: \(currentMode), 周波数: \(baseCyclesPerSecond) Hz, サイクル数/フレーム: \(cyclesPerFrame)")
    }
    
    /// パフォーマンスメトリクスをログに出力
    private func logPerformanceMetrics(forceLog: Bool = false) {
        
        // ログタイマーがない場合は再作成を試みる
        if logTimer == nil {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.logTimer == nil else { return }
                self.startLogTimer()
            }
        }
        
        // 現在のクロックモードに基づく値を計算
        let clockMode = currentClockMode == .mode4MHz ? "4MHz" : "8MHz"
        let baseCyclesPerSecond = currentClockMode == .mode4MHz ? 4_000_000 : 8_000_000
        let cyclesPerFrame = Int(Double(baseCyclesPerSecond) / targetFPS)
        
        // パフォーマンス情報を生成
        let perfLog = "[クロックモード: \(clockMode)] FPS: \(String(format: "%.2f", targetFPS)), 平均フレーム時間: \(String(format: "%.2f", (1.0/targetFPS) * 1000)) ms, サイクル数/フレーム: \(cyclesPerFrame), 周波数: \(baseCyclesPerSecond) Hz"
        
        // コンソールにログを出力
        PC88Logger.core.debug("\n\n\(perfLog)\n\n")
        
        // ログ出力を確実に行うために強制的にフラッシュ
        fflush(stdout)
    }
    
    /// エミュレーションのメインループ
    private func emulationLoop() {
        // クラスプロパティのtargetFPSを使用
        
        // 高精度なタイミング用の変数
        var lastFrameTime = CACurrentMediaTime()
        frameCounter = 0 // クラスのプロパティを使用
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
        
        PC88Logger.core.debug("クロックモード: \(currentMode), サイクル数/フレーム: \(cyclesPerFrame)")
        
        while !Thread.current.isCancelled {
            // 一時停止中は処理をスキップ
            if state == .paused {
                Thread.sleep(forTimeInterval: 0.01)
                lastFrameTime = CACurrentMediaTime() // 再開時にタイミングをリセット
                continue
            }
            
            // クロックモードが変更された場合、サイクル数を再計算
            if currentMode != currentClockMode || shouldResetMetrics {
                updateClockModeSettings(currentMode: &currentMode, 
                                        baseCyclesPerSecond: &baseCyclesPerSecond, 
                                        cyclesPerFrame: &cyclesPerFrame, 
                                        frameTimeAccumulator: &frameTimeAccumulator, 
                                        frameCount: &frameCount, 
                                        lastMetricsTime: &lastMetricsTime, 
                                        lastFrameTime: &lastFrameTime, 
                                        cyclesRemainder: &cyclesRemainder)
            }
            
            // 1フレーム分のCPUサイクルを実行
            // フレームレートに応じて処理量を調整
            let frameRateAdjustment = 60.0 / targetFPS
            let adjustedCycles = Int(Double(cyclesPerFrame) * Double(emulationSpeed) / frameRateAdjustment) + cyclesRemainder
            let executedCycles = executeCPUCycles(adjustedCycles: adjustedCycles)
            
            // 実行されたサイクル数と目標サイクル数の差を次のフレームに持ち越す
            cyclesRemainder = adjustedCycles - executedCycles
            
            // 垂直同期割り込みの処理（60Hz）
            generateVBlankInterrupt()
            
            // パフォーマンスメトリクスの収集とフレームレート調整
            adjustFrameRate(lastFrameTime: &lastFrameTime, 
                           frameTimeAccumulator: &frameTimeAccumulator, 
                           frameCount: &frameCount, 
                           lastMetricsTime: &lastMetricsTime)
        }
    }
    
    /// 画面の更新
    internal func updateScreen() {
        // フレームスキップの処理
        // frameCounterはemulationLoopで更新される
        if frameSkip > 0 && (frameCounter % UInt(frameSkip + 1) != 0) {
            // フレームスキップ中は描画をスキップ
            return
        }
        
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
    
    /// ビープ音でドレミファソラシドを演奏
    /// 8MHzモードでは各音0.25秒、4MHzモードでは各音0.5秒ずつ鳴らす
    func playBeepScale() {
        // ビープ音テストが初期化されているか確認
        guard let beepTest = beepTest else {
            PC88Logger.sound.error("ビープ音テストが初期化されていません")
            return
        }
        
        // ビープ音が初期化されているか確認
        guard beepSound != nil else {
            PC88Logger.sound.error("ビープ音生成機能が初期化されていません")
            return
        }
        
        // すでに再生中なら何もしない
        if beepTest.isPlaying {
            PC88Logger.sound.debug("すでにビープ音が再生中です")
            return
        }
        
        // 現在の状態を保存
        let wasRunning = state == .running
        
        // エミュレーションを一時停止
        if wasRunning {
            pause()
        }
        
        // CPUクロックモードを確認して表示
        let clockModeText = cpuClock.currentMode == .mode4MHz ? "4MHz" : "8MHz"
        PC88Logger.cpu.debug("現在のクロックモード: \(clockModeText)")
        
        // クロックモードが正しく設定されているか確認
        if let z80 = cpu as? Z80CPU {
            let cpuMode = z80.getClockMode()
            if cpuMode != cpuClock.currentMode {
                PC88Logger.cpu.warning("警告: CPUクロックモードが不一致しています。修正します。")
                cpuClock.setClockMode(cpuMode)
            }
        }
        
        // ビープ音を有効化
        if let beepSound = beepSound {
            beepSound.start()
        }
        
        // 別スレッドで演奏を実行
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // ドレミファソラシドを演奏
            beepTest.playScale()
            
            // メインスレッドに戻ってエミュレーションを再開
            DispatchQueue.main.async {
                // 元の状態が実行中だった場合は再開
                if wasRunning {
                    self?.resume()
                }
            }
        }
        
        PC88Logger.sound.debug("ビープ音の演奏を開始しました")
    }
    
    /// フォントを設定
    private func setupFonts(for screen: PC88ScreenBase) {
        PC88Logger.core.debug("フォントデータの読み込みを開始します...")
        
        // フォントローダーを初期化
        let fontLoaded = PC88FontLoader.shared.loadFonts()
        PC88Logger.core.debug("フォントデータの読み込み結果: \(fontLoaded ? "成功" : "失敗")")
        
        // フォントデータを画面に設定
        var successCount = 0
        var failureCount = 0
        
        // テスト用に重要な文字コードを確認
        let testChars: [UInt8] = [0x41, 0x42, 0x43, 0x50, 0x38, 0x2D] // A, B, C, P, 8, -
        
        for testChar in testChars {
            if let fontData = PC88FontLoader.shared.getFontBitmap8x16(charCode: testChar) {
                PC88Logger.core.debug("文字コード \(testChar) (\(String(format: "%c", testChar))) のフォントデータ: \(fontData.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))...")
            } else {
                PC88Logger.core.error("文字コード \(testChar) のフォントデータが取得できません")
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
        
        PC88Logger.core.debug("フォントデータを画面に設定しました (成功: \(successCount), 失敗: \(failureCount))")
        
        // 画面のフォントデータを確認
        for testChar in testChars {
            // フォントデータを直接PC88FontLoaderから取得して表示
            if let fontData = PC88FontLoader.shared.getFontBitmap8x16(charCode: testChar) {
                PC88Logger.core.debug("画面の文字コード \(testChar) (\(String(format: "%c", testChar))) のフォントデータ: \(fontData.prefix(4).map { String(format: "%02X", $0) }.joined(separator: " "))...")
            }
        }
    }
    
    /// IPLを実行してOSを起動
    private func executeIPL() {
        PC88Logger.core.debug("IPLを実行します...")
        
        // CPUが初期化されているか確認
        if cpu == nil {
            PC88Logger.cpu.error("CPUが初期化されていません")
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
            
            PC88Logger.cpu.debug("Z80 CPUレジスタを初期化しました: PC=0x0000, SP=0xF380")
        }
        
        // I/Oポートの初期化
        if let pc88IO = io as? PC88IO {
            // 割り込みコントローラの初期化
            pc88IO.writePort(0xE4, value: 0x00) // 割り込みコントロールレジスタ
            pc88IO.writePort(0xE6, value: 0x00) // 割り込みマスクレジスタ
            
            // CRTCの初期化（必要に応じて実装）
            PC88Logger.io.debug("I/Oポートを初期化しました")
        }
        
        // 画面モードの初期化
        if let pc88Screen = screen as? PC88ScreenBase {
            // テキストモードを設定
            pc88Screen.writeIO(port: 0x30, value: 0x00) // テキストモード有効、グラフィックモード無効
            PC88Logger.screen.debug("画面モードを初期化しました: テキストモード有効")
        }
        
        // ディスクがセットされているか確認
        if let pc88FDC = fdc as? PC88FDC, pc88FDC.hasDiskImage(drive: 0) {
            // ディスクがセットされていればIPLを実行
            PC88Logger.disk.debug("ディスクからのIPLを実行します")
            
            // ブートセクタをメモリにロード (通常0x8000にロード)
            loadBootSector()
            
            // ディスクイメージの種類を確認
            let diskName = pc88FDC.getDiskName(drive: 0) ?? ""
            let isAlphaMiniDos = diskName.contains("ALPHA-MINI")
            
            if let z80 = cpu as? Z80CPU {
                if isAlphaMiniDos {
                    // ALPHA-MINI-DOSの場合は特別処理
                    PC88Logger.disk.debug("ALPHA-MINI-DOSの実行を開始します")
                    
                    // PC88AlphaMiniDosIntegrationを使用して初期化
                    if let pc88Memory = memory as? PC88Memory,
                       let pc88FDC = fdc as? PC88FDC,
                       let d88DiskImage = pc88FDC.getDiskImage(drive: 0) as? D88DiskImage {
                        
                        let integration = PC88AlphaMiniDosIntegration(memory: pc88Memory, cpu: z80)
                        
                        if integration.loadAlphaMiniDos(from: d88DiskImage) {
                            PC88Logger.disk.debug("ALPHA-MINI-DOSの初期化に成功しました")
                        } else {
                            PC88Logger.disk.warning("ALPHA-MINI-DOSの初期化に失敗しました。従来の方法で続行します")
                            
                            // 従来の方法で初期化
                            // Z80 CPUの初期状態を設定
                            z80.setPC(0xC000)  // プログラムカウンタをIPLの先頭に設定
                            z80.setRegister(.af, value: 0x0000)  // Aレジスタとフラグをクリア
                            z80.setRegister(.bc, value: 0x0000)  // BCレジスタをクリア
                            z80.setRegister(.de, value: 0x0000)  // DEレジスタをクリア
                            z80.setRegister(.hl, value: 0x0000)  // HLレジスタをクリア
                            z80.setRegister(.ix, value: 0x0000)  // IXレジスタをクリア
                            z80.setRegister(.iy, value: 0x0000)  // IYレジスタをクリア
                            z80.setSP(0xF000)  // スタックポインタを設定
                            
                            // 割り込みを無効化
                            z80.disableInterrupts()  // 割り込み無効化
                        }
                    } else {
                        PC88Logger.disk.error("ALPHA-MINI-DOSの初期化に必要なコンポーネントが取得できませんでした")
                        
                        // 従来の方法で初期化
                        z80.setPC(0xC000)  // プログラムカウンタをIPLの先頭に設定
                        z80.setSP(0xF000)  // スタックポインタを設定
                        z80.disableInterrupts()  // 割り込み無効化
                    }
                    
                    PC88Logger.cpu.debug("Z80 CPUの初期状態を設定しました: PC=0xC000, SP=0xF000")
                    
                    // メモリの内容を確認
                    if let pc88Memory = memory as? PC88Memory {
                        PC88Logger.memory.debug("IPLメモリ内容確認 (0xC000-0xC00F):")
                        for i in 0..<16 {
                            let byte = pc88Memory.readByte(at: 0xC000 + UInt16(i))
                            PC88Logger.memory.debug(String(format: "%02X ", byte), terminator: "")
                        }
                        PC88Logger.memory.debug("")
                    }
                    
                    // 命令トレースを有効化
                    z80.enableInstructionTrace()
                    PC88Logger.cpu.debug("ALPHA-MINI-DOSの実行をトレースします")
                    
                    // 画面を強制的に更新
                    if let pc88Screen = screen as? PC88ScreenBase {
                        // テスト画面を強制的に消す
                        pc88Screen.forceClearScreen()
                        
                        // テキストモードを再設定
                        pc88Screen.writeIO(port: 0x30, value: 0x00) // テキストモード有効
                        pc88Screen.writeIO(port: 0x31, value: 0x00) // 色指定モード
                        pc88Screen.writeIO(port: 0x32, value: 0x00) // グラフィックモード無効
                        pc88Screen.writeIO(port: 0x33, value: 0x00) // スクロール無効
                        
                        // デバッグ用に文字を表示
                        let testMessage = "ALPHA-MINI-DOS 1.3 (デバッグモード)"
                        for (i, char) in testMessage.utf8.enumerated() {
                            if i < 80 { // 1行目のみ
                                pc88Screen.writeTextVRAM(address: UInt16(i), value: char)
                            }
                        }
                        
                        // 2行目に追加情報
                        let infoMessage = "PC=C000h SP=F000h"
                        for (i, char) in infoMessage.utf8.enumerated() {
                            if i < 80 { // 2行目
                                pc88Screen.writeTextVRAM(address: UInt16(80 + i), value: char)
                            }
                        }
                        
                        // 画面を更新
                        updateScreen()
                        PC88Logger.screen.debug("ALPHA-MINI-DOS用に画面を更新しました")
                    }
                } else {
                    // 通常のディスクイメージは0x8000に設定
                    z80.setPC(0x8000)
                    PC88Logger.cpu.debug("ブートセクタから実行を開始します: PC=0x8000")
                }
            }
        } else {
            PC88Logger.disk.warning("ディスクがセットされていないか、読み込みに失敗しました")
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
