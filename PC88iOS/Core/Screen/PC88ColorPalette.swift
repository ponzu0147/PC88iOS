//
//  PC88ColorPalette.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation
import CoreGraphics

/// PC-88のカラーパレットを管理するクラス
class PC88ColorPalette {
    /// デジタルパレット（8色）
    private var digitalPalette = [UInt32](repeating: 0, count: 8)
    
    /// アナログパレット（8色）
    private var analogPalette = [UInt32](repeating: 0, count: 8)
    
    /// アナログモードかどうか
    private var isAnalogMode = false
    
    /// デジタルパレットかどうか
    var isDigitalPalette: Bool {
        return !isAnalogMode
    }
    
    /// 現在のパレット（読み取り専用）
    var palette: [UInt32] {
        return isDigitalPalette ? digitalPalette : analogPalette
    }
    
    /// 初期化
    init() {
        initializeDefaultPalettes()
    }
    
    /// デフォルトパレットの初期化
    private func initializeDefaultPalettes() {
        // デジタルパレットの初期化（8色）
        digitalPalette[0] = 0xFF000000  // 黒
        digitalPalette[1] = 0xFF0000FF  // 青
        digitalPalette[2] = 0xFFFF0000  // 赤
        digitalPalette[3] = 0xFFFF00FF  // マゼンタ
        digitalPalette[4] = 0xFF00FF00  // 緑
        digitalPalette[5] = 0xFF00FFFF  // シアン
        digitalPalette[6] = 0xFFFFFF00  // 黄
        digitalPalette[7] = 0xFFFFFFFF  // 白
        
        // アナログパレットも同じ初期値で設定
        analogPalette = digitalPalette
    }
    
    /// パレットの設定
    func setPaletteColor(index: Int, color: UInt32) {
        guard index >= 0 && index < 8 else { return }
        
        if isDigitalPalette {
            digitalPalette[index] = color
        } else {
            analogPalette[index] = color
        }
    }
    
    /// パレットの設定（PC-88形式の色コード）
    func setPalette(index: Int, colorCode: UInt8) {
        guard index >= 0 && index < 8 else { return }
        
        // PC-88のカラーコード（0-7）をRGBA値に変換
        let r = (colorCode & 0x04) != 0 ? 0xFF : 0x00
        let g = (colorCode & 0x02) != 0 ? 0xFF : 0x00
        let b = (colorCode & 0x01) != 0 ? 0xFF : 0x00
        
        let color: UInt32 = 0xFF000000 | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
        setPaletteColor(index: index, color: color)
    }
    
    /// アナログモードの設定
    func setAnalogMode(_ enabled: Bool) {
        isAnalogMode = enabled
    }
    
    /// 色コードから色を取得
    func getColor(colorCode: UInt8) -> UInt32 {
        let index = Int(colorCode & 0x07)
        return palette[index]
    }
    
    /// CGColorを取得
    func getCGColor(colorCode: UInt8) -> CGColor {
        let color = getColor(colorCode: colorCode)
        
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        
        return CGColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// デジタルカラーを設定
    func setDigitalColor(index: Int, color: UInt32) {
        guard index >= 0 && index < 8 else { return }
        digitalPalette[index] = color
    }
    
    /// アナログカラーを設定
    func setAnalogColor(index: Int, color: UInt32) {
        guard index >= 0 && index < 8 else { return }
        analogPalette[index] = color
    }
    
    /// デジタルカラーを取得
    func getDigitalColor(index: Int) -> UInt32 {
        guard index >= 0 && index < 8 else { return 0xFF000000 }
        return digitalPalette[index]
    }
    
    /// アナログカラーを取得
    func getAnalogColor(index: Int) -> UInt32 {
        guard index >= 0 && index < 8 else { return 0xFF000000 }
        return analogPalette[index]
    }
    
    /// リセット
    func reset() {
        initializeDefaultPalettes()
        isAnalogMode = false
    }
}
