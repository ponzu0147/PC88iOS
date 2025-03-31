//
//  LogicalOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// AND命令（A &= r）
struct ANDInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.AND_r }
    var description: String { return "AND A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // 結果の設定
        registers.a &= value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: true)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    

}

/// OR命令（A |= r）
struct ORInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.OR_r }
    var description: String { return "OR A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // 結果の設定
        registers.a |= value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    

}

/// XOR命令（A ^= r）
struct XORInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.XOR_r }
    var description: String { return "XOR A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // 結果の設定
        registers.a ^= value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    

}

/// CP命令（A - r、結果は破棄）
struct CPInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CP_r }
    var description: String { return "CP A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // ハーフキャリーの計算
        let halfCarry = (registers.a & 0x0F) < (value & 0x0F)
        
        // キャリーの計算
        let carry = registers.a < value
        
        // 結果の計算（Aは変更しない）
        let result = registers.a &- value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(result))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    

}
