//
//
//

import Foundation

class Z80InstructionDecoder {
    
    func decode(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        if let instruction = decodeBasicInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        }
        
        if let instruction = decodeArithmeticInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeLogicalInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeControlInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeLoadInstruction(opcode, memory: memory, pc: pc) {
            return instruction
        } else {
            return UnimplementedInstruction(opcode: opcode)
        }
    }
    
    
    // MARK: - Basic Instructions
    
    private func decodeBasicInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 命令をカテゴリごとに分割して処理
        if let instruction = decodeBasicGroup1(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup2(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup3(opcode, memory: memory, pc: pc) {
            return instruction
        }
        
        return nil
    }
    
    private func decodeBasicGroup1(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 命令をさらに小さなグループに分割
        if let instruction = decodeBasicGroup1A(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup1B(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup1C(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup1D(opcode, memory: memory, pc: pc) {
            return instruction
        }
        
        return nil
    }
    
    // 基本命令グループ2: 追加のグループ
    private func decodeBasicGroup2(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // CBプレフィックス命令（ビット操作、シフト、ローテーション）
        if opcode == 0xCB {
            return decodeCBPrefixedInstruction(memory: memory, pc: pc)
        }
        
        // EDプレフィックス命令（拡張命令）
        if opcode == 0xED {
            return decodeEDPrefixedInstruction(memory: memory, pc: pc)
        }
        
        return nil
    }
    
    // 基本命令グループ3: 追加のグループ
    private func decodeBasicGroup3(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 特殊命令やその他の命令をデコード
        switch opcode {
        case 0xDD: // IXプレフィックス
            return decodeIXPrefixedInstruction(memory: memory, pc: pc)
        case 0xFD: // IYプレフィックス
            return decodeIYPrefixedInstruction(memory: memory, pc: pc)
        default:
            return nil
        }
    }
    
    // CBプレフィックス命令（ビット操作、シフト、ローテーション）
    private func decodeCBPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        let cbOpcode = memory.readByte(at: nextPC)
        
        // CBプレフィックス命令をカテゴリごとに分類して処理
        let highNibble = cbOpcode >> 6
        let lowNibble = cbOpcode & 0x07
        let middleNibble = (cbOpcode >> 3) & 0x07
        
        // ターゲットレジスタの取得
        let register = decodeRegister8(lowNibble)
        let operand = convertToRegisterOperand(register)
        
        switch highNibble {
        case 0: // ローテーション命令 (0x00-0x3F)
            return decodeRotationInstruction(cbOpcode, operand: operand)
        case 1: // BIT命令 (0x40-0x7F)
            return decodeBITInstruction(middleNibble, operand: operand)
        case 2: // RES命令 (0x80-0xBF)
            return decodeRESInstruction(middleNibble, operand: operand)
        case 3: // SET命令 (0xC0-0xFF)
            return decodeSETInstruction(middleNibble, operand: operand)
        default:
            return nil
        }
    }
    
    // EDプレフィックス命令（拡張命令）
    private func decodeEDPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        let edOpcode = memory.readByte(at: nextPC)
        
        // ED命令のデコード
        switch edOpcode {
        // ブロック転送命令
        case 0xA0: return LDIInstruction()
        case 0xB0: return LDIRInstruction()
        case 0xA8: return LDDInstruction()
        case 0xB8: return LDDRInstruction()
            
        // ブロック比較命令
        case 0xA1: return CPIInstruction()
        case 0xB1: return CPIRInstruction()
        case 0xA9: return CPDInstruction()
        case 0xB9: return CPDRInstruction()
            
        // 入出力命令
        case 0x40: return INrCInstruction(operand: .b)
        case 0x48: return INrCInstruction(operand: .c)
        case 0x50: return INrCInstruction(operand: .d)
        case 0x58: return INrCInstruction(operand: .e)
        case 0x60: return INrCInstruction(operand: .h)
        case 0x68: return INrCInstruction(operand: .l)
        case 0x78: return INrCInstruction(operand: .a)
            
        case 0x41: return OUTCrInstruction(operand: .b)
        case 0x49: return OUTCrInstruction(operand: .c)
        case 0x51: return OUTCrInstruction(operand: .d)
        case 0x59: return OUTCrInstruction(operand: .e)
        case 0x61: return OUTCrInstruction(operand: .h)
        case 0x69: return OUTCrInstruction(operand: .l)
        case 0x79: return OUTCrInstruction(operand: .a)
            
        // 16ビット算術命令
        case 0x42: return SBCHLrrInstruction(operand: RegisterPairOperand.bc)
        case 0x52: return SBCHLrrInstruction(operand: RegisterPairOperand.de)
        case 0x62: return SBCHLrrInstruction(operand: RegisterPairOperand.hl)
        case 0x72: return SBCHLrrInstruction(operand: RegisterPairOperand.sp)
            
        case 0x4A: return ADCHLrrInstruction(operand: RegisterPairOperand.bc)
        case 0x5A: return ADCHLrrInstruction(operand: RegisterPairOperand.de)
        case 0x6A: return ADCHLrrInstruction(operand: RegisterPairOperand.hl)
        case 0x7A: return ADCHLrrInstruction(operand: RegisterPairOperand.sp)
            
        // メモリ操作命令
        case 0x43: // LD (nn),BC
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDnnrrInstruction(address: address, operand: RegisterPairOperand.bc)
            
        case 0x53: // LD (nn),DE
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDnnrrInstruction(address: address, operand: RegisterPairOperand.de)
            
        case 0x63: // LD (nn),HL
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDnnrrInstruction(address: address, operand: RegisterPairOperand.hl)
            
        case 0x73: // LD (nn),SP
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDnnrrInstruction(address: address, operand: RegisterPairOperand.sp)
            
        case 0x4B: // LD BC,(nn)
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDrrnnInstruction(operand: RegisterPairOperand.bc, address: address)
            
        case 0x5B: // LD DE,(nn)
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDrrnnInstruction(operand: RegisterPairOperand.de, address: address)
            
        case 0x6B: // LD HL,(nn)
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDrrnnInstruction(operand: RegisterPairOperand.hl, address: address)
            
        case 0x7B: // LD SP,(nn)
            let addressLow = memory.readByte(at: nextPC + 1)
            let addressHigh = memory.readByte(at: nextPC + 2)
            let address = UInt16(addressHigh) << 8 | UInt16(addressLow)
            return LDrrnnInstruction(operand: RegisterPairOperand.sp, address: address)
            
        // 特殊命令
        case 0x44, 0x4C, 0x54, 0x5C, 0x64, 0x6C, 0x74, 0x7C: return NEGInstruction()
        case 0x45, 0x4D, 0x55, 0x5D, 0x65, 0x6D, 0x75, 0x7D: return RETNInstruction()
        case 0x4E, 0x6E: return IMInstruction(mode: 0)
        case 0x56, 0x76: return IMInstruction(mode: 1)
        case 0x5E, 0x7E: return IMInstruction(mode: 2)
        case 0x57, 0x5F, 0x67, 0x6F, 0x77, 0x7F: return UnimplementedInstruction(opcode: edOpcode) // LD A,I/R等は実装予定
            
        default:
            return UnimplementedInstruction(opcode: edOpcode)
        }
    }
    
    // IXプレフィックス命令
    private func decodeIXPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        let ddOpcode = memory.readByte(at: nextPC)
        
        // IX命令のデコード
        switch ddOpcode {
        // IXレジスタ関連命令
        case 0x21: // LD IX,nn
            let lowByte = memory.readByte(at: nextPC + 1)
            let highByte = memory.readByte(at: nextPC + 2)
            let value = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDIXnnInstruction(value: value)
            
        case 0x22: // LD (nn),IX
            let lowByte = memory.readByte(at: nextPC + 1)
            let highByte = memory.readByte(at: nextPC + 2)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDnnIXInstruction(address: address)
            
        case 0x2A: // LD IX,(nn)
            let lowByte = memory.readByte(at: nextPC + 1)
            let highByte = memory.readByte(at: nextPC + 2)
            let address = UInt16(highByte) << 8 | UInt16(lowByte)
            return LDIXnnAddrInstruction(address: address)
            
        case 0x36: // LD (IX+d),n
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            let value = memory.readByte(at: nextPC + 2)
            return LDIXdNInstruction(offset: offset, value: value)
            
        case 0x70: // LD (IX+d),B
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .b)
            
        case 0x71: // LD (IX+d),C
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .c)
            
        case 0x72: // LD (IX+d),D
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .d)
            
        case 0x73: // LD (IX+d),E
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .e)
            
        case 0x74: // LD (IX+d),H
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .h)
            
        case 0x75: // LD (IX+d),L
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .l)
            
        case 0x77: // LD (IX+d),A
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDIXdRInstruction(offset: offset, source: .a)
            
        case 0x46: // LD B,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .b, offset: offset)
            
        case 0x4E: // LD C,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .c, offset: offset)
            
        case 0x56: // LD D,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .d, offset: offset)
            
        case 0x5E: // LD E,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .e, offset: offset)
            
        case 0x66: // LD H,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .h, offset: offset)
            
        case 0x6E: // LD L,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .l, offset: offset)
            
        case 0x7E: // LD A,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return LDRIXdInstruction(destination: .a, offset: offset)
            
        // IXレジスタの算術命令
        case 0x09: // ADD IX,BC
            return ADDIXrrInstruction(operand: .bc)
            
        case 0x19: // ADD IX,DE
            return ADDIXrrInstruction(operand: .de)
            
        case 0x29: // ADD IX,IX
            return ADDIXrrInstruction(operand: .ix)
            
        case 0x39: // ADD IX,SP
            return ADDIXrrInstruction(operand: .sp)
            
        case 0x23: // INC IX
            return INCIXInstruction()
            
        case 0x2B: // DEC IX
            return DECIXInstruction()
            
        case 0x34: // INC (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return INCIXdInstruction(offset: offset)
            
        case 0x35: // DEC (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return DECIXdInstruction(offset: offset)
            
        // IXレジスタのスタック操作
        case 0xE5: // PUSH IX
            return PUSHIXInstruction()
            
        case 0xE1: // POP IX
            return POPIXInstruction()
            
        case 0xE3: // EX (SP),IX
            return EXSPIXInstruction()
            
        case 0xE9: // JP (IX)
            return JPIXInstruction()
            
        // IX+dを使用した算術・論理命令
        case 0x86: // ADD A,(IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return ADDAIXdInstruction(offset: offset)
            
        case 0x96: // SUB (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return SUBIXdInstruction(offset: offset)
            
        case 0xA6: // AND (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return ANDIXdInstruction(offset: offset)
            
        case 0xB6: // OR (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return ORIXdInstruction(offset: offset)
            
        case 0xAE: // XOR (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return XORIXdInstruction(offset: offset)
            
        case 0xBE: // CP (IX+d)
            let offset = Int8(bitPattern: memory.readByte(at: nextPC + 1))
            return CPIXdInstruction(offset: offset)
            
        default:
            return UnimplementedInstruction(opcode: ddOpcode)
        }
    }
    
    // IYプレフィックス命令
    private func decodeIYPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
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
    
    // 基本命令グループ1A: 0x00-0x2F
    private func decodeBasicGroup1A(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if let instruction = decodeBasicGroup1A1(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup1A2(opcode, memory: memory, pc: pc) {
            return instruction
        }
        return nil
    }
    
    // 基本命令グループ1A1: 0x00-0x17
    private func decodeBasicGroup1A1(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0x00: // NOP
            return NOPInstruction()
        case 0x01: // LD BC,nn
            return decodeLDRegPairImm(.registerBC, memory: memory, pc: pc)
        case 0x02: // LD (BC),A
            return LDMemRegInstruction(address: .registerBC, source: .a)
        case 0x03: // INC BC
            return INCRegPairInstruction(register: .registerBC)
        case 0x04: // INC B
            return INCRegInstruction(register: .b)
        case 0x05: // DEC B
            return DECRegInstruction(register: .b)
        case 0x06: // LD B,n
            return decodeLDRegImm(.b, memory: memory, pc: pc)
        case 0x07: // RLCA
            return RLCAInstruction()
        case 0x08: // EX AF,AF'
            return EXAFInstruction()
        case 0x0A: // LD A,(BC)
            return LDRegMemInstruction(destination: .a, address: .registerBC)
        case 0x0B: // DEC BC
            return DECRegPairInstruction(register: RegisterPairOperand.bc)
        case 0x0C: // INC C
            return INCRegInstruction(register: .c)
        case 0x0D: // DEC C
            return DECRegInstruction(register: .c)
        case 0x0E: // LD C,n
            return decodeLDRegImm(.c, memory: memory, pc: pc)
        case 0x0F: // RRCA
            return RRCAInstruction()
        case 0x10: // DJNZ
            return decodeDJNZ(memory: memory, pc: pc)
        case 0x11: // LD DE,nn
            return decodeLDRegPairImm(.registerDE, memory: memory, pc: pc)
        case 0x12: // LD (DE),A
            return LDMemRegInstruction(address: .registerDE, source: .a)
        case 0x13: // INC DE
            return INCRegPairInstruction(register: .registerDE)
        case 0x14: // INC D
            return INCRegInstruction(register: .d)
        case 0x15: // DEC D
            return DECRegInstruction(register: .d)
        case 0x16: // LD D,n
            return decodeLDRegImm(.d, memory: memory, pc: pc)
        case 0x18: // JR n
            return decodeJR(.none, memory: memory, pc: pc)
        default:
            return nil
        }
    }
    
    // 基本命令グループ1A2: 0x1A-0x2F
    private func decodeBasicGroup1A2(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0x1A: // LD A,(DE)
            return LDRegMemInstruction(destination: .a, address: .registerDE)
        case 0x1C: // INC E
            return INCRegInstruction(register: .e)
        case 0x1D: // DEC E
            return DECRegInstruction(register: .e)
        case 0x1E: // LD E,n
            return decodeLDRegImm(.e, memory: memory, pc: pc)
        case 0x20: // JR NZ,n
            return decodeJR(.notZero, memory: memory, pc: pc)
        case 0x21: // LD HL,nn
            return decodeLDRegPairImm(.registerHL, memory: memory, pc: pc)
        case 0x22: // LD (nn),HL
            return decodeLDMemAddrRegPair(memory: memory, pc: pc)
        case 0x23: // INC HL
            return INCRegPairInstruction(register: .registerHL)
        case 0x24: // INC H
            return INCRegInstruction(register: .h)
        case 0x25: // DEC H
            return DECRegInstruction(register: .h)
        case 0x26: // LD H,n
            return decodeLDRegImm(.h, memory: memory, pc: pc)
        case 0x28: // JR Z,n
            return decodeJR(.zero, memory: memory, pc: pc)
        case 0x2A: // LD HL,(nn)
            return decodeLDRegPairMemAddr(memory: memory, pc: pc)
        case 0x2C: // INC L
            return INCRegInstruction(register: .l)
        case 0x2D: // DEC L
            return DECRegInstruction(register: .l)
        case 0x2E: // LD L,n
            return decodeLDRegImm(.l, memory: memory, pc: pc)
        case 0x2F: // CPL
            return CPLInstruction()
        default:
            return nil
        }
    }
    
    // 基本命令グループ1B: 0x30-0x76
    private func decodeBasicGroup1B(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0x30: // JR NC,n
            return decodeJR(.notCarry, memory: memory, pc: pc)
        case 0x31: // LD SP,nn
            return decodeLDRegPairImm(.registerSP, memory: memory, pc: pc)
        case 0x32: // LD (nn),A
            return decodeLDDirectMemReg(memory: memory, pc: pc)
        case 0x33: // INC SP
            return INCRegPairInstruction(register: .registerSP)
        case 0x36: // LD (HL),n
            return decodeLDMemImm(memory: memory, pc: pc)
        case 0x38: // JR C,n
            return decodeJR(.carry, memory: memory, pc: pc)
        case 0x39: // ADD HL,SP
            return ADDHLInstruction(source: .registerSP)
        case 0x3A: // LD A,(nn)
            return decodeLDRegMemAddr(memory: memory, pc: pc)
        case 0x3B: // DEC SP
            return DECRegPairInstruction(register: .registerSP)
        case 0x76: // HALT
            return HALTInstruction()
        default:
            return nil
        }
    }
    
    // 基本命令グループ1C: 0x98-0xDA
    private func decodeBasicGroup1C(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        if let instruction = decodeBasicGroup1C1(opcode, memory: memory, pc: pc) {
            return instruction
        } else if let instruction = decodeBasicGroup1C2(opcode, memory: memory, pc: pc) {
            return instruction
        }
        return nil
    }
    
    // 基本命令グループ1C1: 0x98-0xCD
    private func decodeBasicGroup1C1(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0x98: // SBC A,B
            return SBCInstruction(source: .b)
        case 0xC0: // RET NZ
            return RETInstruction(condition: .notZero)
        case 0xC1: // POP BC
            return POPInstruction(register: .registerBC)
        case 0xC2: // JP NZ,nn
            return decodeJP(.notZero, memory: memory, pc: pc)
        case 0xC3: // JP nn
            return decodeJP(.none, memory: memory, pc: pc)
        case 0xC4: // CALL NZ,nn
            return decodeCALL(.notZero, memory: memory, pc: pc)
        case 0xC5: // PUSH BC
            return PUSHInstruction(register: .registerBC)
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
        default:
            return nil
        }
    }
    
    // 基本命令グループ1C2: 0xD0-0xDA
    private func decodeBasicGroup1C2(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0xD0: // RET NC
            return RETInstruction(condition: .notCarry)
        case 0xD1: // POP DE
            return POPInstruction(register: .registerDE)
        case 0xD2: // JP NC,nn
            return decodeJP(.notCarry, memory: memory, pc: pc)
        case 0xD3: // OUT (n), A
            return decodeOUT(memory: memory, pc: pc)
        case 0xD4: // CALL NC,nn
            return decodeCALL(.notCarry, memory: memory, pc: pc)
        case 0xD5: // PUSH DE
            return PUSHInstruction(register: .registerDE)
        case 0xD8: // RET C
            return RETInstruction(condition: .carry)
        case 0xDA: // JP C,nn
            return decodeJP(.carry, memory: memory, pc: pc)
        default:
            return nil
        }
    }
    
    // 基本命令グループ1D: 0xDB-0xFF
    private func decodeBasicGroup1D(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        switch opcode {
        case 0xDB: // IN A,(n)
            return decodeIN(memory: memory, pc: pc)
        case 0xDC: // CALL C,nn
            return decodeCALL(.carry, memory: memory, pc: pc)
        case 0xE1: // POP HL
            return POPInstruction(register: .registerHL)
        case 0xE5: // PUSH HL
            return PUSHInstruction(register: .registerHL)
        case 0xF1: // POP AF
            return POPInstruction(register: .registerAF)
        case 0xF3: // DI
            return DISInstruction()
        case 0xF5: // PUSH AF
            return PUSHInstruction(register: .registerAF)
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
        return LDDirectMemRegInstruction(address: address, source: .a)
    }
    
    private func decodeLDRegMemAddr(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDRegMemAddrInstruction(destination: .a, address: address)
    }
    
    private func decodeLDRegImm(_ register: RegisterOperand, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let value = memory.readByte(at: pc)
        return LDRegImmInstruction(destination: register, value: value)
    }
    
    private func decodeLDMemAddrRegPair(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDMemAddrRegPairInstruction(address: address, source: .registerHL)
    }
    
    private func decodeLDRegPairMemAddr(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let lowByte = memory.readByte(at: pc)
        let highByte = memory.readByte(at: pc &+ 1)
        let address = UInt16(highByte) << 8 | UInt16(lowByte)
        return LDRegPairMemAddrInstruction(destination: .registerHL, address: address)
    }
    
    private func decodeLDMemImm(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction {
        let value = memory.readByte(at: pc)
        return LDMemImmInstruction(address: .registerHL, value: value)
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
    
    
    private func decodeArithmeticInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
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
    
    
    private func decodeLogicalInstruction(_ opcode: UInt8, memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
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
            return LDRegMemInstruction(destination: convertToRegisterOperand(reg), address: .registerHL)
        }
        
        if (opcode & 0xF8) == 0x70 {
            let reg = decodeRegister8(opcode & 0x07)
            return LDMemRegInstruction(address: .registerHL, source: convertToRegisterOperand(reg))
        }
        
        if opcode == 0x31 {
            return decodeLDRegPairImm(.registerSP, memory: memory, pc: pc)
        }
        
        if opcode == 0x01 {
            return decodeLDRegPairImm(.registerBC, memory: memory, pc: pc)
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
        case .f: return .f
        }
    }
    
    // CBプレフィックス命令のデコード処理用ヘルパーメソッド
    
    // ローテーション命令のデコード
    private func decodeRotationInstruction(_ opcode: UInt8, operand: RegisterOperand) -> Z80Instruction? {
        let operation = (opcode >> 3) & 0x07
        
        switch operation {
        case 0: // RLC r
            return RLCInstruction(operand: operand)
        case 1: // RRC r
            return RRCInstruction(operand: operand)
        case 2: // RL r
            return RLInstruction(operand: operand)
        case 3: // RR r
            return RRInstruction(operand: operand)
        case 4: // SLA r
            return SLAInstruction(operand: operand)
        case 5: // SRA r
            return SRAInstruction(operand: operand)
        case 6: // SWAP r (Z80ではSLL r、ただし非公式命令)
            return SLLInstruction(operand: operand)
        case 7: // SRL r
            return SRLInstruction(operand: operand)
        default:
            return nil
        }
    }
    
    // BIT命令のデコード
    private func decodeBITInstruction(_ bit: UInt8, operand: RegisterOperand) -> Z80Instruction? {
        return BITInstruction(bit: bit, operand: operand)
    }
    
    // RES命令のデコード
    private func decodeRESInstruction(_ bit: UInt8, operand: RegisterOperand) -> Z80Instruction? {
        return RESInstruction(bit: bit, operand: operand)
    }
    
    // SET命令のデコード
    private func decodeSETInstruction(_ bit: UInt8, operand: RegisterOperand) -> Z80Instruction? {
        return SETInstruction(bit: bit, operand: operand)
    }
}










