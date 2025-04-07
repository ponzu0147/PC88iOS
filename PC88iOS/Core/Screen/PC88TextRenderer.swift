//
//  PC88TextRenderer.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation
import CoreGraphics
import UIKit

/// PC-88のテキスト描画を担当するクラス
class PC88TextRenderer {
    /// デバッグモードかどうか
    var isDebugMode = false
    
    /// デバッグメッセージ
    private var debugMessages: [String] = []
    /// テキストVRAM
    private var textVRAM: [UInt8]
    
    /// 画面設定
    private var settings: PC88ScreenSettings
    
    /// 属性ハンドラ
    private var attributeHandler: PC88AttributeHandler
    
    /// カラーパレット
    private var colorPalette: PC88ColorPalette
    
    /// フォントデータ
    private var fontData = [UInt8](repeating: 0, count: 256 * 16)
    
    /// 各行のテキストモード（文字/セミグラフィック）
    private var lineTextModes = [PC88TextMode](repeating: .character, count: 25)
    
    /// 点滅状態
    private var blinkState = true
    
    /// 初期化
    init(textVRAM: [UInt8], settings: PC88ScreenSettings, attributeHandler: PC88AttributeHandler, colorPalette: PC88ColorPalette) {
        self.textVRAM = textVRAM
        self.settings = settings
        self.attributeHandler = attributeHandler
        self.colorPalette = colorPalette
    }
    
    /// テキストVRAMの参照を更新
    func updateTextVRAMReference(_ textVRAM: [UInt8]) {
        self.textVRAM = textVRAM
        attributeHandler.updateTextVRAMReference(textVRAM)
    }
    
    /// フォントデータを設定
    func setFontData(_ data: [UInt8]) {
        guard data.count == 256 * 16 else { return }
        fontData = data
    }
    
    /// 点滅状態を更新
    func updateBlinkState(_ state: Bool) {
        blinkState = state
        attributeHandler.updateBlinkState(state)
    }
    
    /// 行のテキストモードを設定
    func setLineTextMode(line: Int, mode: PC88TextMode) {
        guard line >= 0 && line < PC88ScreenConstants.textHeight25 else { return }
        lineTextModes[line] = mode
    }
    
    /// 画面をクリア
    func clearScreen() {
        let textWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        let textHeight = settings.is20LineMode ? PC88ScreenConstants.textHeight20 : PC88ScreenConstants.textHeight25
        
        for line in 0..<textHeight {
            let lineOffset = line * PC88ScreenConstants.textVRAMBytesPerLine
            
            // 文字部分をスペースで埋める
            for column in 0..<textWidth {
                textVRAM[lineOffset + column] = 0x20  // スペース
            }
            
            // 属性部分をクリア
            for i in 0..<PC88ScreenConstants.maxAttributesPerLine * 2 {
                textVRAM[lineOffset + textWidth + i] = 0
            }
            
            // 属性数を0に設定
            textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1] = 0
        }
        
