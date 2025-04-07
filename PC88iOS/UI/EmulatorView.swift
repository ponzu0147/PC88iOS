//
//  EmulatorView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import SwiftUI
import CoreGraphics
import Foundation
import Combine
import AVFoundation

// サウンド関連クラスをインポート

// 必要なクラスをインポート

/// エミュレータのメイン画面
struct EmulatorView: View {
    @StateObject private var viewModel = EmulatorViewInternalModel()
    @EnvironmentObject private var appState: EmulatorAppState
    
    // パフォーマンス情報を表示するための状態変数
    @State private var performanceLog: String = ""
    @State private var showPerformanceLog: Bool = false
    
    var body: some View {
        VStack {
            // エミュレータ画面
            if let image = viewModel.screenImage {
                Image(image, scale: 1.0, label: Text("PC-88 Screen"))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                    .overlay(alignment: .topTrailing) {
                        // バックグラウンド時は一時停止表示
                        if appState.isInBackground || viewModel.isPaused {
                            Text(viewModel.isPaused ? "一時停止中" : "バックグラウンド中")
                                .font(.headline)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(12)
                        }
                    }
            } else {
                Text("エミュレータ起動中...")
                    .font(.title)
                    .padding()
            }
            
            // コントロールパネル
            VStack(spacing: 10) {
                // 上段ボタン行
                HStack(spacing: 15) {
                    Button(action: viewModel.resetEmulator) {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20))
                            Text("リセット")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: viewModel.togglePause) {
                        VStack {
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 20))
                            Text(viewModel.isPaused ? "再開" : "一時停止")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: viewModel.loadDisk) {
                        VStack {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 20))
                            Text("ディスク")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                }
                
