//
//  PC88EmulatorApp.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Combine
import Foundation
import SwiftUI

/// エミュレータアプリの状態管理クラス
class EmulatorAppState: ObservableObject {
    @Published var scenePhase: ScenePhase = .active
    @Published var isInBackground: Bool = false
}

// 通知名の拡張
extension Notification.Name {
    static let emulatorPauseNotification = Notification.Name("EmulatorPauseNotification")
    static let emulatorResumeNotification = Notification.Name("EmulatorResumeNotification")
}

@main
struct PC88EmulatorApp: App {
    // 初期化済みフラグ
    @State private var isInitialized = false
    
    // エミュレータ状態管理用
    @StateObject private var appState = EmulatorAppState()
    
    // シーンフェーズを環境変数から取得
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            EmulatorView()
                .environmentObject(appState)
                .onAppear {
                    if !isInitialized {
                        // アプリ起動時にリソースファイルをコピー
                        copyResourceFilesToDocuments()
                        
                        // エミュレータの画面表示を確実に初期化するための処理
                        // 通知名を定数化して一責性を確保
                        let forceUpdateNotification = Notification.Name("ForceScreenUpdateNotification")
                        let emulatorStartNotification = Notification.Name("EmulatorStartNotification")
                        
                        // EmulatorViewの初期化が完了するのを待ってから通知を送信
                        // 最初のエミュレータ開始通知（これが重要）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            PC88Logger.app.info("アプリ起動時: エミュレータ開始通知を送信します")
                            NotificationCenter.default.post(name: emulatorStartNotification, object: nil)
                        }
                        
                        // 最初の画面更新通知（EmulatorViewのonAppearが呼ばれた後）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            PC88Logger.app.info("アプリ起動時: 最初の画面更新通知を送信します")
                            NotificationCenter.default.post(name: forceUpdateNotification, object: nil)
                            // エミュレータ開始通知も再度送信
                            NotificationCenter.default.post(name: emulatorStartNotification, object: nil)
                        }
                        
                        // 少し遅らせて再度更新（EmulatorViewInternalModelの初期化完了後）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            PC88Logger.app.info("アプリ起動時: 2回目の画面更新通知を送信します")
                            NotificationCenter.default.post(name: forceUpdateNotification, object: nil)
                            // エミュレータ開始通知も再度送信
                            NotificationCenter.default.post(name: emulatorStartNotification, object: nil)
                        }
                        
                        // さらに遅らせて再度更新（エミュレータコアの初期化完了後）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            PC88Logger.app.info("アプリ起動時: 3回目の画面更新通知を送信します")
                            NotificationCenter.default.post(name: forceUpdateNotification, object: nil)
                            // エミュレータ開始通知も再度送信
                            NotificationCenter.default.post(name: emulatorStartNotification, object: nil)
                        }
                        
                        // 最終確認の更新通知
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            PC88Logger.app.info("アプリ起動時: 最終確認の画面更新通知を送信します")
                            NotificationCenter.default.post(name: forceUpdateNotification, object: nil)
                            // エミュレータ開始通知も再度送信
                            NotificationCenter.default.post(name: emulatorStartNotification, object: nil)
                        }
                        
                        isInitialized = true
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            appState.scenePhase = newPhase
            handleScenePhaseChange(newPhase)
        }
    }
    
    /// シーンフェーズ変更時の処理
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // フォアグラウンドに戻ったとき
            PC88Logger.app.info("アプリがフォアグラウンドに戻りました")
            appState.isInBackground = false
            NotificationCenter.default.post(name: .emulatorResumeNotification, object: nil)
            
        case .background:
            // バックグラウンドに移行したとき
            PC88Logger.app.info("アプリがバックグラウンドに移行しました")
            appState.isInBackground = true
            NotificationCenter.default.post(name: .emulatorPauseNotification, object: nil)
            
        case .inactive:
            // 非アクティブ状態（例：マルチタスク画面表示中）
            PC88Logger.app.info("アプリが非アクティブになりました")
            
        @unknown default:
            break
        }
    }
    
    /// リソースファイルをDocumentsディレクトリにコピーする
    private func copyResourceFilesToDocuments() {
        // Documentsディレクトリのパスを取得
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            PC88Logger.app.error("Documentsディレクトリの取得に失敗しました")
            return
        }
        
        // コピーするリソースファイルのリスト
        let resourceFiles = [
            "N88.ROM", "N88N.ROM", "N88_0.ROM", "N88_1.ROM", "N88_2.ROM", "N88_3.ROM", "DISK.ROM", "font.rom",
            "2608_bd.wav", "2608_sd.wav", "2608_tom.wav", "2608_hh.wav", "2608_top.wav", "2608_rim.wav"
        ]
        
        // 各ファイルをバンドルから探してDocumentsディレクトリにコピー
        for fileName in resourceFiles {
            // ファイル名から拡張子を分離
            let fileComponents = fileName.split(separator: ".")
            if fileComponents.count != 2 {
                PC88Logger.app.warning("無効なファイル名: \(fileName)")
                continue
            }
            
            let name = String(fileComponents[0])
            let ext = String(fileComponents[1])
            
            // バンドルからリソースURLを取得
            guard let sourceURL = Bundle.main.url(forResource: name, withExtension: ext) else {
                PC88Logger.app.warning("リソースが見つかりません: \(fileName)")
                continue
            }
            
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                // ファイルが存在する場合は上書き
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                PC88Logger.app.info("ファイルをコピーしました: \(fileName)")
            } catch {
                PC88Logger.app.error("ファイルのコピー中にエラーが発生しました: \(fileName) - \(error.localizedDescription)")
            }
        }
        
        PC88Logger.app.info("リソースファイルのコピー処理が完了しました")
    }
}
