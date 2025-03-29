//
//  PC88IO.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// PC-88のI/O実装
class PC88IO: IOAccessing {
    // MARK: - 定数
    
    /// I/Oポート定義
    private enum IOPort: UInt8 {
        // FDC関連ポート
        case fdcCommand = 0xFB
        case fdcStatus = 0xFC
        case fdcData = 0xFD
        
        // キーボード関連ポート
        case keyboardData = 0x00
        case keyboardCommand = 0x01
        
        // 画面関連ポート
        case crtcRegister = 0x50
        case crtcData = 0x51
        
        // サウンド関連ポート
        case psgRegister = 0x44
        case psgData = 0x45
        
        // 割り込み関連ポート
        case interruptControl = 0xE4
        case interruptMask = 0xE6
    }
    
    /// 割り込み要因
    enum InterruptSource {
        case vblank   // 垂直帰線期間
        case timer    // タイマー
        case keyboard // キーボード
        case fdc      // FDC
    }
    
    // MARK: - プロパティ
    
    /// FDCエミュレーション
    private var fdc: FDCEmulating?
    
    /// サウンドチップエミュレーション
    private var soundChip: SoundChipEmulating?
    
    /// キーボード状態
    private var keyboardState = [UInt8](repeating: 0, count: 16)
    
    /// 割り込み要求フラグ
    private var interruptRequestFlag: UInt8 = 0
    
    /// 割り込みマスク
    private var interruptMask: UInt8 = 0
    
    /// CRTCレジスタ選択
    private var crtcRegisterSelect: UInt8 = 0
    
    /// CRTCレジスタ
    private var crtcRegisters = [UInt8](repeating: 0, count: 16)
    
    /// PSGレジスタ選択
    private var psgRegisterSelect: UInt8 = 0
    
    // MARK: - 初期化
    
    init() {
        reset()
    }
    
    // MARK: - 公開メソッド
    
    /// FDCを接続
    func connectFDC(_ fdc: FDCEmulating) {
        self.fdc = fdc
    }
    
    /// サウンドチップを接続
    func connectSoundChip(_ soundChip: SoundChipEmulating) {
        self.soundChip = soundChip
    }
    
    /// キーボード入力（キーダウン）
    func keyDown(_ key: PC88Key) {
        let (row, bit) = getKeyboardMatrixPosition(key)
        
        if row < keyboardState.count {
            keyboardState[row] |= (1 << bit)
        }
        
        // キーボード割り込みを発生
        requestInterrupt(from: .keyboard)
    }
    
    /// キーボード入力（キーアップ）
    func keyUp(_ key: PC88Key) {
        let (row, bit) = getKeyboardMatrixPosition(key)
        
        if row < keyboardState.count {
            keyboardState[row] &= ~(1 << bit)
        }
    }
    
    /// ジョイスティックボタン状態変更
    func joystickButtonChanged(_ button: JoystickButton, isPressed: Bool) {
        // ジョイスティックボタンの処理
        let buttonValue = button.rawValue
        // 実装は省略
    }
    
    /// ジョイスティック方向状態変更
    func joystickDirectionChanged(_ direction: JoystickDirection, value: Float) {
        // ジョイスティック方向の処理
        switch direction {
        case .horizontal:
            // 水平方向の処理
            break
        case .vertical:
            // 垂直方向の処理
            break
        }
    }
    
    /// マウス移動
    func mouseMoved(x: Int, y: Int) {
        // マウス移動の処理
    }
    
    /// マウスボタン状態変更
    func mouseButtonChanged(_ button: MouseButton, isPressed: Bool) {
        // マウスボタンの処理
        let buttonValue = button.rawValue
        // 実装は省略
    }
    
    /// 割り込み要求
    func requestInterrupt(from source: InterruptSource) {
        switch source {
        case .vblank:
            interruptRequestFlag |= 0x01
        case .timer:
            interruptRequestFlag |= 0x02
        case .keyboard:
            interruptRequestFlag |= 0x04
        case .fdc:
            interruptRequestFlag |= 0x08
        }
    }
    
    /// 状態のリセット
    func reset() {
        // キーボード状態をクリア
        keyboardState = [UInt8](repeating: 0, count: 16)
        
        // 割り込み関連レジスタをリセット
        interruptRequestFlag = 0
        interruptMask = 0
        
        // CRTCレジスタをリセット
        crtcRegisterSelect = 0
        crtcRegisters = [UInt8](repeating: 0, count: 16)
        
        // PSGレジスタ選択をリセット
        psgRegisterSelect = 0
    }
    
    // MARK: - IOAccessing プロトコル実装
    
