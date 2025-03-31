//
//  Z80InstructionDecoder.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//
//  注意: このファイルは Z80Opcodes/ControlOpcodes.swift で定義されている
//  JumpCondition, JPInstruction, JRInstruction, CALLInstruction, RETInstruction の型を使用します。
//  これらの型はZ80InstructionDecoderでは定義されていません。

import Foundation

/// Z80命令デコーダ
class Z80InstructionDecoder {
    // レジスタ定義は別ファイルで定義されているので使用
    
    // オペランドソースとターゲットは別ファイルで定義されているので使用
    /// 命令をデコード
    func decode(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        // 基本的な命令デコード
        switch opcode {
        case 0x00: // NOP
            return NOPInstruction()
        case 0x03: // INC BC
            return INCRegPairInstruction(register: .bc)
        case 0x07: // RLCA
            return RLCAInstruction()
        case 0x08: // EX AF,AF'
            return EXAFInstruction()
        case 0x0F: // RRCA
            return RRCAInstruction()
        case 0x10: // DJNZ
            let offset = memory.readByte(at: pc)
            return DJNZInstruction(offset: Int8(bitPattern: offset))
        case 0x11: // LD DE,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .de, value: value)
        case 0x12: // LD (DE),A
            return LDMemRegInstruction(address: .de, source: .a)
        case 0x13: // INC DE
            return INCRegPairInstruction(register: .de)
        case 0x21: // LD HL,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .hl, value: value)
        case 0x23: // INC HL
            return INCRegPairInstruction(register: .hl)
        case 0x02: // LD (BC),A
            return LDMemRegInstruction(address: .bc, source: .a)
            
        case 0x1A: // LD A,(DE)
            return LDRegMemInstruction(destination: .a, address: .de)
            
        case 0x32: // LD (nn),A
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDDirectMemRegInstruction(address: address, source: .a)
            
        case 0x3A: // LD A,(nn)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegMemAddrInstruction(destination: .a, address: address)
            
        case 0x3B: // DEC SP
            return DECRegPairInstruction(register: .sp)
        case 0x01: // LD BC,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .bc, value: value)
        case 0x04: // INC B
            return INCRegInstruction(register: .b)
        case 0x05: // DEC B
            return DECRegInstruction(register: .b)
        case 0x06: // LD B,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .b, value: value)
        case 0x0A: // LD A,(BC)
            return LDRegMemInstruction(destination: .a, address: .bc)
        case 0x0C: // INC C
            return INCRegInstruction(register: .c)
        case 0x0D: // DEC C
            return DECRegInstruction(register: .c)
        case 0x0E: // LD C,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .c, value: value)
        case 0x14: // INC D
            return INCRegInstruction(register: .d)
        case 0x15: // DEC D
            return DECRegInstruction(register: .d)
        case 0x16: // LD D,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .d, value: value)
        case 0x1C: // INC E
            return INCRegInstruction(register: .e)
        case 0x1D: // DEC E
            return DECRegInstruction(register: .e)
        case 0x1E: // LD E,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .e, value: value)
        case 0x22: // LD (nn),HL
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDMemAddrRegPairInstruction(address: address, source: .hl)
        case 0x24: // INC H
            return INCRegInstruction(register: .h)
        case 0x25: // DEC H
            return DECRegInstruction(register: .h)
        case 0x26: // LD H,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .h, value: value)
        case 0x2A: // LD HL,(nn)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairMemAddrInstruction(destination: .hl, address: address)
        case 0x2C: // INC L
            return INCRegInstruction(register: .l)
        case 0x2D: // DEC L
            return DECRegInstruction(register: .l)
        case 0x2E: // LD L,n
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: .l, value: value)
        case 0x31: // LD SP,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .sp, value: value)
        case 0x33: // INC SP
            return INCRegPairInstruction(register: .sp)
        case 0x36: // LD (HL),n
            let value = memory.readByte(at: pc)
            return LDMemImmInstruction(address: .hl, value: value)
        case 0x18: // JR n
            let offset = memory.readByte(at: pc)
            return JRInstruction(condition: .none, offset: Int8(bitPattern: offset))
        case 0x20: // JR NZ,n
            let offset = memory.readByte(at: pc)
            return JRInstruction(condition: .notZero, offset: Int8(bitPattern: offset))
        case 0x28: // JR Z,n
            let offset = memory.readByte(at: pc)
            return JRInstruction(condition: .zero, offset: Int8(bitPattern: offset))
        case 0x30: // JR NC,n
            let offset = memory.readByte(at: pc)
            return JRInstruction(condition: .notCarry, offset: Int8(bitPattern: offset))
        case 0x38: // JR C,n
            let offset = memory.readByte(at: pc)
            return JRInstruction(condition: .carry, offset: Int8(bitPattern: offset))
        case 0x39: // ADD HL,SP
            return ADDHLInstruction(source: .sp)
        case 0x76: // HALT
            return HALTInstruction()
        case 0xC0: // RET NZ
            return RETInstruction(condition: .notZero)
        case 0xC2: // JP NZ,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .notZero, address: address)
        case 0xC3: // JP nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .none, address: address)
        case 0xC4: // CALL NZ,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .notZero, address: address)
        case 0xC8: // RET Z
            return RETInstruction(condition: .zero)
        case 0xC9: // RET
            return RETInstruction(condition: .none)
        case 0xCA: // JP Z,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .zero, address: address)
        case 0xCC: // CALL Z,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .zero, address: address)
        case 0xCD: // CALL nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .none, address: address)
        case 0xD0: // RET NC
            return RETInstruction(condition: .notCarry)
        case 0xD2: // JP NC,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .notCarry, address: address)
        case 0xD4: // CALL NC,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .notCarry, address: address)
        case 0xD8: // RET C
            return RETInstruction(condition: .carry)
        case 0xDA: // JP C,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .carry, address: address)
        case 0xDC: // CALL C,nn
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .carry, address: address)
        case 0x98: // SBC A,B
            return SBCInstruction(source: .b)
        case 0xC5: // PUSH BC
            return PUSHInstruction(register: .bc)
        case 0xD3: // OUT (n), A
            let port = memory.readByte(at: pc)
            return OUTInstruction(port: port)
        case 0xD5: // PUSH DE
            return PUSHInstruction(register: .de)
        case 0xDB: // IN A,(n)
            let port = memory.readByte(at: pc)
            return INInstruction(port: port)
        case 0xE1: // POP HL
            return POPInstruction(register: .hl)
        case 0xE5: // PUSH HL
            return PUSHInstruction(register: .hl)
        case 0x2F: // CPL
            return CPLInstruction()
        case 0xC1: // POP BC
            return POPInstruction(register: .bc)
        case 0xD1: // POP DE
            return POPInstruction(register: .de)
        case 0xF1: // POP AF
            return POPInstruction(register: .af)
        case 0xF3: // DI
            return DISInstruction()
        case 0xF5: // PUSH AF
            return PUSHInstruction(register: .af)
        case 0xFB: // EI
            return EIInstruction()
        case 0xFD: // IYプレフィックス
            return decodeIYPrefixedInstruction(memory: memory, pc: pc)
        case 0xFF: // RST 38H
            return RSTInstruction(address: 0x38)
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
            // 安全なメモリアクセス
            let lowByte = memory.readByte(at: pc)
            // 安全なアドレス計算
            let nextPC = pc < UInt16.max ? pc + 1 : pc
            let highByte = memory.readByte(at: nextPC)
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
            // 安全なメモリアクセス
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
        
