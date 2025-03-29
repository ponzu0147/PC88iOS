//
//  EmulatorView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import SwiftUI
import CoreGraphics

/// エミュレータのメイン画面
struct EmulatorView: View {
    @StateObject private var viewModel = EmulatorViewModel()
    
    var body: some View {
        VStack {
            // エミュレータ画面
            if let image = viewModel.screenImage {
                Image(image, scale: 1.0, label: Text("PC-88 Screen"))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("エミュレータ起動中...")
                    .font(.title)
                    .padding()
            }
            
            // コントロールパネル
            HStack {
                Button(action: viewModel.resetEmulator) {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                }
                .padding()
                
                Button(action: viewModel.togglePause) {
                    Label(viewModel.isPaused ? "再開" : "一時停止", 
                          systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                }
                .padding()
                
                Button(action: viewModel.loadDisk) {
                    Label("ディスク", systemImage: "opticaldisc")
                }
                .padding()
                
                Button(action: viewModel.showKeyboard) {
                    Label("キーボード", systemImage: "keyboard")
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            viewModel.startEmulator()
        }
        .onDisappear {
            viewModel.stopEmulator()
        }
    }
}

/// エミュレータのビューモデル
class EmulatorViewModel: ObservableObject {
    @Published var screenImage: CGImage?
    @Published var isPaused: Bool = false
    
    private var emulatorCore: EmulatorCoreManaging?
    private var timer: Timer?
    
    func startEmulator() {
        // エミュレータコアの初期化
        // 実際の実装では、依存性注入などを使用してエミュレータコアを取得
        // emulatorCore = EmulatorCoreFactory.createEmulatorCore()
        // emulatorCore?.initialize()
        // emulatorCore?.start()
        
        // 画面更新タイマーの開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
    }
    
    func stopEmulator() {
        timer?.invalidate()
        timer = nil
        emulatorCore?.stop()
    }
    
    func resetEmulator() {
        emulatorCore?.reset()
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
        // ディスク選択UIを表示
        // 実際の実装では、ファイルピッカーを表示してディスクイメージを選択
    }
    
    func showKeyboard() {
        // カスタムキーボードUIを表示
    }
    
    private func updateScreen() {
        // エミュレータコアから画面イメージを取得
        screenImage = emulatorCore?.getScreen()
    }
}

// プレビュー用
struct EmulatorView_Previews: PreviewProvider {
    static var previews: some View {
        EmulatorView()
    }
}