    func readPort(_ port: UInt8) -> UInt8 {
        switch port {
        case IOPort.fdcStatus.rawValue:
            // FDCステータスレジスタ
            return fdc?.readStatus() ?? 0
            
        case IOPort.fdcData.rawValue:
            // FDCデータレジスタ
            return fdc?.readData() ?? 0
            
        case IOPort.keyboardData.rawValue:
            // キーボードデータ
            let strobe = crtcRegisters[9] & 0x0F
            if strobe < keyboardState.count {
                return keyboardState[Int(strobe)]
            }
            return 0
            
        case IOPort.crtcData.rawValue:
            // CRTCデータ
            if crtcRegisterSelect < crtcRegisters.count {
                return crtcRegisters[Int(crtcRegisterSelect)]
            }
            return 0
            
        case IOPort.psgData.rawValue:
            // PSGデータ
            return soundChip?.readRegister(psgRegisterSelect) ?? 0
            
        case IOPort.interruptControl.rawValue:
            // 割り込み制御
            return interruptRequestFlag
            
        case IOPort.interruptMask.rawValue:
            // 割り込みマスク
            return interruptMask
            
        default:
            // 未実装ポート
            return 0
        }
    }
    
    func writePort(_ port: UInt8, value: UInt8) {
        switch port {
        case IOPort.fdcCommand.rawValue:
            // FDCコマンドレジスタ
            fdc?.sendCommand(value)
            
        case IOPort.fdcData.rawValue:
            // FDCデータレジスタ
            fdc?.sendData(value)
            
        case IOPort.keyboardCommand.rawValue:
            // キーボードコマンド
            // 実装なし
            break
            
        case IOPort.crtcRegister.rawValue:
            // CRTCレジスタ選択
            crtcRegisterSelect = value & 0x0F
            
        case IOPort.crtcData.rawValue:
            // CRTCデータ
            if crtcRegisterSelect < crtcRegisters.count {
                crtcRegisters[Int(crtcRegisterSelect)] = value
            }
            
        case IOPort.psgRegister.rawValue:
            // PSGレジスタ選択
            psgRegisterSelect = value
            
        case IOPort.psgData.rawValue:
            // PSGデータ
            soundChip?.writeRegister(psgRegisterSelect, value: value)
            
        case IOPort.interruptControl.rawValue:
            // 割り込み制御
            interruptRequestFlag &= ~value
            
        case IOPort.interruptMask.rawValue:
            // 割り込みマスク
            interruptMask = value
            
        default:
            // 未実装ポート
            break
        }
    }
    
    func processInputEvent(_ event: InputEvent) {
        switch event {
        case .keyDown(let key):
            keyDown(key)
            
        case .keyUp(let key):
            keyUp(key)
            
        case .joystickButton(let button, let isPressed):
            joystickButtonChanged(button, isPressed: isPressed)
            
        case .joystickDirection(let direction, let value):
            joystickDirectionChanged(direction, value: value)
            
        case .mouseMove(let x, let y):
            mouseMoved(x: x, y: y)
            
        case .mouseButton(let button, let isPressed):
            mouseButtonChanged(button, isPressed: isPressed)
            
        case .touchBegan(_, _), .touchMoved(_, _), .touchEnded(_, _):
            // タッチイベントはここでは処理しない
            break
        }
    }
    
    func requestInterrupt() {
        // 任意の割り込み要求（デフォルトはキーボード）
        requestInterrupt(from: .keyboard)
    }
    
    func getInterruptStatus() -> UInt8 {
        // 割り込み状態を返す
        return interruptRequestFlag & ~interruptMask
    }
    
    // MARK: - プライベートメソッド
    
    /// PC88Keyからキーボードマトリクスの位置を取得
    private func getKeyboardMatrixPosition(_ key: PC88Key) -> (row: Int, bit: Int) {
        // PC-88のキーボードマトリクスに変換
        // 実際のPC-88のキーボードマトリクスに合わせて実装する必要があります
        // ここでは簡易的な実装を行います
        
        switch key {
        // ファンクションキー (STROBE 0)
        case .f1, .f2, .f3, .f4, .f5:
            return (0, Int(key.rawValue - 0x01))
        case .f6, .f7, .f8, .f9, .f10:
            return (0, Int(key.rawValue - 0x01))
            
        // 特殊キー (STROBE 1)
        case .esc, .tab, .ctrl, .shift, .caps, .kana, .graph, .stop:
            return (1, Int(key.rawValue - 0x0B))
            
        // 制御キー (STROBE 2)
        case .home, .del, .ins, .end, .up, .down, .left, .right, .space, .returnKey:
            return (2, Int(key.rawValue - 0x13))
            
        // 数字キー (STROBE 3)
        case .num0, .num1, .num2, .num3, .num4, .num5, .num6, .num7, .num8, .num9:
            return (3, Int(key.rawValue - 0x30))
            
        // アルファベットキー (STROBE 4-8)
        case .a, .b, .c, .d, .e, .f, .g, .h, .i, .j:
            return (4, Int(key.rawValue - 0x41))
        case .k, .l, .m, .n, .o, .p, .q, .r, .s, .t:
            return (5, Int(key.rawValue - 0x4B))
        case .u, .v, .w, .x, .y, .z:
            return (6, Int(key.rawValue - 0x55))
            
        // 記号キー (STROBE 9-10)
        case .minus, .caret, .yen, .at, .bracketLeft:
            return (9, Int((key.rawValue - 0x2D) % 8))
        case .semicolon, .colon, .bracketRight, .comma, .period, .slash, .underscore:
            return (10, Int((key.rawValue - 0x3A) % 8))
        }
    }
}
