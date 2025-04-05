// JumpCondition.swift
// PC88iOS
//

import Foundation

/// ジャンプ条件を表す列挙型
enum JumpCondition {
    case none            // 無条件
    case zero            // ゼロフラグがセットされている
    case notZero         // ゼロフラグがクリアされている
    case carry           // キャリーフラグがセットされている
    case notCarry        // キャリーフラグがクリアされている
    case parityEven      // パリティフラグがセットされている
    case parityOdd       // パリティフラグがクリアされている
    case sign            // サインフラグがセットされている
    case notSign         // サインフラグがクリアされている
    
    /// 条件コードから条件を生成
    static func fromCode(_ code: UInt8) -> JumpCondition {
        switch code {
        case 0: return .notZero
        case 1: return .zero
        case 2: return .notCarry
        case 3: return .carry
        case 4: return .parityOdd
        case 5: return .parityEven
        case 6: return .notSign
        case 7: return .sign
        default: return .none
        }
    }
}
