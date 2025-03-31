//
//  CPUUtilities.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// Z80 CPU関連のユーティリティ関数

/// パリティチェック（偶数なら真）
func parityEven(_ value: UInt8) -> Bool {
    var v = value
    v ^= v >> 4
    v ^= v >> 2
    v ^= v >> 1
    return (v & 1) == 0
}

/// Z80 CPUのマシンサイクル種類
enum MachineCycleType {
    /// オペコードフェッチ (M1) サイクル
    case opcodeFetch
    /// メモリ読み込みサイクル
    case memoryRead
    /// メモリ書き込みサイクル
    case memoryWrite
    /// IO読み込みサイクル
    case ioRead
    /// IO書き込みサイクル
    case ioWrite
    /// 割り込み応答サイクル
    case interruptAcknowledge
    /// 内部処理サイクル
    case internalProcessing
    
    /// サイクルあたりのT-ステート数を取得
    var tStates: Int {
        switch self {
        case .opcodeFetch:
            return 4  // M1サイクルは常に4 T-ステート
        case .memoryRead, .memoryWrite:
            return 3  // メモリアクセスは3 T-ステート
        case .ioRead, .ioWrite:
            return 4  // I/Oアクセスは4 T-ステート
        case .interruptAcknowledge:
            return 5  // 割り込み応答は5 T-ステート
        case .internalProcessing:
            return 1  // 内部処理は1 T-ステート (可変だが基本単位)
        }
    }
}

/// Z80 CPUのサイクル情報
struct CycleInfo {
    /// マシンサイクルの種類
    let type: MachineCycleType
    /// 追加の内部サイクル数（該当する場合）
    let additionalInternalCycles: Int
    
    /// 合計T-ステート数を計算
    var totalTStates: Int {
        return type.tStates + additionalInternalCycles
    }
    
    /// 基本的なマシンサイクル情報を作成
    init(type: MachineCycleType, additionalInternalCycles: Int = 0) {
        self.type = type
        self.additionalInternalCycles = additionalInternalCycles
    }
}

/// 命令実行サイクル情報
struct InstructionCycles {
    /// マシンサイクル情報の配列
    let cycles: [CycleInfo]
    
    /// 合計M-サイクル数
    var mCycles: Int {
        return cycles.count
    }
    
    /// 合計T-ステート数
    var tStates: Int {
        return cycles.reduce(0) { $0 + $1.totalTStates }
    }
    
    /// 基本的な命令サイクル情報を作成
    init(cycles: [CycleInfo]) {
        self.cycles = cycles
    }
    
    /// 一般的な命令パターンのサイクル情報を作成
    static func standard(opcodeFetch: Bool = true, memoryReads: Int = 0, memoryWrites: Int = 0, 
                         ioReads: Int = 0, ioWrites: Int = 0, internalCycles: Int = 0,
                         interruptAcknowledge: Bool = false) -> InstructionCycles {
        var cycleInfos: [CycleInfo] = []
        
        // オペコードフェッチサイクル（M1）
        if opcodeFetch {
            cycleInfos.append(CycleInfo(type: .opcodeFetch))
        }
        
        // メモリ読み込みサイクル
        for _ in 0..<memoryReads {
            cycleInfos.append(CycleInfo(type: .memoryRead))
        }
        
        // メモリ書き込みサイクル
        for _ in 0..<memoryWrites {
            cycleInfos.append(CycleInfo(type: .memoryWrite))
        }
        
        // IO読み込みサイクル
        for _ in 0..<ioReads {
            cycleInfos.append(CycleInfo(type: .ioRead))
        }
        
        // IO書き込みサイクル
        for _ in 0..<ioWrites {
            cycleInfos.append(CycleInfo(type: .ioWrite))
        }
        
        // 内部処理サイクル
        if internalCycles > 0 {
            cycleInfos.append(CycleInfo(type: .internalProcessing, additionalInternalCycles: internalCycles - 1))
        }
        
        // 割り込み応答サイクル
        if interruptAcknowledge {
            cycleInfos.append(CycleInfo(type: .interruptAcknowledge))
        }
        
        return InstructionCycles(cycles: cycleInfos)
    }
}

/// Z80 CPUの命令サイクル定義
struct Z80InstructionCycles {
    // 8ビット転送命令のサイクル
    static let LD_r_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let LD_r_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LD_r_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LD_HL_r = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let LD_HL_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 10T
    static let LD_A_BC = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LD_A_DE = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LD_A_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 3) // 4M, 13T
    static let LD_BC_A = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let LD_DE_A = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let LD_nn_A = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 1) // 4M, 13T
    
    // 16ビット転送命令のサイクル
    static let LD_rr_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let LD_HL_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 5) // 6M, 16T
    static let LD_nn_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 16T
    static let LD_SP_HL = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    
    // 算術演算命令のサイクル
    static let ADD_A_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let ADD_A_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let ADD_A_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let ADC_A_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let ADC_A_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let ADC_A_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let SUB_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let SUB_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let SUB_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let SBC_A_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let SBC_A_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let SBC_A_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let INC_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let INC_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 11T
    static let DEC_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let DEC_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 11T
    
    // 論理演算命令のサイクル
    static let AND_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let AND_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let AND_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let OR_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let OR_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let OR_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let XOR_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let XOR_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let XOR_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let CP_r = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let CP_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let CP_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    
    // スタック操作命令のサイクル
    static let PUSH_rr = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) // 3M, 11T
    static let POP_rr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
    // レジスタペア操作命令のサイクル
    static let INC_rr = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let DEC_rr = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let ADD_HL_rr = InstructionCycles.standard(opcodeFetch: true, internalCycles: 7) // 3M, 11T
    
    // ジャンプ命令のサイクル
    static let JP_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let JP_cc_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let JR_e = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 12T
    static let JR_cc_e = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 12T
    static let DJNZ_e = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 13T
    
    // その他の命令のサイクル
    static let NOP = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let CPL = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let RET = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
    // プレフィックス命令のサイクル
    static let IX_PREFIX = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let IY_PREFIX = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let LD_IY_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 4M, 14T
    
    // 制御命令のサイクル
    static let CALL_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2, internalCycles: 1) // 5M, 17T
    static let CALL_cc_nn = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T (条件不成立時)
    static let CALL_cc_nn_taken = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2, internalCycles: 1) // 5M, 17T (条件成立時)
    static let RET_cc = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 1M, 5T (条件不成立時)
    static let RET_cc_taken = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, internalCycles: 1) // 3M, 11T (条件成立時)
    
    // その他の命令のサイクル
    static let HALT = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let DI = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let EI = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let IN_A_n = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioReads: 1) // 3M, 11T
    static let OUT_n_A = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioWrites: 1) // 3M, 11T
}
