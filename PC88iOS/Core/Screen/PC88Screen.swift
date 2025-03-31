//
//  PC88Screen.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import CoreGraphics
import UIKit

/// PC-88の画面モード
enum PC88ScreenMode {
    /// テキストモードのみ
    case text
    /// グラフィックモードのみ
    case graphics
    /// テキストとグラフィックの混合モード
    case mixed
}

// ScreenMode はプロトコルで定義済み

/// PC-88のテキストモード
enum PC88TextMode {
    /// 文字モード
    case character
    /// セミグラフィックモード
    case semiGraphics
}

/// PC-88のテキスト属性タイプ
enum PC88AttributeType {
    /// 色指定
    case color
    /// 装飾指定
    case decoration
}

/// PC-88の装飾効果
enum PC88Decoration: UInt8 {
    /// 通常表示
    case normal = 0x00
    /// シークレット（非表示）
    case secret = 0x01
    /// 点滅
    case blink = 0x02
    /// シークレット（非表示）
    case secretAlt = 0x03
    /// 反転
    case reverse = 0x04
    /// 反転点滅
    case reverseBlink = 0x06
    /// 反転シークレット
    case reverseSecret = 0x07
}

/// PC-88の画面描画を担当するクラス
class PC88Screen: ScreenRendering {
    // MARK: - 定数
    
    /// テキスト画面の幅（80桁モード）
    private let textWidth80 = 80
    
    /// テキスト画面の幅（40桁モード）
    private let textWidth40 = 40
    
    /// テキスト画面の高さ（25行モード）
    private let textHeight25 = 25
    
    /// テキスト画面の高さ（20行モード）
    private let textHeight20 = 20
    
    /// グラフィック画面の幅（ピクセル）
    private let graphicsWidth = 640
    
    /// グラフィック画面の高さ（400ラインモード）
    private let graphicsHeight400 = 400
    
    /// グラフィック画面の高さ（200ラインモード）
    private let graphicsHeight200 = 200
    
    /// 現在のグラフィックス高さ
    private var graphicsHeight: Int {
        return is400LineMode ? graphicsHeight400 : graphicsHeight200
    }
    
    /// フォントデータの幅（ピクセル）
    private let fontWidth = 8
    
    /// フォントデータの高さ（25行モード、ピクセル）
    private let fontHeight25 = 16
    
    /// フォントデータの高さ（20行モード、ピクセル）
    private let fontHeight20 = 20
    
    /// 現在のフォント高さ
    private var fontHeight: Int {
        return is20LineMode ? fontHeight20 : fontHeight25
    }
    
    /// セミグラフィックの幅（ピクセル）
    private let semiGraphicsWidth = 160
    
    /// セミグラフィックの高さ（ピクセル）
    private let semiGraphicsHeight = 100
    
    /// テキストVRAMの1行あたりのバイト数（80文字 + 40バイトの属性）
    private let textVRAMBytesPerLine = 120
    
    /// テキストVRAMの開始アドレス（デフォルト: 0xF3C8）
    private var textVRAMStartAddress: UInt16 = 0xF3C8
    
    /// 1行あたりの最大アトリビュート数
    private let maxAttributesPerLine = 20
    
    /// I/Oポート定数
    private let crtModeControlPort: UInt16 = 0x30    // CRTモード制御ポート
    private let crtLineControlPort: UInt16 = 0x31    // CRT行数制御ポート
    private let colorModeControlPort: UInt16 = 0x32  // カラーモード制御ポート
    private let crtcParameterPort: UInt16 = 0x50     // CRTCパラメータポート
    private let crtcCommandPort: UInt16 = 0x51       // CRTCコマンドポート
    private let dmacCh2AddressPort: UInt16 = 0x64    // DMAC Ch.2アドレスポート
    private let dmacCh2CountPort: UInt16 = 0x65      // DMAC Ch.2カウントポート
    private let dmacControlPort: UInt16 = 0x68       // DMAC制御ポート
    
    // MARK: - プロパティ
    
    /// メモリアクセス
    private var memory: MemoryAccessing?
    
    /// I/Oアクセス
    private var io: IOAccessing?
    
    /// テキストVRAM (1行120バイト: 80文字 + 40バイトの属性)
    private var textVRAM = [UInt8](repeating: 0, count: 120 * 25)
    
    /// 属性VRAM
    private var attributeVRAM = [UInt8](repeating: 0, count: 120 * 25)
    
    /// グラフィックVRAM（3プレーン: R, G, B）
    private var graphicsVRAM = Array(repeating: [UInt8](repeating: 0, count: 640 * 400 / 8), count: 3)
    
    /// デジタルパレット（8色）
    private var digitalPalette = [UInt32](repeating: 0, count: 8)
    
    /// アナログパレット（8色）
    private var analogPalette = [UInt32](repeating: 0, count: 8)
    
    /// 点滅状態を管理するフラグ（trueの場合、点滅テキストを表示）
    private var blinkState = true
    
    /// 点滅カウンター（60FPSでのカウント用）
    private var blinkCounter = 0
    
    /// 点滅タイマー
    private var blinkTimer: Timer?
    
    /// 現在の画面モード
    private var currentScreenMode: ScreenMode = .text
    
    /// 現在のテキストモード
    private var currentTextMode: PC88TextMode = .character
    
    /// 40桁モードかどうか
    private var is40ColumnMode = false
    
    /// 20行モードかどうか
    private var is20LineMode = false
    
    /// カラーモードかどうか
    var isColorMode = true
    
    /// 400ラインモードかどうか
    private var is400LineMode = false
    
    /// アナログモードかどうか
    private var isAnalogMode = false
    
    /// デジタルパレットかどうか
    private var isDigitalPalette: Bool {
        return !isAnalogMode
    }
    
    /// 現在のパレット（読み取り専用）
    private var palette: [UInt32] {
        return isDigitalPalette ? digitalPalette : analogPalette
    }
    
    /// パレットの設定（書き込み用）
    private func setPaletteColor(index: Int, color: UInt32) {
        if isDigitalPalette {
            digitalPalette[index] = color
        } else {
            analogPalette[index] = color
        }
    }
    
    /// 各行のテキストモード（文字/セミグラフィック）
    private var lineTextModes = [PC88TextMode](repeating: .character, count: 25)
    
    /// フォントデータ
    private var fontData = [UInt8](repeating: 0, count: 256 * 16)
    
    /// 画面バッファ
    private var screenBuffer: CGContext?
    
    /// CRTC/DMAC関連
    private var crtcParameters = [UInt8](repeating: 0, count: 5)
    private var crtcCommandRegister: UInt8 = 0
    private var crtcParameterIndex: Int = 0
    private var dmacAddress: UInt16 = 0
    private var dmacCount: UInt16 = 0
    
    // MARK: - 初期化
    
    init() {
        initializePalettes()
        initializeFontData()
        createScreenBuffer()
    }
    
