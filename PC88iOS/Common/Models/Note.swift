//
//  Note.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 音符を表す構造体
struct Note {
    /// 音名
    enum NoteName: Int, CaseIterable {
        case noteC = 0
        case cSharp = 1
        case noteD = 2
        case dSharp = 3
        case noteE = 4
        case noteF = 5
        case fSharp = 6
        case noteG = 7
        case gSharp = 8
        case noteA = 9
        case aSharp = 10
        case noteB = 11
        
        /// 文字列表現
        var description: String {
            switch self {
            case .noteC: return "C"
            case .cSharp: return "C#"
            case .noteD: return "D"
            case .dSharp: return "D#"
            case .noteE: return "E"
            case .noteF: return "F"
            case .fSharp: return "F#"
            case .noteG: return "G"
            case .gSharp: return "G#"
            case .noteA: return "A"
            case .aSharp: return "A#"
            case .noteB: return "B"
            }
        }
        
        /// 代替表記
        var alternateDescription: String {
            switch self {
            case .cSharp: return "Db"
            case .dSharp: return "Eb"
            case .fSharp: return "Gb"
            case .gSharp: return "Ab"
            case .aSharp: return "Bb"
            default: return description
            }
        }
    }
    
    /// 音名
    let name: NoteName
    
    /// オクターブ（中央のCを4とする）
    let octave: Int
    
    /// 長さ（4 = 四分音符, 8 = 八分音符, etc.）
    let length: Int
    
    /// 付点の数
    let dots: Int
    
    /// ベロシティ（0-127）
    let velocity: Int
    
    /// 周波数を取得
    var frequency: Double {
        // A4 (440Hz) を基準とする
        let baseFreq = 440.0
        let semitoneOffset = Double(name.rawValue - NoteName.noteA.rawValue) + Double(octave - 4) * 12.0
        return baseFreq * pow(2.0, semitoneOffset / 12.0)
    }
    
    /// MIDIノート番号を取得
    var midiNote: Int {
        return name.rawValue + (octave + 1) * 12
    }
    
    /// 音符の実際の長さ（拍）を取得
    var actualLength: Double {
        var length = 4.0 / Double(self.length)
        var dotValue = length / 2.0
        
        for _ in 0..<dots {
            length += dotValue
            dotValue /= 2.0
        }
        
        return length
    }
    
    /// 初期化
    init(name: NoteName, octave: Int, length: Int = 4, dots: Int = 0, velocity: Int = 100) {
        self.name = name
        self.octave = octave
        self.length = length
        self.dots = dots
        self.velocity = velocity
    }
    
    /// 文字列表現
    var description: String {
        var result = name.description + String(octave)
        
        if length != 4 {
            result += "/\(length)"
        }
        
        for _ in 0..<dots {
            result += "."
        }
        
        return result
    }
}
