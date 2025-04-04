//
//  OperandTypes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// レジスタオペランド
enum RegisterOperand {
    case regA, regB, regC, regD, regE, regH, regL, regF
    case immediate(UInt8)
    case memory
    
    func read(from registers: Z80Registers, memory: MemoryAccessing? = nil) -> UInt8 {
        switch self {
        case .regA: return registers.a
        case .regB: return registers.b
        case .regC: return registers.c
        case .regD: return registers.d
        case .regE: return registers.e
        case .regH: return registers.h
        case .regL: return registers.l
        case .regF: return registers.f
        case .immediate(let value): return value
        case .memory:
            if let memory = memory {
                return memory.readByte(at: registers.hl)
            } else {
                print("警告: memoryが指定されていません")
                return 0
            }
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt8, memory: MemoryAccessing? = nil) {
        switch self {
        case .regA: registers.a = value
        case .regB: registers.b = value
        case .regC: registers.c = value
        case .regD: registers.d = value
        case .regE: registers.e = value
        case .regH: registers.h = value
        case .regL: registers.l = value
        case .regF: registers.f = value
        case .immediate: 
            print("警告: immediate値に書き込みが行われました")
        case .memory:
            if let memory = memory {
                memory.writeByte(value, at: registers.hl)
            } else {
                print("警告: memoryが指定されていません")
            }
        }
    }
}

/// レジスタペアオペランド
enum RegisterPairOperand {
    case af, bc, de, hl, sp, afAlt
    
    func read(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .af: return UInt16(registers.regA) << 8 | UInt16(registers.regF)
        case .bc: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .de: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        case .hl: return registers.regHL
        case .sp: return registers.regSP
        case .afAlt: return UInt16(registers.regAAlt) << 8 | UInt16(registers.regFAlt)
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt16) {
        switch self {
        case .af:
            registers.regA = UInt8(value >> 8)
            registers.regF = UInt8(value & 0xFF)
        case .bc:
            registers.regB = UInt8(value >> 8)
            registers.regC = UInt8(value & 0xFF)
        case .de:
            registers.regD = UInt8(value >> 8)
            registers.regE = UInt8(value & 0xFF)
        case .hl:
            registers.regHL = value
        case .sp:
            registers.regSP = value
        case .afAlt:
            registers.regAAlt = UInt8(value >> 8)
            registers.regFAlt = UInt8(value & 0xFF)
        }
    }
}

/// メモリアドレスオペランド
enum AddressOperand {
    case bc, de, hl, direct(UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .bc: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .de: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        case .hl: return registers.regHL
        case .direct(let address): return address
        }
    }
}

/// 拡張メモリアドレスオペランド
enum MemoryAddressOperand {
    case hl, bc, de, ix(offset: Int8), iy(offset: Int8), direct(address: UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .hl: return registers.regHL
        case .bc: return registers.regBC
        case .de: return registers.regDE
        case .ix(let offset): return UInt16(Int(registers.regIX) + Int(offset))
        case .iy(let offset): return UInt16(Int(registers.regIY) + Int(offset))
        case .direct(let address): return address
        }
    }
}
