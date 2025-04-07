//
//  Z80CBInstructions.swift
//  PC88iOS
//
//  Created on 2025-04-07
//

import Foundation

// MARK: - ローテーション命令

/// RLC命令: レジスタを左に回転し、ビット7をキャリーフラグとビット0にコピー
struct RLCInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 左ローテーション実行
        let carry = (value & 0x80) != 0
        value = (value << 1) | (carry ? 1 : 0)
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.RLC_HL : Z80InstructionCycles.RLC_R }
    var description: String { return "RLC \(operand)" }
}

/// RRC命令: レジスタを右に回転し、ビット0をキャリーフラグとビット7にコピー
struct RRCInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 右ローテーション実行
        let carry = (value & 0x01) != 0
        value = (value >> 1) | (carry ? 0x80 : 0)
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.RRC_HL : Z80InstructionCycles.RRC_R }
    var description: String { return "RRC \(operand)" }
}

/// RL命令: レジスタを左に回転し、キャリーフラグをビット0に入れ、ビット7をキャリーフラグに設定
struct RLInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 左ローテーション実行（キャリー経由）
        let oldCarry = registers.getFlag(Z80Registers.Flags.carry)
        let newCarry = (value & 0x80) != 0
        value = (value << 1) | (oldCarry ? 1 : 0)
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: newCarry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.RL_HL : Z80InstructionCycles.RL_R }
    var description: String { return "RL \(operand)" }
}

/// RR命令: レジスタを右に回転し、キャリーフラグをビット7に入れ、ビット0をキャリーフラグに設定
struct RRInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 右ローテーション実行（キャリー経由）
        let oldCarry = registers.getFlag(Z80Registers.Flags.carry)
        let newCarry = (value & 0x01) != 0
        value = (value >> 1) | (oldCarry ? 0x80 : 0)
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: newCarry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.RR_HL : Z80InstructionCycles.RR_R }
    var description: String { return "RR \(operand)" }
}

/// SLA命令: レジスタを左に算術シフト（ビット0に0を入れ、ビット7をキャリーフラグに設定）
struct SLAInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 左シフト実行
        let carry = (value & 0x80) != 0
        value = value << 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.SLA_HL : Z80InstructionCycles.SLA_R }
    var description: String { return "SLA \(operand)" }
}

/// SRA命令: レジスタを右に算術シフト（ビット7を保持し、ビット0をキャリーフラグに設定）
struct SRAInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 右算術シフト実行
        let carry = (value & 0x01) != 0
        let msb = value & 0x80
        value = (value >> 1) | msb
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.SRA_HL : Z80InstructionCycles.SRA_R }
    var description: String { return "SRA \(operand)" }
}

/// SLL命令: レジスタを左に論理シフト（ビット0に1を入れ、ビット7をキャリーフラグに設定）- 非公式命令
struct SLLInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 左シフト実行（ビット0に1を設定）
        let carry = (value & 0x80) != 0
        value = (value << 1) | 0x01
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.SLL_HL : Z80InstructionCycles.SLL_R }
    var description: String { return "SLL \(operand)" }
}

/// SRL命令: レジスタを右に論理シフト（ビット7に0を入れ、ビット0をキャリーフラグに設定）
struct SRLInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // 右論理シフト実行
        let carry = (value & 0x01) != 0
        value = value >> 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: calculateParity(value))
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.SRL_HL : Z80InstructionCycles.SRL_R }
    var description: String { return "SRL \(operand)" }
}

// MARK: - ビット操作命令

/// BIT命令: レジスタの指定ビットをテスト
struct BITInstruction: Z80Instruction {
    let bit: UInt8
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // ビットテスト実行
        let mask = UInt8(1 << Int(bit))
        let isZero = (value & mask) == 0
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.zero, value: isZero)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: true)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 12 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.BIT_B_HL : Z80InstructionCycles.BIT_B_R }
    var description: String { return "BIT \(bit),\(operand)" }
}

/// SET命令: レジスタの指定ビットを1に設定
struct SETInstruction: Z80Instruction {
    let bit: UInt8
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // ビットセット実行
        let mask = UInt8(1 << Int(bit))
        value |= mask
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.SET_B_HL : Z80InstructionCycles.SET_B_R }
    var description: String { return "SET \(bit),\(operand)" }
}

/// RES命令: レジスタの指定ビットを0に設定
struct RESInstruction: Z80Instruction {
    let bit: UInt8
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt8 = 0
        
        // オペランドから値を取得
        switch operand {
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
        case .memory:
            let address = registers.hl
            value = memory.readByte(at: address)
        default:
            return cycles
        }
        
        // ビットリセット実行
        let mask = ~UInt8(1 << Int(bit))
        value &= mask
        
        // 結果を書き戻し
        switch operand {
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
        case .memory:
            let address = registers.hl
            memory.writeByte(value, at: address)
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return operand == .memory ? 15 : 8 }
    var cycleInfo: InstructionCycles { return operand == .memory ? Z80InstructionCycles.RES_B_HL : Z80InstructionCycles.RES_B_R }
    var description: String { return "RES \(bit),\(operand)" }
}

// MARK: - パリティチェック関数

/// パリティチェック（1ビットの数が偶数ならtrue）
func calculateParity(_ value: UInt8) -> Bool {
    var count = 0
    var tempValue = value
    
    for _ in 0..<8 {
        if tempValue & 1 == 1 {
            count += 1
        }
        tempValue >>= 1
    }
    
    return count % 2 == 0
}