                // 下段ボタン行
                HStack(spacing: 15) {

                    Button(action: viewModel.playBeepSound) {
                        VStack {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                            Text("ビープ音")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { viewModel.isDebugMode.toggle() }) {
                        VStack {
                            Image(systemName: viewModel.isDebugMode ? "ladybug.fill" : "ladybug")
                                .font(.system(size: 20))
                            Text("デバッグ")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.isDebugMode ? .green : .gray)
                    
                    Button(action: viewModel.showKeyboard) {
                        VStack {
                            Image(systemName: "keyboard")
                                .font(.system(size: 20))
                            Text("キーボード")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: viewModel.cycleFrameRate) {
                        VStack {
                            Image(systemName: "speedometer")
                                .font(.system(size: 20))
                            Text("\(viewModel.currentFPS)fps")
                                .font(.caption)
                        }
                        .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                }
                
                // クロックモード切り替えボタン
                HStack {
                    Text("現在のクロック: \(viewModel.clockFrequency)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: { viewModel.setClockMode(.mode4MHz) }) {
                        Text("4MHz")
                            .frame(minWidth: 80)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(viewModel.clockMode == .mode4MHz)
                    .background(viewModel.clockMode == .mode4MHz ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    
                    Button(action: { viewModel.setClockMode(.mode8MHz) }) {
                        Text("8MHz")
                            .frame(minWidth: 80)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .disabled(viewModel.clockMode == .mode8MHz)
                    .background(viewModel.clockMode == .mode8MHz ? Color.purple.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                
                // 音量調整スライダー
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    
                    Slider(value: $viewModel.volume, in: 0...1, step: 0.01)
                        .accentColor(.blue)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
            .padding()
        }
        .onAppear {
            viewModel.startEmulator()
            viewModel.setupBackgroundHandling()
            
            // パフォーマンス情報の通知を受け取る
            NotificationCenter.default.addObserver(forName: NSNotification.Name("LogUpdateNotification"), object: nil, queue: .main) { notification in
                if let logMessage = notification.object as? String {
                    self.performanceLog = logMessage
                }
            }
        }
        .onDisappear {
            viewModel.stopEmulator()
            viewModel.removeBackgroundHandling()
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            // ドキュメントピッカーを表示
            DocumentPicker { url in
                // 選択されたディスクイメージをロード
                viewModel.loadDiskImageFromDevice(url: url, drive: 0)
            }
        }
    }
}

/// エミュレータのビュー内部モデル
class EmulatorViewInternalModel: ObservableObject {
    // 通知用の購読管理
    private var backgroundObservers: Set<AnyCancellable> = []
    @Published var screenImage: CGImage?
    @Published var isPaused: Bool = false
    @Published var showDocumentPicker = false
    @Published var diskImagePath: String = ""
    @Published var clockMode: PC88CPUClock.ClockMode = .mode4MHz
    @Published var clockFrequency: String = "4MHz"
    @Published var currentFPS: Int = 30
    @Published var isDebugMode: Bool = false
    @Published var volume: Float = 0.5 {
        didSet {
            // 音量変更をPC88BeepSoundに反映
            PC88BeepSound.volume = volume
        }
    }
    
    private var emulatorCore: EmulatorCoreManaging?
    private var timer: Timer?
    
    func startEmulator() {
        PC88Logger.app.debug("エミュレータの初期化を開始します")
        // エミュレータコアの初期化
        emulatorCore = PC88EmulatorCore()
        emulatorCore?.initialize()
        
        // スクリーンテストを表示（必ず最初に表示する）
        if let core = emulatorCore as? PC88EmulatorCore {
            PC88Logger.app.debug("エミュレータコアの初期化が完了しました")
            
            // 初期クロックモードを4MHzに設定
            core.setCPUClockMode(.mode4MHz)
            clockMode = .mode4MHz
            clockFrequency = "4MHz"
            PC88Logger.app.debug("初期クロックモードを4MHzに設定しました")
            
            // 4MHzボタンを押した時と同じ処理を行う
            resetEmulator()
            PC88Logger.app.debug("エミュレータをリセットしました")
            
            // スクリーンテストの表示を強制
            updateScreen()
            PC88Logger.app.debug("スクリーンテストを表示しました")
            
            // エミュレータを開始
            emulatorCore?.start()
            PC88Logger.app.debug("エミュレータを開始しました（初期化直後）")
            
            // 画面を即座に更新
            forceScreenUpdate()
            PC88Logger.app.debug("画面を強制更新しました（開始直後）")
            
            // クロックモードを再設定してリセット（これが重要）
            core.setCPUClockMode(.mode4MHz)
            PC88Logger.app.debug("クロックモードを再設定しました: 4MHz")
            
            // 画面更新のタイミングを調整
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.forceScreenUpdate()
                PC88Logger.app.debug("画面を強制更新しました（初期化後0.1秒）")
                
                // エミュレーションが開始されているか確認
                if self?.emulatorCore?.getState() != .running {
                    self?.emulatorCore?.start()
                    PC88Logger.app.debug("エミュレーションを再度開始しました（初期化後0.1秒）")
                }
            }
            
            // クロックモードの再設定と画面更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                if let self = self, let core = self.emulatorCore as? PC88EmulatorCore {
                    // クロックモードを再設定
                    core.setCPUClockMode(.mode4MHz)
                    PC88Logger.app.debug("クロックモードを再設定しました: 4MHz（初期化後0.3秒）")
                    
                    // エミュレーションが開始されているか確認
                    if self.emulatorCore?.getState() != .running {
                        self.emulatorCore?.start()
                        PC88Logger.app.debug("エミュレーションを再度開始しました（初期化後0.3秒）")
                    }
                    
                    // 画面を強制更新
                    self.forceScreenUpdate()
                    PC88Logger.app.debug("画面を強制更新しました（初期化後0.3秒）")
                }
            }
            
            // 最終確認と画面更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if let self = self {
                    // エミュレーションが開始されているか確認
                    if self.emulatorCore?.getState() != .running {
                        self.emulatorCore?.start() // 再度開始を試みる
                        PC88Logger.app.debug("エミュレーションを再度開始しました（初期化後0.5秒）")
                    } else {
                        PC88Logger.app.debug("エミュレーションは正常に実行中です（初期化後0.5秒）")
                    }
                    
                    // 画面を強制更新
                    self.forceScreenUpdate()
                    PC88Logger.app.debug("画面を強制更新しました（初期化後0.5秒）")
                    
                    // 4MHzモードを再設定して確実にエミュレーションを開始
                    if let core = self.emulatorCore as? PC88EmulatorCore {
                        core.setCPUClockMode(.mode4MHz)
                        PC88Logger.app.debug("最終確認: クロックモードを4MHzに再設定しました")
                    }
                }
            }
        }
        
        // 初期状態ではユーザー設定の音量を適用
        PC88BeepSound.volume = volume
        
        // 画面更新タイマーの開始（初期値は30FPS）
        let initialFPS = 30.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/initialFPS, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        RunLoop.current.add(timer!, forMode: .common) // スクロール中も更新を継続
        
        // 確実に画面が更新されるように複数回の更新を行う
        // 初期化直後に更新
        updateScreen() // 即座に更新
        
        // 強制的に画面を更新するための処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.updateScreen()
            PC88Logger.app.debug("画面を更新しました（初期化直後）")
        }
        
        // 少し待ってから再度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.updateScreen()
            PC88Logger.app.debug("画面を更新しました（初期化後0.2秒）")
        }
        
        // エミュレーションループが確実に開始された後に再度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.updateScreen()
            PC88Logger.app.debug("エミュレーションを開始しました（初期化後0.5秒）")
            
            // 画面イメージが正しく生成されているか確認
            if self.screenImage == nil {
                PC88Logger.app.warning("画面イメージがnilです。強制的に再生成を試みます")
                if let image = self.emulatorCore?.getScreen() {
                    self.screenImage = image
                    PC88Logger.app.debug("画面イメージを強制的に再生成しました")
                }
            }
        }
        
