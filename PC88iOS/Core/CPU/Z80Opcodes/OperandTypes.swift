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
        case .regA: return registers.regA
        case .regB: return registers.regB
        case .regC: return registers.regC
        case .regD: return registers.regD
        case .regE: return registers.regE
        case .regH: return registers.regH
        case .regL: return registers.regL
        case .regF: return registers.regF
        default:
            PC88Logger.cpu.error("不正なレジスタタイプです")
            return 0
        }
    }
    
    private func readFromMemory(_ registers: Z80Registers, _ memory: MemoryAccessing?) -> UInt8 {
        if let memory = memory {
            return memory.readByte(at: registers.regHL)
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
        case .regA: registers.regA = value
        case .regB: registers.regB = value
        case .regC: registers.regC = value
        case .regD: registers.regD = value
        case .regE: registers.regE = value
        case .regH: registers.regH = value
        case .regL: registers.regL = value
        case .regF: registers.regF = value
        default:
            PC88Logger.cpu.error("不正なレジスタタイプです")
        }
    }
    
    private func writeToMemory(_ registers: Z80Registers, _ value: UInt8, _ memory: MemoryAccessing?) {
        if let memory = memory {
            memory.writeByte(value, at: registers.regHL)
        } else {
            PC88Logger.cpu.debug("警告: memoryが指定されていません")
        }
    }
}

/// レジスタペアオペランド
enum RegisterPairOperand {
    case registerAF, registerBC, registerDE, registerHL, registerSP, registerAFAlt
    
    func read(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerAF: return UInt16(registers.regA) << 8 | UInt16(registers.regF)
        case .registerBC: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .registerDE: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        case .registerHL: return registers.regHL
        case .registerSP: return registers.regSP
        case .registerAFAlt: return UInt16(registers.regAAlt) << 8 | UInt16(registers.regFAlt)

        }
    }
    
    func write(to registers: inout Z80Registers, value: UInt16) {
        switch self {
        case .registerAF:
            registers.regA = UInt8(value >> 8)
            registers.regF = UInt8(value & 0xFF)
        case .registerBC:
            registers.regB = UInt8(value >> 8)
            registers.regC = UInt8(value & 0xFF)
        case .registerDE:
            registers.regD = UInt8(value >> 8)
            registers.regE = UInt8(value & 0xFF)
        case .registerHL:
            registers.regHL = value
        case .registerSP:
            registers.regSP = value
        case .registerAFAlt:
            registers.regAAlt = UInt8(value >> 8)
            registers.regFAlt = UInt8(value & 0xFF)
        default:
            PC88Logger.cpu.error("不正なレジスタペアタイプです")
        }
    }
}

/// メモリアドレスオペランド
enum AddressOperand {
    case registerBC, registerDE, registerHL, direct(UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerBC: return UInt16(registers.regB) << 8 | UInt16(registers.regC)
        case .registerDE: return UInt16(registers.regD) << 8 | UInt16(registers.regE)
        case .registerHL: return registers.regHL
        case .direct(let address): return address
        }
    }
}

/// 拡張メモリアドレスオペランド
enum MemoryAddressOperand {
    case registerHL, registerBC, registerDE, registerIX(offset: Int8), registerIY(offset: Int8), direct(address: UInt16)
    
    func getAddress(from registers: Z80Registers) -> UInt16 {
        switch self {
        case .registerHL: return registers.regHL
        case .registerBC: return registers.regBC
        case .registerDE: return registers.regDE
        case .registerIX(let offset): return UInt16(Int(registers.regIX) + Int(offset))
        case .registerIY(let offset): return UInt16(Int(registers.regIY) + Int(offset))
        case .direct(let address): return address
        }
    }
}