        // LD SP, nn (0x31)
        if opcode == 0x31 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .sp, value: value)
        }
        
        // LD BC, nn (0x01)
        if opcode == 0x01 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: .bc, value: value)
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
    
    /// IYプレフィックス命令のデコード
    private func decodeIYPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        // 次のバイトを読み取る
        let nextOpcode = memory.readByte(at: pc)
        let nextPc = pc &+ 1
        
        // 特別なIY命令の処理
        switch nextOpcode {
        case 0x21: // LD IY,nn
            let lowByte = memory.readByte(at: nextPc)
            let highByte = memory.readByte(at: nextPc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDIYInstruction(value: value)
        default:
            // 他の通常命令をIYプレフィックスとしてデコード
            let instruction = decode(nextOpcode, memory: memory, pc: nextPc)
            return IYPrefixedInstruction(instruction: instruction)
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
    
    /// 命令の詳細なサイクル情報
    var cycleInfo: InstructionCycles { get }
    
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
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
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
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.HALT }
    var description: String { return "HALT" }
}

/// DI命令（割り込み禁止）
struct DISInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // 割り込み禁止（CPUExecutingプロトコルのメソッドを使用）
        (cpu as CPUExecuting).setInterruptEnabled(false)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.DI }
    var description: String { return "DI" }
}

/// EI命令（割り込み許可）
struct EIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // 割り込み許可（CPUExecutingプロトコルのメソッドを使用）
        (cpu as CPUExecuting).setInterruptEnabled(true)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.EI }
    var description: String { return "EI" }
}

