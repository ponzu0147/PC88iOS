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

// 必要なクラスをインポート

/// エミュレータのメイン画面
struct EmulatorView: View {
    @StateObject private var viewModel = EmulatorViewInternalModel()
    @EnvironmentObject private var appState: EmulatorAppState
    
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
                            Image(systemName: "opticaldisc")
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
    @Published var currentFPS: Int = 60
    @Published var volume: Float = 0.5 {
        didSet {
            // 音量変更をPC88BeepSoundに反映
            PC88BeepSound.volume = volume
        }
    }
    
    private var emulatorCore: EmulatorCoreManaging?
    private var timer: Timer?
    
    func startEmulator() {
        // エミュレータコアの初期化
        emulatorCore = PC88EmulatorCore()
        emulatorCore?.initialize()
        
        // 初期音量を設定
        PC88BeepSound.volume = volume
        
        // スクリーンテストを表示（必ず最初に表示する）
        if let core = emulatorCore as? PC88EmulatorCore {
            // スクリーンテストの表示を強制
            // PC88EmulatorCoreの初期化メソッド内ですでにテスト画面が表示されている
            // 画面更新を強制的に行う
            updateScreen()
            print("スクリーンテストを表示しました")
            
            // 初期クロックモードを4MHzに設定
            core.setCPUClockMode(.mode4MHz)
            clockMode = .mode4MHz
            clockFrequency = "4MHz"
        }
        
        // エミュレータを開始
        emulatorCore?.start()
        
        // 画面更新タイマーの開始（初期値は60FPS）
        let initialFPS = 60.0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/initialFPS, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        RunLoop.current.add(timer!, forMode: .common) // スクロール中も更新を継続
        
        // 初期化後に強制的に画面更新を行う（タイマーが動く前に確実に更新）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateScreen()
        }
        
        // エミュレーションループが確実に開始されるように少し待ってから再度更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateScreen()
            print("エミュレーションを開始しました")
        }
    }
    
    func stopEmulator() {
        timer?.invalidate()
        timer = nil
        emulatorCore?.stop()
    }
    
    /// バックグラウンド処理のセットアップ
    func setupBackgroundHandling() {
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
            
            print("バックグラウンド移行によりエミュレータを一時停止しました")
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
            let fps = currentFPS > 0 ? Double(currentFPS) : 60.0
            updateTimerInterval(fps: fps)
            
            print("フォアグラウンド復帰によりエミュレータを再開しました")
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
            print("クロックモードを変更しました: " + (self?.clockFrequency ?? ""))
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
            
            print("フレームレートを\(currentFPS)fpsに切り替えました")
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
                print("ディスクイメージをロードしました: \(url.lastPathComponent)")
                
                // ディスクイメージがロードされたら自動的にリセットを行う
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    print("エミュレータをリセットします...")
                    
                    // 一時停止中なら再開
                    if self?.isPaused == true {
                        self?.emulatorCore?.resume()
                        self?.isPaused = false
                    }
                    
                    // リセット実行
                    self?.emulatorCore?.reset()
                    
                    // リセット後にメッセージを表示
                    print("IPLを実行してOSを起動します...")
                }
            } else {
                print("ディスクイメージのロードに失敗しました: \(url.path)")
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
        }
    }
}

// プレビュー用
struct EmulatorView_Previews: PreviewProvider {
    static var previews: some View {
        EmulatorView()
    }
}
