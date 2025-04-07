//
//  Z80EDInstructions.swift
//  PC88iOS
//
//  Created on 2025-04-07
//

import Foundation

// MARK: - 入出力命令

/// IN r,(C)命令: ポートCからデータを読み込み、レジスタrに格納
struct INrCInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let port = registers.c
        let value = inputOutput.readPort(port)
        
        // フラグ更新
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
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 12 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.IN_R_C }
    var description: String { return "IN \(operand),(C)" }
}

/// OUT (C),r命令: レジスタrの値をポートCに出力
struct OUTCrInstruction: Z80Instruction {
    let operand: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let port = registers.c
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
        default:
            return cycles
        }
        
        // ポートに出力
        inputOutput.writePort(port, value: value)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 12 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.OUT_C_R }
    var description: String { return "OUT (C),\(operand)" }
}

// MARK: - 16ビット算術命令

/// SBC HL,rr命令: HLからレジスタペアとキャリーフラグを引く
struct SBCHLrrInstruction: Z80Instruction {
    let operand: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let hl = registers.hl
        var value: UInt16 = 0
        
        // オペランドから値を取得
        switch operand {
        case .bc:
            value = registers.bc
        case .de:
            value = registers.de
        case .hl:
            value = registers.hl
        case .sp:
            value = registers.sp
        default:
            return cycles
        }
        
        // キャリーフラグを取得
        let carry: UInt16 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        // 減算実行
        let result = hl &- value &- carry
        
        // フラグ更新
        let halfCarry = ((hl & 0x0FFF) < ((value & 0x0FFF) + carry))
        let overflow = ((hl & 0x8000) != (value & 0x8000)) && ((result & 0x8000) != (hl & 0x8000))
        
        registers.setFlag(Z80Registers.Flags.carry, value: hl < (value + carry))
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x8000) != 0)
        
        // 結果を書き戻し
        registers.hl = result
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 15 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.SBC_HL_RR }
    var description: String { return "SBC HL,\(operand)" }
}

/// ADC HL,rr命令: HLにレジスタペアとキャリーフラグを加える
struct ADCHLrrInstruction: Z80Instruction {
    let operand: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let hl = registers.hl
        var value: UInt16 = 0
        
        // オペランドから値を取得
        switch operand {
        case .bc:
            value = registers.bc
        case .de:
            value = registers.de
        case .hl:
            value = registers.hl
        case .sp:
            value = registers.sp
        default:
            return cycles
        }
        
        // キャリーフラグを取得
        let carry: UInt16 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        // 加算実行
        let result = hl &+ value &+ carry
        
        // フラグ更新
        let halfCarry = ((hl & 0x0FFF) + (value & 0x0FFF) + carry) > 0x0FFF
        let overflow = ((hl & 0x8000) == (value & 0x8000)) && ((result & 0x8000) != (hl & 0x8000))
        
        registers.setFlag(Z80Registers.Flags.carry, value: (hl + value + carry) > 0xFFFF)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x8000) != 0)
        
        // 結果を書き戻し
        registers.hl = result
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 15 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.ADC_HL_RR }
    var description: String { return "ADC HL,\(operand)" }
}

/// LD (nn),rr命令: レジスタペアの値をアドレスnnに格納
struct LDnnrrInstruction: Z80Instruction {
    let address: UInt16
    let operand: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        var value: UInt16 = 0
        
        // オペランドから値を取得
        switch operand {
        case .bc:
            value = registers.bc
        case .de:
            value = registers.de
        case .hl:
            value = registers.hl
        case .sp:
            value = registers.sp
        default:
            return cycles
        }
        
        // メモリに書き込み
        memory.writeWord(value, at: address)
        
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 20 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LD_NN_RR }
    var description: String { return "LD (\(String(format: "0x%04X", address))),\(operand)" }
}

/// LD rr,(nn)命令: アドレスnnから値を読み込み、レジスタペアに格納
struct LDrrnnInstruction: Z80Instruction {
    let operand: RegisterPairOperand
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // メモリから読み込み
        let value = memory.readWord(at: address)
        
        // 結果を書き戻し
        switch operand {
        case .bc:
            registers.bc = value
        case .de:
            registers.de = value
        case .hl:
            registers.hl = value
        case .sp:
            registers.sp = value
        default:
            break
        }
        
        return cycles
    }
    
    var size: UInt16 { return 4 }
    var cycles: Int { return 20 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LD_RR_NN }
    var description: String { return "LD \(operand),(\(String(format: "0x%04X", address)))" }
}

// MARK: - ブロック転送命令

/// LDI命令: (HL)から(DE)にバイトを転送し、HLとDEをインクリメント、BCをデクリメント
struct LDIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        
        // (DE)に値を書き込み
        memory.writeByte(value, at: registers.de)
        
        // レジスタを更新
        registers.hl = registers.hl &+ 1
        registers.de = registers.de &+ 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDI }
    var description: String { return "LDI" }
}

/// LDIR命令: LDIを繰り返し、BCが0になるまで実行
struct LDIRInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        
        // (DE)に値を書き込み
        memory.writeByte(value, at: registers.de)
        
        // レジスタを更新
        registers.hl = registers.hl &+ 1
        registers.de = registers.de &+ 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: false)
        
        // BCが0でない場合、PCを戻して再実行
        if registers.bc != 0 {
            registers.pc = registers.pc &- size
            return cycles + 5 // 追加サイクル
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDIR }
    var description: String { return "LDIR" }
}

