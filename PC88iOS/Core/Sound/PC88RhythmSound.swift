//
//  PC88RhythmSound.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import AVFoundation

/// PC-88のリズム音源を管理するクラス
class PC88RhythmSound {
    // MARK: - リズム音源の種類
    
    /// リズム音源の種類
    enum RhythmType: String {
        case bassDrum = "2608_bd"    // バスドラム
        case snare = "2608_sd"       // スネア
        case tom = "2608_tom"        // タム
        case hiHat = "2608_hh"       // ハイハット
        case topCymbal = "2608_top"  // トップシンバル
        case rimShot = "2608_rim"    // リムショット
    }
    
    // MARK: - シングルトン
    
    /// シングルトンインスタンス
    static let shared = PC88RhythmSound()
    
    // MARK: - プロパティ
    
    /// 音源プレイヤー
    private var audioPlayers: [RhythmType: AVAudioPlayer] = [:]
    
    // MARK: - 初期化
    
    private init() {
        // シングルトンのため、privateに
    }
    
    // MARK: - メソッド
    
    /// リズム音源を読み込む
    /// - Returns: 読み込みに成功したかどうか
    func loadRhythmSounds() -> Bool {
        let rhythmTypes: [RhythmType] = [.bassDrum, .snare, .tom, .hiHat, .topCymbal, .rimShot]
        
        for type in rhythmTypes {
            if !loadRhythmSound(type) {
                return false
            }
        }
        
        return true
    }
    
    /// 指定されたリズム音源を読み込む
    /// - Parameter type: リズム音源の種類
    /// - Returns: 読み込みに成功したかどうか
    private func loadRhythmSound(_ type: RhythmType) -> Bool {
        // 1. Documentsディレクトリから読み込みを試みる
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent("\(type.rawValue).wav")
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                    audioPlayer.prepareToPlay()
                    audioPlayers[type] = audioPlayer
                    print("Rhythm sound loaded from Documents: \(type.rawValue).wav")
                    return true
                } catch {
                    print("Failed to load rhythm sound from Documents \(type.rawValue): \(error)")
                }
            }
        }
        
        // 2. バンドルから試す
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.prepareToPlay()
                audioPlayers[type] = audioPlayer
                print("Rhythm sound loaded from Bundle: \(type.rawValue).wav")
                return true
            } catch {
                print("Failed to load rhythm sound from Bundle \(type.rawValue): \(error)")
            }
        }
        
        // 3. Resourcesディレクトリから試す
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "wav", subdirectory: "Resources") {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.prepareToPlay()
                audioPlayers[type] = audioPlayer
                print("Rhythm sound loaded from Resources: \(type.rawValue).wav")
                return true
            } catch {
                print("Failed to load rhythm sound from Resources \(type.rawValue): \(error)")
            }
        }
        
        // 4. 直接ファイルパスを指定して試す
        let resourcePath = "/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS/Resources/\(type.rawValue).wav"
        let fileURL = URL(fileURLWithPath: resourcePath)
        
        if FileManager.default.fileExists(atPath: resourcePath) {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer.prepareToPlay()
                audioPlayers[type] = audioPlayer
                print("Rhythm sound loaded from direct path: \(type.rawValue).wav")
                return true
            } catch {
                print("Failed to load rhythm sound from direct path \(type.rawValue): \(error)")
            }
        }
        
        print("Rhythm sound file not found: \(type.rawValue).wav")
        return false
    }
    
    /// 指定されたリズム音源を再生する
    /// - Parameter type: リズム音源の種類
    func playRhythmSound(_ type: RhythmType) {
        guard let player = audioPlayers[type] else {
            print("Rhythm sound player not found: \(type.rawValue)")
            return
        }
        
        // 再生中なら停止して先頭に戻す
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        
        player.play()
    }
    
    /// 指定されたリズム音源を停止する
    /// - Parameter type: リズム音源の種類
    func stopRhythmSound(_ type: RhythmType) {
        guard let player = audioPlayers[type] else { return }
        player.stop()
    }
    
    /// 全てのリズム音源を停止する
    func stopAllRhythmSounds() {
        for (_, player) in audioPlayers {
            player.stop()
        }
    }
}
