//
//
//

import Foundation

struct LDRegRegInstruction: Z80Instruction {
    let destination: RegisterOperand
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers, memory: memory)
        destination.write(to: &registers, value: value, memory: memory)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRR }
    var description: String { return "LD \(destination),\(source)" }
}

struct LDRegImmInstruction: Z80Instruction {
    let destination: RegisterOperand
    let value: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        destination.write(to: &registers, value: value, memory: memory)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 7 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRI }
    var description: String { return "LD \(destination),\(String(format: "0x%02X", value))" }
}

struct LDRegMemInstruction: Z80Instruction {
    let destination: RegisterOperand
    let address: AddressOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        let value = memory.readByte(at: addr)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRM }
    var description: String { return "LD \(destination),(\(address))" }
}

struct LDMemRegInstruction: Z80Instruction {
    let address: AddressOperand
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        let value = source.read(from: registers)
        memory.writeByte(value, at: addr)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDMR }
    var description: String { return "LD (\(address)),\(source)" }
}

struct LDMemImmInstruction: Z80Instruction {
    let address: AddressOperand
    let value: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        memory.writeByte(value, at: addr)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDMI }
    var description: String { return "LD (\(address)),\(String(format: "0x%02X", value))" }
}

struct LDRegPairImmInstruction: Z80Instruction {
    let register: RegisterPairOperand
    let value: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        register.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRPI }
    var description: String { return "LD \(register),\(String(format: "0x%04X", value))" }
}

struct LDRegMemAddrInstruction: Z80Instruction {
    let destination: RegisterOperand
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = memory.readByte(at: address)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRMA }
    var description: String { return "LD \(destination),(\(String(format: "0x%04X", address)))" }
}

struct LDMemAddrRegInstruction: Z80Instruction {
    let address: UInt16
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers)
        memory.writeByte(value, at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDMAR }
    var description: String { return "LD (\(String(format: "0x%04X", address))),\(source)" }
}

struct LDRegPairMemAddrInstruction: Z80Instruction {
    let destination: RegisterPairOperand
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = memory.readWord(at: address)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDRPMA }
    var description: String { return "LD \(destination),(\(String(format: "0x%04X", address)))" }
}

struct LDMemAddrRegPairInstruction: Z80Instruction {
    let address: UInt16
    let source: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers)
        memory.writeWord(value, at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 16 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.LDMARP }
    var description: String { return "LD (\(String(format: "0x%04X", address))),\(source)" }
}