/// 未実装命令
struct UnimplementedInstruction: Z80Instruction {
    let opcode: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // PCの計算で整数オーバーフローを防止
        let pc = registers.pc > 0 ? registers.pc - 1 : 0
        print("警告: 未実装の命令 0x\(String(opcode, radix: 16, uppercase: true)) at PC=0x\(String(pc, radix: 16, uppercase: true))")
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP } // 未実装命令はNOPと同じサイクル情報を使用
    var description: String { return "UNIMPLEMENTED \(String(format: "0x%02X", opcode))" }
}

/// POP命令 - スタックから値を取得してレジスタペアに格納
struct POPInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // スタックから値を取得
        let value = memory.readWord(at: registers.sp)
        
        // レジスタに設定
        register.write(to: &registers, value: value)
        
        // SPを増加
        if registers.sp < UInt16.max - 1 {
            registers.sp += 2
        } else {
            // オーバーフローを防止
            registers.sp = 0
            print("警告: スタックポインタがオーバーフローしました")
        }
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RET } // POPはRETと同じサイクル情報
    var description: String { return "POP \(register)" }
}



/// RLCA命令
struct RLCAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // Aレジスタを左に回転し、最上位ビットをキャリーフラグと最下位ビットに設定
        let carry = (registers.a & 0x80) != 0
        registers.a = (registers.a << 1) | (carry ? 1 : 0)
        
        // フラグを設定
        if carry {
            registers.f = (registers.f | 0x01) // キャリーフラグをセット
        } else {
            registers.f = (registers.f & 0xFE) // キャリーフラグをクリア
        }
        
        // HとNフラグをクリア
        registers.f &= ~0x12
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP } // RLCAはNOPと同じサイクル情報
    var description: String { return "RLCA" }
}

/// SBC A,B命令
struct SBCInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // ソースの値を取得
        let value = source.read(from: registers, memory: memory)
        
        // キャリーフラグの状態を取得
        let carry: UInt8 = (registers.f & 0x01) != 0 ? 1 : 0
        
        // 減算とキャリーを実行
        let result = registers.a &- value &- carry
        
        // フラグを設定
        // ゼロフラグ
        let zeroFlag: UInt8 = (result == 0) ? 0x40 : 0
        
        // サインフラグ
        let signFlag: UInt8 = (result & 0x80) != 0 ? 0x80 : 0
        
        // キャリーフラグ
        let carryFlag: UInt8 = (Int(registers.a) - Int(value) - Int(carry) < 0) ? 0x01 : 0
        
        // ハーフキャリーフラグ
        let halfCarryFlag: UInt8 = (Int(registers.a & 0x0F) - Int(value & 0x0F) - Int(carry) < 0) ? 0x10 : 0
        
        // Nフラグは常に1
        let nFlag: UInt8 = 0x02
        
        // パリティ/オーバーフローフラグ
        let pFlag: UInt8 = ((registers.a ^ value) & 0x80) != 0 && ((value ^ result) & 0x80) != 0 ? 0x04 : 0
        
        // フラグを組み合わせて設定
        registers.f = zeroFlag | signFlag | carryFlag | halfCarryFlag | nFlag | pFlag
        
        // 結果をAレジスタに設定
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.SBC_A_r }
    var description: String { return "SBC A,\(source)" }
}

/// RRCA命令
struct RRCAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // Aレジスタを右に回転
        let carry = registers.a & 0x01
        registers.a = (registers.a >> 1) | (carry << 7)
        
        // フラグを設定
        if carry != 0 {
            registers.f = (registers.f | 0x01) // キャリーフラグをセット
        } else {
            registers.f = (registers.f & 0xFE) // キャリーフラグをクリア
        }
        
        // HとNフラグをクリア
        registers.f &= ~0x12
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP } // RRCAはNOPと同じサイクル情報
    var description: String { return "RRCA" }
}

/// EX AF,AF'命令
struct EXAFInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // AFとAF'を交換
        let tempA = registers.a
        let tempF = registers.f
        registers.a = registers.a_alt
        registers.f = registers.f_alt
        registers.a_alt = tempA
        registers.f_alt = tempF
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP } // EX AF,AF'はNOPと同じサイクル情報
    var description: String { return "EX AF,AF'" }
}

