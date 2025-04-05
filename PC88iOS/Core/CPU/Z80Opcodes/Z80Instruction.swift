//
//
//

import Foundation
import PC88iOS


struct NOPInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.NOP }
    var description: String { return "NOP" }
}

struct HALTInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        cpu.halt()
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.HALT }
    var description: String { return "HALT" }
}

struct DISInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.iff1 = false
        registers.iff2 = false
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.DI }
    var description: String { return "DI" }
}

struct EIInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        registers.iff1 = true
        registers.iff2 = true
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.EI }
    var description: String { return "EI" }
}

struct UnimplementedInstruction: Z80Instruction {
    let opcode: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let pc = registers.pc > 0 ? registers.pc - 1 : 0
        let opcodeHex = String(opcode, radix: 16, uppercase: true)
        let pcHex = String(pc, radix: 16, uppercase: true)
        PC88Logger.cpu.warning("未実装の命令 0x\(opcodeHex) at PC=0x\(pcHex)")
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.UNIMPLEMENTED }
    var description: String { return "UNIMPLEMENTED 0x\(String(opcode, radix: 16, uppercase: true))" }
}
