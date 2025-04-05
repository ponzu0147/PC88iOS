//
//
//

import Foundation

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
    var cycleInfo: PC88iOS.InstructionCycles { return PC88iOS.Z80InstructionCycles.logicalAndReg }
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
    var cycleInfo: PC88iOS.InstructionCycles { return PC88iOS.Z80InstructionCycles.logicalOrReg }
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
    var cycleInfo: PC88iOS.InstructionCycles { return PC88iOS.Z80InstructionCycles.logicalXorReg }
    var description: String { return "XOR \(source)" }
}

