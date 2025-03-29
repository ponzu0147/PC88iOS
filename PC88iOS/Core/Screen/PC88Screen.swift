//
//  PC88Screen.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import CoreGraphics
import UIKit

/// PC-88の画面描画を担当するクラス
class PC88Screen: ScreenRendering {
    // MARK: - 定数
    
    /// テキスト画面の幅（文字数）
    private let textWidth = 80
    
    /// テキスト画面の高さ（文字数）
    private let textHeight = 25
    
    /// グラフィック画面の幅（ピクセル）
    private let graphicsWidth = 640
    
    /// グラフィック画面の高さ（ピクセル）
    private let graphicsHeight = 400
    
    /// フォントデータの幅（ピクセル）
    private let fontWidth = 8
    
    /// フォントデータの高さ（ピクセル）
    private let fontHeight = 16
    
    // MARK: - プロパティ
    
    /// メモリアクセス
    private var memory: MemoryAccessing?
    
    /// I/Oアクセス
    private var io: IOAccessing?
    
    /// テキストVRAM
    private var textVRAM = [UInt8](repeating: 0, count: 80 * 25)
    
    /// 属性VRAM
    private var attributeVRAM = [UInt8](repeating: 0, count: 80 * 25)
    
    /// グラフィックVRAM（3プレーン: R, G, B）
    private var graphicsVRAM = Array(repeating: [UInt8](repeating: 0, count: 640 * 400 / 8), count: 3)
    
    /// パレット
    private var palette = [UInt32](repeating: 0, count: 8)
    
    /// 現在の画面モード
    private var currentMode: ScreenMode = .text
    
    /// フォントデータ
    private var fontData = [UInt8](repeating: 0, count: 256 * 16)
    
    /// 画面バッファ
    private var screenBuffer: CGContext?
    
    // MARK: - 初期化
    
    init() {
        initializePalette()
        initializeFontData()
        createScreenBuffer()
    }
    
    // MARK: - 公開メソッド
    
    /// メモリアクセスを接続
    func connectMemory(_ memory: MemoryAccessing) {
        self.memory = memory
    }
    
    /// I/Oアクセスを接続
    func connectIO(_ io: IOAccessing) {
        self.io = io
    }
    
    // MARK: - ScreenRendering プロトコル実装
    
    func initialize() {
        // テキストVRAMをクリア
        textVRAM = [UInt8](repeating: 0x20, count: textWidth * textHeight)  // スペースで埋める
        
        // 属性VRAMをクリア
        attributeVRAM = [UInt8](repeating: 0, count: textWidth * textHeight)
        
        // グラフィックVRAMをクリア
        for i in 0..<3 {
            graphicsVRAM[i] = [UInt8](repeating: 0, count: graphicsWidth * graphicsHeight / 8)
        }
        
        // パレットを初期化
        initializePalette()
        
        // 画面モードをテキストモードに設定
        currentMode = .text
        
        // 画面バッファを作成
        createScreenBuffer()
    }
    
    func updateTextVRAM(at address: UInt16, value: UInt8) {
        let offset = Int(address)
        if offset < textVRAM.count {
            textVRAM[offset] = value
        }
    }
    
    func updateGraphicsVRAM(at address: UInt16, value: UInt8, plane: Int) {
        guard plane >= 0 && plane < 3 else { return }
        
        let offset = Int(address)
        if offset < graphicsVRAM[plane].count {
            graphicsVRAM[plane][offset] = value
        }
    }
    
    func setScreenMode(_ mode: ScreenMode) {
        currentMode = mode
    }
    
    func setPalette(index: Int, color: UInt8) {
        guard index >= 0 && index < palette.count else { return }
        
        // PC-88のパレット値をRGBA値に変換
        let r = (color & 0x04) != 0 ? 255 : 0
        let g = (color & 0x02) != 0 ? 255 : 0
        let b = (color & 0x01) != 0 ? 255 : 0
        
        // RGBA値をUInt32に変換（アルファは常に255）
        palette[index] = (UInt32(r) << 24) | (UInt32(g) << 16) | (UInt32(b) << 8) | 255
    }
    
