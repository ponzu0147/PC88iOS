//
//
//

import Foundation

class Z80InstructionDecoder {
    
    func decode(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        switch opcode {
        case 0x00: // NOP
            return NOPInstruction()
        case 0x76: // HALT
            return HALTInstruction()
        case 0xF3: // DI
            return DISInstruction()
        case 0xFB: // EI
            return EIInstruction()
        case 0xFD: // IYプレフィックス
            return decodeIYPrefixedInstruction(memory: memory, pc: pc)
        default:
            if let instruction = decodeArithmeticInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeLogicalInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeControlInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeLoadInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeStackInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else if let instruction = decodeIOInstruction(opcode, memory: memory, pc: pc) {
                return instruction
            } else {
                return UnimplementedInstruction(opcode: opcode)
            }
        }
    }
    
    
    private func decodeArithmeticInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if (opcode & 0xF8) == 0x80 {
            let reg = decodeRegister8(opcode & 0x07)
            return ADDInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xC6 {
            let value = memory.readByte(at: pc)
            return ADDInstruction(source: .immediate(value))
        }
        
        if opcode == 0x86 {
            return ADDInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0x90 {
            let reg = decodeRegister8(opcode & 0x07)
            return SUBInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xD6 {
            let value = memory.readByte(at: pc)
            return SUBInstruction(source: .immediate(value))
        }
        
        if opcode == 0x96 {
            return SUBInstruction(source: .memory)
        }
        
        if (opcode & 0xC7) == 0x04 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return INCRegInstruction(register: reg)
        }
        
        if (opcode & 0xC7) == 0x05 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return DECRegInstruction(register: reg)
        }
        
        if (opcode & 0xCF) == 0x03 {
            let rp = decodeRegisterPair((opcode >> 4) & 0x03)
            return INCRegPairInstruction(register: rp)
        }
        
        if (opcode & 0xCF) == 0x0B {
            let rp = decodeRegisterPair((opcode >> 4) & 0x03)
            return DECRegPairInstruction(register: rp)
        }
        
        if (opcode & 0xCF) == 0x09 {
            let rp = decodeRegisterPair((opcode >> 4) & 0x03)
            return ADDHLInstruction(source: rp)
        }
        
        if opcode == 0x98 {
            return SBCInstruction(source: .b)
        }
        
        if opcode == 0x07 {
            return RLCAInstruction()
        }
        
        if opcode == 0x0F {
            return RRCAInstruction()
        }
        
        if opcode == 0x10 {
            let offset = memory.readByte(at: pc)
            return DJNZInstruction(offset: Int8(bitPattern: offset))
        }
        
        if opcode == 0x2F {
            return CPLInstruction()
        }
        
        return nil
    }
    
    private func decodeLogicalInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if (opcode & 0xF8) == 0xA0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ANDInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xE6 {
            let value = memory.readByte(at: pc)
            return ANDInstruction(source: .immediate(value))
        }
        
        if opcode == 0xA6 {
            return ANDInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xB0 {
            let reg = decodeRegister8(opcode & 0x07)
            return ORInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xF6 {
            let value = memory.readByte(at: pc)
            return ORInstruction(source: .immediate(value))
        }
        
        if opcode == 0xB6 {
            return ORInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xA8 {
            let reg = decodeRegister8(opcode & 0x07)
            return XORInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xEE {
            let value = memory.readByte(at: pc)
            return XORInstruction(source: .immediate(value))
        }
        
        if opcode == 0xAE {
            return XORInstruction(source: .memory)
        }
        
        if (opcode & 0xF8) == 0xB8 {
            let reg = decodeRegister8(opcode & 0x07)
            return CPInstruction(source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0xFE {
            let value = memory.readByte(at: pc)
            return CPInstruction(source: .immediate(value))
        }
        
        if opcode == 0xBE {
            return CPInstruction(source: .memory)
        }
        
        return nil
    }
    
    private func decodeControlInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if opcode == 0xC3 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: .none, address: address)
        }
        
        if (opcode & 0xC7) == 0xC2 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return JPInstruction(condition: condition, address: address)
        }
        
        if opcode == 0x18 {
            let offset = Int8(bitPattern: memory.readByte(at: pc))
            return JRInstruction(condition: .none, offset: offset)
        }
        
        if (opcode & 0xE7) == 0x20 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let offset = Int8(bitPattern: memory.readByte(at: pc))
            return JRInstruction(condition: condition, offset: offset)
        }
        
        if opcode == 0xCD {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: .none, address: address)
        }
        