/// PUSH命令
struct PUSHInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = register.read(from: registers)
        // SPを減算
        if registers.sp >= 2 {
            registers.sp = registers.sp &- 2
        } else {
            registers.sp = 0xFFFF
            print("警告: スタックポインタがオーバーフローしました")
        }
        // メモリに書き込み
        memory.writeWord(value, at: registers.sp)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryWrites: 2) }
    var description: String { return "PUSH \(register)" }
}



/// INCレジスタペア命令
struct INCRegPairInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = register.read(from: registers)
        register.write(to: &registers, value: value &+ 1)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 6 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) }
    var description: String { return "INC \(register)" }
}



/// LD A,(nn)命令（直接アドレスからAレジスタへのロード）
struct LDRegMemAddrInstruction: Z80Instruction {
    let destination: RegisterOperand
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = memory.readByte(at: address)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 3, internalCycles: 2) }
    var description: String { return "LD \(destination),(\(String(address, radix: 16)))" }
}

/// レジスタペアのデクリメント命令
struct DECRegPairInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = register.read(from: registers)
        register.write(to: &registers, value: value &- 1)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 6 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, internalCycles: 2) }
    var description: String { return "DEC \(register)" }
}

/// LD直接メモリレジスタ命令
struct LDDirectMemRegInstruction: Z80Instruction {
    let address: UInt16
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        memory.writeByte(value, at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 } // オペコード + アドレス(2バイト)
    var cycles: Int { return 13 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LD_nn_A } // 直接メモリアドレスへの書き込み
    var description: String { return "LD (\(String(format: "0x%04X", address))),\(source)" }
}

/// ADD HL,rr命令
struct ADDHLInstruction: Z80Instruction {
    let source: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let hl = registers.hl
        let value = source.read(from: registers)
        let result = hl &+ value
        
        // フラグ設定
        // キャリーフラグ
        let carryFlag: UInt8 = ((UInt32(hl) + UInt32(value)) > 0xFFFF) ? 0x01 : 0
        
        // ハーフキャリーフラグ
        let halfCarryFlag: UInt8 = (((hl & 0x0FFF) + (value & 0x0FFF)) > 0x0FFF) ? 0x10 : 0
        
        // Nフラグはリセット
        registers.f = (registers.f & 0xC4) | carryFlag | halfCarryFlag
        
        registers.hl = result
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, internalCycles: 7) }
    var description: String { return "ADD HL,\(source)" }
}

/// DJNZ命令
struct DJNZInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // Bレジスタをデクリメント
        registers.b = registers.b &- 1
        
        // Bが0でなければジャンプ
        if registers.b != 0 {
            // PCにオフセットを加算
            registers.pc = UInt16(Int(registers.pc) + Int(offset))
            return 13 // ジャンプする場合のサイクル数
        }
        
        return 8 // ジャンプしない場合のサイクル数
    }
    
    var size: UInt16 { return 2 } // オペコード + オフセット
    var cycles: Int { return 8 } // 非ジャンプ時のサイクル数
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 1, internalCycles: 5) }
    var description: String { return "DJNZ \(String(format: "%+d", offset))" }
}

/// IYプレフィックス命令
/// CPL命令 - Aレジスタの全ビットを反転する
struct CPLInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // Aレジスタの全ビットを反転
        registers.a = ~registers.a
        
        // フラグの設定
        // H, Nフラグをセット
        registers.f = (registers.f & 0xC5) | 0x12 // 0x12 = (H | N)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "CPL" }
}

struct IYPrefixedInstruction: Z80Instruction {
    let instruction: Z80Instruction
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // IYプレフィックス命令は通常の命令と同じように実行されるが、
        // HLレジスタの代わりにIYレジスタを使用する
        let savedHL = registers.hl
        registers.hl = registers.iy
        
        let cycles = instruction.execute(cpu: cpu, registers: &registers, memory: memory, io: io)
        
        registers.iy = registers.hl
        registers.hl = savedHL
        
        return cycles
    }
    
    var size: UInt16 { return instruction.size + 1 } // プレフィックスバイトを追加
    var cycles: Int { return instruction.cycles + 4 } // プレフィックス命令は通常の命令より4サイクル多く消費する
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "IY: \(instruction.description)" }
}

/// LD IY,nn命令
struct LDIYInstruction: Z80Instruction {
    let value: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        registers.iy = value
        return cycles
    }
    
    var size: UInt16 { return 4 } // FD + 21 + nn (2バイト)
    var cycles: Int { return 14 } // LD HL,nnの10サイクル + プレフィックスの4サイクル
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true, memoryReads: 2) }
    var description: String { return "LD IY,\(String(format: "0x%04X", value))" }
}










