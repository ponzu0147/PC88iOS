//
//  PC88GraphicsRenderer.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation
import CoreGraphics

/// PC-88のグラフィック描画を担当するクラス
class PC88GraphicsRenderer {
    /// グラフィックVRAM（3プレーン: R, G, B）
    private var graphicsVRAM: [[UInt8]]
    
    /// 画面設定
    private var settings: PC88ScreenSettings
    
    /// カラーパレット
    private var colorPalette: PC88ColorPalette
    
    /// 初期化
    init(graphicsVRAM: [[UInt8]], settings: PC88ScreenSettings, colorPalette: PC88ColorPalette) {
        self.graphicsVRAM = graphicsVRAM
        self.settings = settings
        self.colorPalette = colorPalette
    }
    
    /// グラフィックVRAMの参照を更新
    func updateGraphicsVRAMReference(_ graphicsVRAM: [[UInt8]]) {
        self.graphicsVRAM = graphicsVRAM
    }
    
    /// グラフィックVRAMを更新
    func updateGraphicsVRAM(at address: UInt16, value: UInt8, plane: Int) {
        guard plane >= 0 && plane < 3 else { return }
        
        let offset = Int(address)
        if offset < graphicsVRAM[plane].count {
            graphicsVRAM[plane][offset] = value
        }
    }
    
    /// グラフィックVRAMをクリア
    func clearGraphicsVRAM() {
        for plane in 0..<3 {
            for i in 0..<graphicsVRAM[plane].count {
                graphicsVRAM[plane][i] = 0
            }
        }
    }
    
    /// グラフィックモードを描画
    func renderGraphicsMode(_ context: CGContext) {
        let height = settings.is400LineMode ? PC88ScreenConstants.graphicsHeight400 : PC88ScreenConstants.graphicsHeight200
        
        for y in 0..<height {
            for x in 0..<PC88ScreenConstants.graphicsWidth {
                // ピクセルの色を取得
                let colorCode = getPixelColor(x: x, y: y)
                
                // 色が0（黒）でない場合のみ描画
                if colorCode != 0 {
                    let color = colorPalette.getCGColor(colorCode: colorCode)
                    context.setFillColor(color)
                    
                    // 200ラインモードの場合は、1ピクセルを縦に2倍に拡大
                    if settings.is400LineMode {
                        context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    } else {
                        context.fill(CGRect(x: x, y: y * 2, width: 1, height: 2))
                    }
                }
            }
        }
    }
    
    /// ピクセルの色を取得
    private func getPixelColor(x: Int, y: Int) -> UInt8 {
        // ピクセル位置からバイトオフセットとビット位置を計算
        let byteOffset = (y * PC88ScreenConstants.graphicsWidth + x) / 8
        let bitPosition = 7 - (x % 8)  // MSBが左端
        
        // 各プレーンのビット値を取得
        var colorCode: UInt8 = 0
        
        if byteOffset < graphicsVRAM[0].count {
            // 青プレーン (B)
            if (graphicsVRAM[0][byteOffset] & (1 << bitPosition)) != 0 {
                colorCode |= 0x01
            }
            
            // 赤プレーン (R)
            if (graphicsVRAM[1][byteOffset] & (1 << bitPosition)) != 0 {
                colorCode |= 0x04
            }
            
            // 緑プレーン (G)
            if (graphicsVRAM[2][byteOffset] & (1 << bitPosition)) != 0 {
                colorCode |= 0x02
            }
        }
        
        return colorCode
    }
    
    /// テストパターンを描画
    func drawTestPattern() {
        clearGraphicsVRAM()
        
        // 水平カラーバー
        let colors = [1, 2, 3, 4, 5, 6, 7]  // 青、緑、シアン、赤、マゼンタ、黄、白
        let barHeight = PC88ScreenConstants.graphicsHeight400 / colors.count
        
        for (i, color) in colors.enumerated() {
            let startY = i * barHeight
            let endY = (i + 1) * barHeight
            
            for y in startY..<endY {
                for x in 0..<PC88ScreenConstants.graphicsWidth {
                    setPixel(x: x, y: y, color: UInt8(color))
                }
            }
        }
    }
    
