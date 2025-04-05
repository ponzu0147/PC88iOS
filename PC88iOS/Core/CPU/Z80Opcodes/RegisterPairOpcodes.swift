//
//
//

import Foundation

struct INCRegPairInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = register.read(from: registers)
        register.write(to: &registers, value: value &+ 1)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 6 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.INCRP }
    var description: String { return "INC \(register)" }
}

struct DECRegPairInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = register.read(from: registers)
        register.write(to: &registers, value: value &- 1)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 6 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.DECRP }
    var description: String { return "DEC \(register)" }
}

struct ADDHLInstruction: Z80Instruction {
    let source: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let hl = registers.hl
        let value = source.read(from: registers)
        
        let halfCarry = ((hl & 0x0FFF) + (value & 0x0FFF)) > 0x0FFF
        
        let result = UInt32(hl) + UInt32(value)
        
        let carry = result > 0xFFFF
        
        registers.hl = UInt16(result & 0xFFFF)
        
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.ADDHL }
    var description: String { return "ADD HL,\(source)" }
}

struct SBCInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers)
        let carryValue: UInt8 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        let halfCarry = (registers.a & 0x0F) < ((value & 0x0F) + carryValue)
        
        let result = Int(registers.a) - Int(value) - Int(carryValue)
        let carry = result < 0
        
        registers.a = UInt8(result & 0xFF)
        
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.SBC }
    var description: String { return "SBC A,\(source)" }
}

struct LDDirectMemRegInstruction: Z80Instruction {
    let address: UInt16
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers)
        memory.writeByte(value, at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDMEM }
    var description: String { return "LD (\(String(format: "0x%04X", address))),\(source)" }
}