    func render() -> CGImage? {
        guard let context = screenBuffer else { return nil }
        
        // 画面をクリア
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: graphicsWidth, height: graphicsHeight))
        
        // 現在のモードに応じて描画
        switch currentMode {
        case .text:
            renderTextMode(context)
        case .graphics:
            renderGraphicsMode(context)
        case .mixed:
            renderGraphicsMode(context)
            renderTextMode(context)
        }
        
        return context.makeImage()
    }
    
    func reset() {
        initialize()
    }
    
    // MARK: - プライベートメソッド
    
    /// パレットの初期化
    private func initializePalette() {
        // 基本8色パレット
        palette[0] = 0x000000FF  // 黒
        palette[1] = 0x0000FFFF  // 青
        palette[2] = 0x00FF00FF  // 緑
        palette[3] = 0x00FFFFFF  // シアン
        palette[4] = 0xFF0000FF  // 赤
        palette[5] = 0xFF00FFFF  // マゼンタ
        palette[6] = 0xFFFF00FF  // 黄
        palette[7] = 0xFFFFFFFF  // 白
    }
    
    /// フォントデータの初期化
    private func initializeFontData() {
        // 仮のフォントデータ（実際にはROMから読み込むか、リソースから読み込む）
        // ここでは単純な例として、いくつかの文字だけ定義
        
        // スペース (0x20)
        let spaceIndex = 0x20 * fontHeight
        for i in 0..<fontHeight {
            fontData[spaceIndex + i] = 0x00
        }
        
        // 'A' (0x41)
        let aIndex = 0x41 * fontHeight
        fontData[aIndex + 0] = 0b00001000
        fontData[aIndex + 1] = 0b00011100
        fontData[aIndex + 2] = 0b00110110
        fontData[aIndex + 3] = 0b01100011
        fontData[aIndex + 4] = 0b01100011
        fontData[aIndex + 5] = 0b01111111
        fontData[aIndex + 6] = 0b01100011
        fontData[aIndex + 7] = 0b01100011
        fontData[aIndex + 8] = 0b01100011
        fontData[aIndex + 9] = 0b01100011
        fontData[aIndex + 10] = 0b00000000
        fontData[aIndex + 11] = 0b00000000
        fontData[aIndex + 12] = 0b00000000
        fontData[aIndex + 13] = 0b00000000
        fontData[aIndex + 14] = 0b00000000
        fontData[aIndex + 15] = 0b00000000
        
        // 他の文字も同様に定義...
    }
    
    /// 画面バッファの作成
    private func createScreenBuffer() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        screenBuffer = CGContext(
            data: nil,
            width: graphicsWidth,
            height: graphicsHeight,
            bitsPerComponent: 8,
            bytesPerRow: graphicsWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
    
    /// テキストモードの描画
    private func renderTextMode(_ context: CGContext) {
        for y in 0..<textHeight {
            for x in 0..<textWidth {
                let index = y * textWidth + x
                let char = textVRAM[index]
                let attr = attributeVRAM[index]
                
                // 文字の前景色と背景色を決定
                let fgColorIndex = (attr & 0x07)
                let bgColorIndex = (attr >> 3) & 0x07
                let fgColor = palette[Int(fgColorIndex)]
                let bgColor = palette[Int(bgColorIndex)]
                
                // 背景を描画
                let rectX = x * fontWidth
                let rectY = y * fontHeight
                context.setFillColor(UIColor(
                    red: CGFloat((bgColor >> 24) & 0xFF) / 255.0,
                    green: CGFloat((bgColor >> 16) & 0xFF) / 255.0,
                    blue: CGFloat((bgColor >> 8) & 0xFF) / 255.0,
                    alpha: CGFloat(bgColor & 0xFF) / 255.0
                ).cgColor)
                context.fill(CGRect(x: rectX, y: rectY, width: fontWidth, height: fontHeight))
                
                // 文字を描画
                let fontOffset = Int(char) * fontHeight
                for cy in 0..<fontHeight {
                    let fontLine = fontData[fontOffset + cy]
                    for cx in 0..<fontWidth {
                        if (fontLine & (0x80 >> cx)) != 0 {
                            let pixelX = rectX + cx
                            let pixelY = rectY + cy
                            context.setFillColor(UIColor(
                                red: CGFloat((fgColor >> 24) & 0xFF) / 255.0,
                                green: CGFloat((fgColor >> 16) & 0xFF) / 255.0,
                                blue: CGFloat((fgColor >> 8) & 0xFF) / 255.0,
                                alpha: CGFloat(fgColor & 0xFF) / 255.0
                            ).cgColor)
                            context.fill(CGRect(x: pixelX, y: pixelY, width: 1, height: 1))
                        }
                    }
                }
            }
        }
    }
    
    /// グラフィックモードの描画
    private func renderGraphicsMode(_ context: CGContext) {
        for y in 0..<graphicsHeight {
            for x in 0..<graphicsWidth {
                // ピクセルの色を決定
                let byteOffset = (y * graphicsWidth + x) / 8
                let bitOffset = 7 - (x % 8)
                
                let r = (graphicsVRAM[0][byteOffset] & (1 << bitOffset)) != 0
                let g = (graphicsVRAM[1][byteOffset] & (1 << bitOffset)) != 0
                let b = (graphicsVRAM[2][byteOffset] & (1 << bitOffset)) != 0
                
                // パレットインデックスを計算
                let colorIndex = (r ? 4 : 0) | (g ? 2 : 0) | (b ? 1 : 0)
                let color = palette[colorIndex]
                
                // ピクセルを描画
                context.setFillColor(UIColor(
                    red: CGFloat((color >> 24) & 0xFF) / 255.0,
                    green: CGFloat((color >> 16) & 0xFF) / 255.0,
                    blue: CGFloat((color >> 8) & 0xFF) / 255.0,
                    alpha: CGFloat(color & 0xFF) / 255.0
                ).cgColor)
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
    }
    
    /// 画面の描画（EmulatorCoreManaging用）
    func renderScreen() -> CGImage? {
        return render()
    }
}
