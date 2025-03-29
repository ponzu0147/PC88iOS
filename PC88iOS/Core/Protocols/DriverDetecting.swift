//
//  DriverDetecting.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 音楽ドライバの検出を担当するプロトコル
protocol DriverDetecting {
    /// メモリ内のドライバを検出
    func detectDriver(in memory: MemoryAccessing) -> DriverInformation?
    
    /// ディスクイメージ内のドライバを検出
    func detectDriverInDisk(_ disk: DiskImageAccessing) -> [DriverInformation]
    
    /// 特定のアドレスにドライバが存在するか確認
    func checkDriverSignature(at address: UInt16, in memory: MemoryAccessing) -> DriverType?
}

/// 音楽ドライバの種類を表す列挙型
enum DriverType: String {
    // FM音源系
    case mmlCompiler = "MML Compiler"
    case midiCompiler = "MIDI Compiler"
    case fmpac = "FM-PAC"
    case pmdDriver = "PMD"
    case mmdDriver = "MMD"
    case mucomDriver = "MUCOM88"
    case fmpcDriver = "FM-PC"
    case opnaDriver = "OPNA"
    
    // SSG音源系
    case psg = "PSG"
    case mgsDriver = "MGS"
    case mckDriver = "MCK"
    case nsdDriver = "NSD"
    
    // ADPCM音源系
    case adpcmDriver = "ADPCM"
    
    // 効果音系
    case sfxDriver = "SFX"
    
    // 汎用
    case customDriver = "Custom"
    case unknown = "Unknown"
    
    /// ドライバの説明
    var description: String {
        switch self {
        case .mmlCompiler:
            return "MML (Music Macro Language) コンパイラ"
        case .midiCompiler:
            return "MIDI データコンパイラ"
        case .fmpac:
            return "FM-PAC 音源ドライバ"
        case .pmdDriver:
            return "Professional Music Driver (PMD)"
        case .mmdDriver:
            return "MML Music Driver (MMD)"
        case .mucomDriver:
            return "MUCOM88 音楽作成システム"
        case .fmpcDriver:
            return "FM-PC 音源ドライバ"
        case .opnaDriver:
            return "OPNA/OPN3 汎用ドライバ"
        case .psg:
            return "PSG 音源ドライバ"
        case .mgsDriver:
            return "MGS 音楽フォーマット"
        case .mckDriver:
            return "MCK (MML to NSF Compiler)"
        case .nsdDriver:
            return "NSD 音楽フォーマット"
        case .adpcmDriver:
            return "ADPCM サンプル再生ドライバ"
        case .sfxDriver:
            return "効果音専用ドライバ"
        case .customDriver:
            return "カスタムドライバ"
        case .unknown:
            return "不明なドライバ"
        }
    }
    
    /// サポートしている音源
    var supportedSoundChips: [SoundChipType] {
        switch self {
        case .mmlCompiler, .midiCompiler:
            return [.opn, .opna, .psg]
        case .fmpac:
            return [.opn]
        case .pmdDriver, .mmdDriver, .mucomDriver, .fmpcDriver, .opnaDriver:
            return [.opna, .psg]
        case .psg, .mgsDriver, .mckDriver, .nsdDriver:
            return [.psg]
        case .adpcmDriver:
            return [.opna]
        case .sfxDriver:
            return [.psg, .opna]
        case .customDriver, .unknown:
            return [.psg, .opn, .opna]
        }
    }
}

/// サウンドチップの種類
enum SoundChipType: String {
    case psg = "PSG"      // AY-3-8910
    case opn = "OPN"      // YM2203
    case opna = "OPNA"    // YM2608
}