        // さらに遅らせて再度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateScreen()
            PC88Logger.app.debug("画面を更新しました（初期化後1.0秒）")
        }
    }
    
    func stopEmulator() {
        timer?.invalidate()
        timer = nil
        emulatorCore?.stop()
    }
    
    /// バックグラウンド処理のセットアップ
    func setupBackgroundHandling() {
        // 既存の購読をクリア
        backgroundObservers.removeAll()
        
        // バックグラウンド移行時の通知を購読
        NotificationCenter.default.publisher(for: .emulatorPauseNotification)
            .sink { [weak self] _ in
                self?.handleBackgroundTransition()
            }
            .store(in: &backgroundObservers)
        
        // フォアグラウンド復帰時の通知を購読
        NotificationCenter.default.publisher(for: .emulatorResumeNotification)
            .sink { [weak self] _ in
                self?.handleForegroundTransition()
            }
            .store(in: &backgroundObservers)
            
        // 強制画面更新通知を購読
        NotificationCenter.default.publisher(for: Notification.Name("ForceScreenUpdateNotification"))
            .sink { [weak self] _ in
                self?.forceScreenUpdate()
                PC88Logger.app.debug("強制画面更新通知を受信しました")
            }
            .store(in: &backgroundObservers)
        
        // エミュレータ開始通知を購読
        NotificationCenter.default.publisher(for: Notification.Name("EmulatorStartNotification"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // エミュレーションが開始されていない場合は開始する
                if self.emulatorCore?.getState() != .running {
                    PC88Logger.app.debug("エミュレータ開始通知を受信し、エミュレーションを開始します")
                    
                    // クロックモードを4MHzに再設定
                    if let core = self.emulatorCore as? PC88EmulatorCore {
                        core.setCPUClockMode(.mode4MHz)
                        PC88Logger.app.debug("エミュレータ開始通知: クロックモードを4MHzに再設定しました")
                    }
                    
                    // エミュレーション開始
                    self.emulatorCore?.start()
                    
                    // 画面を強制更新
                    self.forceScreenUpdate()
                }
            }
            .store(in: &backgroundObservers)
        
        // 購読設定後に強制的に画面更新を行う
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.forceScreenUpdate()
            PC88Logger.app.debug("通知購読設定後に画面を強制更新しました")
        }
    }
    
    /// バックグラウンド処理の解除
    func removeBackgroundHandling() {
        backgroundObservers.removeAll()
    }
    
    /// バックグラウンド移行時の処理
    private func handleBackgroundTransition() {
        // エミュレータを一時停止
        if !isPaused {
            // タイマーを停止
            timer?.invalidate()
            timer = nil
            
            // エミュレータコアを一時停止
            emulatorCore?.pause()
            
            // オーディオ処理を停止
            if let core = emulatorCore as? PC88EmulatorCore {
                core.muteAudio()
            }
            
            PC88Logger.app.debug("バックグラウンド移行によりエミュレータを一時停止しました")
        }
    }
    
    /// フォアグラウンド復帰時の処理
    private func handleForegroundTransition() {
        // エミュレータを再開（ユーザーが手動で一時停止していない場合のみ）
        if !isPaused {
            // エミュレータコアを再開
            emulatorCore?.resume()
            
            // オーディオ処理を再開
            if let core = emulatorCore as? PC88EmulatorCore {
                core.unmuteAudio()
            }
            
            // タイマーを再開
            let fps = currentFPS > 0 ? Double(currentFPS) : 30.0
            updateTimerInterval(fps: fps)
            
            PC88Logger.app.debug("フォアグラウンド復帰によりエミュレータを再開しました")
        }
    }
    
    /// クロックモードを設定
    func setClockMode(_ mode: PC88CPUClock.ClockMode) {
        clockMode = mode
        clockFrequency = mode == .mode4MHz ? "4MHz" : "8MHz"
        
        // Z80 CPUのクロックモードを設定
        if let core = emulatorCore as? PC88EmulatorCore {
            core.setCPUClockMode(mode)
        }
        
        // クロックモード変更後にリセット
        resetEmulator()
        
        // クロックモード変更後に強制的に画面更新を行う
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateScreen()
        }
        
        // エミュレーションループが確実に開始されるように少し待ってから再度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateScreen()
            PC88Logger.app.debug("クロックモードを変更しました: \(self?.clockFrequency ?? "")")
        }
    }
    
    func resetEmulator() {
        emulatorCore?.reset()
        
        // リセット後に強制的に画面更新を行う
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateScreen()
        }
    }
    
    /// フレームレートを切り替え
    func cycleFrameRate() {
        if let core = emulatorCore as? PC88EmulatorCore {
            core.cycleFrameRate()
            
            // 現在のフレームレートを取得して表示を更新
            let fps = core.getFrameRate()
            currentFPS = Int(fps)
            
            // タイマーの間隔も更新
            updateTimerInterval(fps: fps)
            
            PC88Logger.app.debug("フレームレートを\(self.currentFPS)fpsに切り替えました")
        }
    }
    
    /// タイマーの間隔を更新
    private func updateTimerInterval(fps: Double) {
        // 既存のタイマーを停止
        timer?.invalidate()
        
        // 新しい間隔でタイマーを再開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/fps, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        RunLoop.current.add(timer!, forMode: .common) // スクロール中も更新を継続
    }
    
    func togglePause() {
        if isPaused {
            emulatorCore?.resume()
        } else {
            emulatorCore?.pause()
        }
        isPaused.toggle()
    }
    
    func loadDisk() {
        // ドキュメントピッカーを表示するためのフラグをセット
        showDocumentPicker = true
    }
    
    /// ビープ音でドレミファソラシドを演奏
    func playBeepSound() {
        if let core = emulatorCore as? PC88EmulatorCore {
            core.playBeepScale()
        }
    }
    
    /// 端末からディスクイメージをロード
    func loadDiskImageFromDevice(url: URL, drive: Int) {
        // ディスクイメージのロードはエミュレータコアに委任
        if let core = emulatorCore {
            if core.loadDiskImage(url: url, drive: drive) {
                diskImagePath = url.lastPathComponent
                PC88Logger.disk.debug("ディスクイメージをロードしました: \(url.lastPathComponent)")
                
                // ディスクイメージがロードされたら自動的にリセットを行う
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    PC88Logger.app.debug("エミュレータをリセットします...")
                    
                    // 一時停止中なら再開
                    if self?.isPaused == true {
                        self?.emulatorCore?.resume()
                        self?.isPaused = false
                    }
                    
                    // リセット実行
                    self?.emulatorCore?.reset()
                    
                    // リセット後にメッセージを表示
                    PC88Logger.app.debug("IPLを実行してOSを起動します...")
                }
            } else {
                PC88Logger.disk.error("ディスクイメージのロードに失敗しました: \(url.path)")
            }
        }
    }
    
    func showKeyboard() {
        // カスタムキーボードUIを表示
    }
    
    private func updateScreen() {
        // エミュレータコアから画面イメージを取得
        if let image = emulatorCore?.getScreen() {
            screenImage = image
        } else {
            PC88Logger.app.warning("警告: エミュレータコアから画面イメージを取得できませんでした")
        }
        
        // デバッグモードの設定をPC88TextRendererに反映
        if let core = emulatorCore as? PC88EmulatorCore {
            core.setTextRendererDebugMode(isDebugMode)
            
            // CPUの状態をデバッグ情報として追加
            if isDebugMode {
                let cpuState = core.getCPUState()
                core.addDebugMessage("CPU State: \(cpuState)")
                core.addDebugMessage("PC: 0x\(String(format: "%04X", core.getCPURegisterPC()))")
                core.addDebugMessage("Clock: \(clockFrequency)")
            }
        }
    }
    
    /// 強制的に画面を更新する
    func forceScreenUpdate() {
        // エミュレータが初期化されていない場合は初期化する
        if emulatorCore == nil {
            startEmulator()
            PC88Logger.app.debug("エミュレータを初期化しました")
            return // 初期化後は startEmulator 内で画面更新が行われるため、ここでは終了
        }
        
        // エミュレータが一時停止中なら再開する
        if isPaused {
            emulatorCore?.resume()
            isPaused = false
            PC88Logger.app.debug("エミュレータを再開しました")
        }
        
        // 画面を即座に更新
        updateScreen()
        
        // 画面イメージが取得できない場合は、再度試行
        if screenImage == nil {
            PC88Logger.app.warning("警告: 画面イメージがnilです。強制的に再生成を試みます")
            if let core = emulatorCore as? PC88EmulatorCore {
                // テスト画面を再表示するための代替処理
                // PC88EmulatorCoreのgetScreen()メソッドを利用して内部でテスト画面を表示する
                // これにより、privateプロパティにアクセスする必要がなくなる
                _ = core.getScreen() // これは内部でテスト画面を表示する処理を含む
                
                // 少し待ってから再度取得
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    if let image = self?.emulatorCore?.getScreen() {
                        self?.screenImage = image
                        PC88Logger.app.debug("画面イメージを強制的に再生成しました")
                    }
                }
            }
        } else {
            PC88Logger.app.debug("画面を強制更新しました")
        }
    }
}

// プレビュー用
struct EmulatorView_Previews: PreviewProvider {
    static var previews: some View {
        EmulatorView()
    }
}