    /// パレットの初期化
    private func initializePalettes() {
        // デジタルパレットの初期化（基本8色）（RGBA形式: 0xRRGGBBAA）
        digitalPalette[0] = 0x000000FF  // 黒
        digitalPalette[1] = 0x0000FFFF  // 青
        digitalPalette[2] = 0x00FF00FF  // 緑
        digitalPalette[3] = 0x00FFFFFF  // シアン
        digitalPalette[4] = 0xFF0000FF  // 赤
        digitalPalette[5] = 0xFF00FFFF  // マゼンタ
        digitalPalette[6] = 0xFFFF00FF  // 黄
        digitalPalette[7] = 0xFFFFFFFF  // 白
        
        // アナログパレットの初期化（デジタルパレットと同じ初期値）
        for i in 0..<8 {
            analogPalette[i] = digitalPalette[i]
        }
    }
    
    /// フォントデータの初期化
    private func initializeFontData() {
        // 仮のフォントデータ（実際にはROMから読み込むか、リソースから読み込む）
        // ここでは単純な例として、いくつかの文字だけ定義
        
        // スペース (0x20)
        let spaceIndex = 0x20 * fontHeight25
        for i in 0..<fontHeight25 {
            fontData[spaceIndex + i] = 0x00
        }
        
        // 'A' (0x41)
        let aIndex = 0x41 * fontHeight25
        fontData[aIndex + 0] = 0b00000000
        fontData[aIndex + 1] = 0b00011000
        fontData[aIndex + 2] = 0b00111100
        fontData[aIndex + 3] = 0b01100110
        fontData[aIndex + 4] = 0b01100110
        fontData[aIndex + 5] = 0b01111110
        fontData[aIndex + 6] = 0b01100110
        fontData[aIndex + 7] = 0b01100110
        fontData[aIndex + 8] = 0b01100110
        fontData[aIndex + 9] = 0b00000000
        fontData[aIndex + 10] = 0b00000000
        fontData[aIndex + 11] = 0b00000000
        fontData[aIndex + 12] = 0b00000000
        fontData[aIndex + 13] = 0b00000000
        fontData[aIndex + 14] = 0b00000000
        fontData[aIndex + 15] = 0b00000000
    }
    
    /// 画面バッファの作成
    private func createScreenBuffer() {
        let width = graphicsWidth
        let height = graphicsHeight400
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        screenBuffer = CGContext(data: nil,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: bitsPerComponent,
                                 bytesPerRow: bytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: bitmapInfo)
        
        // Y軸を反転させる（スクリーン座標系に合わせる）
        screenBuffer?.translateBy(x: 0, y: CGFloat(height))
        screenBuffer?.scaleBy(x: 1.0, y: -1.0)
    }
    
