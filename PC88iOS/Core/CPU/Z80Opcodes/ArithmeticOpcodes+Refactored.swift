//
//
//

import Foundation
import PC88iOS

struct ADDInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        let regA = registers.regA
        
        let halfCarry = ((regA & 0x0F) + (value & 0x0F)) > 0x0F
        
        let result = regA &+ value
        
        let carry = Int(regA) + Int(value) > 0xFF
        
        let overflow = (regA & 0x80) == (value & 0x80) && (result & 0x80) != (regA & 0x80)
        
        registers.regA = result
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.ADD }
    var description: String { return "ADD A,\(source)" }
}

struct SUBInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        let regA = registers.regA
        
        let halfCarry = (regA & 0x0F) < (value & 0x0F)
        
        let result = regA &- value
        
        let carry = Int(regA) < Int(value)
        
        let overflow = (regA & 0x80) != (value & 0x80) && (result & 0x80) != (regA & 0x80)
        
        registers.regA = result
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.SUB }
    var description: String { return "SUB A,\(source)" }
}

struct INCRegInstruction: Z80Instruction {
    let register: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = register.read(from: registers, memory: memory)
        
        let halfCarry = (value & 0x0F) == 0x0F
        
        let result = value &+ 1
        
        let overflow = value == 0x7F
        
        register.write(to: &registers, value: result, memory: memory)
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return register.isMemory ? 11 : 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.INC }
    var description: String { return "INC \(register)" }
}

struct DECRegInstruction: Z80Instruction {
    let register: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = register.read(from: registers, memory: memory)
        
        let halfCarry = (value & 0x0F) == 0
        
        let result = value &- 1
        
        let overflow = value == 0x80
        
        register.write(to: &registers, value: result, memory: memory)
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return register.isMemory ? 11 : 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.DEC }
    var description: String { return "DEC \(register)" }
}

struct CPInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        let regA = registers.regA
        
        let halfCarry = (regA & 0x0F) < (value & 0x0F)
        
        let result = regA &- value
        
        let carry = Int(regA) < Int(value)
        
        let overflow = (regA & 0x80) != (value & 0x80) && (result & 0x80) != (regA & 0x80)
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: overflow)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    var size: UInt16 { return source.isImmediate ? 2 : 1 }
    var cycles: Int { return source.isImmediate ? 7 : (source.isMemory ? 7 : 4) }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CP }
    var description: String { return "CP \(source)" }
}

struct CPLInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.regA = ~registers.regA
        
        registers.setFlag(Z80Registers.Flags.halfCarry, value: true)
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CPL }
    var description: String { return "CPL" }
}
