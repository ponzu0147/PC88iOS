//
//  PC88AttributeHandler.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation
import CoreGraphics

/// PC-88の属性処理を担当するクラス
class PC88AttributeHandler {
    /// テキストVRAMの参照
    private var textVRAM: [UInt8]
    
    /// 画面設定の参照
    private var settings: PC88ScreenSettings
    
    /// 点滅状態
    private var blinkState = true
    
    /// 初期化
    init(textVRAM: [UInt8], settings: PC88ScreenSettings) {
        self.textVRAM = textVRAM
        self.settings = settings
    }
    
    /// テキストVRAMの参照を更新
    func updateTextVRAMReference(_ textVRAM: [UInt8]) {
        self.textVRAM = textVRAM
    }
    
    /// 点滅状態を更新
    func updateBlinkState(_ state: Bool) {
        blinkState = state
    }
    
    /// 色属性を設定
    func setColorAttribute(line: Int, startColumn: Int, color: UInt8) {
        guard line >= 0 && line < (settings.is20LineMode ? PC88ScreenConstants.textHeight20 : PC88ScreenConstants.textHeight25) else { return }
        let maxWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        guard startColumn >= 0 && startColumn < maxWidth else { return }
        guard settings.isColorMode else { return }  // カラーモードのみ有効
        
        // アトリビュートの開始位置を計算
        let lineOffset = line * PC88ScreenConstants.textVRAMBytesPerLine
        let attributeOffset = lineOffset + (settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80)
        
        // 現在のアトリビュート数を取得
        let attributeCount = min(Int(textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1]), PC88ScreenConstants.maxAttributesPerLine)
        
        // 新しいアトリビュートの挿入位置を探す
        var insertIndex = 0
        var found = false
        
        for i in 0..<attributeCount {
            let positionIndex = attributeOffset + i * 2
            let currentPosition = Int(textVRAM[positionIndex])
            
            if currentPosition > startColumn {
                // 挿入位置を見つけた
                insertIndex = i
                found = true
                break
            } else if currentPosition == startColumn {
                // 同じ位置のアトリビュートが既に存在する場合は上書き
                let attrIndex = attributeOffset + i * 2 + 1
                
                // 色指定: bit3=1, RGB値を設定
                // PC-88のカラーコード（カラーモード色指定）: bit7=G, bit6=R, bit5=B
                textVRAM[attrIndex] = 0x08 | (color & 0x07)
                return
            }
        }
        
        if !found {
            // 末尾に追加
            insertIndex = attributeCount
        }
        
        // アトリビュート数が最大に達している場合は何もしない
        if attributeCount >= PC88ScreenConstants.maxAttributesPerLine {
            return
        }
        
        // 挿入位置以降のアトリビュートを後ろにずらす
        for i in stride(from: attributeCount - 1, through: insertIndex, by: -1) {
            let srcPosIndex = attributeOffset + i * 2
            let srcAttrIndex = srcPosIndex + 1
            let destPosIndex = attributeOffset + (i + 1) * 2
            let destAttrIndex = destPosIndex + 1
            
            textVRAM[destPosIndex] = textVRAM[srcPosIndex]
            textVRAM[destAttrIndex] = textVRAM[srcAttrIndex]
        }
        
        // 新しいアトリビュートを挿入
        let newPosIndex = attributeOffset + insertIndex * 2
        let newAttrIndex = newPosIndex + 1
        
