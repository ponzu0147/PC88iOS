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
    var bitValue = value
    bitValue ^= bitValue >> 4
    bitValue ^= bitValue >> 2
    bitValue ^= bitValue >> 1
    return (bitValue & 1) == 0
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
    static func standard(
        opcodeFetch: Bool = true, 
        memoryReads: Int = 0, 
        memoryWrites: Int = 0, 
        ioReads: Int = 0, 
        ioWrites: Int = 0, 
        internalCycles: Int = 0,
        interruptAcknowledge: Bool = false
    ) -> InstructionCycles {
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
    // 基本命令のサイクル
    static let NOP = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let HALT = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let DI = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let EI = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let JP = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let JR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 1) // 3M, 12T
    static let CALL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 17T
    static let RET = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let RST = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) // 3M, 11T
    static let UNIMPLEMENTED = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    
    // I/O命令のサイクル
    static let IN = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioReads: 1) // 3M, 11T
    static let OUT = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioWrites: 1) // 3M, 11T
    static let INRC = InstructionCycles.standard(opcodeFetch: true, ioReads: 1) // 2M, 8T
    static let OUTCR = InstructionCycles.standard(opcodeFetch: true, ioWrites: 1) // 2M, 8T
    // 8ビット転送命令のサイクル
    static let loadRegToReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let loadRegToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let loadRegToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let loadHLToReg = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let loadHLToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 10T
    static let loadAToBC = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let loadAToDE = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let loadAToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 3) // 4M, 13T
    static let loadBCToA = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let loadDEToA = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let loadAddrToA = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 1) // 4M, 13T
    static let loadAddrToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 16T
    static let loadHLToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 16T
    static let LDRI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LDRM = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LDMR = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let LDMI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 10T
    static let LDRPI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let LDRMA = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let LDMAR = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 1) // 2M, 7T
    static let LDRPMA = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 1) // 4M, 13T
    static let LDMARP = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 1) // 4M, 13T
    
    // 16ビット転送命令のサイクル
    static let loadRegPairToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let loadHLToAddr16 = InstructionCycles.standard(opcodeFetch: true, memoryReads: 5) // 6M, 16T
    static let loadAddr16ToHL = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 2, 
        memoryWrites: 2
    )
    static let loadSPToHL = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    
    // 算術演算命令のサイクル
    static let addAToReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let addAToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let addAToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    
    // CB命令のサイクル
    static let RLC_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let RLC_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let RRC_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let RRC_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let RL_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let RL_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let RR_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let RR_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let SLA_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let SLA_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let SRA_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let SRA_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let SLL_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let SLL_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let SRL_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let SRL_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let BIT_B_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let BIT_B_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 1) // 3M, 12T
    static let SET_B_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let SET_B_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let RES_B_R = InstructionCycles.standard(opcodeFetch: true, internalCycles: 1) // 2M, 8T
    static let RES_B_HL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 1) // 4M, 15T
    static let addWithCarryAToReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let addWithCarryAToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let addWithCarryAToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let subtractReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let subtractVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let subtractHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let subtractWithCarryAToReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let subtractWithCarryAToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let subtractWithCarryAToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let incrementReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let incrementHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 11T
    static let decrementReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let decrementHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1) // 3M, 11T
    static let CP = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let CPL = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    
    // 論理演算命令のサイクル
    static let logicalAndReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let logicalAndVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let logicalAndHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let logicalOrReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let logicalOrVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let logicalOrHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let logicalXorReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let logicalXorVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let logicalXorHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let compareReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let compareVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let compareHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    
    // スタック操作命令のサイクル
    static let pushRegPair = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) // 3M, 11T
    static let popRegPair = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let PUSH = InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) // 3M, 11T
    static let POP = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
    // レジスタペア操作命令のサイクル
    static let incrementRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let decrementRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let addHLToRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 7)
    static let INCRP = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let DECRP = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let ADDHL = InstructionCycles.standard(opcodeFetch: true, internalCycles: 7)
    static let SBC = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 8T
    static let LDMEM = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
    // ジャンプ命令のサイクル
    static let jumpToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2)
    static let jumpCondToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2)
    static let jumpRelative = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 1, 
        internalCycles: 5
    ) // 3M, 12T
    static let jumpRelativeCond = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 1, 
        internalCycles: 5
    ) // 3M, 12T
    static let decrJumpNotZero = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 1, 
        internalCycles: 5
    ) // 3M, 13T
    static let DJNZ = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 1) // 3M, 13T
    
    // その他の命令のサイクル
    static let noOperation = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let RLCA = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let RRCA = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let EXAF = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let LDIY = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let complementA = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let returnFromSub = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
    // EDプレフィックス命令のサイクル
    static let IN_R_C = InstructionCycles.standard(opcodeFetch: true, ioReads: 1) // 2M, 8T
    static let OUT_C_R = InstructionCycles.standard(opcodeFetch: true, ioWrites: 1) // 2M, 8T
    static let SBC_HL_RR = InstructionCycles.standard(opcodeFetch: true, internalCycles: 4) // 2M, 8T
    static let ADC_HL_RR = InstructionCycles.standard(opcodeFetch: true, internalCycles: 4) // 2M, 8T
    static let LD_NN_RR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 16T
    static let LD_RR_NN = InstructionCycles.standard(opcodeFetch: true, memoryReads: 4) // 5M, 16T
    static let LDI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 2) // 4M, 16T
    static let LDIR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 5) // 5M, 21T
    static let LDD = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 2) // 4M, 16T
    static let LDDR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, memoryWrites: 1, internalCycles: 5) // 5M, 21T
    static let CPI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 1) // 3M, 12T
    static let CPIR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 4) // 4M, 17T
    static let CPD = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 1) // 3M, 12T
    static let CPDR = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 4) // 4M, 17T
    static let NEG = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let RETN = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let RETI = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let IM = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    
    // プレフィックス命令のサイクル
    static let indexXPrefix = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let indexYPrefix = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let loadIYToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 4M, 14T
    
    // 制御命令のサイクル
    // サブルーチン呼び出し: 5M, 17T
    static let callSubroutine = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 2, 
        memoryWrites: 2, 
        internalCycles: 1
    )
    // 条件付きサブルーチン呼び出し（条件不成立時）: 3M, 10T
    static let callCondSubroutine = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 2
    )
    // 条件成立時の呼び出し: 5M, 17T
    static let callCondSubroutineTaken = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 2, 
        memoryWrites: 2, 
        internalCycles: 1
    )
    // 条件付き戻り（条件不成立時）: 1M, 5T
    static let returnCond = InstructionCycles.standard(
        opcodeFetch: true, 
        internalCycles: 1
    )
    // 条件付き戻り（条件成立時）: 3M, 11T
    static let returnCondTaken = InstructionCycles.standard(
        opcodeFetch: true, 
        memoryReads: 2, 
        internalCycles: 1
    )
    
    // その他の命令のサイクル
    // CPU停止: 1M, 4T
    static let haltCPU = InstructionCycles.standard(opcodeFetch: true)
    // 割り込み無効化: 1M, 4T
    static let disableInterrupt = InstructionCycles.standard(opcodeFetch: true)
    // 割り込み有効化: 1M, 4T
    static let enableInterrupt = InstructionCycles.standard(opcodeFetch: true)
    static let inputAFromPort = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioReads: 1) // 3M, 11T
    static let outputAToPort = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, ioWrites: 1) // 3M, 11T
    
    // 旧定数名（互換性のため）
    static let nopOld = noOperation
    static let haltOld = haltCPU
    static let disableInterruptOld = disableInterrupt
    static let enableInterruptOld = enableInterrupt
}
