//
//
//

import Foundation
import PC88iOS

struct ANDInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        
        registers.a &= value
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: true)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.AND }
    var description: String { return "AND \(source)" }
}

struct ORInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        
        registers.a |= value
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.OR }
    var description: String { return "OR \(source)" }
}

struct XORInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        
        registers.a ^= value
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.XOR }
    var description: String { return "XOR \(source)" }
}

func parityEven(_ value: UInt8) -> Bool {
    var count = 0
    var temp = value
    
    for _ in 0..<8 {
        if (temp & 1) != 0 {
            count += 1
        }
        temp >>= 1
    }
    
    return (count % 2) == 0
}
