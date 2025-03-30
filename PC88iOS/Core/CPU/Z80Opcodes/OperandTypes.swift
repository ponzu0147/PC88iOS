//
//  OperandTypes.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// レジスタオペランド
enum RegisterOperand {
    case a, b, c, d, e, h, l, f
    case immediate(UInt8)
    case memory
    
    func read(from registers: Z80Registers, memory: MemoryAccessing? = nil) -> UInt8 {
        switch self {
        case .a: return registers.a
        case .b: return registers.b
        case .c: return registers.c
        case .d: return registers.d
        case .e: return registers.e
        case .h: return registers.h
        case .l: return registers.l
        case .f: return registers.f
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
        case .a: registers.a = value
        case .b: registers.b = value
        case .c: registers.c = value
        case .d: registers.d = value
        case .e: registers.e = value
        case .h: registers.h = value
        case .l: registers.l = value
        case .f: registers.f = value
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
    case af, bc, de, hl, sp, af_alt
    
    func read(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .af: return UInt16(registers.a) << 8 | UInt16(registers.f)
        case .bc: return UInt16(registers.b) << 8 | UInt16(registers.c)
        case .de: return UInt16(registers.d) << 8 | UInt16(registers.e)
        case .hl: return registers.hl
        case .sp: return registers.sp
        case .af_alt: return UInt16(registers.a_alt) << 8 | UInt16(registers.f_alt)
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt16) {
        switch self {
        case .af:
            registers.a = UInt8(value >> 8)
            registers.f = UInt8(value & 0xFF)
        case .bc:
            registers.b = UInt8(value >> 8)
            registers.c = UInt8(value & 0xFF)
        case .de:
            registers.d = UInt8(value >> 8)
            registers.e = UInt8(value & 0xFF)
        case .hl:
            registers.hl = value
        case .sp:
            registers.sp = value
        case .af_alt:
            registers.a_alt = UInt8(value >> 8)
            registers.f_alt = UInt8(value & 0xFF)
        }
    }
}

/// メモリアドレスオペランド
enum AddressOperand {
    case bc, de, hl, direct(UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .bc: return UInt16(registers.b) << 8 | UInt16(registers.c)
        case .de: return UInt16(registers.d) << 8 | UInt16(registers.e)
        case .hl: return registers.hl
        case .direct(let address): return address
        }
    }
}

/// 拡張メモリアドレスオペランド
enum MemoryAddressOperand {
    case hl, bc, de, ix(offset: Int8), iy(offset: Int8), direct(address: UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .hl: return registers.hl
        case .bc: return registers.bc
        case .de: return registers.de
        case .ix(let offset): return UInt16(Int(registers.ix) + Int(offset))
        case .iy(let offset): return UInt16(Int(registers.iy) + Int(offset))
        case .direct(let address): return address
        }
    }
}
