//
//  EmulatorViewModel.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import SwiftUI
import Combine
import UIKit

/// エミュレータのビューモデル
class EmulatorViewModel: ObservableObject {
    // MARK: - プロパティ
    
    /// エミュレータコア
    private let emulatorCore: EmulatorCoreManaging
    
    /// 画面イメージ
    @Published var screenImage: CGImage?
    
    /// 一時停止状態
    @Published var isPaused = false
    
    /// ディスクイメージパス
    @Published var diskImagePath: String?
    
    /// キーボード表示フラグ
    @Published var isKeyboardVisible = false
    
    /// 購読キャンセル
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初期化
    
    init() {
        // エミュレータコアの生成と初期化
        self.emulatorCore = PC88EmulatorCore()
        emulatorCore.initialize()
        
        // 画面イメージの監視
        Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateScreenImage()
            }
            .store(in: &cancellables)
        
        // エミュレータの開始
        emulatorCore.start()
    }
    
    // MARK: - メソッド
    
    /// エミュレータのリセット
    func resetEmulator() {
        emulatorCore.reset()
    }
    
    /// 一時停止/再開の切り替え
    func togglePause() {
        if isPaused {
            emulatorCore.resume()
        } else {
            emulatorCore.pause()
        }
        isPaused.toggle()
    }
    
    /// ディスクのロード
    func loadDisk() {
        // ドキュメントピッカーを表示するためのフラグをセット
        showDocumentPicker = true
    }
    
    /// ドキュメントピッカーの表示フラグ
    @Published var showDocumentPicker = false
    
    /// 端末からディスクイメージをロード
    func loadDiskImageFromDevice(url: URL, drive: Int) {
        // エミュレータコアにディスクイメージのロードを依頼
        if emulatorCore.loadDiskImage(url: url, drive: drive) {
            diskImagePath = url.lastPathComponent
        } else {
            PC88Logger.app.debug("ディスクイメージのロードに失敗しました: \(url.path)")
        }
    }
    
    /// キーボードの表示
    func showKeyboard() {
        isKeyboardVisible.toggle()
    }
    
    /// 画面イメージの更新
    private func updateScreenImage() {
        screenImage = emulatorCore.getScreen()
    }
    
    /// キー入力の処理
    func handleKeyPress(_ key: String) {
        // キー入力をエミュレータに送信
        // 文字列からPC88Keyに変換
        if let pc88Key = convertStringToPC88Key(key) {
            emulatorCore.handleInputEvent(.keyDown(key: pc88Key))
        }
    }
    
    /// 文字列からPC88Keyに変換
    private func convertStringToPC88Key(_ key: String) -> PC88Key? {
        switch key.lowercased() {
        case "1": return .num1
        case "2": return .num2
        case "3": return .num3
        case "4": return .num4
        case "5": return .num5
        case "6": return .num6
        case "7": return .num7
        case "8": return .num8
        case "9": return .num9
        case "0": return .num0
        case "a": return .keyA
        case "b": return .keyB
        case "c": return .keyC
        case "d": return .keyD
        case "e": return .keyE
        case "f": return .keyF
        case "g": return .keyG
        case "h": return .keyH
        case "i": return .keyI
        case "j": return .keyJ
        case "k": return .keyK
            
        case "l": return .keyL
        case "m": return .keyM
        case "n": return .keyN
            
        case "o": return .keyO
        case "p": return .keyP
        case "q": return .keyQ
        case "r": return .keyR
        case "s": return .keyS
        case "t": return .keyT
        case "u": return .keyU
        case "v": return .keyV
        case "w": return .keyW
        case "x": return .keyX
        case "y": return .keyY
        case "z": return .keyZ
        case "space": return .space
        case "return", "enter": return .returnKey
        case "f1": return .f1
        case "f2": return .f2
        case "f3": return .f3
        case "f4": return .f4
        case "f5": return .f5
        default: return nil
        }
    }
}
