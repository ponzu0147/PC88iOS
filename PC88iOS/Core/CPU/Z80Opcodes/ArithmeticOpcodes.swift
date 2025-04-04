//
//  ArithmeticOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 加算命令（A += r）
struct ADDInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "ADD A," + sourceDescription() }
    
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
            case .regA: value = registers.a
            case .regB: value = registers.b
            case .regC: value = registers.c
            case .regD: value = registers.d
            case .regE: value = registers.e
            case .regH: value = registers.h
            case .regL: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // ハーフキャリーの計算
        let halfCarry = ((registers.a & 0x0F) + (value & 0x0F)) > 0x0F
        
        // キャリーの計算
        let result = UInt16(registers.a) + UInt16(value)
        let carry = result > 0xFF
        
        // 結果の設定
        registers.a = UInt8(result & 0xFF)
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    

}

/// 加算命令（A += r + Carry）
struct ADCInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "ADC A," + sourceDescription() }
    
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
            case .regA: value = registers.a
            case .regB: value = registers.b
            case .regC: value = registers.c
            case .regD: value = registers.d
            case .regE: value = registers.e
            case .regH: value = registers.h
            case .regL: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        let carryValue: UInt8 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        // ハーフキャリーの計算
        let halfCarry = ((registers.a & 0x0F) + (value & 0x0F) + carryValue) > 0x0F
        
        // キャリーの計算
        let result = UInt16(registers.a) + UInt16(value) + UInt16(carryValue)
        let carry = result > 0xFF
        
        // 結果の設定
        registers.a = UInt8(result & 0xFF)
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    

}

/// 減算命令（A -= r）
struct SUBInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "SUB A," + sourceDescription() }
    
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
            case .regA: value = registers.a
            case .regB: value = registers.b
            case .regC: value = registers.c
            case .regD: value = registers.d
            case .regE: value = registers.e
            case .regH: value = registers.h
            case .regL: value = registers.l
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
        
        // 結果の設定
        registers.a = registers.a &- value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    

}

/// レジスタソース
enum RegisterSource {
    case register(Register8)
    case memory
    case immediate(UInt8)
}

/// 8ビットレジスタ
enum Register8 {
    case regA, regB, regC, regD, regE, regH, regL
}

/// INC r命令（レジスタインクリメント）
struct INCRegInstruction: Z80Instruction {
    let register: Register8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        
        // レジスタから値を取得
        switch register {
        case .regA: value = registers.a
        case .regB: value = registers.b
        case .regC: value = registers.c
        case .regD: value = registers.d
        case .regE: value = registers.e
        case .regH: value = registers.h
        case .regL: value = registers.l
        }
        
        // ハーフキャリーの計算
        let halfCarry = (value & 0x0F) == 0x0F
        
        // 値をインクリメント
        let result = value &+ 1
        
        // 結果をレジスタに設定
        switch register {
        case .regA: registers.a = result
        case .regB: registers.b = result
        case .regC: registers.c = result
        case .regD: registers.d = result
        case .regE: registers.e = result
        case .regH: registers.h = result
        case .regL: registers.l = result
        }
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(result))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "INC \(register)" }
}

/// DEC r命令（レジスタデクリメント）
struct DECRegInstruction: Z80Instruction {
    let register: Register8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        
        // レジスタから値を取得
        switch register {
        case .regA: value = registers.a
        case .regB: value = registers.b
        case .regC: value = registers.c
        case .regD: value = registers.d
        case .regE: value = registers.e
        case .regH: value = registers.h
        case .regL: value = registers.l
        }
        
        // ハーフキャリーの計算
        let halfCarry = (value & 0x0F) == 0x00
        
        // 値をデクリメント
        let result = value &- 1
        
        // 結果をレジスタに設定
        switch register {
        case .regA: registers.a = result
        case .regB: registers.b = result
        case .regC: registers.c = result
        case .regD: registers.d = result
        case .regE: registers.e = result
        case .regH: registers.h = result
        case .regL: registers.l = result
        }
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(result))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "DEC \(register)" }
}
