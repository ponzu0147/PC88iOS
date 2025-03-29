//
//  DriverInformation.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 音楽ドライバの情報を表す構造体
struct DriverInformation {
    /// ドライバの種類
    let type: DriverType
    
    /// ドライバのバージョン
    let version: String
    
    /// ドライバのメモリ上のアドレス
    let address: UInt16
    
    /// 曲データのアドレス
    let musicDataAddress: UInt16?
    
    /// 作曲者名（検出できた場合）
    let composer: String?
    
    /// 曲名（検出できた場合）
    let title: String?
    
    /// ファイル名（ディスクから検出した場合）
    let filename: String?
    
    /// ドライバの機能フラグ
    let features: DriverFeatures
    
    /// 初期化
    init(type: DriverType, version: String, address: UInt16, musicDataAddress: UInt16? = nil,
         composer: String? = nil, title: String? = nil, filename: String? = nil,
         features: DriverFeatures = DriverFeatures()) {
        self.type = type
        self.version = version
        self.address = address
        self.musicDataAddress = musicDataAddress
        self.composer = composer
        self.title = title
        self.filename = filename
        self.features = features
    }
    
    /// 文字列表現
    var description: String {
        var desc = "\(type.rawValue) v\(version) at 0x\(String(address, radix: 16, uppercase: true))"
        
        if let musicDataAddress = musicDataAddress {
            desc += ", Data at 0x\(String(musicDataAddress, radix: 16, uppercase: true))"
        }
        
        if let title = title {
            desc += ", Title: \(title)"
        }
        
        if let composer = composer {
            desc += ", By: \(composer)"
        }
        
        return desc
    }
}

/// ドライバの機能フラグ
struct DriverFeatures: OptionSet {
    let rawValue: UInt16
    
    /// FMサウンド対応
    static let fmSound = DriverFeatures(rawValue: 1 << 0)
    
    /// SSGサウンド対応
    static let ssgSound = DriverFeatures(rawValue: 1 << 1)
    
    /// ADPCMサウンド対応
    static let adpcmSound = DriverFeatures(rawValue: 1 << 2)
    
    /// リズムサウンド対応
    static let rhythmSound = DriverFeatures(rawValue: 1 << 3)
    
    /// 効果音対応
    static let soundEffects = DriverFeatures(rawValue: 1 << 4)
    
    /// ループ再生対応
    static let loopPlayback = DriverFeatures(rawValue: 1 << 5)
    
    /// テンポ変更対応
    static let tempoChange = DriverFeatures(rawValue: 1 << 6)
    
    /// 音量変更対応
    static let volumeChange = DriverFeatures(rawValue: 1 << 7)
    
    /// パート別ミュート対応
    static let partMute = DriverFeatures(rawValue: 1 << 8)
    
    /// 初期化
    init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}
