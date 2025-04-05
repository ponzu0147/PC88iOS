//
//  PC88TextEmulatorView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import SwiftUI
import CoreGraphics

/// PC-88のテキスト表示エミュレーションテスト画面
struct PC88TextEmulatorView: View {
    /// PC-88画面
    @State private var screen = PC88ScreenBase()
    
    /// テキストエミュレータ
    @State private var textEmulator: PC88TextEmulator?
    
    /// 表示用のイメージ
    @State private var displayImage: CGImage?
    
    /// 表示間隔（秒）
    @State private var displayInterval: Double = 0.01
    
    /// 表示するテキスト
    @State private var textToDisplay: String = """
PC-88 テキスト表示テスト

これはPC-88のテキスト表示をエミュレートするテストです。
左上から1文字ずつ表示していきます。

表示間隔: 0.01秒/文字

ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
0123456789
!"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~
"""
    
    /// 表示中かどうか
    @State private var isDisplaying: Bool = false
    
    /// 現在表示中の文字位置
    @State private var currentPosition: String = "0, 0"
    
    var body: some View {
        VStack {
            // タイトル
            Text("PC-88 テキスト表示エミュレーション")
                .font(.headline)
                .padding(.bottom, 5)
            
            // 画面表示エリア
            if let image = displayImage {
                Image(image, scale: 1.0, label: Text("PC-88 Screen"))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .border(Color.gray, width: 2)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(4/3, contentMode: .fit)
                    .border(Color.gray, width: 2)
            }
            
            // 現在位置表示
            Text("現在位置: \(currentPosition)")
                .font(.caption)
                .padding(.top, 5)
            
            // コントロールパネル
            HStack {
                // 表示間隔調整
                VStack(alignment: .leading) {
                    Text("表示間隔: \(String(format: "%.3f", displayInterval))秒")
                    Slider(value: $displayInterval, in: 0.001...0.1, step: 0.001)
                        .frame(width: 200)
                        .disabled(isDisplaying)
                }
                
                Spacer()
                
                // ボタン群
                VStack(spacing: 10) {
                    // 開始/停止ボタン
                    Button(action: {
                        if isDisplaying {
                            stopDisplay()
                        } else {
                            startDisplay()
                        }
                    }) {
                        Text(isDisplaying ? "停止" : "開始")
                            .frame(width: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // クリアボタン
                    Button(action: {
                        clearScreen()
                    }) {
                        Text("クリア")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDisplaying)
                }
            }
            .padding()
            
            // テキスト入力エリア
            VStack(alignment: .leading) {
                Text("表示するテキスト:")
                    .font(.caption)
                
                TextEditor(text: $textToDisplay)
                    .font(.system(size: 14, design: .monospaced))
                    .frame(height: 150)
                    .border(Color.gray, width: 1)
                    .disabled(isDisplaying)
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            setupEmulator()
            renderScreen()
        }
    }
    
    /// エミュレータをセットアップ
    private func setupEmulator() {
        // テキストエミュレータを初期化
        textEmulator = PC88TextEmulator(screen: screen)
        
        // 文字表示コールバックを設定
        textEmulator?.onCharacterDisplayed = { row, column, char in
            currentPosition = "\(column), \(row)"
            renderScreen()
        }
        
        // 表示完了コールバックを設定
        textEmulator?.onDisplayComplete = {
            isDisplaying = false
        }
    }
    
    /// 表示を開始
    private func startDisplay() {
        guard let emulator = textEmulator, !textToDisplay.isEmpty else { return }
        
        isDisplaying = true
        emulator.displayText(textToDisplay, interval: displayInterval)
    }
    
    /// 表示を停止
    private func stopDisplay() {
        textEmulator?.stopDisplay()
        isDisplaying = false
    }
    
    /// 画面をクリア
    private func clearScreen() {
        screen.clear()
        currentPosition = "0, 0"
        renderScreen()
    }
    
    /// 画面を描画
    private func renderScreen() {
        displayImage = screen.renderScreen()
    }
}

#Preview {
    PC88TextEmulatorView()
}
