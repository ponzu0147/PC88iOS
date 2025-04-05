//
//
//

import Foundation
import PC88iOS

struct RLCAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let carry = (registers.regA & 0x80) != 0
        registers.regA = (registers.regA << 1) | (carry ? 1 : 0)
        
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RLCA }
    var description: String { return "RLCA" }
}

struct RRCAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let carry = (registers.regA & 0x01) != 0
        registers.regA = (registers.regA >> 1) | (carry ? 0x80 : 0)
        
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RRCA }
    var description: String { return "RRCA" }
}

struct EXAFInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let tempA = registers.regA
        let tempF = registers.regF
        
        registers.regA = registers.regAPrime
        registers.regF = registers.regFPrime
        
        registers.regAPrime = tempA
        registers.regFPrime = tempF
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.EXAF }
    var description: String { return "EX AF,AF'" }
}

struct DJNZInstruction: Z80Instruction {
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.regB = registers.regB &- 1
        
        if registers.regB != 0 {
            registers.pc = UInt16(Int(registers.pc) + Int(offset) + 2)
            return 13 // ジャンプする場合
        } else {
            registers.programCounter = registers.programCounter &+ size
            return 8 // ジャンプしない場合
        }
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 8 } // 最小サイクル数
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.DJNZ }
    var description: String { return "DJNZ \(offset)" }
}

struct IYPrefixedInstruction: Z80Instruction {
    let instruction: Z80Instruction
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let baseCycles = instruction.execute(cpu: cpu, registers: &registers, memory: memory, inputOutput: inputOutput)
        return baseCycles + 4 // IYプレフィックスの追加サイクル
    }
    
    var size: UInt16 { return instruction.size + 1 } // プレフィックスバイト分を追加
    var cycles: Int { return instruction.cycles + 4 } // プレフィックスの追加サイクル
    var cycleInfo: InstructionCycles { return instruction.cycleInfo } // 基本的には元の命令のサイクル情報
    var description: String { return "IY: \(instruction.description)" }
}

struct LDIYInstruction: Z80Instruction {
    let value: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.regIY = value
        return cycles
    }
    
    var size: UInt16 { return 4 } // FD + 21 + nn + nn
    var cycles: Int { return 14 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDIY }
    var description: String { return "LD IY,\(String(format: "0x%04X", value))" }
}
