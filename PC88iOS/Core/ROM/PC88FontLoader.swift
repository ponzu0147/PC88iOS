//
//  PC88FontLoader.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import CoreGraphics

/// PC-88のフォントを読み込み・処理するためのクラス
class PC88FontLoader {
    // MARK: - シングルトン
    
    /// シングルトンインスタンス
    static let shared = PC88FontLoader()
    
    // MARK: - プロパティ
    
    /// フォントデータ（8x8）
    private var font8x8: [UInt8]?
    
    /// フォントデータ（8x16）
    private var font8x16: [UInt8]?
    
    // MARK: - 初期化
    
    private init() {
        // シングルトンのため、privateに
    }
    
    // MARK: - メソッド
    
    /// フォントデータを読み込む
    /// - Returns: 読み込みに成功したかどうか
    func loadFonts() -> Bool {
        // フォントROMを読み込む
        if let fontROMData = loadFontROMDirectly() {
            // データサイズを確認
            PC88Logger.core.debug("フォントROMデータサイズ: \(fontROMData.count) バイト")
            
            // 8x8フォントデータを抽出
            if fontROMData.count >= 2048 {
                font8x8 = Array(fontROMData.prefix(2048))
                PC88Logger.core.debug("8x8フォントデータを読み込みました (サイズ: \(font8x8?.count ?? 0) バイト)")
            } else {
                PC88Logger.core.error("8x8フォントデータの読み込みに失敗しました: データサイズ不足")
                return false
            }
            
            // 8x16フォントデータを抽出
            if fontROMData.count >= 4096 {
                font8x16 = Array(fontROMData.suffix(from: 2048))
                PC88Logger.core.debug("8x16フォントデータを読み込みました (サイズ: \(font8x16?.count ?? 0) バイト)")
                
                // デバッグ用に最初の数バイトを表示
                if let font = font8x16, !font.isEmpty {
                    PC88Logger.core.debug("最初の数バイト: \(font.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " "))")
                }
            } else {
                PC88Logger.core.error("8x16フォントデータの読み込みに失敗しました: データサイズ不足")
                return false
            }
            
            PC88Logger.core.debug("フォントROMを読み込みました")
            return true
        }
        
        // PC88ROMLoaderからの読み込みを試す
        if let fontROMData = PC88ROMLoader.shared.loadROM(.font) {
            PC88Logger.core.debug("フォントROMデータサイズ (PC88ROMLoader): \(fontROMData.count) バイト")
            
            // 8x8フォントデータを抽出
            if fontROMData.count >= 2048 {
                font8x8 = Array(fontROMData.prefix(2048))
                PC88Logger.core.debug("8x8フォントデータを読み込みました (サイズ: \(font8x8?.count ?? 0) バイト)")
            } else {
                PC88Logger.core.error("8x8フォントデータの読み込みに失敗しました: データサイズ不足")
                return false
            }
            
            // 8x16フォントデータを抽出
            if fontROMData.count >= 4096 {
                font8x16 = Array(fontROMData.suffix(from: 2048))
                PC88Logger.core.debug("8x16フォントデータを読み込みました (サイズ: \(font8x16?.count ?? 0) バイト)")
            } else {
                PC88Logger.core.error("8x16フォントデータの読み込みに失敗しました: データサイズ不足")
                return false
            }
            
            PC88Logger.core.debug("フォントROMをPC88ROMLoaderから読み込みました")
            return true
        }
        
        // フォントデータをハードコードして作成
        PC88Logger.core.warning("フォントROMの読み込みに失敗しました。デフォルトフォントを使用します")
        createDefaultFont()
        return true
    }
    
