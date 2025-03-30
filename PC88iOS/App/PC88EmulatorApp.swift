//
//  PC88EmulatorApp.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import SwiftUI
import Foundation

@main
struct PC88EmulatorApp: App {
    // 初期化済みフラグ
    @State private var isInitialized = false
    
    var body: some Scene {
        WindowGroup {
            EmulatorView()
                .onAppear {
                    if !isInitialized {
                        // アプリ起動時にリソースファイルをコピー
                        copyResourceFilesToDocuments()
                        isInitialized = true
                    }
                }
        }
    }
    
    /// リソースファイルをDocumentsディレクトリにコピーする
    private func copyResourceFilesToDocuments() {
        // Documentsディレクトリのパスを取得
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documentsディレクトリの取得に失敗しました")
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
                print("無効なファイル名: \(fileName)")
                continue
            }
            
            let name = String(fileComponents[0])
            let ext = String(fileComponents[1])
            
            // バンドルからリソースURLを取得
            guard let sourceURL = Bundle.main.url(forResource: name, withExtension: ext) else {
                print("リソースが見つかりません: \(fileName)")
                continue
            }
            
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                // ファイルが存在する場合は上書き
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                print("ファイルをコピーしました: \(fileName)")
            } catch {
                print("ファイルのコピー中にエラーが発生しました: \(fileName) - \(error)")
            }
        }
        
        print("リソースファイルのコピー処理が完了しました")
    }
}
