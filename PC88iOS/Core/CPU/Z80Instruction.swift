//
//
//

import Foundation

protocol Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int
    
    var size: UInt16 { get }
    
    var cycles: Int { get }
    
    var cycleInfo: InstructionCycles { get }
    
    var description: String { get }
}
