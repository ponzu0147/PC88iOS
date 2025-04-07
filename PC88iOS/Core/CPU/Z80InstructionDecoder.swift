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
        _ = memory.readByte(at: nextPC)
        
        // TODO: 実際のCB命令のデコード処理を実装
        // 現時点では未実装のため、nil（不明な命令）を返す
        return nil
    }
    
    // EDプレフィックス命令（拡張命令）
    private func decodeEDPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        _ = memory.readByte(at: nextPC)
        
        // TODO: 実際のED命令のデコード処理を実装
        // 現時点では未実装のため、nil（不明な命令）を返す
        return nil
    }
    
    // IXプレフィックス命令
    private func decodeIXPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        _ = memory.readByte(at: nextPC)
        
        // TODO: 実際のIX命令のデコード処理を実装
        // 現時点では未実装のため、nil（不明な命令）を返す
        return nil
    }
    
    // IYプレフィックス命令
    private func decodeIYPrefixedInstruction(memory: MemoryAccessing, pc: UInt16) -> Z80Instruction? {
        // 次のオペコードを取得
        let nextPC = pc + 1
        _ = memory.readByte(at: nextPC)
        
        // TODO: 実際のIY命令のデコード処理を実装
        // 現時点では未実装のため、nil（不明な命令）を返す
        return nil
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
}
