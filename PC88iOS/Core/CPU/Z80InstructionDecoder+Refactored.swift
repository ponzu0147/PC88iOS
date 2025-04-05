//
//
//

import Foundation

class Z80InstructionDecoderRefactored {
    
    func decode(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        if let instruction = decodeBasicInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        }
        
        if let instruction = decodeArithmeticInstruction(opcode) {
            return instruction
        } else if let instruction = decodeLogicalInstruction(opcode) {
            return instruction
        } else if let instruction = decodeControlInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeLoadInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else {
            return UnimplementedInstruction(opcode: opcode)
        }
    }
    
    
    private func decodeBasicInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
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
            return decodeDJNZ(memory: memory, pc: pc)
        case 0x11: // LD DE,nn
            return decodeLDRegPairImm(.de, memory: memory, pc: pc)
        case 0x12: // LD (DE),A
            return LDMemRegInstruction(address: .de, source: .regA)
        case 0x13: // INC DE
            return INCRegPairInstruction(register: .de)
        case 0x21: // LD HL,nn
            return decodeLDRegPairImm(.hl, memory: memory, pc: pc)
        case 0x23: // INC HL
            return INCRegPairInstruction(register: .hl)
        case 0x02: // LD (BC),A
            return LDMemRegInstruction(address: .bc, source: .regA)
        case 0x1A: // LD A,(DE)
            return LDRegMemInstruction(destination: .regA, address: .de)
        case 0x32: // LD (nn),A
            return decodeLDDirectMemReg(memory: memory, pc: pc)
        case 0x3A: // LD A,(nn)
            return decodeLDRegMemAddr(memory: memory, pc: pc)
        case 0x3B: // DEC SP
            return DECRegPairInstruction(register: .sp)
        case 0x01: // LD BC,nn
            return decodeLDRegPairImm(.bc, memory: memory, pc: pc)
        case 0x04: // INC B
            return INCRegInstruction(register: .regB)
        case 0x05: // DEC B
            return DECRegInstruction(register: .regB)
        case 0x06: // LD B,n
            return decodeLDRegImm(.regB, memory: memory, pc: pc)
        case 0x0A: // LD A,(BC)
            return LDRegMemInstruction(destination: .regA, address: .bc)
        case 0x0C: // INC C
            return INCRegInstruction(register: .regC)
        case 0x0D: // DEC C
            return DECRegInstruction(register: .regC)
        case 0x0E: // LD C,n
            return decodeLDRegImm(.regC, memory: memory, pc: pc)
        case 0x14: // INC D
            return INCRegInstruction(register: .regD)
        case 0x15: // DEC D
            return DECRegInstruction(register: .regD)
        case 0x16: // LD D,n
            return decodeLDRegImm(.regD, memory: memory, pc: pc)
        case 0x1C: // INC E
            return INCRegInstruction(register: .regE)
        case 0x1D: // DEC E
            return DECRegInstruction(register: .regE)
        case 0x1E: // LD E,n
            return decodeLDRegImm(.regE, memory: memory, pc: pc)
        case 0x22: // LD (nn),HL
            return decodeLDMemAddrRegPair(memory: memory, pc: pc)
        case 0x24: // INC H
            return INCRegInstruction(register: .regH)
        case 0x25: // DEC H
            return DECRegInstruction(register: .regH)
        case 0x26: // LD H,n
            return decodeLDRegImm(.regH, memory: memory, pc: pc)
        case 0x2A: // LD HL,(nn)
            return decodeLDRegPairMemAddr(memory: memory, pc: pc)
        case 0x2C: // INC L
            return INCRegInstruction(register: .regL)
        case 0x2D: // DEC L
            return DECRegInstruction(register: .regL)
        case 0x2E: // LD L,n
            return decodeLDRegImm(.regL, memory: memory, pc: pc)
        case 0x31: // LD SP,nn
            return decodeLDRegPairImm(.sp, memory: memory, pc: pc)
        case 0x33: // INC SP
            return INCRegPairInstruction(register: .sp)
        case 0x36: // LD (HL),n
            return decodeLDMemImm(memory: memory, pc: pc)
        case 0x18: // JR n
            return decodeJR(.none, memory: memory, pc: pc)
        case 0x20: // JR NZ,n
            return decodeJR(.notZero, memory: memory, pc: pc)
        case 0x28: // JR Z,n
            return decodeJR(.zero, memory: memory, pc: pc)
        case 0x30: // JR NC,n
            return decodeJR(.notCarry, memory: memory, pc: pc)
        case 0x38: // JR C,n
            return decodeJR(.carry, memory: memory, pc: pc)
        case 0x39: // ADD HL,SP
            return ADDHLInstruction(source: .sp)
        case 0x76: // HALT
            return HALTInstruction()
        case 0xC0: // RET NZ
            return RETInstruction(condition: .notZero)
        case 0xC2: // JP NZ,nn
            return decodeJP(.notZero, memory: memory, pc: pc)
        case 0xC3: // JP nn
            return decodeJP(.none, memory: memory, pc: pc)
        case 0xC4: // CALL NZ,nn
            return decodeCALL(.notZero, memory: memory, pc: pc)
        case 0xC8: // RET Z
            return RETInstruction(condition: .zero)
        case 0xC9: // RET
            return RETInstruction(condition: .none)
        case 0xCA: // JP Z,nn
            return decodeJP(.zero, memory: memory, pc: pc)
        case 0xCC: // CALL Z,nn
            return decodeCALL(.zero, memory: memory, pc: pc)
        case 0xCD: // CALL nn
            return decodeCALL(.none, memory: memory, pc: pc)
        case 0xD0: // RET NC
            return RETInstruction(condition: .notCarry)
        case 0xD2: // JP NC,nn
            return decodeJP(.notCarry, memory: memory, pc: pc)
        case 0xD4: // CALL NC,nn
            return decodeCALL(.notCarry, memory: memory, pc: pc)
        case 0xD8: // RET C
            return RETInstruction(condition: .carry)
        case 0xDA: // JP C,nn
            return decodeJP(.carry, memory: memory, pc: pc)
        case 0xDC: // CALL C,nn
            return decodeCALL(.carry, memory: memory, pc: pc)
        case 0x98: // SBC A,B
            return SBCInstruction(source: .regB)
        case 0xC5: // PUSH BC
            return PUSHInstruction(register: .bc)
        case 0xD3: // OUT (n), A
            return decodeOUT(memory: memory, pc: pc)
        case 0xD5: // PUSH DE
            return PUSHInstruction(register: .de)
        case 0xDB: // IN A,(n)
            return decodeIN(memory: memory, pc: pc)
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
            return nil
        }
    }
    
    
    private func decodeDJNZ(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let offset = memory.readByte(at: pc)
        return DJNZInstruction(offset: Int8(bitPattern: offset))
    }
    
    private func decodeLDRegPairImm(_ register: RegisterPairOperand, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let value = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDRegPairImmInstruction(register: register, value: value)
    }
    
    private func decodeLDDirectMemReg(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDDirectMemRegInstruction(address: address, source: .regA)
    }
    
    private func decodeLDRegMemAddr(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDRegMemAddrInstruction(destination: .regA, address: address)
    }
    
    private func decodeLDRegImm(_ register: RegisterOperand, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let value = memory.readByte(at: pc)
        return LDRegImmInstruction(destination: register, value: value)
    }
    
    private func decodeLDMemAddrRegPair(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDMemAddrRegPairInstruction(address: address, source: .hl)
    }
    
    private func decodeLDRegPairMemAddr(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDRegPairMemAddrInstruction(destination: .hl, address: address)
    }
    
    private func decodeLDMemImm(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let value = memory.readByte(at: pc)
        return LDMemImmInstruction(address: .hl, value: value)
    }
    
    private func decodeJR(_ condition: JumpCondition, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let offset = memory.readByte(at: pc)
        return JRInstruction(condition: condition, offset: Int8(bitPattern: offset))
    }
    
    private func decodeJP(_ condition: JumpCondition, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return JPInstruction(condition: condition, address: address)
    }
    
    private func decodeCALL(_ condition: JumpCondition, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return CALLInstruction(condition: condition, address: address)
    }
    
    private func decodeOUT(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let port = memory.readByte(at: pc)
        return OUTInstruction(port: port)
    }
    
    private func decodeIN(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let port = memory.readByte(at: pc)
        return INInstruction(port: port)
    }
    
    
    private func decodeArithmeticInstruction(_ opcode: UInt8) -> Z80Instruction? {
        if (opcode & 0xF8) == 0x80 {
            let reg = decodeRegister8(opcode & 0x07)
            return ADDInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xC6 {
            return ADDInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0x86 {
            return ADDInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0x90 {
            let reg = decodeRegister8(opcode & 0x07)
            return SUBInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xD6 {
            return SUBInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0x96 {
            return SUBInstruction(source: .memory)
        }
        
        if (opcode & 0xC7) == 0x04 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return INCRegInstruction(register: convertToRegisterOperand(reg))
        }
        
        if (opcode & 0xC7) == 0x05 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return DECRegInstruction(register: convertToRegisterOperand(reg))
        }
        
        return nil
    }
    
    
    private func decodeLogicalInstruction(_ opcode: UInt8) -> Z80Instruction? {
        if (opcode & 0xF8) == 0xA0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ANDInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xE6 {
            return ANDInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0xA6 {
            return ANDInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xB0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ORInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xF6 {
            return ORInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0xB6 {
            return ORInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xA8 {
            let reg = decodeRegister8(opcode & 0x07)
            return XORInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xEE {
            return XORInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0xAE {
            return XORInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xB8 {
            let reg = decodeRegister8(opcode & 0x07)
            return CPInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xFE {
            return CPInstruction(source: .immediate(0)) // 即値は後で読み込む
        }
        
        if opcode == 0xBE {
            return CPInstruction(source: .memory)
        }
        
        return nil
    }
    
    
    private func decodeControlInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if opcode == 0xC3 {
            return decodeJP(.none, memory: memory, pc: pc)
        }
        
        if (opcode & 0xC7) == 0xC2 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return decodeJP(condition, memory: memory, pc: pc)
        }
        
        if opcode == 0x18 {
            return decodeJR(.none, memory: memory, pc: pc)
        }
        
        if (opcode & 0xE7) == 0x20 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return decodeJR(condition, memory: memory, pc: pc)
        }
        
        if opcode == 0xCD {
            return decodeCALL(.none, memory: memory, pc: pc)
        }
        
        if (opcode & 0xC7) == 0xC4 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return decodeCALL(condition, memory: memory, pc: pc)
        }
        
        if opcode == 0xC9 {
            return RETInstruction(condition: .none)
        }
        
        if (opcode & 0xC7) == 0xC0 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return RETInstruction(condition: condition)
        }
        
        return nil
    }
    
    
    private func decodeLoadInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if (opcode & 0xC0) == 0x40 && opcode != 0x76 { // 0x76はHALT
            let dst = decodeRegister8((opcode >> 3) & 0x07)
            let src = decodeRegister8(opcode & 0x07)
            return LDRegRegInstruction(
                destination: convertToRegisterOperand(dst),
                source: convertToRegisterOperand(src)
            )
        }
        
        if (opcode & 0xC7) == 0x06 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return decodeLDRegImm(convertToRegisterOperand(reg), memory: memory, pc: pc)
        }
        
        if (opcode & 0xC7) == 0x46 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return LDRegMemInstruction(destination: convertToRegisterOperand(reg), address: .hl)
        }
        
        if (opcode & 0xF8) == 0x70 {
            let reg = decodeRegister8(opcode & 0x07)
            return LDMemRegInstruction(address: .hl, source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0x31 {
            return decodeLDRegPairImm(.sp, memory: memory, pc: pc)
        }
        
        if opcode == 0x01 {
            return decodeLDRegPairImm(.bc, memory: memory, pc: pc)
        }
        
        return nil
    }
    
    
    private func decodeIYPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let nextOpcode = memory.readByte(at: pc)
        let nextPc = pc &+ 1
        
        switch nextOpcode {
        case 0x21: // LD IY,nn
            let lowByte = memory.readByte(at: nextPc)
            let highByte = memory.readByte(at: nextPc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDIYInstruction(value: value)
        default:
            let instruction = decode(nextOpcode, memory: memory, pc: nextPc)
            return IYPrefixedInstruction(instruction: instruction)
        }
    }
    
    
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
    
    private func decodeCondition(_ code: UInt8) -> JumpCondition {
        switch code {
        case 0: return .notZero
        case 1: return .zero
        case 2: return .notCarry
        case 3: return .carry
        default: return .none
        }
    }
    
    private func convertToRegisterOperand(_ reg: Register8) -> RegisterOperand {
        switch reg {
        case .a: return .regA
        case .b: return .regB
        case .c: return .regC
        case .d: return .regD
        case .e: return .regE
        case .h: return .regH
        case .l: return .regL
        }
    }
}
