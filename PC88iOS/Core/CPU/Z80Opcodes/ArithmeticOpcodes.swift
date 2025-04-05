//
//
//

import Foundation
import PC88iOS

struct ADDInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "ADD A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .regA: value = registers.regA
            case .regB: value = registers.regB
            case .regC: value = registers.regC
            case .regD: value = registers.regD
            case .regE: value = registers.regE
            case .regH: value = registers.regH
            case .regL: value = registers.regL
            }
        case .memory:
            value = memory.readByte(at: registers.regHL)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        let halfCarry = ((registers.regA & 0x0F) + (value & 0x0F)) > 0x0F
        
        let result = UInt16(registers.regA) + UInt16(value)
        let carry = result > 0xFF
        
        registers.regA = UInt8(result & 0xFF)
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.regA == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.regA & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.regA))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
}
struct ADCInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "ADC A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .regA: value = registers.regA
            case .regB: value = registers.regB
            case .regC: value = registers.regC
            case .regD: value = registers.regD
            case .regE: value = registers.regE
            case .regH: value = registers.regH
            case .regL: value = registers.regL
            }
        case .memory:
            value = memory.readByte(at: registers.regHL)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        let carryValue: UInt8 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        let halfCarry = ((registers.regA & 0x0F) + (value & 0x0F) + carryValue) > 0x0F
        
        let result = UInt16(registers.regA) + UInt16(value) + UInt16(carryValue)
        let carry = result > 0xFF
        
        registers.regA = UInt8(result & 0xFF)
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.regA == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.regA & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.regA))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
}

struct SUBInstruction: Z80Instruction {
    let source: RegisterSource
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "SUB A," + sourceDescription() }
    
    private func sourceDescription() -> String {
        switch source {
        case .register(let reg): return "\(reg)"
        case .memory: return "(HL)"
        case .immediate(let value): return String(format: "0x%02X", value)
        }
    }
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .regA: value = registers.regA
            case .regB: value = registers.regB
            case .regC: value = registers.regC
            case .regD: value = registers.regD
            case .regE: value = registers.regE
            case .regH: value = registers.regH
            case .regL: value = registers.regL
            }
        case .memory:
            value = memory.readByte(at: registers.regHL)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        let halfCarry = (registers.regA & 0x0F) < (value & 0x0F)
        
        let carry = registers.regA < value
        
        registers.regA = registers.regA &- value
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.regA == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.regA & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.regA))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
}

enum RegisterSource {
    case register(Register8)
    case memory
    case immediate(UInt8)
}

enum Register8 {
    case regA, regB, regC, regD, regE, regH, regL
}

struct INCRegInstruction: Z80Instruction {
    let register: Register8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch register {
        case .regA: value = registers.regA
        case .regB: value = registers.regB
        case .regC: value = registers.regC
        case .regD: value = registers.regD
        case .regE: value = registers.regE
        case .regH: value = registers.regH
        case .regL: value = registers.regL
        }
        
        let halfCarry = (value & 0x0F) == 0x0F
        
        let result = value &+ 1
        
        switch register {
        case .regA: registers.regA = result
        case .regB: registers.regB = result
        case .regC: registers.regC = result
        case .regD: registers.regD = result
        case .regE: registers.regE = result
        case .regH: registers.regH = result
        case .regL: registers.regL = result
        }
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(result))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "INC \(register)" }
}

struct DECRegInstruction: Z80Instruction {
    let register: Register8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch register {
        case .regA: value = registers.regA
        case .regB: value = registers.regB
        case .regC: value = registers.regC
        case .regD: value = registers.regD
        case .regE: value = registers.regE
        case .regH: value = registers.regH
        case .regL: value = registers.regL
        }
        
        let halfCarry = (value & 0x0F) == 0x00
        
        let result = value &- 1
        
        switch register {
        case .regA: registers.regA = result
        case .regB: registers.regB = result
        case .regC: registers.regC = result
        case .regD: registers.regD = result
        case .regE: registers.regE = result
        case .regH: registers.regH = result
        case .regL: registers.regL = result
        }
        
        registers.setFlag(Z80Registers.Flags.zero, value: result == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (result & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(result))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return InstructionCycles.standard(opcodeFetch: true) }
    var description: String { return "DEC \(register)" }
}
