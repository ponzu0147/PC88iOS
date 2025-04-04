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
    
    // 16ビット転送命令のサイクル
    static let loadRegPairToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let loadHLToAddr16 = InstructionCycles.standard(opcodeFetch: true, memoryReads: 5) // 6M, 16T
    static let loadAddr16ToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2) // 5M, 16T
    static let loadSPToHL = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    
    // 算術演算命令のサイクル
    static let addAToReg = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let addAToVal = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
    static let addAToHL = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1) // 2M, 7T
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
    
    // レジスタペア操作命令のサイクル
    static let incrementRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let decrementRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) // 2M, 6T
    static let addHLToRegPair = InstructionCycles.standard(opcodeFetch: true, internalCycles: 7) // 3M, 11T
    
    // ジャンプ命令のサイクル
    static let jumpToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let jumpCondToAddr = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    static let jumpRelative = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 12T
    static let jumpRelativeCond = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 12T
    static let decrJumpNotZero = InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) // 3M, 13T
    
    // その他の命令のサイクル
    static let noOperation = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let complementA = InstructionCycles.standard(opcodeFetch: true) // 1M, 4T
    static let returnFromSub = InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) // 3M, 10T
    
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
    static let NOP = noOperation
    static let HALT = haltCPU
    static let DI = disableInterrupt
    static let EI = enableInterrupt
}