    /// CRTCとDMACの初期化
    private func initializeCRTCAndDMAC() {
        // CRTCパラメータの初期化
        crtcParameters = [UInt8](repeating: 0, count: 5)
        crtcCommandRegister = 0
        crtcParameterIndex = 0
        
        // DMACの初期化
        dmacAddress = 0
        dmacCount = 0
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
    
    /// フォントデータを設定
    func setFontData(charCode: UInt8, data: [UInt8]) {
        let offset = Int(charCode) * fontHeight25
        guard offset + data.count <= fontData.count else { return }
        
        // フォントデータをコピー
        for i in 0..<min(data.count, fontHeight25) {
            fontData[offset + i] = data[i]
        }
    }
    
    /// テスト画面を表示（デバッグ用）
    func displayTestScreen() {
        // 新しいテストクラスを使用してテスト画面を表示
        let screenTest = PC88ScreenTest(screen: self)
        screenTest.displayTestScreen()
    }
    
    /// 画面をクリア
    private func clearScreen() {
        // テキストVRAMをクリア
        for i in 0..<textVRAM.count {
            textVRAM[i] = 0x20 // スペース文字
        }
        
        // 全行を文字モードに設定
        for line in 0..<textHeight25 {
            setTextMode(.character, forLine: line)
        }
    }
    
    /// テキストを指定位置に書き込む
    private func writeText(_ text: String, atLine line: Int, column: Int) {
        guard line >= 0 && line < textHeight25 else { return }
        guard column >= 0 && column < textWidth80 else { return }
        
        let offset = line * textVRAMBytesPerLine + column
        
        for (i, char) in text.utf8.enumerated() {
            let pos = offset + i
            if pos < textVRAM.count && i + column < textWidth80 {
                textVRAM[pos] = char
            }
        }
    }
    
    /// 1文字を指定位置に書き込む（テスト用）
    func writeCharacter(_ char: UInt8, atLine line: Int, column: Int) {
        guard line >= 0 && line < textHeight25 else { return }
        guard column >= 0 && column < textWidth80 else { return }
        
        let offset = line * textVRAMBytesPerLine + column
        if offset < textVRAM.count {
            textVRAM[offset] = char
        }
    }
    
    /// 指定した行のテキストモードを設定
    func setTextMode(_ mode: PC88TextMode, forLine line: Int) {
        guard line >= 0 && line < textHeight25 else { return }
        
        lineTextModes[line] = mode
        
        // アトリビュートも更新
        let attributeOffset = line * textVRAMBytesPerLine + textWidth80
        
        // 最初のアトリビュートは常に位置0に適用
        textVRAM[attributeOffset] = 0x00
        
        if mode == .semiGraphics {
            // セミグラフィックモードの場合、bit7を1に設定
            if isColorMode {
                // カラーモード: 白色 + セミグラフィック (0xE8 | 0x10 = 0xF8)
                textVRAM[attributeOffset + 1] = 0xF8
            } else {
                // 白黒モード: 通常表示 + セミグラフィック (0x00 | 0x80 = 0x80)
                textVRAM[attributeOffset + 1] = 0x80
            }
        } else {
            // 文字モードの場合
            if isColorMode {
                // カラーモード: 白色 (0xE8)
                textVRAM[attributeOffset + 1] = 0xE8
            } else {
                // 白黒モード: 通常表示 (0x00)
                textVRAM[attributeOffset + 1] = 0x00
            }
        }
    }
    
    /// 色属性を設定
    func setColorAttribute(line: Int, startColumn: Int, color: UInt8) {
        guard line >= 0 && line < textHeight25 else { return }
        guard startColumn >= 0 && startColumn < textWidth80 else { return }
        guard isColorMode else { return }  // カラーモードのみ有効
        
        // アトリビュートの開始位置を計算
        let attributeOffset = line * textVRAMBytesPerLine + textWidth80
        
        // 既存のアトリビュート数をカウント
        var attributeCount = 0
        for i in stride(from: 0, to: maxAttributesPerLine * 2, by: 2) {
            if attributeOffset + i >= textVRAM.count || attributeOffset + i + 1 >= textVRAM.count || textVRAM[attributeOffset + i] == 0 {
                break
            }
            attributeCount += 1
        }
        
        // 最大アトリビュート数を超えていないか確認
        if attributeCount >= maxAttributesPerLine {
            // 既存の色属性を探して更新する
            for i in 0..<attributeCount {
                let posIndex = attributeOffset + i * 2
                let attrIndex = posIndex + 1
                
                if posIndex < textVRAM.count && attrIndex < textVRAM.count {
                    let pos = Int(textVRAM[posIndex])
                    let attr = textVRAM[attrIndex]
                    
                    if pos == startColumn && (attr & 0x08) != 0 {
                        // 同じ位置に色属性がある場合は更新
                        textVRAM[attrIndex] = 0x08 | (color & 0x07)
                        return
                    }
                }
            }
            return // 更新できない場合は終了
        }
        
        // 同じ位置に色属性が既にあるか確認
        var existingColorAttrIndex = -1
        for i in 0..<attributeCount {
            let posIndex = attributeOffset + i * 2
            let attrIndex = posIndex + 1
            
            if posIndex < textVRAM.count && attrIndex < textVRAM.count {
                let pos = Int(textVRAM[posIndex])
                let attr = textVRAM[attrIndex]
                
                if pos == startColumn && (attr & 0x08) != 0 {
                    // 同じ位置に色属性がある
                    existingColorAttrIndex = i
                    break
                }
            }
        }
        
        if existingColorAttrIndex != -1 {
            // 既存の色属性を更新
            let attrIndex = attributeOffset + existingColorAttrIndex * 2 + 1
            
            // PC-88のカラーコード（カラーモード色指定）: bit7=G, bit6=R, bit5=B
            // bit3=1は色属性を示す
            // 色コードをビットに変換
            let r = (color & 0x04) != 0 ? 0x40 : 0
            let g = (color & 0x02) != 0 ? 0x80 : 0
            let b = (color & 0x01) != 0 ? 0x20 : 0
            
            // bit3=1（色属性）、bit7,6,5に色情報を設定
            let newAttr = 0x08 | r | g | b
            
            textVRAM[attrIndex] = UInt8(newAttr)
            return
        }
        
        // 適切な位置に新しい色属性を挿入
        var insertIndex = -1
        for i in 0..<attributeCount {
            let positionIndex = attributeOffset + i * 2
            let currentPosition = Int(textVRAM[positionIndex])
            
            if currentPosition > startColumn {
                // この位置の前に挿入
                insertIndex = i
                break
            }
        }
        
        if insertIndex == -1 {
            // 末尾に追加
            insertIndex = attributeCount
        }
        
        // アトリビュートを挿入するために他のアトリビュートを移動
        for i in stride(from: attributeCount - 1, through: insertIndex, by: -1) {
            let srcPosIndex = attributeOffset + i * 2
            let srcAttrIndex = srcPosIndex + 1
            let dstPosIndex = attributeOffset + (i + 1) * 2
            let dstAttrIndex = dstPosIndex + 1
            
            if dstAttrIndex < textVRAM.count && srcAttrIndex < textVRAM.count {
                textVRAM[dstPosIndex] = textVRAM[srcPosIndex]
                textVRAM[dstAttrIndex] = textVRAM[srcAttrIndex]
            }
        }
        
        // 新しい色属性を設定
        let newPosIndex = attributeOffset + insertIndex * 2
        let newAttrIndex = newPosIndex + 1
        
        if newAttrIndex < textVRAM.count {
            textVRAM[newPosIndex] = UInt8(startColumn)
            
            // 色指定: bit3=1, RGB値を設定
            // PC-88のカラーコード（カラーモード色指定）: bit7=G, bit6=R, bit5=B
            // 色コードをビットに変換
            let r = (color & 0x04) != 0 ? 0x40 : 0
            let g = (color & 0x02) != 0 ? 0x80 : 0
            let b = (color & 0x01) != 0 ? 0x20 : 0
            
            // bit3=1（色属性）、bit7,6,5に色情報を設定
            let attr: UInt8 = UInt8(0x08 | r | g | b)
            
            textVRAM[newAttrIndex] = attr
        }
    }
    
    /// 装飾属性を設定
    func setDecorationAttribute(line: Int, startColumn: Int, decoration: PC88Decoration, underline: Bool = false, upperline: Bool = false) {
        guard line >= 0 && line < textHeight25 else { return }
        guard startColumn >= 0 && startColumn < textWidth80 else { return }
        
        // アトリビュートの開始位置を計算
        let attributeOffset = line * textVRAMBytesPerLine + textWidth80
        
        // 既存のアトリビュート数をカウント
        var attributeCount = 0
        for i in stride(from: 0, to: maxAttributesPerLine * 2, by: 2) {
            if attributeOffset + i >= textVRAM.count || attributeOffset + i + 1 >= textVRAM.count || textVRAM[attributeOffset + i] == 0 {
                break
            }
            attributeCount += 1
        }
        
        // 最大アトリビュート数を超えていないか確認
        if attributeCount >= maxAttributesPerLine {
            // 既存の装飾属性を探して更新する
            for i in 0..<attributeCount {
                let posIndex = attributeOffset + i * 2
                let attrIndex = posIndex + 1
                
                if posIndex < textVRAM.count && attrIndex < textVRAM.count {
                    let pos = Int(textVRAM[posIndex])
                    let attr = textVRAM[attrIndex]
                    
                    if pos == startColumn && (attr & 0x08) == 0 {
                        // 同じ位置に装飾属性がある場合は更新
                        var newAttr: UInt8 = 0
                        
                        // 装飾タイプに基づいて属性を設定
                        switch decoration {
                        case .normal:
                            newAttr = 0x00
                        case .reverse:
                            newAttr = 0x04 // bit2=1
                        case .blink:
                            newAttr = 0x02 // bit1=1
                        case .reverseBlink:
                            newAttr = 0x06 // bit2=1, bit1=1
                        case .secret:
                            newAttr = 0x01 // bit0=1
                        case .secretAlt:
                            newAttr = 0x03 // bit1=1, bit0=1
                        case .reverseSecret:
                            newAttr = 0x05 // bit2=1, bit0=1
                        }
                        
                        // アンダーライン/アッパーライン設定
                        if underline {
                            newAttr |= 0x20
                        }
                        if upperline {
                            newAttr |= 0x10
                        }
                        
                        textVRAM[attrIndex] = newAttr
                        return
                    }
                }
            }
            return // 更新できない場合は終了
        }
        
        // 同じ位置に装飾属性が既にあるか確認
        var existingDecorationAttrIndex = -1
        for i in 0..<attributeCount {
            let posIndex = attributeOffset + i * 2
            let attrIndex = posIndex + 1
            
            if posIndex < textVRAM.count && attrIndex < textVRAM.count {
                let pos = Int(textVRAM[posIndex])
                let attr = textVRAM[attrIndex]
                
                if pos == startColumn && (attr & 0x08) == 0 {
                    // 同じ位置に装飾属性がある (bit3=0は装飾属性)
                    existingDecorationAttrIndex = i
                    break
                }
            }
        }
        
        if existingDecorationAttrIndex != -1 {
            // 既存の装飾属性を更新
            let attrIndex = attributeOffset + existingDecorationAttrIndex * 2 + 1
            var attr: UInt8 = 0
            
            // 装飾タイプに基づいて属性を設定
            switch decoration {
            case .normal:
                attr = 0x00
            case .reverse:
                attr = 0x04 // bit2=1
            case .blink:
                attr = 0x02 // bit1=1
            case .reverseBlink:
                attr = 0x06 // bit2=1, bit1=1
            case .secret:
                attr = 0x01 // bit0=1
            case .secretAlt:
                attr = 0x03 // bit1=1, bit0=1
            case .reverseSecret:
                attr = 0x05 // bit2=1, bit0=1
            }
            
            // アンダーライン/アッパーライン設定
            if underline {
                attr |= 0x20
            }
            if upperline {
                attr |= 0x10
            }
            
            textVRAM[attrIndex] = attr
            return
        }
        
        // 適切な位置に新しい装飾属性を挿入
        var insertIndex = -1
        for i in 0..<attributeCount {
            let positionIndex = attributeOffset + i * 2
            let currentPosition = Int(textVRAM[positionIndex])
            
            if currentPosition > startColumn {
                // この位置の前に挿入
                insertIndex = i
                break
            }
        }
        
        if insertIndex == -1 {
            // 末尾に追加
            insertIndex = attributeCount
        }
        
        // アトリビュートを挿入するために他のアトリビュートを移動
        for i in stride(from: attributeCount - 1, through: insertIndex, by: -1) {
            let srcPosIndex = attributeOffset + i * 2
            let srcAttrIndex = srcPosIndex + 1
            let dstPosIndex = attributeOffset + (i + 1) * 2
            let dstAttrIndex = dstPosIndex + 1
            
            if dstAttrIndex < textVRAM.count && srcAttrIndex < textVRAM.count {
                textVRAM[dstPosIndex] = textVRAM[srcPosIndex]
                textVRAM[dstAttrIndex] = textVRAM[srcAttrIndex]
            }
        }
        
        // 新しい装飾属性を設定
        let newPosIndex = attributeOffset + insertIndex * 2
        let newAttrIndex = newPosIndex + 1
        
        if newAttrIndex < textVRAM.count {
            textVRAM[newPosIndex] = UInt8(startColumn)
            
            var attr: UInt8 = 0
            
            // 装飾タイプに基づいて属性を設定
            // PC-88の装飾コード: bit2=反転, bit1=点滅, bit0=消去
            switch decoration {
            case .normal:
                attr = 0x00
            case .reverse:
                attr = 0x04 // bit2=1
            case .blink:
                attr = 0x02 // bit1=1
            case .reverseBlink:
                attr = 0x06 // bit2=1, bit1=1
            case .secret:
                attr = 0x01 // bit0=1
            case .secretAlt:
                attr = 0x03 // bit1=1, bit0=1
            case .reverseSecret:
                attr = 0x05 // bit2=1, bit0=1
            }
            
            // アンダーライン/アッパーライン設定
            if underline {
                attr |= 0x20
            }
            if upperline {
                attr |= 0x10
            }
            
            textVRAM[newAttrIndex] = attr
        }
    }
    
    // MARK: - テキストVRAMアクセス
    
    /// テキストVRAMから読み込む
    func readTextVRAM(offset: Int) -> UInt8 {
        guard offset >= 0 && offset < textVRAM.count else { return 0x20 } // 範囲外の場合はスペース
        return textVRAM[offset]
    }
    
    /// テキストVRAMに書き込む
    func writeTextVRAM(offset: Int, value: UInt8) {
        guard offset >= 0 && offset < textVRAM.count else { return }
        textVRAM[offset] = value
    }
    
    // MARK: - 拡張機能
    
    /// 画面を描画する
    /// - Parameter context: 描画先のグラフィックスコンテキスト
    func render(to context: CGContext) {
        switch currentScreenMode {
        case .text:
            renderTextScreen(context: context)
        case .graphics:
            renderGraphicsScreen(context: context)
        case .mixed:
            renderGraphicsScreen(context: context)
            renderTextScreen(context: context)
        }
    }
    
    /// 画面をクリアする
    func clear() {
        clearScreen()
    }
    
    /// 画面の更新が必要かどうか
    var needsUpdate: Bool {
        return true // 常に更新が必要と仮定
    }
    
    /// 画面の幅（ピクセル単位）
    var screenWidth: Int {
        return graphicsWidth
    }
    
    /// 画面の高さ（ピクセル単位）
    var screenHeight: Int {
        return is400LineMode ? graphicsHeight400 : graphicsHeight200
    }
    
    // MARK: - I/Oポート処理
    
    /// I/Oポートからの読み込み
    func readIO(port: UInt16) -> UInt8 {
        switch port {
        case crtModeControlPort: // CRTモード制御ポート (0x30)
            // bit0: 40/80桁モード (0=80桁, 1=40桁)
            // bit1: 20/25行モード (0=25行, 1=20行)
            // bit2: カラー/白黒モード (0=白黒, 1=カラー)
            // bit3: グラフィックモード (0=オフ, 1=オン)
            var value: UInt8 = 0
            if is40ColumnMode { value |= 0x01 }
            if is20LineMode { value |= 0x02 }
            if isColorMode { value |= 0x04 }
            if currentScreenMode == .graphics || currentScreenMode == .mixed { value |= 0x08 }
            return value
            
        case crtLineControlPort: // CRT行数制御ポート (0x31)
            // bit0: 400ラインモード (0=200ライン, 1=400ライン)
            // bit1: アナログ/デジタルモード (0=デジタル, 1=アナログ)
            var value: UInt8 = 0
            if is400LineMode { value |= 0x01 }
            if isAnalogMode { value |= 0x02 }
            return value
            
        case colorModeControlPort: // カラーモード制御ポート (0x32)
            // パレット読み込みは実装されていない
            return 0
            
        case crtcCommandPort: // CRTCコマンドポート (0x51)
            return crtcCommandRegister
            
        case crtcParameterPort: // CRTCパラメータポート (0x50)
            if crtcParameterIndex < crtcParameters.count {
                return crtcParameters[crtcParameterIndex]
            }
            return 0
            
        case dmacCh2AddressPort: // DMACアドレスレジスター (0x64)
            return UInt8(dmacAddress & 0xFF)
            
        case dmacCh2CountPort: // DMACカウントレジスター (0x65)
            return UInt8(dmacCount & 0xFF)
            
        default:
            return 0
        }
    }
    
    /// I/Oポートへの書き込み
    func writeIO(port: UInt16, value: UInt8) {
        switch port {
        case crtModeControlPort: // CRTモード制御ポート (0x30)
            // bit0: 40/80桁モード (0=80桁, 1=40桁)
            // bit1: 20/25行モード (0=25行, 1=20行)
            // bit2: カラー/白黒モード (0=白黒, 1=カラー)
            // bit3: グラフィックモード (0=オフ, 1=オン)
            is40ColumnMode = (value & 0x01) != 0
            is20LineMode = (value & 0x02) != 0
            isColorMode = (value & 0x04) != 0
            
            if (value & 0x08) != 0 {
                // グラフィックモードON
                if currentScreenMode == .text {
                    currentScreenMode = .mixed
                }
            } else {
                // グラフィックモードOFF
                if currentScreenMode == .graphics || currentScreenMode == .mixed {
                    currentScreenMode = .text
                }
            }
            
        case crtLineControlPort: // CRT行数制御ポート (0x31)
            // bit0: 400ラインモード (0=200ライン, 1=400ライン)
            // bit1: アナログ/デジタルモード (0=デジタル, 1=アナログ)
            is400LineMode = (value & 0x01) != 0
            isAnalogMode = (value & 0x02) != 0
            
        case colorModeControlPort: // カラーモード制御ポート (0x32)
            // パレット設定処理を実装予定
            break
            
        case crtcCommandPort: // CRTCコマンドポート (0x51)
            crtcCommandRegister = value
            crtcParameterIndex = 0
            
        case crtcParameterPort: // CRTCパラメータポート (0x50)
            if crtcParameterIndex < crtcParameters.count {
                crtcParameters[crtcParameterIndex] = value
                crtcParameterIndex += 1
            }
            
        case dmacCh2AddressPort: // DMACアドレスレジスター (0x64)
            dmacAddress = (dmacAddress & 0xFF00) | UInt16(value)
            
        case dmacCh2CountPort: // DMACカウントレジスター (0x65)
            dmacCount = (dmacCount & 0xFF00) | UInt16(value)
            
        default:
            break
        }
    }
    
    /// テキストVRAMへの書き込み
    func writeTextVRAM(address: UInt16, value: UInt8) {
        let offset = Int(address)
        if offset < textVRAM.count {
            textVRAM[offset] = value
        }
    }
    
    /// テキストVRAMからの読み込み
    func readTextVRAM(address: UInt16) -> UInt8 {
        let offset = Int(address)
        if offset < textVRAM.count {
            return textVRAM[offset]
        }
        return 0
    }
    
    /// グラフィックVRAMへの書き込み
    func writeGraphicsVRAM(plane: Int, address: UInt16, value: UInt8) {
        guard plane >= 0 && plane < 3 else { return }
        
        let offset = Int(address)
        if offset < graphicsVRAM[plane].count {
            graphicsVRAM[plane][offset] = value
        }
    }
    
    /// グラフィックVRAMからの読み込み
    func readGraphicsVRAM(plane: Int, address: UInt16) -> UInt8 {
        guard plane >= 0 && plane < 3 else { return 0 }
        
        let offset = Int(address)
        if offset < graphicsVRAM[plane].count {
            return graphicsVRAM[plane][offset]
        }
        return 0
    }
    
    // MARK: - ScreenRendering プロトコル実装
    
    func initialize() {
        // テキストVRAMをクリア
        textVRAM = [UInt8](repeating: 0x20, count: textVRAMBytesPerLine * textHeight25)  // スペースで埋める
        
        // グラフィックVRAMをクリア
        for i in 0..<3 {
            graphicsVRAM[i] = [UInt8](repeating: 0, count: graphicsWidth * graphicsHeight400 / 8)
        }
        
        // パレットを初期化
        initializePalettes()
        
        // 画面モードをテキストモードに設定
        currentScreenMode = .text
        currentTextMode = .character
        
        // 各行のテキストモードを初期化
        lineTextModes = [PC88TextMode](repeating: .character, count: textHeight25)
        
        // 画面バッファを作成
        createScreenBuffer()
        
        // CRTCとDMACを初期化
        initializeCRTCAndDMAC()
        
        // 点滅タイマーを設定
        setupBlinkTimer()
    }
    
    func deinitialize() {
        // リソースの解放処理
        blinkTimer?.invalidate()
        blinkTimer = nil
    }
    
    /// 点滅状態を更新（60FPSに対応）
    func updateBlinkState() {
        // 60FPSでの点滅処理（約30フレームごとに切り替え）
        blinkCounter += 1
        if blinkCounter >= 30 { // 0.5秒相当（60FPSの場合）
            blinkState.toggle()
            blinkCounter = 0
        }
    }
    
    /// 点滅タイマーをセットアップ
    private func setupBlinkTimer() {
        // 既存のタイマーを停止
        blinkTimer?.invalidate()
        
        // 点滅処理はフレーム更新時に行うため、タイマーは不要
        blinkCounter = 0
        blinkState = true
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
        currentScreenMode = mode
    }
    
    func setPalette(index: Int, color: UInt8) {
        guard index >= 0 && index < digitalPalette.count else { return }
        
        // PC-88のパレット値をRGBA値に変換
        // PC-88のカラーコード: bit2=R, bit1=G, bit0=B
        let r = (color & 0x04) != 0 ? 255 : 0
        let g = (color & 0x02) != 0 ? 255 : 0
        let b = (color & 0x01) != 0 ? 255 : 0
        
        // RGBA値をUInt32に変換（アルファは常に255）
        // CGContextのピクセルフォーマットに合わせる (RGBA)
        setPaletteColor(index: index, color: (UInt32(r) << 24) | (UInt32(g) << 16) | (UInt32(b) << 8) | 255)
    }
    
    func render() -> CGImage? {
        guard let context = screenBuffer else { return nil }
        
        // 点滅状態を更新（60FPSに対応）
        updateBlinkState()
        
        // 背景を黒でクリア
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: graphicsWidth, height: graphicsHeight400))
        
