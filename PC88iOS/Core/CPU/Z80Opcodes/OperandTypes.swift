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
        case .regA, .regB, .regC, .regD, .regE, .regH, .regL, .regF:
            return readFromRegister(registers)
        case .immediate(let value):
            return value
        case .memory:
            return readFromMemory(registers, memory)
        }
    }
    
    private func readFromRegister(_ registers: Z80Registers) -> UInt8 {
        switch self {
        case .regA: return registers.a
        case .regB: return registers.b
        case .regC: return registers.c
        case .regD: return registers.d
        case .regE: return registers.e
        case .regH: return registers.h
        case .regL: return registers.l
        case .regF: return registers.f
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
        case .regA, .regB, .regC, .regD, .regE, .regH, .regL, .regF:
            writeToRegister(&registers, value)
        case .immediate:
            PC88Logger.cpu.debug("警告: immediate値に書き込みが行われました")
        case .memory:
            writeToMemory(registers, value, memory)
        }
    }
    
    private func writeToRegister(_ registers: inout Z80Registers, _ value: UInt8) {
        switch self {
        case .regA: registers.a = value
        case .regB: registers.b = value
        case .regC: registers.c = value
        case .regD: registers.d = value
        case .regE: registers.e = value
        case .regH: registers.h = value
        case .regL: registers.l = value
        case .regF: registers.f = value
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
    case af, bc, de, hl, sp, afAlt
    
    func read(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .af, .bc, .de:
            return readRegisterPair(registers)
        case .hl, .sp, .afAlt:
            return readSpecialRegister(registers)
        }
    }
    
    private func readRegisterPair(_ registers: Z80Registers) -> UInt16 {
        switch self {
        case .af: return UInt16(registers.regA) << 8 | UInt16(registers.regF)
        case .bc: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .de: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
            return 0
        }
    }
    
    private func readSpecialRegister(_ registers: Z80Registers) -> UInt16 {
        switch self {
        case .hl: return registers.regHL
        case .sp: return registers.regSP
        case .afAlt: return UInt16(registers.regAAlt) << 8 | UInt16(registers.regFAlt)
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
            return 0
        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt16) {
        switch self {
        case .af, .bc, .de:
            writeToRegisterPair(&registers, value)
        case .hl, .sp, .afAlt:
            writeToSpecialRegister(&registers, value)
        }
    }
    
    private func writeToRegisterPair(_ registers: inout Z80Registers, _ value: UInt16) {
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
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
        }
    }
    
    private func writeToSpecialRegister(_ registers: inout Z80Registers, _ value: UInt16) {
        switch self {
        case .hl:
            registers.regHL = value
        case .sp:
            registers.regSP = value
        case .afAlt:
            registers.regAAlt = UInt8(value >> 8)
            registers.regFAlt = UInt8(value & 0xFF)
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
        }
    }
}

/// メモリアドレスオペランド
enum AddressOperand {
    case bc, de, hl, direct(UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .bc, .de:
            return getRegisterPairAddress(registers)
        case .hl:
            return registers.regHL
        case .direct(let address):
            return address
        }
    }
    
    private func getRegisterPairAddress(_ registers: Z80Registers) -> UInt16 {
        switch self {
        case .bc: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .de: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        default:
            PC88Logger.cpu.error("不正なアドレスオペランドタイプです")
            return 0
        }
    }
}

/// 拡張メモリアドレスオペランド
enum MemoryAddressOperand {
    case hl, bc, de, ix(offset: Int8), iy(offset: Int8), direct(address: UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .hl, .bc, .de:
            return getBasicAddress(registers)
        case .ix, .iy:
            return getIndexedAddress(registers)
        case .direct(let address):
            return address
        }
    }
    
    private func getBasicAddress(_ registers: Z80Registers) -> UInt16 {
        switch self {
        case .hl: return registers.regHL
        case .bc: return registers.regBC
        case .de: return registers.regDE
        default:
            PC88Logger.cpu.error("不正な拡張アドレスオペランドタイプです")
            return 0
        }
    }
    
    private func getIndexedAddress(_ registers: Z80Registers) -> UInt16 {
        switch self {
        case .ix(let offset): return UInt16(Int(registers.regIX) + Int(offset))
        case .iy(let offset): return UInt16(Int(registers.regIY) + Int(offset))
        default:
            PC88Logger.cpu.error("不正なインデックスアドレスオペランドタイプです")
            return 0
        }
    }
}
