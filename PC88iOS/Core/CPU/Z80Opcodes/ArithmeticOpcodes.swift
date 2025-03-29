//
//  ArithmeticOpcodes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 加算命令（A += r）
struct ADDInstruction: Z80Instruction {
    let source: RegisterSource
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // ハーフキャリーの計算
        let halfCarry = ((registers.a & 0x0F) + (value & 0x0F)) > 0x0F
        
        // キャリーの計算
        let result = UInt16(registers.a) + UInt16(value)
        let carry = result > 0xFF
        
        // 結果の設定
        registers.a = UInt8(result & 0xFF)
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    // パリティチェック（偶数なら真）
    private func parityEven(_ value: UInt8) -> Bool {
        var v = value
        v ^= v >> 4
        v ^= v >> 2
        v ^= v >> 1
        return (v & 1) == 0
    }
}

/// 加算命令（A += r + Carry）
struct ADCInstruction: Z80Instruction {
    let source: RegisterSource
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        let carryValue: UInt8 = registers.getFlag(Z80Registers.Flags.carry) ? 1 : 0
        
        // ハーフキャリーの計算
        let halfCarry = ((registers.a & 0x0F) + (value & 0x0F) + carryValue) > 0x0F
        
        // キャリーの計算
        let result = UInt16(registers.a) + UInt16(value) + UInt16(carryValue)
        let carry = result > 0xFF
        
        // 結果の設定
        registers.a = UInt8(result & 0xFF)
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: false)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    // パリティチェック（偶数なら真）
    private func parityEven(_ value: UInt8) -> Bool {
        var v = value
        v ^= v >> 4
        v ^= v >> 2
        v ^= v >> 1
        return (v & 1) == 0
    }
}

/// 減算命令（A -= r）
struct SUBInstruction: Z80Instruction {
    let source: RegisterSource
    
    func execute(cpu: Z80CPU, registers: inout Z80Registers, memory: MemoryAccessing, io: IOAccessing) -> Int {
        let value: UInt8
        var cycles = 4
        
        switch source {
        case .register(let reg):
            switch reg {
            case .a: value = registers.a
            case .b: value = registers.b
            case .c: value = registers.c
            case .d: value = registers.d
            case .e: value = registers.e
            case .h: value = registers.h
            case .l: value = registers.l
            }
        case .memory:
            value = memory.readByte(at: registers.hl)
            cycles = 7
        case .immediate(let imm):
            value = imm
            cycles = 7
        }
        
        // ハーフキャリーの計算
        let halfCarry = (registers.a & 0x0F) < (value & 0x0F)
        
        // キャリーの計算
        let carry = registers.a < value
        
        // 結果の設定
        registers.a = registers.a &- value
        
        // フラグの設定
        registers.setFlag(Z80Registers.Flags.zero, value: registers.a == 0)
        registers.setFlag(Z80Registers.Flags.sign, value: (registers.a & 0x80) != 0)
        registers.setFlag(Z80Registers.Flags.halfCarry, value: halfCarry)
        registers.setFlag(Z80Registers.Flags.parity, value: parityEven(registers.a))
        registers.setFlag(Z80Registers.Flags.subtract, value: true)
        registers.setFlag(Z80Registers.Flags.carry, value: carry)
        
        return cycles
    }
    
    // パリティチェック（偶数なら真）
    private func parityEven(_ value: UInt8) -> Bool {
        var v = value
        v ^= v >> 4
        v ^= v >> 2
        v ^= v >> 1
        return (v & 1) == 0
    }
}

/// レジスタソース
enum RegisterSource {
    case register(Register8)
    case memory
    case immediate(UInt8)
}

/// 8ビットレジスタ
enum Register8 {
    case a, b, c, d, e, h, l
}
