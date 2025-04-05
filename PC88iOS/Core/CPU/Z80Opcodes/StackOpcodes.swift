//
//
//

import Foundation
import PC88iOS

struct POPInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = memory.readWord(at: registers.stackPointer)
        
        register.write(to: &registers, value: value)
        
        if registers.stackPointer <= UInt16.max - 2 {
            registers.stackPointer = registers.stackPointer &+ 2
        } else {
            registers.stackPointer = 0
            PC88Logger.cpu.warning("スタックポインタがオーバーフローしました")
        }
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 10 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.POP }
    var description: String { return "POP \(register)" }
}

struct PUSHInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = register.read(from: registers)
        
        if registers.stackPointer >= 2 {
            registers.stackPointer = registers.stackPointer &- 2
        } else {
            registers.stackPointer = 0xFFFF
            PC88Logger.cpu.warning("スタックポインタがオーバーフローしました")
        }
        memory.writeWord(value, at: registers.stackPointer)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.PUSH }
    var description: String { return "PUSH \(register)" }
}