        if (opcode & 0xC7) == 0xC4 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return CALLInstruction(condition: condition, address: address)
        }
        
        if opcode == 0xC9 {
            return RETInstruction(condition: .none)
        }
        
        if (opcode & 0xC7) == 0xC0 {
            let condition = decodeCondition((opcode >> 3) & 0x03)
            return RETInstruction(condition: condition)
        }
        
        if (opcode & 0xC7) == 0xC7 {
            let address = UInt16(opcode & 0x38)
            return RSTInstruction(address: address)
        }
        
        if opcode == 0x08 {
            return EXAFInstruction()
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
            let value = memory.readByte(at: pc)
            return LDRegImmInstruction(destination: convertToRegisterOperand(reg), value: value)
        }
        
        if (opcode & 0xC7) == 0x46 {
            let reg = decodeRegister8((opcode >> 3) & 0x07)
            return LDRegMemInstruction(destination: convertToRegisterOperand(reg), address: .hl)
        }
        
        if (opcode & 0xF8) == 0x70 {
            let reg = decodeRegister8(opcode & 0x07)
            return LDMemRegInstruction(address: .hl, source: convertToRegisterOperand(reg))
        }
        
        if (opcode & 0xCF) == 0x01 {
            let rp = decodeRegisterPair((opcode >> 4) & 0x03)
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairImmInstruction(register: rp, value: value)
        }
        
        if opcode == 0x0A {
            return LDRegMemInstruction(destination: .a, address: .bc)
        }
        
        if opcode == 0x1A {
            return LDRegMemInstruction(destination: .a, address: .de)
        }
        
        if opcode == 0x02 {
            return LDMemRegInstruction(address: .bc, source: .a)
        }
        
        if opcode == 0x12 {
            return LDMemRegInstruction(address: .de, source: .a)
        }
        
        if opcode == 0x3A {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegMemAddrInstruction(destination: .a, address: address)
        }
        
        if opcode == 0x32 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDDirectMemRegInstruction(address: address, source: .a)
        }
        
        if opcode == 0x2A {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDRegPairMemAddrInstruction(destination: .hl, address: address)
        }
        
        if opcode == 0x22 {
            let lowByte = memory.readByte(at: pc)
            let highByte = memory.readByte(at: pc &+ 1)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDMemAddrRegPairInstruction(address: address, source: .hl)
        }
        
        if opcode == 0x36 {
            let value = memory.readByte(at: pc)
            return LDMemImmInstruction(address: .hl, value: value)
        }
        
        return nil
    }
    
    private func decodeStackInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if opcode == 0xC5 {
            return PUSHInstruction(register: .bc)
        }
        
        if opcode == 0xD5 {
            return PUSHInstruction(register: .de)
        }
        
        if opcode == 0xE5 {
            return PUSHInstruction(register: .hl)
        }
        
        if opcode == 0xF5 {
            return PUSHInstruction(register: .af)
        }
        
        if opcode == 0xC1 {
            return POPInstruction(register: .bc)
        }
        
        if opcode == 0xD1 {
            return POPInstruction(register: .de)
        }
        
        if opcode == 0xE1 {
            return POPInstruction(register: .hl)
        }
        
        if opcode == 0xF1 {
            return POPInstruction(register: .af)
        }
        
        return nil
    }
    
    private func decodeIOInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if opcode == 0xDB {
            let port = memory.readByte(at: pc)
            return INInstruction(port: port)
        }
        
        if opcode == 0xD3 {
            let port = memory.readByte(at: pc)
            return OUTInstruction(port: port)
        }
        
        return nil
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
    
    private func decodeRegisterPair(_ code: UInt8) -> RegisterPairOperand {
        switch code {
        case 0: return .bc
        case 1: return .de
        case 2: return .hl
        case 3: return .sp
        default: return .hl
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
        case .a: return .a
        case .b: return .b
        case .c: return .c
        case .d: return .d
        case .e: return .e
        case .h: return .h
        case .l: return .l
        }
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
}