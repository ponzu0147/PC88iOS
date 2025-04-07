//
//  InputEvent.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import UIKit

/// 入力イベントを表す構造体
enum InputEvent {
    /// キーボード入力
    case keyDown(key: PC88Key)
    case keyUp(key: PC88Key)
    
    /// ジョイスティック入力
    case joystickButton(button: JoystickButton, isPressed: Bool)
    case joystickDirection(direction: JoystickDirection, value: Float)
    
    /// マウス入力
    case mouseMove(x: Int, y: Int)
    case mouseButton(button: MouseButton, isPressed: Bool)
    
    /// タッチ入力（iOS特有）
    case touchBegan(location: CGPoint, identifier: String)
    case touchMoved(location: CGPoint, identifier: String)
    case touchEnded(location: CGPoint, identifier: String)
}

/// PC-88のキー
enum PC88Key: UInt8 {
    // ファンクションキー
    case f1 = 0x01
    case f2 = 0x02
    case f3 = 0x03
    case f4 = 0x04
    case f5 = 0x05
    case f6 = 0x06
    case f7 = 0x07
    case f8 = 0x08
    case f9 = 0x09
    case f10 = 0x0A
    
    // 特殊キー
    case esc = 0x0B
    case tab = 0x0C
    case ctrl = 0x0D
    case shift = 0x0E
    case caps = 0x0F
    case kana = 0x10
    case graph = 0x11
    case stop = 0x12
    
    // 制御キー
    case home = 0x13
    case del = 0x14
    case ins = 0x15
    case end = 0x16
    case up = 0x17
    case down = 0x18
    case left = 0x19
    case right = 0x1A
    case space = 0x1B
    case returnKey = 0x1C
    
    // 数字キー
    case num0 = 0x30
    case num1 = 0x31
    case num2 = 0x32
    case num3 = 0x33
    case num4 = 0x34
    case num5 = 0x35
    case num6 = 0x36
    case num7 = 0x37
    case num8 = 0x38
    case num9 = 0x39
    
    // アルファベットキー
    case keyA = 0x41
    case keyB = 0x42
    case keyC = 0x43
    case keyD = 0x44
    case keyE = 0x45
    case keyF = 0x46
    case keyG = 0x47
    case keyH = 0x48
    case keyI = 0x49
    case keyJ = 0x4A
    case keyK = 0x4B
    case keyL = 0x4C
    case keyM = 0x4D
    case keyN = 0x4E
    case keyO = 0x4F
    case keyP = 0x50
    case keyQ = 0x51
    case keyR = 0x52
    case keyS = 0x53
    case keyT = 0x54
    case keyU = 0x55
    case keyV = 0x56
    case keyW = 0x57
    case keyX = 0x58
    case keyY = 0x59
    case keyZ = 0x5A
    
    // 記号キー
    case minus = 0x2D      // -
    case caret = 0x5E      // ^
    case yen = 0x5C        // ¥
    case at = 0x40         // @
    case bracketLeft = 0x5B  // [
    case semicolon = 0x3B  // ;
    case colon = 0x3A      // :
    case bracketRight = 0x5D // ]
    case comma = 0x2C      // ,
    case period = 0x2E     // .
    case slash = 0x2F      // /
    case underscore = 0x5F // _
}

/// ジョイスティックボタン
enum JoystickButton: Int {
    case button1 = 0
    case button2 = 1
    case button3 = 2
    case button4 = 3
}

/// ジョイスティック方向
enum JoystickDirection {
    case horizontal
    case vertical
}

/// マウスボタン
enum MouseButton: Int {
    case left = 0
    case right = 1
    case middle = 2
}
