//
//
//

import Foundation

struct POPInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = memory.readWord(at: registers.sp)
        
        register.write(to: &registers, value: value)
        
        if registers.sp <= UInt16.max - 2 {
            registers.sp = registers.sp &+ 2
        } else {
            registers.sp = 0
            PC88Logger.cpu.warning("スタックポインタがオーバーフローしました")
        }
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 10 }
    var cycleInfo: PC88iOS.InstructionCycles { return PC88iOS.Z80InstructionCycles.POP }
    var description: String { return "POP \(register)" }
}

struct PUSHInstruction: Z80Instruction {
    let register: RegisterPairOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let value = register.read(from: registers)
        
        if registers.sp >= 2 {
            registers.sp = registers.sp &- 2
        } else {
            registers.sp = 0xFFFF
            PC88Logger.cpu.warning("スタックポインタがオーバーフローしました")
        }
        memory.writeWord(value, at: registers.sp)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: PC88iOS.InstructionCycles { return PC88iOS.Z80InstructionCycles.PUSH }
    var description: String { return "PUSH \(register)" }
}
