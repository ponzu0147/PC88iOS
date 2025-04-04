//
//  PC88ScreenModels.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation

/// PC-88の画面モード
enum PC88ScreenMode {
    /// テキストモードのみ
    case text
    /// グラフィックモードのみ
    case graphics
    /// テキストとグラフィックの混合モード
    case mixed
}

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

/// PC-88の画面設定
struct PC88ScreenSettings {
    /// 40桁モードかどうか (false = 80桁モード, true = 40桁モード)
    var is40ColumnMode = false
    /// 20行モードかどうか (false = 25行モード, true = 20行モード)
    var is20LineMode = false
    /// カラーモードかどうか (false = 白黒モード, true = カラーモード)
    var isColorMode = true
    /// 400ラインモードかどうか (false = 200ラインモード, true = 400ラインモード)
    var is400LineMode = true
    /// アナログモードかどうか (false = デジタルモード, true = アナログモード)
    var isAnalogMode = false
    /// 点滅を有効にするかどうか
    var isBlinkEnabled = true
    
    /// 現在のテキストモード
    var currentTextMode: PC88TextMode = .character
    
    /// 現在の列数を取得
    var columns: Int {
        return is40ColumnMode ? 40 : 80
    }
    
    /// 現在の行数を取得
    var lines: Int {
        return is20LineMode ? 20 : 25
    }
    
    /// 現在の画面の高さを取得
    var screenHeight: Int {
        return is400LineMode ? PC88ScreenConstants.graphicsHeight400 : PC88ScreenConstants.graphicsHeight200
    }
    
    /// 現在の画面の幅を取得
    var screenWidth: Int {
        return PC88ScreenConstants.graphicsWidth
    }
}

/// PC-88の画面サイズ定数
struct PC88ScreenConstants {
    // テキスト関連
    static let textWidth80 = 80
    static let textWidth40 = 40
    static let textHeight25 = 25
    static let textHeight20 = 20
    static let fontWidth = 8
    static let fontHeight25 = 16
    static let fontHeight20 = 20
    static let textVRAMBytesPerLine = 120
    static let maxAttributesPerLine = 20
    
    // グラフィック関連
    static let graphicsWidth = 640
    static let graphicsHeight400 = 400
    static let graphicsHeight200 = 200
    static let semiGraphicsWidth = 160
    static let semiGraphicsHeight = 100
    
    // I/Oポート
    static let crtModeControlPort: UInt16 = 0x30    // CRTモード制御ポート
    static let crtLineControlPort: UInt16 = 0x31    // CRT行数制御ポート
    static let colorModeControlPort: UInt16 = 0x32  // カラーモード制御ポート
    static let crtcParameterPort: UInt16 = 0x50     // CRTCパラメータポート
    static let crtcCommandPort: UInt16 = 0x51       // CRTCコマンドポート
    static let dmacCh2AddressPort: UInt16 = 0x64    // DMAC Ch.2アドレスポート
    static let dmacCh2CountPort: UInt16 = 0x65      // DMAC Ch.2カウントポート
    static let dmacControlPort: UInt16 = 0x68       // DMAC制御ポート
}
