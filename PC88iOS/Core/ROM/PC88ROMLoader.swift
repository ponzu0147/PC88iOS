//
//  PC88ROMLoader.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// PC-88のROMを読み込むためのクラス
class PC88ROMLoader {
    // MARK: - ROM種類の定義
    
    /// ROM種類
    enum ROMType: String {
        case n88 = "N88.ROM"       // N88-BASIC ROM
        case n88n = "N88N.ROM"     // N88-BASIC ROM (N88-V2モード)
        case n880 = "N88_0.ROM"    // フォントROM 0
        case n881 = "N88_1.ROM"    // フォントROM 1
        case n882 = "N88_2.ROM"    // フォントROM 2
        case n883 = "N88_3.ROM"    // フォントROM 3
        case disk = "DISK.ROM"     // ディスクROM
        case font = "font.rom"     // フォントROM
    }
    
    // MARK: - シングルトン
    
    /// シングルトンインスタンス
    static let shared = PC88ROMLoader()
    
    /// ROMキャッシュ
    private var romCache: [ROMType: Data] = [:]
    
    // MARK: - 初期化
    
    private init() {
        // シングルトンのため、privateに
    }
    
    // MARK: - メソッド
    
    /// 指定されたROMを読み込む
    /// - Parameter type: ROM種類
    /// - Returns: ROMデータ、読み込みに失敗した場合はnil
    func loadROM(_ type: ROMType) -> Data? {
        // キャッシュにあればそれを返す
        if let cachedROM = romCache[type] {
            return cachedROM
        }
        
        // 1. Documentsディレクトリから読み込みを試みる
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(type.rawValue)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let romData = try Data(contentsOf: fileURL)
                    romCache[type] = romData
                    PC88Logger.core.debug("ROM loaded from Documents: \(type.rawValue)")
                    return romData
                } catch {
                    PC88Logger.core.error("Failed to load ROM from Documents \(type.rawValue): \(error)")
                }
            }
        }
        
        // 2. リソースからROMを読み込む
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: nil) {
            do {
                let romData = try Data(contentsOf: url)
                romCache[type] = romData
                PC88Logger.core.debug("ROM loaded from Bundle: \(type.rawValue)")
                return romData
            } catch {
                PC88Logger.core.error("Failed to load ROM from Bundle \(type.rawValue): \(error)")
            }
        }
        
        // 3. Resourcesディレクトリから試す
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: nil, subdirectory: "Resources") {
            do {
                let romData = try Data(contentsOf: url)
                romCache[type] = romData
                PC88Logger.core.debug("ROM loaded from Resources: \(type.rawValue)")
                return romData
            } catch {
                PC88Logger.core.error("Failed to load ROM from Resources \(type.rawValue): \(error)")
            }
        }
        
        // 4. 直接ファイルパスを指定して試す
        let resourcePath = "/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS/Resources/\(type.rawValue)"
        let fileURL = URL(fileURLWithPath: resourcePath)
        
        if FileManager.default.fileExists(atPath: resourcePath) {
            do {
                let romData = try Data(contentsOf: fileURL)
                romCache[type] = romData
                PC88Logger.core.debug("ROM loaded from direct path: \(type.rawValue)")
                return romData
            } catch {
                PC88Logger.core.error("Failed to load ROM from direct path \(type.rawValue): \(error)")
            }
        }
        
        PC88Logger.core.error("ROM file not found: \(type.rawValue)")
        return nil
    }
    
    /// 全てのROMを読み込む
    /// - Returns: 読み込みに成功したかどうか
    func loadAllROMs() -> Bool {
        let romTypes: [ROMType] = [.n88, .n88n, .n880, .n881, .n882, .n883, .disk, .font]
        
        for type in romTypes {
            if loadROM(type) == nil {
                return false
            }
        }
        
        return true
    }
}
