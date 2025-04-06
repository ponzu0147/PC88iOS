//
//
//

import Foundation
import PC88iOS

struct INInstruction: Z80Instruction {
    let port: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = inputOutput.readPort(port)
        
        registers.a = value
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.IN }
    var description: String { return "IN A,(\(String(format: "0x%02X", port)))" }
}

struct OUTInstruction: Z80Instruction {
    let port: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        inputOutput.writePort(port, value: registers.a)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.OUT }
    var description: String { return "OUT (\(String(format: "0x%02X", port))),A" }
}

struct INRegCInstruction: Z80Instruction {
    let register: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let port = registers.c
        
        let value = inputOutput.readPort(port)
        
        register.write(to: &registers, value: value)
        
        registers.setFlag(Z80Registers.Flags.zero, value: value == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (value & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: false)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(value))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 12 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.INRC }
    var description: String { return "IN \(register),(C)" }
}

struct OUTCRegInstruction: Z80Instruction {
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let port = registers.c
        
        let value = source.read(from: registers)
        
        inputOutput.writePort(port, value: value)
        
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 12 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.OUTCR }
    var description: String { return "OUT (C),\(source)" }
}
