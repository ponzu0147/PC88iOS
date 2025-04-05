//
//  ControlOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import PC88iOS

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
            registers.programCounter = address
            return 10 // 条件が真の場合
        } else {
            registers.programCounter &+= size
            return 10 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { 
        return Z80InstructionCycles.JP
    }
    var description: String { 
        let addressStr = String(format: "0x%04X", address)
        return "JP \(condition), \(addressStr)" 
    }
}

/// JR命令（相対ジャンプ）
public struct JRInstruction: Z80Instruction {
    let condition: JumpCondition
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            let newPC = Int(registers.programCounter) + Int(offset) + 2
            registers.programCounter = UInt16(newPC)
            return 12 // 条件が真の場合
        } else {
            registers.programCounter &+= size
            return 7 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return condition == .none ? 12 : 7 }
    var cycleInfo: InstructionCycles { 
        return Z80InstructionCycles.JR
    }
    var description: String { 
        return "JR \(condition), \(offset)" 
    }
}

/// CALL命令（サブルーチンコール）
public struct CALLInstruction: Z80Instruction {
    let condition: JumpCondition
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            // スタックにリターンアドレスをプッシュ
            registers.stackPointer &-= 2
            let returnAddress = registers.programCounter &+ size
            memory.writeWord(returnAddress, at: registers.stackPointer)
            
            // ジャンプ先に移動
            registers.programCounter = address
            return 17 // 条件が真の場合
        } else {
            registers.programCounter &+= size
            return 10 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return condition == .none ? 17 : 10 }
    var cycleInfo: InstructionCycles { 
        return Z80InstructionCycles.CALL
    }
    var description: String { 
        let addressStr = String(format: "0x%04X", address)
        return "CALL \(condition), \(addressStr)" 
    }
}

/// RET命令（サブルーチンリターン）
public struct RETInstruction: Z80Instruction {
    let condition: JumpCondition
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if condition.evaluate(registers: registers) {
            // スタックからリターンアドレスをポップ
            let returnAddress = memory.readWord(at: registers.stackPointer)
            registers.stackPointer &+= 2
            
            // リターンアドレスにジャンプ
            registers.programCounter = returnAddress
            return 11 // 条件が真の場合
        } else {
            registers.programCounter &+= size
            return 5 // 条件が偽の場合
        }
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return condition == .none ? 10 : 5 }
    var cycleInfo: InstructionCycles { 
        return Z80InstructionCycles.JP
    }
    var description: String { 
        return "RET \(condition)" 
    }
}

/// RST命令（リスタート）
struct RSTInstruction: Z80Instruction {
    let address: UInt8 // 0x00, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // スタックにリターンアドレスをプッシュ
        registers.stackPointer &-= 2
        let returnAddress = registers.programCounter &+ size
        memory.writeWord(returnAddress, at: registers.stackPointer)
        
        // リスタートアドレスにジャンプ
        registers.programCounter = UInt16(address)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { 
        return Z80InstructionCycles.RST
    }
    var description: String { 
        return "RST \(String(format: "0x%02X", address))" 
    }
}
