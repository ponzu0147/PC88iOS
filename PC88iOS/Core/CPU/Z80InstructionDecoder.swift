//
//  Z80InstructionDecoder.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// Z80命令デコーダ
class Z80InstructionDecoder {
    // レジスタ定義は別ファイルで定義されているので使用
    
    // オペランドソースとターゲットは別ファイルで定義されているので使用
    /// 命令をデコード
    func decode(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        // 基本的な命令デコード
        switch opcode {
        case 0x00:
            return NOPInstruction()
        case 0x76:
            return HALTInstruction()
        case 0xF3:
            return DISInstruction()
        case 0xFB:
            return EIInstruction()
        default:
            // 他の命令はグループごとに処理
            if let instruction = decodeArithmeticInstruction(opcode) {
                return instruction
            } else if let instruction = decodeLogicalInstruction(opcode) {
                return instruction
            } else if let instruction = decodeControlInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeLoadInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else {
                // 未実装の命令
                return UnimplementedInstruction(opcode: opcode)
            }
        }
    }
    
    // 算術命令のデコード
    private func decodeArithmeticInstruction(_ opcode: UInt8) -> Z80Instruction? {
        // ADD A, r
        if (opcode & 0xF8) == 0x80 {
            let reg = decodeRegister8(opcode & 0x07)
            return ADDInstruction(source: .register(reg))
        }
        
        // ADD A, n
        if opcode == 0xC6 {
            return ADDInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // ADD A, (HL)
        if opcode == 0x86 {
            return ADDInstruction(source: .memory)
        }
        
        // SUB A, r
        if (opcode & 0xF8) == 0x90 {
            let reg = decodeRegister8(opcode & 0x07)
            return SUBInstruction(source: .register(reg))
        }
        
        // SUB A, n
        if opcode == 0xD6 {
            return SUBInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // SUB A, (HL)
        if opcode == 0x96 {
            return SUBInstruction(source: .memory)
        }
        
        // INC r
        if (opcode & 0xC7) == 0x04 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return INCRegInstruction(register: reg)
        }
        
        // DEC r
        if (opcode & 0xC7) == 0x05 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return DECRegInstruction(register: reg)
        }
        
        return nil
    }
    
    // 論理命令のデコード
    private func decodeLogicalInstruction(_ opcode: UInt8) -> Z80Instruction? {
        // AND A, r
        if (opcode & 0xF8) == 0xA0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ANDInstruction(source: .register(reg))
        }
        
        // AND A, n
        if opcode == 0xE6 {
            return ANDInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // AND A, (HL)
        if opcode == 0xA6 {
            return ANDInstruction(source: .memory)
        }
        
        // OR A, r
        if (opcode & 0xF8) == 0xB0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ORInstruction(source: .register(reg))
        }
        
        // OR A, n
        if opcode == 0xF6 {
            return ORInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // OR A, (HL)
        if opcode == 0xB6 {
            return ORInstruction(source: .memory)
        }
        
        // XOR A, r
        if (opcode & 0xF8) == 0xA8 {
            let reg = decodeRegister8(opcode & 0x07)
            return XORInstruction(source: .register(reg))
        }
        
        // XOR A, n
        if opcode == 0xEE {
            return XORInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // XOR A, (HL)
        if opcode == 0xAE {
            return XORInstruction(source: .memory)
        }
        
        // CP A, r
        if (opcode & 0xF8) == 0xB8 {
            let reg = decodeRegister8(opcode & 0x07)
            return CPInstruction(source: .register(reg))
        }
        
        // CP A, n
        if opcode == 0xFE {
            return CPInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        // CP A, (HL)
        if opcode == 0xBE {
            return CPInstruction(source: .memory)
        }
        
        return nil
    }
    
    // 制御命令のデコード
    private func decodeControlInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // JP nn
        if opcode == 0xC3 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .none, address: address)
        }
        
