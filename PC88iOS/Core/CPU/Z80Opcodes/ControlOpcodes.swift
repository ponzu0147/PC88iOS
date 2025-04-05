//
//  ControlOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

// 必要なファイルをインポート
// プロジェクト内の他のファイルは直接参照できるはず

/// ジャンプ条件
public enum JumpCondition {
    case none
    case zero
    case notZero
    case carry
    case notCarry
    
    /// 条件が満たされているか評価
    func evaluate(registers: Z80Registers) -> Bool {
        switch self {
        case .none:
            return true
        case .zero:
            return registers.getFlag(Z80Registers.Flags.zero)
        case .notZero:
            return !registers.getFlag(Z80Registers.Flags.zero)
        case .carry:
            return registers.getFlag(Z80Registers.Flags.carry)
        case .notCarry:
            return !registers.getFlag(Z80Registers.Flags.carry)
        }
    }
}

/// JP命令（絶対ジャンプ）
public struct JPInstruction: Z80Instruction {
    let condition: JumpCondition
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            registers.pc = address
            return 10 // 条件が真の場合
        } else {
            registers.pc &+= size
            return 10 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) }
    var description: String { return "JP \(condition), \(String(format: "0x%04X", address))" }
}

/// JR命令（相対ジャンプ）
public struct JRInstruction: Z80Instruction {
    let condition: JumpCondition
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            registers.pc = UInt16(Int(registers.pc) + Int(offset) + 2)
            return 12 // 条件が真の場合
        } else {
            registers.pc &+= size
            return 7 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return condition == .none ? 12 : 7 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) }
    var description: String { return "JR \(condition), \(offset)" }
}

/// CALL命令（サブルーチンコール）
public struct CALLInstruction: Z80Instruction {
    let condition: JumpCondition
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            // スタックにリターンアドレスをプッシュ
            registers.sp &-= 2
            let returnAddress = registers.pc &+ size
            memory.writeWord(returnAddress, at: registers.sp)
            
            // ジャンプ先に移動
            registers.pc = address
            return 17 // 条件が真の場合
        } else {
            registers.pc &+= size
            return 10 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return condition == .none ? 17 : 10 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 2, memoryWrites: 2, internalCycles: 1) }
    var description: String { return "CALL \(condition), \(String(format: "0x%04X", address))" }
}

/// RET命令（サブルーチンリターン）
public struct RETInstruction: Z80Instruction {
    let condition: JumpCondition
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            // スタックからリターンアドレスをポップ
            let returnAddress = memory.readWord(at: registers.sp)
            registers.sp &+= 2
            
            // リターンアドレスにジャンプ
            registers.pc = returnAddress
            return 11 // 条件が真の場合
        } else {
            registers.pc &+= size
            return 5 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return condition == .none ? 10 : 5 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) }
    var description: String { return "RET \(condition)" }
}

/// RST命令（リスタート）
struct RSTInstruction: Z80Instruction {
    let address: UInt8 // 0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // スタックにリターンアドレスをプッシュ
        registers.sp &-= 2
        let returnAddress = registers.pc &+ size
        memory.writeWord(returnAddress, at: registers.sp)
        
        // リスタートアドレスにジャンプ
        registers.pc = UInt16(address)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) }
    var description: String { return "RST \(String(format: "0x%02X", address))" }
}