    /// フォントROMを直接読み込む
    /// - Returns: ROMデータ、読み込みに失敗した場合はnil
    private func loadFontROMDirectly() -> Data? {
        // 1. Documentsディレクトリから読み込みを試みる
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("font.rom")
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let romData = try Data(contentsOf: fileURL)
                    PC88Logger.core.debug("フォントROMをDocumentsから読み込みました: font.rom")
                    return romData
                } catch {
                    PC88Logger.core.error("フォントROMの読み込みに失敗しました(Documents): \(error)")
                }
            }
        }
        
        // 2. バンドルから試す
        if let url = Bundle.main.url(forResource: "font", withExtension: "rom") {
            do {
                let romData = try Data(contentsOf: url)
                PC88Logger.core.debug("フォントROMをバンドルから読み込みました: font.rom")
                return romData
            } catch {
                PC88Logger.core.error("フォントROMの読み込みに失敗しました(バンドル): \(error)")
            }
        }
        
        // 3. Resourcesディレクトリから試す
        if let url = Bundle.main.url(forResource: "font", withExtension: "rom", subdirectory: "Resources") {
            do {
                let romData = try Data(contentsOf: url)
                PC88Logger.core.debug("フォントROMをResourcesから読み込みました: font.rom")
                return romData
            } catch {
                PC88Logger.core.error("フォントROMの読み込みに失敗しました(Resources): \(error)")
            }
        }
        
        // 4. 直接ファイルパスを指定して試す
        let resourcePath = "/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS/Resources/font.rom"
        let fileURL = URL(fileURLWithPath: resourcePath)
        
        if FileManager.default.fileExists(atPath: resourcePath) {
            do {
                let romData = try Data(contentsOf: fileURL)
                PC88Logger.core.debug("フォントROMを直接パスから読み込みました: \(resourcePath)")
                return romData
            } catch {
                PC88Logger.core.error("フォントROMの読み込みに失敗しました(直接パス): \(error)")
            }
        }
        
        return nil
    }
    
    /// 指定された文字コードのフォントビットマップを取得（8x8）
    /// - Parameter charCode: 文字コード（0-255）
    /// - Returns: 8バイトのフォントデータ
    func getFontBitmap8x8(charCode: UInt8) -> [UInt8]? {
        guard let font8x8 = font8x8 else { return nil }
        
        let offset = Int(charCode) * 8
        guard offset + 8 <= font8x8.count else { return nil }
        
        // フォントデータを取得
        let fontData = Array(font8x8[offset..<offset+8])
        return fontData
    }
    
    /// 指定された文字コードのフォントビットマップを取得（8x16）
    /// - Parameter charCode: 文字コード（0-255）
    /// - Returns: 16バイトのフォントデータ
    func getFontBitmap8x16(charCode: UInt8) -> [UInt8]? {
        guard let font8x16 = font8x16 else { return nil }
        
        let offset = Int(charCode) * 16
        guard offset + 16 <= font8x16.count else { return nil }
        
        // フォントデータを取得
        let fontData = Array(font8x16[offset..<offset+16])
        return fontData
    }
    
    /// バイト内のビット順を反転する
    /// - Parameter byte: 元のバイト
    /// - Returns: ビット順を反転したバイト
    private func reverseBits(_ byte: UInt8) -> UInt8 {
        var result: UInt8 = 0
        var temp = byte
        
        for _ in 0..<8 {
            result = (result << 1) | (temp & 1)
            temp >>= 1
        }
        
        return result
    }
    
    /// 文字のビットマップからCGImageを生成（8x8）
    /// - Parameters:
    ///   - charCode: 文字コード
    ///   - foregroundColor: 前景色
    ///   - backgroundColor: 背景色
    /// - Returns: CGImage
    func createCGImage8x8(charCode: UInt8, foregroundColor: UInt32 = 0xFFFFFFFF, backgroundColor: UInt32 = 0x00000000) -> CGImage? {
        guard let bitmap = getFontBitmap8x8(charCode: charCode) else { return nil }
        
        // ピクセルデータを作成
        var pixels = [UInt32](repeating: backgroundColor, count: 8 * 8)
        
        // ビットマップからピクセルデータを生成
        for y in 0..<8 {
            let row = bitmap[y]
            for x in 0..<8 {
                if (row & (0x80 >> x)) != 0 {
                    pixels[y * 8 + x] = foregroundColor
                }
            }
        }
        
        // CGImageを生成
        let bitsPerComponent = 8
        _ = 32
        let bytesPerRow = 8 * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(data: &pixels, width: 8, height: 8, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        return context.makeImage()
    }
    
    /// 文字のビットマップからCGImageを生成（8x16）
    /// - Parameters:
    ///   - charCode: 文字コード
    ///   - foregroundColor: 前景色
    ///   - backgroundColor: 背景色
    /// - Returns: CGImage
    func createCGImage8x16(charCode: UInt8, foregroundColor: UInt32 = 0xFFFFFFFF, backgroundColor: UInt32 = 0x00000000) -> CGImage? {
        guard let bitmap = getFontBitmap8x16(charCode: charCode) else { return nil }
        
        // ピクセルデータを作成
        var pixels = [UInt32](repeating: backgroundColor, count: 8 * 16)
        
        // ビットマップからピクセルデータを生成
        for y in 0..<16 {
            let row = bitmap[y]
            for x in 0..<8 {
                if (row & (0x80 >> x)) != 0 {
                    pixels[y * 8 + x] = foregroundColor
                }
            }
        }
        
        // CGImageを生成
        let bitsPerComponent = 8
        _ = 32
        let bytesPerRow = 8 * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(data: &pixels, width: 8, height: 16, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        return context.makeImage()
    }
    
    /// デフォルトフォントを作成
    private func createDefaultFont() {
        // 8x8フォントを初期化
        font8x8 = [UInt8](repeating: 0, count: 256 * 8)
        
        // 8x16フォントを初期化
        font8x16 = [UInt8](repeating: 0, count: 256 * 16)
        
        // ASCII文字の一部を定義
        
        // スペース (0x20)
        // 空のまま
        
        // 'A' (0x41)
        let aIndex = 0x41 * 16
        font8x16![aIndex + 0] = 0b00001000
        font8x16![aIndex + 1] = 0b00011100
        font8x16![aIndex + 2] = 0b00110110
        font8x16![aIndex + 3] = 0b01100011
        font8x16![aIndex + 4] = 0b01100011
        font8x16![aIndex + 5] = 0b01111111
        font8x16![aIndex + 6] = 0b01100011
        font8x16![aIndex + 7] = 0b01100011
        font8x16![aIndex + 8] = 0b01100011
        font8x16![aIndex + 9] = 0b01100011
        font8x16![aIndex + 10] = 0b00000000
        font8x16![aIndex + 11] = 0b00000000
        font8x16![aIndex + 12] = 0b00000000
        font8x16![aIndex + 13] = 0b00000000
        font8x16![aIndex + 14] = 0b00000000
        font8x16![aIndex + 15] = 0b00000000
        
        // 'B' (0x42)
        let bIndex = 0x42 * 16
        font8x16![bIndex + 0] = 0b01111100
        font8x16![bIndex + 1] = 0b01100110
        font8x16![bIndex + 2] = 0b01100110
        font8x16![bIndex + 3] = 0b01100110
        font8x16![bIndex + 4] = 0b01111100
        font8x16![bIndex + 5] = 0b01100110
        font8x16![bIndex + 6] = 0b01100110
        font8x16![bIndex + 7] = 0b01100110
        font8x16![bIndex + 8] = 0b01100110
        font8x16![bIndex + 9] = 0b01111100
        font8x16![bIndex + 10] = 0b00000000
        font8x16![bIndex + 11] = 0b00000000
        font8x16![bIndex + 12] = 0b00000000
        font8x16![bIndex + 13] = 0b00000000
        font8x16![bIndex + 14] = 0b00000000
        font8x16![bIndex + 15] = 0b00000000
        
        // 'C' (0x43)
        let cIndex = 0x43 * 16
        font8x16![cIndex + 0] = 0b00111100
        font8x16![cIndex + 1] = 0b01100110
        font8x16![cIndex + 2] = 0b01100000
        font8x16![cIndex + 3] = 0b01100000
        font8x16![cIndex + 4] = 0b01100000
        font8x16![cIndex + 5] = 0b01100000
        font8x16![cIndex + 6] = 0b01100000
        font8x16![cIndex + 7] = 0b01100000
        font8x16![cIndex + 8] = 0b01100110
        font8x16![cIndex + 9] = 0b00111100
        font8x16![cIndex + 10] = 0b00000000
        font8x16![cIndex + 11] = 0b00000000
        font8x16![cIndex + 12] = 0b00000000
        font8x16![cIndex + 13] = 0b00000000
        font8x16![cIndex + 14] = 0b00000000
        font8x16![cIndex + 15] = 0b00000000
        
        // 'P' (0x50)
        let pIndex = 0x50 * 16
        font8x16![pIndex + 0] = 0b01111100
        font8x16![pIndex + 1] = 0b01100110
        font8x16![pIndex + 2] = 0b01100110
        font8x16![pIndex + 3] = 0b01100110
        font8x16![pIndex + 4] = 0b01111100
        font8x16![pIndex + 5] = 0b01100000
        font8x16![pIndex + 6] = 0b01100000
        font8x16![pIndex + 7] = 0b01100000
        font8x16![pIndex + 8] = 0b01100000
        font8x16![pIndex + 9] = 0b01100000
        font8x16![pIndex + 10] = 0b00000000
        font8x16![pIndex + 11] = 0b00000000
        font8x16![pIndex + 12] = 0b00000000
        font8x16![pIndex + 13] = 0b00000000
        font8x16![pIndex + 14] = 0b00000000
        font8x16![pIndex + 15] = 0b00000000
        
        // '8' (0x38)
        let eightIndex = 0x38 * 16
        font8x16![eightIndex + 0] = 0b00111100
        font8x16![eightIndex + 1] = 0b01100110
        font8x16![eightIndex + 2] = 0b01100110
        font8x16![eightIndex + 3] = 0b01100110
        font8x16![eightIndex + 4] = 0b00111100
        font8x16![eightIndex + 5] = 0b01100110
        font8x16![eightIndex + 6] = 0b01100110
        font8x16![eightIndex + 7] = 0b01100110
        font8x16![eightIndex + 8] = 0b01100110
        font8x16![eightIndex + 9] = 0b00111100
        font8x16![eightIndex + 10] = 0b00000000
        font8x16![eightIndex + 11] = 0b00000000
        font8x16![eightIndex + 12] = 0b00000000
        font8x16![eightIndex + 13] = 0b00000000
        font8x16![eightIndex + 14] = 0b00000000
        font8x16![eightIndex + 15] = 0b00000000
        
        // '-' (0x2D)
        let minusIndex = 0x2D * 16
        font8x16![minusIndex + 0] = 0b00000000
        font8x16![minusIndex + 1] = 0b00000000
        font8x16![minusIndex + 2] = 0b00000000
        font8x16![minusIndex + 3] = 0b00000000
        font8x16![minusIndex + 4] = 0b00000000
        font8x16![minusIndex + 5] = 0b01111110
        font8x16![minusIndex + 6] = 0b00000000
        font8x16![minusIndex + 7] = 0b00000000
        font8x16![minusIndex + 8] = 0b00000000
        font8x16![minusIndex + 9] = 0b00000000
        font8x16![minusIndex + 10] = 0b00000000
        font8x16![minusIndex + 11] = 0b00000000
        font8x16![minusIndex + 12] = 0b00000000
        font8x16![minusIndex + 13] = 0b00000000
        font8x16![minusIndex + 14] = 0b00000000
        font8x16![minusIndex + 15] = 0b00000000
        
        PC88Logger.core.debug("デフォルトフォントを作成しました")
    }
}