        // JP cc, nn
        if (opcode & 0xC7) == 0xC2 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: condition, address: address)
        }
        
        // JR e
        if opcode == 0x18 {
            let offset = Int8(bitPattern: memory.readByte(at: pc))
            return JRInstruction(condition: .none, offset: offset)
        }
        
        // JR cc, e
        if (opcode & 0xE7) == 0x20 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let offset = Int8(bitPattern: memory.readByte(at: pc))
            return JRInstruction(condition: condition, offset: offset)
        }
        
        // CALL nn
        if opcode == 0xCD {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .none, address: address)
        }
        
        // CALL cc, nn
        if (opcode & 0xC7) == 0xC4 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: condition, address: address)
        }
        
        // RET
        if opcode == 0xC9 {
            return RETInstruction(condition: .none)
        }
        
        // RET cc
        if (opcode & 0xC7) == 0xC0 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return RETInstruction(condition: condition)
        }
        
        return nil
    }
    
    // ロード命令のデコード
    private func decodeLoadInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // LD r, r'
        if (opcode & 0xC0) == 0x40 && opcode != 0x76 { // 0x76はHALT
            let dst = decodeRegister8((opcode >> 3) & 0x07)
            let src = decodeRegister8(opcode & 0x07)
            return LDRegRegInstruction(destination: convertToRegisterOperand(dst), source: convertToRegisterOperand(src))
        }
        
        // LD r, n
        if (opcode & 0xC7) == 0x06 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: convertToRegisterOperand(reg), value: value)
        }
        
        // LD r, (HL)
        if (opcode & 0xC7) == 0x46 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return LDRegMemInstruction(destination: convertToRegisterOperand(reg), address: .hl)
        }
        
        // LD (HL), r
        if (opcode & 0xF8) == 0x70 {
            let reg = decodeRegister8(opcode & 0x07)
            return LDMemRegInstruction(address: .hl, source: convertToRegisterOperand(reg))
        }
        
        return nil
    }
    
    // レジスタのデコード
    private func decodeRegister8(_ code: UInt8) -> Register8 {
        switch code {
        case 0: return .b
        case 1: return .c
        case 2: return .d
        case 3: return .e
        case 4: return .h
        case 5: return .l
        case 7: return .a
        default: return .a // 6は(HL)だが、ここでは別処理
        }
    }
    
    // 条件のデコード
    private func decodeCondition(_ code: UInt8) -> JumpCondition {
        switch code {
        case 0: return .notZero
        case 1: return .zero
        case 2: return .notCarry
        case 3: return .carry
        default: return .none
        }
    }
    
    // Register8をRegisterOperandに変換
    private func convertToRegisterOperand(_ reg: Register8) -> RegisterOperand {
        switch reg {
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .h: return .h
        case .l: return .l
        }
    }
}

/// Z80命令の基本プロトコル
protocol Z80Instruction {
    /// 命令を実行
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int
    
    /// 命令のサイズ（バイト数）
    var size: UInt16 { get }
    
    /// 命令の実行に必要なサイクル数
    var cycles: Int { get }
    
    /// 命令の文字列表現
    var description: String { get }
}

/// NOP命令
struct NOPInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "NOP" }
}

/// HALT命令
struct HALTInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // CPUをホルト状態にする
        cpu.halt()
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "HALT" }
}

/// DI命令（割り込み禁止）
struct DISInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        cpu.setInterruptEnabled(false)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "DI" }
}

/// EI命令（割り込み許可）
struct EIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        cpu.setInterruptEnabled(true)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "EI" }
}

/// 未実装命令
struct UnimplementedInstruction: Z80Instruction {
    let opcode: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        print("警告: 未実装の命令 0x\(String(opcode, radix: 16, uppercase: true)) at PC=0x\(String(registers.pc, radix: 16, uppercase: true))")
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "UNIMPLEMENTED \(String(format: "0x%02X", opcode))" }
}
