//
//  LoadOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// LD r,r'命令（レジスタ間コピー）
struct LDRegRegInstruction: Z80Instruction {
    let destination: RegisterOperand
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value = source.read(from: registers)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 4 }
    var description: String { return "LD \(destination),\(source)" }
}

/// LD r,n命令（即値ロード）
struct LDRegImmInstruction: Z80Instruction {
    let destination: RegisterOperand
    let value: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 7 }
    var description: String { return "LD \(destination),\(String(format: "0x%02X", value))" }
}

/// LD r,(HL)命令（メモリからレジスタへのロード）
struct LDRegMemInstruction: Z80Instruction {
    let destination: RegisterOperand
    let address: MemoryAddressOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        let value = memory.readByte(at: addr)
        destination.write(to: &registers, value: value)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD \(destination),(\(address))" }
}

/// LD (HL),r命令（レジスタからメモリへのストア）
struct LDMemRegInstruction: Z80Instruction {
    let address: MemoryAddressOperand
    let source: RegisterOperand
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        let value = source.read(from: registers)
        memory.writeByte(value, at: addr)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD (\(address)),\(source)" }
}

/// LD (HL),n命令（即値をメモリにストア）
struct LDMemImmInstruction: Z80Instruction {
    let address: MemoryAddressOperand
    let value: UInt8
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let addr = address.getAddress(from: registers)
        memory.writeByte(value, at: addr)
        return cycles
    }
    
    var size: UInt16 { return 2 }
    var cycles: Int { return 10 }
    var description: String { return "LD (\(address)),\(String(format: "0x%02X", value))" }
}

/// LD A,(BC)命令
struct LDABCInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        registers.a = memory.readByte(at: registers.bc)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD A,(BC)" }
}

/// LD A,(DE)命令
struct LDADEInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        registers.a = memory.readByte(at: registers.de)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD A,(DE)" }
}

/// LD A,(nn)命令
struct LDAnnInstruction: Z80Instruction {
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        registers.a = memory.readByte(at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var description: String { return "LD A,(\(String(format: "0x%04X", address)))" }
}

/// LD (BC),A命令
struct LDBCAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        memory.writeByte(registers.a, at: registers.bc)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD (BC),A" }
}

/// LD (DE),A命令
struct LDDEAInstruction: Z80Instruction {
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        memory.writeByte(registers.a, at: registers.de)
        return cycles
    }
    
    var size: UInt16 { return 1 }
    var cycles: Int { return 7 }
    var description: String { return "LD (DE),A" }
}

/// LD rp,nn命令（レジスタペアに16ビット即値をロード）
struct LDRegPairImmInstruction: Z80Instruction {
    let register: RegisterType
    let value: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        // 直接レジスタを更新する
        switch register {
        case .af: registers.af = value
        case .bc: registers.bc = value
        case .de: registers.de = value
        case .hl: registers.hl = value
        case .ix: registers.ix = value
        case .iy: registers.iy = value
        case .sp: registers.sp = value
        case .pc: registers.pc = value
        }
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 10 }
    var description: String { return "LD \(register),\(String(format: "0x%04X", value))" }
}

/// LD (nn),A命令
struct LDnnAInstruction: Z80Instruction {
    let address: UInt16
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        memory.writeByte(registers.a, at: address)
        return cycles
    }
    
    var size: UInt16 { return 3 }
    var cycles: Int { return 13 }
    var description: String { return "LD (\(String(format: "0x%04X", address))),A" }
}
