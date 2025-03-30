//
//  EmulatorView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import SwiftUI
import CoreGraphics
import Foundation

// 必要なクラスをインポート

/// エミュレータのメイン画面
struct EmulatorView: View {
    @StateObject private var viewModel = EmulatorViewInternalModel()
    
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
    @Published var screenImage: CGImage?
    @Published var isPaused: Bool = false
    @Published var showDocumentPicker = false
    @Published var diskImagePath: String = ""
    
    private var emulatorCore: EmulatorCoreManaging?
    private var timer: Timer?
    
    func startEmulator() {
        // エミュレータコアの初期化
        emulatorCore = PC88EmulatorCore()
        emulatorCore?.initialize()
        emulatorCore?.start()
        
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
        // ドキュメントピッカーを表示するためのフラグをセット
        showDocumentPicker = true
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
        screenImage = emulatorCore?.getScreen()
    }
}

// プレビュー用
struct EmulatorView_Previews: PreviewProvider {
    static var previews: some View {
        EmulatorView()
    }
}