        if newAttrIndex < textVRAM.count {
            textVRAM[newPosIndex] = UInt8(startColumn)
            
            // 色指定: bit3=1, RGB値を設定
            // PC-88のカラーコード（カラーモード色指定）: bit7=G, bit6=R, bit5=B
            textVRAM[newAttrIndex] = 0x08 | (color & 0x07)
            
            // アトリビュート数を更新
            textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1] = UInt8(attributeCount + 1)
        }
    }
    
    /// 装飾属性を設定
    func setDecorationAttribute(line: Int, startColumn: Int, decoration: PC88Decoration, underline: Bool = false, upperline: Bool = false) {
        guard line >= 0 && line < (settings.is20LineMode ? PC88ScreenConstants.textHeight20 : PC88ScreenConstants.textHeight25) else { return }
        let maxWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        guard startColumn >= 0 && startColumn < maxWidth else { return }
        
        // アトリビュートの開始位置を計算
        let lineOffset = line * PC88ScreenConstants.textVRAMBytesPerLine
        let attributeOffset = lineOffset + (settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80)
        
        // 現在のアトリビュート数を取得
        let attributeCount = min(Int(textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1]), PC88ScreenConstants.maxAttributesPerLine)
        
        // 新しいアトリビュートの挿入位置を探す
        var insertIndex = 0
        var found = false
        
        for i in 0..<attributeCount {
            let positionIndex = attributeOffset + i * 2
            let currentPosition = Int(textVRAM[positionIndex])
            
            if currentPosition > startColumn {
                // 挿入位置を見つけた
                insertIndex = i
                found = true
                break
            } else if currentPosition == startColumn {
                // 同じ位置のアトリビュートが既に存在する場合は上書き
                let attrIndex = attributeOffset + i * 2 + 1
                
                // 装飾指定: bit3=0, 装飾値を設定
                var attr: UInt8 = decoration.rawValue
                
                // アンダーライン: bit7=1
                if underline {
                    attr |= 0x80
                }
                
                // アッパーライン: bit6=1
                if upperline {
                    attr |= 0x40
                }
                
                textVRAM[attrIndex] = attr
                return
            }
        }
        
        if !found {
            // 末尾に追加
            insertIndex = attributeCount
        }
        
        // アトリビュート数が最大に達している場合は何もしない
        if attributeCount >= PC88ScreenConstants.maxAttributesPerLine {
            return
        }
        
        // 挿入位置以降のアトリビュートを後ろにずらす
        for i in stride(from: attributeCount - 1, through: insertIndex, by: -1) {
            let srcPosIndex = attributeOffset + i * 2
            let srcAttrIndex = srcPosIndex + 1
            let destPosIndex = attributeOffset + (i + 1) * 2
            let destAttrIndex = destPosIndex + 1
            
            textVRAM[destPosIndex] = textVRAM[srcPosIndex]
            textVRAM[destAttrIndex] = textVRAM[srcAttrIndex]
        }
        
        // 新しいアトリビュートを挿入
        let newPosIndex = attributeOffset + insertIndex * 2
        let newAttrIndex = newPosIndex + 1
        
        if newAttrIndex < textVRAM.count {
            textVRAM[newPosIndex] = UInt8(startColumn)
            
            // 装飾指定: bit3=0, 装飾値を設定
            var attr: UInt8 = decoration.rawValue
            
            // アンダーライン: bit7=1
            if underline {
                attr |= 0x80
            }
            
            // アッパーライン: bit6=1
            if upperline {
                attr |= 0x40
            }
            
            textVRAM[newAttrIndex] = attr
            
            // アトリビュート数を更新
            textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1] = UInt8(attributeCount + 1)
        }
    }
    
    /// 指定位置の属性を取得
    /// アトリビュート情報を格納する構造体
    struct AttributeInfo {
        let attributeType: PC88AttributeType
        let value: UInt8
        let hasUnderline: Bool
        let hasUpperline: Bool
    }
    
    func getAttribute(line: Int, column: Int) -> AttributeInfo? {
        let maxHeight = settings.is20LineMode ? PC88ScreenConstants.textHeight20 : PC88ScreenConstants.textHeight25
        guard line >= 0 && line < maxHeight else { return nil }
        let maxWidth = settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80
        guard column >= 0 && column < maxWidth else { return nil }
        
        // 行のオフセットを計算
        let lineOffset = line * PC88ScreenConstants.textVRAMBytesPerLine
        let attributeOffset = lineOffset + (settings.is40ColumnMode ? PC88ScreenConstants.textWidth40 : PC88ScreenConstants.textWidth80)
        
        // アトリビュート数を取得
        let attributeCount = min(Int(textVRAM[lineOffset + PC88ScreenConstants.textVRAMBytesPerLine - 1]), PC88ScreenConstants.maxAttributesPerLine)
        
        // 該当する列以前の最後のアトリビュートを探す
        var lastAttrIndex = -1
        var lastAttrPosition = -1
        
        for i in 0..<attributeCount {
            let positionIndex = attributeOffset + i * 2
            let position = Int(textVRAM[positionIndex])
            
            if position <= column && position > lastAttrPosition {
                lastAttrPosition = position
                lastAttrIndex = i
            }
        }
        
        // アトリビュートが見つからなかった場合
        if lastAttrIndex == -1 {
            return nil
        }
        
        // アトリビュート値を取得
        let attrValueIndex = attributeOffset + lastAttrIndex * 2 + 1
        let attrValue = textVRAM[attrValueIndex]
        
        // アトリビュートタイプを判定
        let isColorAttr = (attrValue & 0x08) != 0
        let attributeType: PC88AttributeType = isColorAttr ? .color : .decoration
        
        // アンダーライン/アッパーラインの有無を取得
        let hasUnderline = (attrValue & 0x80) != 0
        let hasUpperline = (attrValue & 0x40) != 0
        
        // 値を取得（色または装飾）
        let value: UInt8
        if isColorAttr {
            // 色属性の場合は下位3ビットを取得
            value = attrValue & 0x07
        } else {
            // 装飾属性の場合は下位3ビットを取得
            value = attrValue & 0x07
        }
        
        return AttributeInfo(attributeType: attributeType, value: value, hasUnderline: hasUnderline, hasUpperline: hasUpperline)
    }
    
    /// 指定位置の装飾を取得
    /// 装飾情報を格納する構造体
    struct DecorationInfo {
        let decoration: PC88Decoration
        let hasUnderline: Bool
        let hasUpperline: Bool
        let shouldDisplay: Bool
    }
    
    func getDecoration(line: Int, column: Int) -> DecorationInfo? {
        guard let attr = getAttribute(line: line, column: column) else {
            // デフォルト値を返す
            return DecorationInfo(decoration: PC88Decoration.normal, hasUnderline: false, hasUpperline: false, shouldDisplay: true)
        }
        
        // 色属性の場合は装飾なし
        if attr.attributeType == .color {
            return DecorationInfo(decoration: PC88Decoration.normal, hasUnderline: false, hasUpperline: false, shouldDisplay: true)
        }
        
        // 装飾値からPC88Decorationを取得
        let decoration = PC88Decoration(rawValue: attr.value) ?? .normal
        
        // 点滅する装飾の場合、blinkStateに応じて表示/非表示を決定
        var shouldDisplay = true
        if decoration == .blink || decoration == .reverseBlink {
            shouldDisplay = blinkState
        } else if decoration == .secret || decoration == .secretAlt || decoration == .reverseSecret {
            shouldDisplay = false
        }
        
        return DecorationInfo(decoration: decoration, hasUnderline: attr.hasUnderline, hasUpperline: attr.hasUpperline, shouldDisplay: shouldDisplay)
    }
    
    /// 指定位置の色を取得
    func getColor(line: Int, column: Int) -> UInt8 {
        guard let attr = getAttribute(line: line, column: column) else {
            // デフォルト値（白）を返す
            return 7
        }
        
        // 色属性の場合はその値を返す
        if attr.attributeType == .color {
            return attr.value
        }
        
        // 装飾属性の場合はデフォルト値（白）を返す
        return 7
    }
}
