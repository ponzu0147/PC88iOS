//
//  PC88EmulatorCore.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import CoreGraphics
import UIKit
import SwiftUI

/// PC-88エミュレータのコア実装
class PC88EmulatorCore: EmulatorCoreManaging {
    // MARK: - プロパティ
    
    /// CPUエミュレーション
    private var cpu: CPUExecuting?
    
    /// メモリアクセス
    private var memory: MemoryAccessing?
    
    /// I/Oアクセス
    private var io: IOAccessing?
    
    /// 画面レンダリング
    private var screen: ScreenRendering?
    
    /// FDCエミュレーション
    private var fdc: FDCEmulating?
    
    /// サウンドチップエミュレーション
    private var soundChip: SoundChipEmulating?
    
    /// エミュレータの状態
    private var state: EmulatorState = .initialized
    
    /// エミュレーション速度（1.0 = 通常速度）
    private var emulationSpeed: Float = 1.0
    
    /// エミュレーションスレッド
    private var emulationThread: Thread?
    
    /// エミュレーションタイマー
    private var emulationTimer: Timer?
    
    /// 画面イメージ
    private var screenImage: CGImage?
    
    // MARK: - 初期化
    
    init() {
        // 各コンポーネントの初期化は initialize() メソッドで行う
    }
    
    // MARK: - EmulatorCoreManaging プロトコル実装
    
    func initialize() {
        // メモリの初期化
        memory = PC88Memory()
        
        // I/Oの初期化
        io = PC88IO()
        
        // CPUの初期化
        if let memory = memory, let io = io {
            cpu = Z80CPU(memory: memory, io: io)
        }
        
        // 画面の初期化
        screen = PC88Screen()
        if let screen = screen as? PC88Screen, let memory = memory, let io = io {
            screen.connectMemory(memory)
            screen.connectIO(io)
        }
        
        // FDCの初期化
        fdc = PC88FDC()
        if let fdc = fdc as? PC88FDC, let io = io {
            fdc.connectIO(io)
            
            // IOとFDCを相互接続
            if let io = io as? PC88IO {
                io.connectFDC(fdc)
            }
        }
        
        // サウンドチップの初期化
        soundChip = YM2203Emulator()
        if let soundChip = soundChip as? YM2203Emulator, let io = io as? PC88IO {
            soundChip.initialize(sampleRate: 44100.0)
            io.connectSoundChip(soundChip)
        }
        
        // 状態を初期化済みに変更
        state = .initialized
    }
    
    func start() {
        guard state == .initialized || state == .paused else { return }
        
        // エミュレーションスレッドの開始
        emulationThread = Thread { [weak self] in
            self?.emulationLoop()
        }
        emulationThread?.name = "PC88EmulationThread"
        emulationThread?.start()
        
        // 画面更新タイマーの開始
        emulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateScreen()
        }
        
        // 状態を実行中に変更
        state = .running
    }
    
    func stop() {
        guard state == .running || state == .paused else { return }
        
        // エミュレーションスレッドの停止
        emulationThread?.cancel()
        emulationThread = nil
        
        // 画面更新タイマーの停止
        emulationTimer?.invalidate()
        emulationTimer = nil
        
        // 状態を停止に変更
        state = .initialized
    }
    
    func pause() {
        guard state == .running else { return }
        
        // 状態を一時停止に変更
        state = .paused
    }
    
    func resume() {
        guard state == .paused else { return }
        
        // 状態を実行中に変更
        state = .running
    }
    
    func reset() {
        // CPUのリセット
        cpu?.reset()
        
        // メモリのリセット
        if let memory = memory as? PC88Memory {
            memory.reset()
        }
        
        // I/Oのリセット
        if let io = io as? PC88IO {
            io.reset()
        }
        
        // FDCのリセット
        if let fdc = fdc as? PC88FDC {
            fdc.reset()
        }
        
        // サウンドチップのリセット
        if let soundChip = soundChip {
            soundChip.reset()
        }
        
        // 状態を初期化済みに変更
        state = .initialized
    }
    
    // MARK: - EmulatorCoreManagingプロトコルの実装
    
    /// ディスクイメージのロード
    func loadDiskImage(url: URL, drive: Int) -> Bool {
        guard drive >= 0 && drive < 2 else { return false }
        guard let fdc = fdc else { return false }
        return fdc.loadDiskImage(url: url, drive: drive)
    }
    
    /// 画面の取得
    func getScreen() -> CGImage? {
        return screenImage
    }
    
    /// エミュレーション速度の設定
    func setEmulationSpeed(_ speed: Float) {
        emulationSpeed = max(0.1, min(10.0, speed))
    }
    
    /// 現在のエミュレータの状態を取得
    func getState() -> EmulatorState {
        return state
    }
    
    func handleInputEvent(_ event: InputEvent) {
        switch event {
        case .keyDown(let key):
            // キー入力の処理
            if let io = io as? PC88IO {
                io.keyDown(key)
            }
            
        case .keyUp(let key):
            // キー入力の処理
            if let io = io as? PC88IO {
                io.keyUp(key)
            }
            
        case .joystickButton(let button, let isPressed):
            // ジョイスティックボタンの処理
            if let io = io as? PC88IO {
                io.joystickButtonChanged(button, isPressed: isPressed)
            }
            
        case .joystickDirection(let direction, let value):
            // ジョイスティック方向の処理
            if let io = io as? PC88IO {
                io.joystickDirectionChanged(direction, value: value)
            }
            
        case .mouseMove(let x, let y):
            // マウス移動の処理
            if let io = io as? PC88IO {
                io.mouseMoved(x: x, y: y)
            }
            
        case .mouseButton(let button, let isPressed):
            // マウスボタンの処理
            if let io = io as? PC88IO {
                io.mouseButtonChanged(button, isPressed: isPressed)
            }
            
        case .touchBegan(_, _), .touchMoved(_, _), .touchEnded(_, _):
            // タッチ入力はここでは処理しない（UIレイヤーで処理）
            break
        }
    }
    

    
    // MARK: - プライベートメソッド
    
    /// エミュレーションのメインループ
    private func emulationLoop() {
        let cyclesPerFrame = 4_000_000 / 60  // Z80 4MHz, 60fps
        var lastTime = Date()
        
        while !Thread.current.isCancelled {
            // 一時停止中は処理をスキップ
            if state == .paused {
                Thread.sleep(forTimeInterval: 0.01)
                continue
            }
            
            // 1フレーム分のCPUサイクルを実行
            let adjustedCycles = Int(Float(cyclesPerFrame) * emulationSpeed)
            _ = cpu?.executeCycles(adjustedCycles)
            
            // フレームレート調整
            let targetFrameTime = 1.0 / (60.0 * Double(emulationSpeed))
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < targetFrameTime {
                let sleepTime = targetFrameTime - elapsed
                Thread.sleep(forTimeInterval: sleepTime)
            }
            lastTime = Date()
        }
    }
    
    /// 画面の更新
    private func updateScreen() {
        if let screen = screen {
            screenImage = screen.render()
        }
    }
}
