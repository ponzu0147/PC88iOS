//
//  Z80IXInstructions.swift
//  PC88iOS
//
//  Created on 2025-04-07
//

import Foundation

// MARK: - IXレジスタ関連命令

/// LD IX,nn命令: 即値nnをIXレジスタに読み込む
struct LDIXnnInstruction: Z80Instruction {
    let value: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.ix = value
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 14 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "LD IX,\(String(format: "0x%04X", value))" }
}

/// LD (nn),IX命令: IXレジスタの値をアドレスnnに格納
struct LDnnIXInstruction: Z80Instruction {
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        memory.writeWord(registers.ix, at: address)
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 20 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "LD (\(String(format: "0x%04X", address))),IX" }
}

/// LD IX,(nn)命令: アドレスnnから値を読み込み、IXレジスタに格納
struct LDIXnnAddrInstruction: Z80Instruction {
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.ix = memory.readWord(at: address)
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 20 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "LD IX,(\(String(format: "0x%04X", address)))" }
}

/// LD (IX+d),r命令: レジスタrの値をアドレス(IX+d)に格納
struct LDIXdRInstruction: Z80Instruction {
    let offset: Int8
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // ソースレジスタから値を取得
        switch source {
        case .a:
            value = registers.a
        case .b:
            value = registers.b
        case .c:
            value = registers.c
        case .d:
            value = registers.d
        case .e:
            value = registers.e
        case .h:
            value = registers.h
        case .l:
            value = registers.l
        default:
            return cycles
        }
        
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリに書き込み
        memory.writeByte(value, at: address)
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "LD (IX\(sign)\(offset)),\(source)"
    }
}

/// LD r,(IX+d)命令: アドレス(IX+d)から値を読み込み、レジスタrに格納
struct LDRIXdInstruction: Z80Instruction {
    let destination: RegisterOperand
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        
        // デスティネーションレジスタに値を格納
        switch destination {
        case .a:
            registers.a = value
        case .b:
            registers.b = value
        case .c:
            registers.c = value
        case .d:
            registers.d = value
        case .e:
            registers.e = value
        case .h:
            registers.h = value
        case .l:
            registers.l = value
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "LD \(destination),(IX\(sign)\(offset))"
    }
}

/// LD (IX+d),n命令: 即値nをアドレス(IX+d)に格納
struct LDIXdNInstruction: Z80Instruction {
    let offset: Int8
    let value: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリに書き込み
        memory.writeByte(value, at: address)
        
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "LD (IX\(sign)\(offset)),\(String(format: "0x%02X", value))"
    }
}

/// INC (IX+d)命令: アドレス(IX+d)の値をインクリメント
struct INCIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        
        // インクリメント実行
        let result = value &+ 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: (value & 0x0F) == 0x0F)
        registers.setFlag(Z80Registers.Flags.parity, value: value == 0x7F)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // メモリに書き戻し
        memory.writeByte(result, at: address)
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 23 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "INC (IX\(sign)\(offset))"
    }
}

/// DEC (IX+d)命令: アドレス(IX+d)の値をデクリメント
struct DECIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        
        // デクリメント実行
        let result = value &- 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: (value & 0x0F) == 0)
        registers.setFlag(Z80Registers.Flags.parity, value: value == 0x80)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // メモリに書き戻し
        memory.writeByte(result, at: address)
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 23 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "DEC (IX\(sign)\(offset))"
    }
}

/// ADD IX,rr命令: レジスタペアの値をIXに加算
struct ADDIXrrInstruction: Z80Instruction {
    let operand: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let ix = registers.ix
        var value: UInt16 = 0
        
        // オペランドから値を取得
        switch operand {
        case .registerBC:
            value = registers.bc
        case .registerDE:
            value = registers.de
        case .registerHL:
            value = registers.ix
        case .registerSP:
            value = registers.sp
        default:
            return cycles
        }
        
