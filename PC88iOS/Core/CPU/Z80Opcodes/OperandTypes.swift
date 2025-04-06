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
    
    /// 即値オペランドかどうか
    var isImmediate: Bool {
        switch self {
        case .immediate: return true
        default: return false
        }
    }
    
    /// メモリオペランドかどうか
    var isMemory: Bool {
        switch self {
        case .memory: return true
        default: return false
        }
    }
    
    func read(from registers: Z80Registers, memory: MemoryAccessing? = nil) -> UInt8 {
        switch self {
        case .a, .b, .c, .d, .e, .h, .l, .f:
            return readFromRegister(registers)
        case .immediate(let value):
            return value
        case .memory:
            return readFromMemory(registers, memory)
        }
    }
    
    private func readFromRegister(_ registers: Z80Registers) -> UInt8 {
        switch self {
        case .a: return registers.a
        case .b: return registers.b
        case .c: return registers.c
        case .d: return registers.d
        case .e: return registers.e
        case .h: return registers.h
        case .l: return registers.l
        case .f: return registers.f
        default:
            PC88Logger.cpu.error("不正なレジスタタイプです")
            return 0
        }
    }
    
    private func readFromMemory(_ registers: Z80Registers, _ memory: MemoryAccessing?) -> UInt8 {
        if let memory = memory {
            return memory.readByte(at: registers.hl)
        } else {
            PC88Logger.cpu.debug("警告: memoryが指定されていません")
            return 0
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt8, memory: MemoryAccessing? = nil) {
        switch self {
        case .a, .b, .c, .d, .e, .h, .l, .f:
            writeToRegister(&registers, value)
        case .immediate:
            PC88Logger.cpu.debug("警告: immediate値に書き込みが行われました")
        case .memory:
            writeToMemory(registers, value, memory)
        }
    }
    
    private func writeToRegister(_ registers: inout Z80Registers, _ value: UInt8) {
        switch self {
        case .a: registers.a = value
        case .b: registers.b = value
        case .c: registers.c = value
        case .d: registers.d = value
        case .e: registers.e = value
        case .h: registers.h = value
        case .l: registers.l = value
        case .f: registers.f = value
        default:
            PC88Logger.cpu.error("不正なレジスタタイプです")
        }
    }
    
    private func writeToMemory(_ registers: Z80Registers, _ value: UInt8, _ memory: MemoryAccessing?) {
        if let memory = memory {
            memory.writeByte(value, at: registers.hl)
        } else {
            PC88Logger.cpu.debug("警告: memoryが指定されていません")
        }
    }
}

/// レジスタペアオペランド
enum RegisterPairOperand {
    case registerAF, registerBC, registerDE, registerHL, registerSP, registerAFAlt
    
    // 短縮形のプロパティ
    var af: RegisterPairOperand { return .registerAF }
    var bc: RegisterPairOperand { return .registerBC }
    var de: RegisterPairOperand { return .registerDE }
    var hl: RegisterPairOperand { return .registerHL }
    var sp: RegisterPairOperand { return .registerSP }
    
    func read(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerAF: return UInt16(registers.a) << 8 | UInt16(registers.f)
        case .registerBC: return UInt16(registers.b) << 8 | UInt16(registers.c)
        case .registerDE: return UInt16(registers.d) << 8 | UInt16(registers.e)
        case .registerHL: return registers.hl
        case .registerSP: return registers.sp
        case .registerAFAlt: return UInt16(registers.aAlt) << 8 | UInt16(registers.fAlt)

        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt16) {
        switch self {
        case .registerAF:
            registers.a = UInt8(value >> 8)
            registers.f = UInt8(value & 0xFF)
        case .registerBC:
            registers.b = UInt8(value >> 8)
            registers.c = UInt8(value & 0xFF)
        case .registerDE:
            registers.d = UInt8(value >> 8)
            registers.e = UInt8(value & 0xFF)
        case .registerHL:
            registers.hl = value
        case .registerSP:
            registers.sp = value
        case .registerAFAlt:
            registers.aAlt = UInt8(value >> 8)
            registers.fAlt = UInt8(value & 0xFF)
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
        }
    }
}

/// メモリアドレスオペランド
enum AddressOperand {
    case registerBC, registerDE, registerHL, direct(UInt16)
    
    // 短縮形のプロパティ
    var bc: AddressOperand { return .registerBC }
    var de: AddressOperand { return .registerDE }
    var hl: AddressOperand { return .registerHL }
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerBC: return UInt16(registers.b) << 8 | UInt16(registers.c)
        case .registerDE: return UInt16(registers.d) << 8 | UInt16(registers.e)
        case .registerHL: return registers.hl
        case .direct(let address): return address
        }
    }
}

/// 拡張メモリアドレスオペランド
enum MemoryAddressOperand {
    case registerHL, registerBC, registerDE, registerIX(offset: Int8), registerIY(offset: Int8), direct(address: UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerHL: return registers.hl
        case .registerBC: return registers.bc
        case .registerDE: return registers.de
        case .registerIX(let offset): return UInt16(Int(registers.ix) + Int(offset))
        case .registerIY(let offset): return UInt16(Int(registers.iy) + Int(offset))
        case .direct(let address): return address
        }
    }
}