/// LDD命令: (HL)から(DE)にバイトを転送し、HLとDEをデクリメント、BCをデクリメント
struct LDDInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        
        // (DE)に値を書き込み
        memory.writeByte(value, at: registers.de)
        
        // レジスタを更新
        registers.hl = registers.hl &- 1
        registers.de = registers.de &- 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDD }
    var description: String { return "LDD" }
}

/// LDDR命令: LDDを繰り返し、BCが0になるまで実行
struct LDDRInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        
        // (DE)に値を書き込み
        memory.writeByte(value, at: registers.de)
        
        // レジスタを更新
        registers.hl = registers.hl &- 1
        registers.de = registers.de &- 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: false)
        
        // BCが0でない場合、PCを戻して再実行
        if registers.bc != 0 {
            registers.pc = registers.pc &- size
            return cycles + 5 // 追加サイクル
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDDR }
    var description: String { return "LDDR" }
}

// MARK: - ブロック比較命令

/// CPI命令: Aと(HL)を比較し、HLをインクリメント、BCをデクリメント
struct CPIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        let a = registers.a
        
        // 比較実行
        let result = a &- value
        
        // レジスタを更新
        registers.hl = registers.hl &+ 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CPI }
    var description: String { return "CPI" }
}

/// CPIR命令: CPIを繰り返し、BCが0になるか、Aと(HL)が一致するまで実行
struct CPIRInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        let a = registers.a
        
        // 比較実行
        let result = a &- value
        
        // レジスタを更新
        registers.hl = registers.hl &+ 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        let isZero = result == 0
        
        registers.setFlag(Z80Registers.Flags.zero, value: isZero)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        // BCが0でなく、Aと(HL)が一致しない場合、PCを戻して再実行
        if registers.bc != 0 && !isZero {
            registers.pc = registers.pc &- size
            return cycles + 5 // 追加サイクル
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CPIR }
    var description: String { return "CPIR" }
}

/// CPD命令: Aと(HL)を比較し、HLをデクリメント、BCをデクリメント
struct CPDInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        let a = registers.a
        
        // 比較実行
        let result = a &- value
        
        // レジスタを更新
        registers.hl = registers.hl &- 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CPD }
    var description: String { return "CPD" }
}

/// CPDR命令: CPDを繰り返し、BCが0になるか、Aと(HL)が一致するまで実行
struct CPDRInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // (HL)から値を読み込み
        let value = memory.readByte(at: registers.hl)
        let a = registers.a
        
        // 比較実行
        let result = a &- value
        
        // レジスタを更新
        registers.hl = registers.hl &- 1
        registers.bc = registers.bc &- 1
        
        // フラグ更新
        let halfCarry = (a & 0x0F) < (value & 0x0F)
        let isZero = result == 0
        
        registers.setFlag(Z80Registers.Flags.zero, value: isZero)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: registers.bc != 0)
        
        // BCが0でなく、Aと(HL)が一致しない場合、PCを戻して再実行
        if registers.bc != 0 && !isZero {
            registers.pc = registers.pc &- size
            return cycles + 5 // 追加サイクル
        }
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CPDR }
    var description: String { return "CPDR" }
}

// MARK: - 特殊命令

/// NEG命令: Aの2の補数を取る（A = 0 - A）
struct NEGInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let a = registers.a
        let result: UInt8 = 0 &- a
        
        // フラグ更新
        registers.setFlag(Z80Registers.Flags.carry, value: a != 0)
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: (a & 0x0F) > 0)
        registers.setFlag(Z80Registers.Flags.parity, value: a == 0x80)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        
        // 結果を書き戻し
        registers.a = result
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 8 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NEG }
    var description: String { return "NEG" }
}

/// RETN命令: 割り込みから復帰
struct RETNInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // スタックからアドレスを取得
        let address = memory.readWord(at: registers.sp)
        registers.sp = registers.sp &+ 2
        
        // IFF1をIFF2にコピー
        registers.iff1 = registers.iff2
        
        // PCを設定
        registers.pc = address
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 14 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RETN }
    var description: String { return "RETN" }
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
/// RETI命令: 割り込みから復帰
struct RETIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // スタックからアドレスを取得
        let address = memory.readWord(at: registers.sp)
        registers.sp = registers.sp &+ 2
        
        // PCを設定
        registers.pc = address
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 14 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RETI }
    var description: String { return "RETI" }
}

/// IM命令: 割り込みモードを設定
struct IMInstruction: Z80Instruction {
    let mode: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // 割り込みモードを設定
        registers.interruptMode = mode
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 8 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.IM }
    var description: String { return "IM \(mode)" }
}

// MARK: - UInt8拡張

extension UInt8 {
    /// パリティチェック（1ビットの数が偶数ならtrue）
    var parity: Bool {
        var count = 0
        var value = self
        
        for _ in 0..<8 {
            if value & 1 == 1 {
                count += 1
            }
            value >>= 1
        }
        
        return count % 2 == 0
    }
}
