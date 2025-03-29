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
    
    func read(from registers: Z80Registers) -> UInt8 {
        switch self {
        case .a: return registers.a
        case .b: return registers.b
        case .c: return registers.c
        case .d: return registers.d
        case .e: return registers.e
        case .h: return registers.h
        case .l: return registers.l
        case .f: return registers.f
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt8) {
        switch self {
        case .a: registers.a = value
        case .b: registers.b = value
        case .c: registers.c = value
        case .d: registers.d = value
        case .e: registers.e = value
        case .h: registers.h = value
        case .l: registers.l = value
        case .f: registers.f = value
        }
    }
}

/// メモリアドレスオペランド
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
