//
//  MusicParameters.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 音楽パラメータを表す構造体
struct MusicParameters {
    /// 曲のタイトル
    let title: String?
    
    /// 作曲者名
    let composer: String?
    
    /// テンポ（BPM）
    let tempo: Int
    
    /// 拍子（例: 4/4）
    let timeSignature: TimeSignature
    
    /// 調性
    let key: MusicKey
    
    /// パート情報
    let parts: [PartInfo]
    
    /// ループ情報
    let loopInfo: LoopInfo?
    
    /// 音色データ
    let voiceData: [VoiceData]
    
    /// 初期化
    init(title: String? = nil, composer: String? = nil, tempo: Int = 120,
         timeSignature: TimeSignature = TimeSignature(beats: 4, beatType: 4),
         key: MusicKey = MusicKey(note: Note.NoteName.noteC, isMinor: false),
         parts: [PartInfo] = [], loopInfo: LoopInfo? = nil, voiceData: [VoiceData] = []) {
        self.title = title
        self.composer = composer
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.key = key
        self.parts = parts
        self.loopInfo = loopInfo
        self.voiceData = voiceData
    }
}

/// 拍子を表す構造体
struct TimeSignature {
    /// 分子（1小節の拍数）
    let beats: Int
    
    /// 分母（拍の種類）
    let beatType: Int
    
    /// 文字列表現
    var description: String {
        return "\(beats)/\(beatType)"
    }
}

/// 調性を表す構造体
struct MusicKey {
    /// 音名
    let note: Note.NoteName
    
    /// 短調かどうか
    let isMinor: Bool
    
    /// 文字列表現
    var description: String {
        return "\(note.description) \(isMinor ? "minor" : "major")"
    }
}

/// パート情報を表す構造体
struct PartInfo {
    /// パート名
    let name: String
    
    /// パート番号
    let number: Int
    
    /// 使用チャンネル
    let channel: Int
    
    /// 音色番号
    let voice: Int
    
    /// 音量（0-127）
    let volume: Int
    
    /// パンポット（-64〜+63）
    let pan: Int
    
    /// 初期化
    init(name: String, number: Int, channel: Int, voice: Int, volume: Int = 100, pan: Int = 0) {
        self.name = name
        self.number = number
        self.channel = channel
        self.voice = voice
        self.volume = volume
        self.pan = pan
    }
}

/// ループ情報を表す構造体
struct LoopInfo {
    /// ループ開始位置（小節番号）
    let startMeasure: Int
    
    /// ループ終了位置（小節番号）
    let endMeasure: Int
    
    /// ループ回数（0は無限ループ）
    let count: Int
    
    /// 初期化
    init(startMeasure: Int, endMeasure: Int, count: Int = 0) {
        self.startMeasure = startMeasure
        self.endMeasure = endMeasure
        self.count = count
    }
}

/// 音色データを表す構造体
struct VoiceData {
    /// 音色番号
    let number: Int
    
    /// 音色名
    let name: String?
    
    /// 音色タイプ
    let type: VoiceType
    
    /// 音色パラメータ（音源依存）
    let parameters: [UInt8]
    
    /// 初期化
    init(number: Int, name: String? = nil, type: VoiceType, parameters: [UInt8]) {
        self.number = number
        self.name = name
        self.type = type
        self.parameters = parameters
    }
}

/// 音色タイプ
enum VoiceType {
    case fm2op   // 2オペレータFM
    case fm4op   // 4オペレータFM
    case ssg     // SSG
    case adpcm   // ADPCM
    case rhythm  // リズム音源
}