        // 加算実行
        let result = ix &+ value
        
        // フラグ更新
        let carry = (ix > 0xFFFF - value)
        let halfCarry = ((ix & 0x0FFF) + (value & 0x0FFF)) > 0x0FFF
        
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        
        // 結果を書き戻し
        registers.ix = result
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 15 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "ADD IX,\(operand)" }
}

/// INC IX命令: IXレジスタをインクリメント
struct INCIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.ix = registers.ix &+ 1
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "INC IX" }
}

/// DEC IX命令: IXレジスタをデクリメント
struct DECIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.ix = registers.ix &- 1
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "DEC IX" }
}

/// PUSH IX命令: IXレジスタの値をスタックにプッシュ
struct PUSHIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.sp = registers.sp &- 2
        memory.writeWord(registers.ix, at: registers.sp)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 15 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "PUSH IX" }
}

/// POP IX命令: スタックからIXレジスタにポップ
struct POPIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.ix = memory.readWord(at: registers.sp)
        registers.sp = registers.sp &+ 2
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 14 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "POP IX" }
}

/// JP (IX)命令: IXレジスタの値にジャンプ
struct JPIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.pc = registers.ix
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 8 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "JP (IX)" }
}

/// EX (SP),IX命令: スタックトップとIXレジスタを交換
struct EXSPIXInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let temp = memory.readWord(at: registers.sp)
        memory.writeWord(registers.ix, at: registers.sp)
        registers.ix = temp
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 23 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "EX (SP),IX" }
}

// MARK: - IX+d算術・論理演算命令

/// ADD A,(IX+d)命令: (IX+d)の値をAに加算
struct ADDAIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 加算実行
        let result = a &+ value
        
        // フラグ更新
        let halfCarry = ((a & 0x0F) + (value & 0x0F)) > 0x0F
        let overflow = ((a & 0x80) == (value & 0x80)) && ((result & 0x80) != (a & 0x80))
        
        registers.setFlag(Z80Registers.Flags.carry, value: (a + value) > 0xFF)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "ADD A,(IX\(sign)\(offset))"
    }
}

/// SUB (IX+d)命令: (IX+d)の値をAから減算
struct SUBIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 減算実行
        let result = a &- value
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        let overflow = ((a & 0x80) != (value & 0x80)) && ((result & 0x80) != (a & 0x80))
        
        registers.setFlag(Z80Registers.Flags.carry, value: a < value)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "SUB (IX\(sign)\(offset))"
    }
}

/// AND (IX+d)命令: (IX+d)の値とAの論理積
struct ANDIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 論理積実行
        let result = a & value
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: true)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(result))
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "AND (IX\(sign)\(offset))"
    }
}

/// OR (IX+d)命令: (IX+d)の値とAの論理和
struct ORIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 論理和実行
        let result = a | value
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(result))
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "OR (IX\(sign)\(offset))"
    }
}

/// XOR (IX+d)命令: (IX+d)の値とAの排他的論理和
struct XORIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 排他的論理和実行
        let result = a ^ value
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(result))
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "XOR (IX\(sign)\(offset))"
    }
}

/// CP (IX+d)命令: (IX+d)の値とAを比較
struct CPIXdInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // IX+dのアドレスを計算
        let address = UInt16(Int(registers.ix) + Int(offset))
        
        // メモリから値を読み込み
        let value = memory.readByte(at: address)
        let a = registers.a
        
        // 比較実行
        let result = a &- value
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        let overflow = ((a & 0x80) != (value & 0x80)) && ((result & 0x80) != (a & 0x80))
        
        registers.setFlag(Z80Registers.Flags.carry, value: a < value)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 19 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String {
        let sign = offset >= 0 ? "+" : ""
        return "CP (IX\(sign)\(offset))"
    }
}

// MARK: - 注意

// calculateParity関数はZ80CBInstructions.swiftで定義されているため、ここでは宣言しません