        // 現在のモードに応じて描画
        switch currentScreenMode {
        case .text:
            renderTextScreen(context: context)
        case .graphics:
            renderGraphicsScreen(context: context)
        case .mixed:
            renderGraphicsScreen(context: context)
            renderTextScreen(context: context)
        }
        
        return context.makeImage()
    }
    
    func reset() {
        initialize()
    }
    
    // MARK: - プライベートメソッド
    
    /// パレットの初期化
    private func initializePalette() {
        // 基本8色パレット（RGBA形式: 0xRRGGBBAA）
        // PC-88の色コードに合わせてパレットを配置する
        // bit2=R(4), bit1=G(2), bit0=B(1)
        digitalPalette[0] = 0x000000FF  // 000: 黒
        digitalPalette[1] = 0x0000FFFF  // 001: 青
        digitalPalette[2] = 0x00FF00FF  // 010: 緑
        digitalPalette[3] = 0x00FFFFFF  // 011: シアン (G+B)
        digitalPalette[4] = 0xFF0000FF  // 100: 赤
        digitalPalette[5] = 0xFF00FFFF  // 101: マゼンタ (R+B)
        digitalPalette[6] = 0xFFFF00FF  // 110: 黄 (R+G)
        digitalPalette[7] = 0xFFFFFFFF  // 111: 白 (R+G+B)
    }
    
    // CRTCとDMACの初期化は上記initialize()メソッド内で実装済み
    
    // 画面バッファの作成は上記メソッドで実装済み
    
    /// テキスト画面の描画
    private func renderTextScreen(context: CGContext) {
        // テキスト画面の描画処理
        
        // テキストの行数と桁数を設定
        let textWidth = is40ColumnMode ? textWidth40 : textWidth80
        let textHeight = is20LineMode ? textHeight20 : textHeight25
        let fontHeight = is20LineMode ? fontHeight20 : fontHeight25
        
        // 各行ごとに描画
        for y in 0..<textHeight {
            // 行のテキストモードを取得
            let lineMode = lineTextModes[y]
            
            // 行のアトリビュート開始位置を計算
            let lineOffset = y * textVRAMBytesPerLine
            let attributeOffset = lineOffset + textWidth80
            
            // アトリビュート情報を取得
            var attributes: [(position: Int, color: UInt32, decoration: PC88Decoration, underline: Bool, upperline: Bool)] = []
            
            // アトリビュートを解析
            for i in stride(from: 0, to: maxAttributesPerLine * 2, by: 2) {
                if attributeOffset + i >= textVRAM.count || textVRAM[attributeOffset + i] == 0 {
                    break
                }
                
                let position = Int(textVRAM[attributeOffset + i])
                let attrValue = textVRAM[attributeOffset + i + 1]
                
                // アトリビュートタイプを判定
                let isColorAttr = (attrValue & 0x08) != 0
                
                if isColorAttr {
                    // 色指定の場合
                    // PC-88の色コード（カラーモード色指定）: bit7=G, bit6=R, bit5=B
                    let g = (attrValue & 0x80) != 0 ? 1 : 0
                    let r = (attrValue & 0x40) != 0 ? 1 : 0
                    let b = (attrValue & 0x20) != 0 ? 1 : 0
                    let colorIndex = UInt8((g << 2) | (r << 1) | b)
                    let color = isAnalogMode ? analogPalette[Int(colorIndex)] : digitalPalette[Int(colorIndex)]
                    
                    attributes.append((position, color, .normal, false, false))
                } else {
                    // 装飾指定の場合
                    // カラーモード（装飾指定）: bit5=アンダーライン, bit4=アッパーライン
                    let underline = (attrValue & 0x20) != 0
                    let upperline = (attrValue & 0x10) != 0
                    
                    // PC-88の装飾コード: bit2=反転, bit1=点滅, bit0=消去
                    var decoration: PC88Decoration = .normal
                    
                    // bit2: 反転
                    let isReverse = (attrValue & 0x04) != 0
                    // bit1: 点滅
                    let isBlink = (attrValue & 0x02) != 0
                    // bit0: 消去（シークレット）
                    let isSecret = (attrValue & 0x01) != 0
                    
                    if isReverse && isBlink && isSecret {
                        decoration = .reverseSecret
                    } else if isReverse && isBlink {
                        decoration = .reverseBlink
                    } else if isReverse && isSecret {
                        decoration = .reverseSecret
                    } else if isBlink && isSecret {
                        decoration = .secretAlt
                    } else if isReverse {
                        decoration = .reverse
                    } else if isBlink {
                        decoration = .blink
                    } else if isSecret {
                        decoration = .secret
                    }
                    
                    // デフォルトの色（白）を使用
                    attributes.append((position, 0xFFFFFFFF, decoration, underline, upperline))
                }
            }
            
            // 文字を描画
            for x in 0..<textWidth {
                let charIndex = lineOffset + x
                if charIndex < textVRAM.count {
                    let charCode = textVRAM[charIndex]
                    
                    // 描画位置を計算
                    let posX = x * fontWidth
                    let posY = y * fontHeight
                    
                    // 適用すべきアトリビュートを探す
                    var currentColor: UInt32 = 0xFFFFFFFF  // デフォルトは白
                    var currentDecoration: PC88Decoration = .normal
                    var hasUnderline = false
                    var hasUpperline = false
                    
                    // 色属性と装飾属性を個別に探す
                    for attr in attributes.reversed() {
                        if x >= attr.position {
                            if attr.decoration != .normal {
                                // 装飾属性の場合
                                currentDecoration = attr.decoration
                                hasUnderline = attr.underline
                                hasUpperline = attr.upperline
                            }
                            break
                        }
                    }
                    
                    // 色属性を探す
                    for attr in attributes.reversed() {
                        if x >= attr.position && attr.decoration == .normal {
                            // 色属性の場合
                            currentColor = attr.color
                            break
                        }
                    }
                    
                    // セミグラフィックモードの場合の描画処理
                    if lineMode == .semiGraphics {
                        // セミグラフィックモードの描画処理を実装予定
                        // ここでは簡易的な実装として、文字コードをそのままパターンとして使用
                        
                        // 4x2のセミグラフィックブロックを描画
                        for blockY in 0..<2 {
                            for blockX in 0..<4 {
                                let bitPos = blockY * 4 + blockX
                                let isOn = (charCode & (1 << bitPos)) != 0
                                
                                if isOn {
                                    // セミグラフィックブロックを描画
                                    context.setFillColor(CGColor(
                                        red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                        green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                        blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                        alpha: CGFloat(currentColor & 0xFF) / 255.0
                                    ))
                                    
                                    let blockWidth = fontWidth / 4
                                    let blockHeight = fontHeight / 2
                                    context.fill(CGRect(
                                        x: posX + blockX * blockWidth,
                                        y: posY + blockY * blockHeight,
                                        width: blockWidth,
                                        height: blockHeight
                                    ))
                                }
                            }
                        }
                    } else {
                        // 文字モードの描画処理
                        
                        // 装飾に基づいて描画を制御
                        switch currentDecoration {
                        case .normal:
                            // 通常描画
                            drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: currentColor)
                            
                        case .secret, .secretAlt:
                            // 非表示（何も描画しない）
                            // シークレットモードでは文字を表示しない
                            break
                            
                        case .blink:
                            // 点滅状態に応じて表示/非表示を切り替え
                            if blinkState {
                                // 点滅ONの場合は文字を表示
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: currentColor)
                            } else {
                                // 点滅OFFの場合は何も表示しない
                            }
                            
                        case .reverse:
                            // 反転表示 - 背景を前景色で描画
                            // 背景を前景色で描画
                            context.setFillColor(CGColor(
                                red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                alpha: CGFloat(currentColor & 0xFF) / 255.0
                            ))
                            context.fill(CGRect(x: posX, y: posY, width: fontWidth, height: fontHeight))
                            
                            // 文字を黒で描画（反転）
                            drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: 0x000000FF)
                            
                        case .reverseBlink:
                            // 点滅状態に応じて反転表示を切り替え
                            if blinkState {
                                // 点滅ONの場合は反転表示
                                // 背景を前景色で描画
                                context.setFillColor(CGColor(
                                    red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                    green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                    blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                    alpha: CGFloat(currentColor & 0xFF) / 255.0
                                ))
                                context.fill(CGRect(x: posX, y: posY, width: fontWidth, height: fontHeight))
                                
                                // 文字を黒で描画（反転）
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: 0x000000FF)
                            } else {
                                // 点滅OFFの場合は通常描画
                                drawCharacter(context: context, charCode: charCode, x: posX, y: posY, color: currentColor)
                            }
                            
                        case .reverseSecret:
                            // 反転シークレット - 背景のみ描画（文字は表示しない）
                            context.setFillColor(CGColor(
                                red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                alpha: CGFloat(currentColor & 0xFF) / 255.0
                            ))
                            context.fill(CGRect(x: posX, y: posY, width: fontWidth, height: fontHeight))
                        }
                        
                        // アンダーラインを描画
                        if hasUnderline {
                            context.setFillColor(CGColor(
                                red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                alpha: CGFloat(currentColor & 0xFF) / 255.0
                            ))
                            context.fill(CGRect(x: posX, y: posY + fontHeight - 1, width: fontWidth, height: 1))
                        }
                        
                        // アッパーラインを描画
                        if hasUpperline {
                            context.setFillColor(CGColor(
                                red: CGFloat((currentColor >> 24) & 0xFF) / 255.0,
                                green: CGFloat((currentColor >> 16) & 0xFF) / 255.0,
                                blue: CGFloat((currentColor >> 8) & 0xFF) / 255.0,
                                alpha: CGFloat(currentColor & 0xFF) / 255.0
                            ))
                            context.fill(CGRect(x: posX, y: posY, width: fontWidth, height: 1))
                        }
                    }
                }
            }
        }
    }
    
    /// 文字を描画
    private func drawCharacter(context: CGContext, charCode: UInt8, x: Int, y: Int, color: UInt32) {
        // フォントデータのオフセットを計算
        let fontOffset = Int(charCode) * (is20LineMode ? fontHeight20 : fontHeight25)
        let fontHeight = is20LineMode ? fontHeight20 : fontHeight25
        
        // フォントをピクセル単位で描画
        context.setFillColor(CGColor(
            red: CGFloat((color >> 24) & 0xFF) / 255.0,
            green: CGFloat((color >> 16) & 0xFF) / 255.0,
            blue: CGFloat((color >> 8) & 0xFF) / 255.0,
            alpha: CGFloat(color & 0xFF) / 255.0
        ))
        
        for fontY in 0..<fontHeight {
            if fontOffset + fontY < fontData.count {
                let fontLine = fontData[fontOffset + fontY]
                
                for fontX in 0..<fontWidth {
                    if (fontLine & (0x80 >> fontX)) != 0 {
                        // ピクセルを描画
                        context.fill(CGRect(x: x + fontX, y: y + fontY, width: 1, height: 1))
                    }
                }
            }
        }
    }
        
    /// グラフィック画面の描画
    private func renderGraphicsScreen(context: CGContext) {
        // グラフィックモードの描画処理
        
        // 描画領域のサイズを設定
        let width = graphicsWidth
        let height = is400LineMode ? graphicsHeight400 : graphicsHeight200
        
        // 各プレーンのデータを描画
        for y in 0..<height {
            for x in 0..<width {
                // ピクセル位置に対応するバイトとビット位置を計算
                let bytePos = (y * width + x) / 8
                let bitPos = 7 - (x % 8)  // MSBが左端
                
                // 各プレーンのビット値を取得
                var r = false
                var g = false
                var b = false
                
                if bytePos < graphicsVRAM[0].count {
                    r = (graphicsVRAM[0][bytePos] & (1 << bitPos)) != 0
                    g = (graphicsVRAM[1][bytePos] & (1 << bitPos)) != 0
                    b = (graphicsVRAM[2][bytePos] & (1 << bitPos)) != 0
                }
                
                // ピクセルの色を決定
                if r || g || b {
                    var colorIndex: UInt8 = 0
                    if r { colorIndex |= 0x01 }
                    if g { colorIndex |= 0x02 }
                    if b { colorIndex |= 0x04 }
                    
                    // パレットから色を取得
                    let color = isAnalogMode ? analogPalette[Int(colorIndex)] : digitalPalette[Int(colorIndex)]
                    
                    // ピクセルを描画
                    context.setFillColor(CGColor(
                        red: CGFloat((color >> 24) & 0xFF) / 255.0,
                        green: CGFloat((color >> 16) & 0xFF) / 255.0,
                        blue: CGFloat((color >> 8) & 0xFF) / 255.0,
                        alpha: CGFloat(color & 0xFF) / 255.0
                    ))
                    
                    // 400ラインモードでない場合は、Y方向に2倍の高さで描画
                    let pixelHeight = is400LineMode ? 1 : 2
                    context.fill(CGRect(x: x, y: y * pixelHeight, width: 1, height: pixelHeight))
                }
            }
        }
    }
    
    // PC88FontLoaderからフォントデータを取得
    private let fontLoader = PC88FontLoader.shared
    
    /// テスト用に文字を表示するメソッド
    private func displayTestChars(context: CGContext) {
        // 「PC-88」と表示する
        let testChars: [UInt8] = [0x50, 0x43, 0x2D, 0x38, 0x38]  // "PC-88"
        
        for (i, char) in testChars.enumerated() {
            // 前景色と背景色を設定
            let fgColor: UInt32 = 0xFFFFFFFF  // 白
            let bgColor: UInt32 = 0x000000FF  // 黒
            
            // 文字の位置を計算
            let x = 10 + i * fontWidth
            let y = 10
            
            // 背景を描画
            context.setFillColor(CGColor(
                red: CGFloat((bgColor >> 24) & 0xFF) / 255.0,
                green: CGFloat((bgColor >> 16) & 0xFF) / 255.0,
                blue: CGFloat((bgColor >> 8) & 0xFF) / 255.0,
                alpha: CGFloat(bgColor & 0xFF) / 255.0
            ))
            context.fill(CGRect(x: x, y: y, width: fontWidth, height: fontHeight))
            
            // PC88FontLoaderからフォントデータを取得して描画
            if let fontBitmap = fontLoader.getFontBitmap8x16(charCode: char) {
                for cy in 0..<fontHeight {
                    if cy < fontBitmap.count {
                        let fontLine = fontBitmap[cy]
                        for cx in 0..<fontWidth {
                            if (fontLine & (0x80 >> cx)) != 0 {
                                let pixelX = x + cx
                                let pixelY = y + cy
                                context.setFillColor(CGColor(
                                    red: CGFloat((fgColor >> 24) & 0xFF) / 255.0,
                                    green: CGFloat((fgColor >> 16) & 0xFF) / 255.0,
                                    blue: CGFloat((fgColor >> 8) & 0xFF) / 255.0,
                                    alpha: CGFloat(fgColor & 0xFF) / 255.0
                                ))
                                context.fill(CGRect(x: pixelX, y: pixelY, width: 1, height: 1))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - テスト画面表示
    
    /// シンプルなテスト画面を表示するメソッド
    func displaySimpleTestScreen() {
        // テキストVRAMに文字を書き込む
        let message = "PC-88 Emulator for iOS"
        for (i, char) in message.utf8.enumerated() {
            if i < textWidth80 {
                textVRAM[i] = char
            }
        }
        
        // テキスト属性を設定
        setColorAttribute(line: 0, startColumn: 0, color: 1)  // 青
        setColorAttribute(line: 0, startColumn: 5, color: 2)  // 緑
        setDecorationAttribute(line: 0, startColumn: 14, decoration: .reverse)  // 反転
        setDecorationAttribute(line: 0, startColumn: 20, decoration: .blink, underline: true)  // 点滅+アンダーライン
    }
    
    // MARK: - デバッグ用メソッド
    
    /// デバッグ用にテキストVRAMの内容を表示する
    func debugPrintTextVRAM() {
        print("\n--- テキストVRAMの内容 ---")
        let textWidth = is40ColumnMode ? textWidth40 : textWidth80
        let textHeight = is20LineMode ? textHeight20 : textHeight25
        
        for y in 0..<textHeight {
            var line = ""
            for x in 0..<textWidth {
                let index = y * textWidth + x
                if index < textVRAM.count {
                    let char = textVRAM[index]
                    // 制御文字はピリオドに置き換えて表示
                    if char < 0x20 || char >= 0x7F {
                        line += "."
                    } else {
                        line += String(UnicodeScalar(char))
                    }
                }
            }
            print("\(y): \(line)")
        }
        print("------------------------\n")
    }
    
    // MARK: - テキスト描画メソッド
    
    /// テキストVRAMの内容を描画するメソッド
    private func drawTextVRAMContent(context: CGContext) {
        // テキストの行数と桁数を設定
        let textWidth = is40ColumnMode ? textWidth40 : textWidth80
        let textHeight = is20LineMode ? textHeight20 : textHeight25
        
        for y in 0..<textHeight {
            for x in 0..<textWidth {
                let index = y * textWidth + x
                if index < textVRAM.count && index < attributeVRAM.count {
                    let char = textVRAM[index]
                    let attr = attributeVRAM[index]
                    
                    // 文字の前景色と背景色を決定
                    let fgColorIndex = (attr & 0x07)
                    let bgColorIndex = (attr >> 3) & 0x07
                    let fgColor = palette[Int(fgColorIndex)]
                    let bgColor = palette[Int(bgColorIndex)]
                    
                    // 背景を描画
                    let rectX = x * fontWidth
                    let rectY = y * fontHeight + 50  // テスト文字の下に表示
                    context.setFillColor(CGColor(
                        red: CGFloat((bgColor >> 24) & 0xFF) / 255.0,
                        green: CGFloat((bgColor >> 16) & 0xFF) / 255.0,
                        blue: CGFloat((bgColor >> 8) & 0xFF) / 255.0,
                        alpha: CGFloat(bgColor & 0xFF) / 255.0
                    ))
                    context.fill(CGRect(x: rectX, y: rectY, width: fontWidth, height: fontHeight))
                    
                    // PC88FontLoaderからフォントデータを取得して描画
                    if let fontBitmap = fontLoader.getFontBitmap8x16(charCode: char) {
                        for cy in 0..<fontHeight {
                            if cy < fontBitmap.count {
                                let fontLine = fontBitmap[cy]
                                for cx in 0..<fontWidth {
                                    if (fontLine & (0x80 >> cx)) != 0 {
                                        let pixelX = rectX + cx
                                        let pixelY = rectY + cy
                                        context.setFillColor(CGColor(
                                            red: CGFloat((fgColor >> 24) & 0xFF) / 255.0,
                                            green: CGFloat((fgColor >> 16) & 0xFF) / 255.0,
                                            blue: CGFloat((fgColor >> 8) & 0xFF) / 255.0,
                                            alpha: CGFloat(fgColor & 0xFF) / 255.0
                                        ))
                                        context.fill(CGRect(x: pixelX, y: pixelY, width: 1, height: 1))
                                    }
                                }
                            }
                        }
                    } else {
                        // フォントデータが取得できない場合は内部フォントデータを使用
                        let fontOffset = Int(char) * fontHeight
                        if fontOffset + fontHeight <= fontData.count {
                            for cy in 0..<fontHeight {
                                let fontLine = fontData[fontOffset + cy]
                                for cx in 0..<fontWidth {
                                    if (fontLine & (0x80 >> cx)) != 0 {
                                        let pixelX = rectX + cx
                                        let pixelY = rectY + cy
                                        context.setFillColor(CGColor(
                                            red: CGFloat((fgColor >> 24) & 0xFF) / 255.0,
                                            green: CGFloat((fgColor >> 16) & 0xFF) / 255.0,
                                            blue: CGFloat((fgColor >> 8) & 0xFF) / 255.0,
                                            alpha: CGFloat(fgColor & 0xFF) / 255.0
                                        ))
                                        context.fill(CGRect(x: pixelX, y: pixelY, width: 1, height: 1))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 保存した状態を復元
        context.restoreGState()
    }
    
    /// グラフィックモードの描画
    private func renderGraphicsMode(_ context: CGContext) {
        let height = is400LineMode ? graphicsHeight400 : graphicsHeight200
        
        for y in 0..<height {
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
    
    /// 指定された文字コードのフォントデータを取得
    /// - Parameter charCode: 文字コード
    /// - Returns: フォントデータ
    func getFontData(charCode: UInt8) -> [UInt8] {
        let fontOffset = Int(charCode) * fontHeight
        
        // フォントデータの境界チェック
        if fontOffset + fontHeight <= fontData.count {
            return Array(fontData[fontOffset..<fontOffset+fontHeight])
        } else {
            print("フォントデータの範囲外アクセス: 文字コード \(charCode), オフセット \(fontOffset)")
            return [UInt8](repeating: 0, count: fontHeight)
        }
    }
    
    /// テキストVRAMに文字列を書き込む
    /// - Parameters:
    ///   - text: 表示する文字列
    ///   - x: X座標（文字単位）
    ///   - y: Y座標（文字単位）
    ///   - attribute: 属性（色など）
    func writeText(_ text: String, x: Int, y: Int, attribute: UInt8 = 0x07) {
        // 現在のテキスト幅と高さを取得
        let textWidth = is40ColumnMode ? textWidth40 : textWidth80
        let textHeight = is20LineMode ? textHeight20 : textHeight25
        
        // 座標のチェック
        guard x >= 0 && x < textWidth && y >= 0 && y < textHeight else {
            print("テキスト表示範囲外: (\(x), \(y))")
            return
        }
        
        var currentX = x
        for char in text {
            if currentX >= textWidth {
                break
            }
            
            let index = y * textWidth + currentX
            if index < textVRAM.count {
                // ASCIIコードに変換して書き込む
                if let asciiValue = char.asciiValue {
                    textVRAM[index] = asciiValue
                    attributeVRAM[index] = attribute
                    print("文字設定: '\(char)' (\(asciiValue)) at (\(currentX), \(y))")
                } else {
                    // ASCII以外の文字はスペースに
                    textVRAM[index] = 0x20 // スペース
                    attributeVRAM[index] = attribute
                }
            }
            
            currentX += 1
        }
    }
    
    /// 詳細なテスト表示用のスタブプログラム
    func displayDetailedTestScreen() {
        let textWidth = is40ColumnMode ? textWidth40 : textWidth80
        let textHeight = is20LineMode ? textHeight20 : textHeight25
        
        // 画面をクリア
        for i in 0..<min(textWidth * textHeight, textVRAM.count) {
            textVRAM[i] = 0x20 // スペース
            if i < attributeVRAM.count {
                attributeVRAM[i] = 0x07 // 白地に黒文字
            }
        }
        
        // タイトルを表示 (中央上部)
        writeText("PC-88 Emulator", x: 30, y: 1, attribute: 0x17) // 高輝度白地に黒文字
        
        // メニューライン (左上)
        writeText("1:BASIC 2:DISK 3:MONITOR", x: 0, y: 3, attribute: 0x07)
        
        // ステータス表示 (左上)
        writeText("PC-88 READY", x: 0, y: 5, attribute: 0x02) // 緑色
        
        // テストパターン (画面中央)
        for i in 0..<10 {
            writeText(String(format: "Line %02d: ABCDEFGHIJKLMNOPQRSTUVWXYZ", i), x: 2, y: 7 + i, attribute: UInt8(i % 7 + 1))
        }
        
        // カーソル位置に文字を表示
        writeText("_", x: 10, y: 5, attribute: 0x02) // カーソル
        
        // サンプル文字を表示 (右上)
        writeText("88-Cb", x: 70, y: 0, attribute: 0x04) // 赤色
    }
}