    /// ピクセルを設定
    private func setPixel(x: Int, y: Int, color: UInt8) {
        // ピクセル位置からバイトオフセットとビット位置を計算
        let byteOffset = (y * PC88ScreenConstants.graphicsWidth + x) / 8
        let bitPosition = 7 - (x % 8)  // MSBが左端
        
        if byteOffset < graphicsVRAM[0].count {
            // 青プレーン (B)
            if (color & 0x01) != 0 {
                graphicsVRAM[0][byteOffset] |= (1 << bitPosition)
            } else {
                graphicsVRAM[0][byteOffset] &= ~(1 << bitPosition)
            }
            
            // 赤プレーン (R)
            if (color & 0x04) != 0 {
                graphicsVRAM[1][byteOffset] |= (1 << bitPosition)
            } else {
                graphicsVRAM[1][byteOffset] &= ~(1 << bitPosition)
            }
            
            // 緑プレーン (G)
            if (color & 0x02) != 0 {
                graphicsVRAM[2][byteOffset] |= (1 << bitPosition)
            } else {
                graphicsVRAM[2][byteOffset] &= ~(1 << bitPosition)
            }
        }
    }
    
    /// 線を描画
    func drawLine(x1: Int, y1: Int, x2: Int, y2: Int, color: UInt8) {
        // ブレゼンハムのアルゴリズムで線を描画
        var x = x1
        var y = y1
        
        let dx = abs(x2 - x1)
        let dy = abs(y2 - y1)
        let sx = x1 < x2 ? 1 : -1
        let sy = y1 < y2 ? 1 : -1
        var err = dx - dy
        
        while true {
            setPixel(x: x, y: y, color: color)
            
            if x == x2 && y == y2 {
                break
            }
            
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x += sx
            }
            if e2 < dx {
                err += dx
                y += sy
            }
        }
    }
    
    /// 矩形を描画
    func drawRect(x: Int, y: Int, width: Int, height: Int, color: UInt8, fill: Bool = false) {
        if fill {
            // 塗りつぶし矩形
            for py in y..<(y + height) {
                for px in x..<(x + width) {
                    setPixel(x: px, y: py, color: color)
                }
            }
        } else {
            // 枠線のみ
            drawLine(x1: x, y1: y, x2: x + width - 1, y2: y, color: color)  // 上辺
            drawLine(x1: x, y1: y + height - 1, x2: x + width - 1, y2: y + height - 1, color: color)  // 下辺
            drawLine(x1: x, y1: y, x2: x, y2: y + height - 1, color: color)  // 左辺
            drawLine(x1: x + width - 1, y1: y, x2: x + width - 1, y2: y + height - 1, color: color)  // 右辺
        }
    }
    
    /// 円を描画
    func drawCircle(centerX: Int, centerY: Int, radius: Int, color: UInt8, fill: Bool = false) {
        if fill {
            // 塗りつぶし円
            for y in (centerY - radius)...(centerY + radius) {
                for x in (centerX - radius)...(centerX + radius) {
                    let dx = x - centerX
                    let dy = y - centerY
                    if dx * dx + dy * dy <= radius * radius {
                        setPixel(x: x, y: y, color: color)
                    }
                }
            }
        } else {
            // 円周のみ
            var x = radius
            var y = 0
            var err = 0
            
            while x >= y {
                setPixel(x: centerX + x, y: centerY + y, color: color)
                setPixel(x: centerX + y, y: centerY + x, color: color)
                setPixel(x: centerX - y, y: centerY + x, color: color)
                setPixel(x: centerX - x, y: centerY + y, color: color)
                setPixel(x: centerX - x, y: centerY - y, color: color)
                setPixel(x: centerX - y, y: centerY - x, color: color)
                setPixel(x: centerX + y, y: centerY - x, color: color)
                setPixel(x: centerX + x, y: centerY - y, color: color)
                
                y += 1
                if err <= 0 {
                    err += 2 * y + 1
                }
                if err > 0 {
                    x -= 1
                    err -= 2 * x + 1
                }
            }
        }
    }
}
