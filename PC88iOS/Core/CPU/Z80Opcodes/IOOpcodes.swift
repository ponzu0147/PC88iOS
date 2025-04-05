//
//  IOOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation
import PC88iOS

/// OUT (n),A命令（指定ポートに値を出力）
struct OUTInstruction: Z80Instruction {
    let port: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // PC-88の実装ではポート番号は8ビットであるため、ポート番号のみを使用
        inputOutput.writePort(port, value: registers.regA)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.outputAToPort }
    var description: String { return "OUT (\(String(format: "0x%02X", port))),A" }
}

/// IN A,(n)命令（指定ポートから値を入力）
struct INInstruction: Z80Instruction {
    let port: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, inputOutput: IOAccessing) -> Int {
        // PC-88の実装ではポート番号は8ビットであるため、ポート番号のみを使用
        registers.regA = inputOutput.readPort(port)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 11 }
    var cycleInfo: InstructionCycles { return Z80InstructionCycles.inputAFromPort }
    var description: String { return "IN A,(\(String(format: "0x%02X", port)))" }
}