        // 全行を文字モードに設定
        for i in 0..<lineTextModes.count {
            lineTextModes[i] = .character
        }
    }
    
    /// デバッグメッセージを追加
    func addDebugMessage(_ message: String) {
        debugMessages.append(message)
        // 最大10行まで保持
        if debugMessages.count > 10 {
            debugMessages.removeFirst()
        }
    }
    
    /// デバッグメッセージをクリア
    func clearDebugMessages() {
        debugMessages.removeAll()
    }
    
    /// テキスト画面を描画
    func renderTextScreen(context: CGContext) {
        // テキスト画面の描画処理
        
        // テキストの行数と桁数を設定
        let textWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        let textHeight = settings.is20LineMode ? PC88ScreenConstants.textHeight20 : PC88ScreenConstants.textHeight25
        
        // フォントの高さを設定
        let fontHeight = settings.is20LineMode ? PC88ScreenConstants.fontHeight20 : PC88ScreenConstants.fontHeight25
        
        for y in 0..<textHeight {
            // 行のテキストモードを取得
            let lineMode = lineTextModes[y]
            
            // 行のオフセットを計算
            let lineOffset = y * PC88ScreenConstants.textVRAMBytesPerLine
            
            for x in 0..<textWidth {
                let charIndex = lineOffset + x
                if charIndex < textVRAM.count {
                    let charCode = textVRAM[charIndex]
                    
                    // 描画位置を計算
                    let posX = x * PC88ScreenConstants.fontWidth
                    let posY = y * fontHeight
                    
                    // 属性を取得
                    let colorCode = attributeHandler.getColor(line: y, column: x)
                    let decorationInfo = attributeHandler.getDecoration(line: y, column: x)
                    
                    // 色を取得
                    let color = colorPalette.getColor(colorCode: colorCode)
                    
                    // 装飾情報を取得
                    let currentDecoration = decorationInfo?.decoration ?? .normal
                    let hasUnderline = decorationInfo?.hasUnderline ?? false
                    let hasUpperline = decorationInfo?.hasUpperline ?? false
                    let shouldDisplay = decorationInfo?.shouldDisplay ?? true
                    
                    if lineMode == .semiGraphics {
                        // セミグラフィックモードの描画処理
                        drawSemiGraphics(context: context, charCode: charCode, x: posX, y: posY, color: color)
                    } else {
                        // 文字モードの描画処理
                        
                        // 装飾に基づいて描画を制御
                        switch currentDecoration {
                        case .normal:
                            // 通常表示
                            if shouldDisplay {
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: color)
                            }
                            
                        case .secret, .secretAlt:
                            // シークレット（非表示）
                            // 何も描画しない
                            break
                            
                        case .blink:
                            // 点滅
                            if shouldDisplay {
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: color)
                            }
                            
                        case .reverse, .reverseBlink, .reverseSecret:
                            // 反転表示
                            if shouldDisplay {
                                // 背景を文字色で塗りつぶす
                                context.setFillColor(colorPalette.getCGColor(colorCode: colorCode))
                                context.fill(CGRect(x: posX, y: posY, width: PC88ScreenConstants.fontWidth, height: fontHeight))
                                
                                // 文字を黒で描画
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: 0xFF000000)
                            }
                        }
                        
                        // アンダーラインを描画
                        if hasUnderline {
                            context.setFillColor(colorPalette.getCGColor(colorCode: colorCode))
                            context.fill(CGRect(x: posX, y: posY + fontHeight - 1, width: PC88ScreenConstants.fontWidth, height: 1))
                        }
                        
                        // アッパーラインを描画
                        if hasUpperline {
                            context.setFillColor(colorPalette.getCGColor(colorCode: colorCode))
                            context.fill(CGRect(x: posX, y: posY, width: PC88ScreenConstants.fontWidth, height: 1))
                        }
                    }
                }
            }
        }
    }
    
    /// 文字を描画
    private func drawCharacter(context: CGContext, charCode: UInt8, x: Int, y: Int, color: UInt32) {
        // フォントデータのオフセットを計算
        let fontOffset = Int(charCode) * 16
        
        // フォントの高さを設定
        let fontHeight = settings.is20LineMode ? PC88ScreenConstants.fontHeight20 : PC88ScreenConstants.fontHeight25
        
        // 色を設定
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        
        context.setFillColor(red: r, green: g, blue: b, alpha: a)
        
        // 文字を描画
        for row in 0..<fontHeight {
            // 20行モードの場合は16ドットのフォントを20ドットに引き伸ばす
            let fontRow = settings.is20LineMode ? min(row * 16 / 20, 15) : row
            
            if fontOffset + fontRow < fontData.count {
                let pattern = fontData[fontOffset + fontRow]
                
                for col in 0..<8 {
                    if (pattern & (0x80 >> col)) != 0 {
                        // ピクセルを描画
                        context.fill(CGRect(x: x + col, y: y + row, width: 1, height: 1))
                    }
                }
            }
        }
    }
    
    /// セミグラフィックスを描画
    private func drawSemiGraphics(context: CGContext, charCode: UInt8, x: Int, y: Int, color: UInt32) {
        // セミグラフィックスモードの描画処理
        // 1文字が4x2のブロックに対応
        
        // 色を設定
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        
        context.setFillColor(red: r, green: g, blue: b, alpha: a)
        
        // フォントの高さを設定
        let fontHeight = settings.is20LineMode ? PC88ScreenConstants.fontHeight20 : PC88ScreenConstants.fontHeight25
        
        // 各ブロックを描画
        for blockY in 0..<2 {
            for blockX in 0..<4 {
                // ビットを取得（下位ビットから順に右上、左上、右下、左下）
                let bitPos = blockY * 4 + blockX
                let isSet = (charCode & (1 << bitPos)) != 0
                
                if isSet {
                    // ブロックを描画
                    let blockWidth = PC88ScreenConstants.fontWidth / 4
                    let blockHeight = fontHeight / 2
                    
                    context.fill(CGRect(x: x + blockX * blockWidth, y: y + blockY * blockHeight, width: blockWidth, height: blockHeight))
                }
            }
        }
    }
    
    /// テスト画面を表示
    func displayTestScreen(context: CGContext) {
        // 「PC-88」と表示する
        let testChars: [UInt8] = [0x50, 0x43, 0x2D, 0x38, 0x38]  // "PC-88"
        
        for (i, char) in testChars.enumerated() {
            let x = 10 + i * PC88ScreenConstants.fontWidth
            let y = 10
            
            // 白色で描画
            drawCharacter(context: context, charCode: char, x: x, y: y, color: 0xFFFFFFFF)
        }
    }
    
    /// 詳細なテスト画面を表示
    func displayDetailedTestScreen() {
        let textWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        // textHeight変数は使用されていないため削除
        
        // 画面をクリア
        clearScreen()
        
        // ヘッダー行を表示
        let headerText = "PC-88 TEXT MODE TEST"
        for (i, char) in headerText.utf8.enumerated() {
            if i < textWidth {
                textVRAM[i] = char
            }
        }
        
        // 属性テスト
        for i in 0..<8 {
            if i < textWidth {
                // 2行目に色テスト
                textVRAM[PC88ScreenConstants.textVRAMBytesPerLine + i] = 0x41 + UInt8(i)  // 'A' + i
                attributeHandler.setColorAttribute(line: 1, startColumn: i, color: UInt8(i))
                
                // 3行目に装飾テスト
                textVRAM[PC88ScreenConstants.textVRAMBytesPerLine * 2 + i] = 0x61 + UInt8(i)  // 'a' + i
                
                if i < 7 {
                    let decoration = PC88Decoration(rawValue: UInt8(i)) ?? .normal
                    attributeHandler.setDecorationAttribute(line: 2, startColumn: i, decoration: decoration)
                }
            }
        }
        
        // アンダーライン/アッパーラインテスト
        let lineText = "UNDERLINE & UPPERLINE TEST"
        for (i, char) in lineText.utf8.enumerated() {
            if i < textWidth {
                textVRAM[PC88ScreenConstants.textVRAMBytesPerLine * 3 + i] = char
            }
        }
        
        attributeHandler.setDecorationAttribute(line: 3, startColumn: 0, decoration: .normal, underline: true)
        attributeHandler.setDecorationAttribute(line: 3, startColumn: 10, decoration: .normal, upperline: true)
        attributeHandler.setDecorationAttribute(line: 3, startColumn: 20, decoration: .normal, underline: true, upperline: true)
        
        // セミグラフィックモードテスト
        setLineTextMode(line: 5, mode: .semiGraphics)
        
        for i in 0..<16 {
            if i < textWidth {
                textVRAM[PC88ScreenConstants.textVRAMBytesPerLine * 5 + i] = UInt8(i)
            }
        }
    }
    
    /// デバッグ情報を描画
    func renderDebugInfo(context: CGContext) {
        guard isDebugMode else { return }
        
        // フォントの高さを設定
        let fontHeight = settings.is20LineMode ? PC88ScreenConstants.fontHeight20 : PC88ScreenConstants.fontHeight25
        
        // 背景を半透明の黒で描画
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.7))
        context.fill(CGRect(x: 10, y: 10, width: 300, height: CGFloat(debugMessages.count + 2) * CGFloat(fontHeight)))
        
        // デバッグモードのタイトルを描画
        drawDebugText(context: context, text: "DEBUG MODE", x: 15, y: 15, color: 0xFFFFFF00)
        
        // デバッグメッセージを描画
        for (index, message) in debugMessages.enumerated() {
            let y = 15 + (index + 1) * fontHeight
            drawDebugText(context: context, text: message, x: 15, y: y, color: 0xFFFFFFFF)
        }
    }
    
    /// デバッグテキストを描画
    private func drawDebugText(context: CGContext, text: String, x: Int, y: Int, color: UInt32) {
        // 色を設定
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        
        context.setFillColor(CGColor(red: r, green: g, blue: b, alpha: a))
        
        // デバッグ用のテキストを描画
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor(red: r, green: g, blue: b, alpha: a)
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: CGPoint(x: x, y: y))
    }
}
