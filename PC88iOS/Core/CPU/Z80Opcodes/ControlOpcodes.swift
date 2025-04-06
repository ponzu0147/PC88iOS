//
//
//

import Foundation

struct JPInstruction: Z80Instruction {
    let condition: JumpCondition
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if checkCondition(condition, registers: registers) {
            registers.programCounter = address
            return cycles
        } else {
            registers.programCounter = registers.programCounter &+ size
            return cycles
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return condition == .none ? 10 : 10 } // 条件付きジャンプも同じサイクル数
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.JP }
    var description: String {
        if condition == .none {
            return "JP \(String(format: "0x%04X", address))"
        } else {
            return "JP \(condition),\(String(format: "0x%04X", address))"
        }
    }
}

struct JRInstruction: Z80Instruction {
    let condition: JumpCondition
    let offset: Int8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if checkCondition(condition, registers: registers) {
            registers.programCounter = UInt16(Int(registers.programCounter) + Int(offset) + 2)
            return condition == .none ? 12 : 12 // 条件付きジャンプも同じサイクル数
        } else {
            registers.programCounter = registers.programCounter &+ size
            return condition == .none ? 7 : 7 // 条件付きジャンプも同じサイクル数
        }
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return condition == .none ? 12 : 7 } // 条件が満たされない場合は7サイクル
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.JR }
    var description: String {
        if condition == .none {
            return "JR \(offset)"
        } else {
            return "JR \(condition),\(offset)"
        }
    }
}

struct CALLInstruction: Z80Instruction {
    let condition: JumpCondition
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if checkCondition(condition, registers: registers) {
            let returnAddress = registers.programCounter &+ size
            
            registers.sp = registers.sp &- 2
            
            memory.writeWord(returnAddress, at: registers.sp)
            
            registers.programCounter = address
            
            return condition == .none ? 17 : 17 // 条件付きコールも同じサイクル数
        } else {
            registers.programCounter = registers.programCounter &+ size
            return condition == .none ? 10 : 10 // 条件付きコールも同じサイクル数
        }
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return condition == .none ? 17 : 10 } // 条件が満たされない場合は10サイクル
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.CALL }
    var description: String {
        if condition == .none {
            return "CALL \(String(format: "0x%04X", address))"
        } else {
            return "CALL \(condition),\(String(format: "0x%04X", address))"
        }
    }
}

struct RETInstruction: Z80Instruction {
    let condition: JumpCondition
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        if checkCondition(condition, registers: registers) {
            let returnAddress = memory.readWord(at: registers.sp)
            
            registers.sp = registers.sp &+ 2
            
            registers.programCounter = returnAddress
            
            return condition == .none ? 10 : 11 // 条件付きリターンは11サイクル
        } else {
            registers.programCounter = registers.programCounter &+ size
            return condition == .none ? 5 : 5 // 条件が満たされない場合は5サイクル
        }
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return condition == .none ? 10 : 5 } // 条件が満たされない場合は5サイクル
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RET }
    var description: String {
        if condition == .none {
            return "RET"
        } else {
            return "RET \(condition)"
        }
    }
}

struct RSTInstruction: Z80Instruction {
    let address: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        let returnAddress = registers.programCounter &+ size
        
        registers.sp = registers.sp &- 2
        
        memory.writeWord(returnAddress, at: registers.sp)
        
        registers.programCounter = UInt16(address)
        
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.RST }
    var description: String { return "RST \(String(format: "0x%02X", address))" }
}

func checkCondition(_ condition: JumpCondition, registers: Z80Registers) -> Bool {
    switch condition {
    case .none:
        return true
    case .zero:
        return registers.getFlag(Z80Registers.Flags.zero)
    case .notZero:
        return !registers.getFlag(Z80Registers.Flags.zero)
    case .carry:
        return registers.getFlag(Z80Registers.Flags.carry)
    case .notCarry:
        return !registers.getFlag(Z80Registers.Flags.carry)
    case .parityEven:
        return registers.getFlag(Z80Registers.Flags.parity)
    case .parityOdd:
        return !registers.getFlag(Z80Registers.Flags.parity)
    case .sign:
        return registers.getFlag(Z80Registers.Flags.sign)
    case .notSign:
        return !registers.getFlag(Z80Registers.Flags.sign)
    }
}
