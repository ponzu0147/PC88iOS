//
//  Z80CPU.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// Z80 CPUの実装
class Z80CPU: CPUExecuting {
    // レジスタ
    private var registers = Z80Registers()
    
    // メモリアクセス
    private let memory: MemoryAccessing
    
    // I/Oアクセス
    private let io: IOAccessing
    
    // 命令デコーダ
    private let decoder = Z80InstructionDecoder()
    
    // 割り込み有効フラグ
    private var interruptEnabled = false
    
    // 保留中の割り込み
    private var pendingInterrupt: InterruptType?
    
    // ホルトフラグ
    private var halted = false
    
    /// 初期化
    init(memory: MemoryAccessing, io: IOAccessing) {
        self.memory = memory
        self.io = io
    }
    
    /// CPUの初期化
    func initialize() {
        reset()
    }
    
    /// リセット
    func reset() {
        registers.reset()
        interruptEnabled = false
        pendingInterrupt = nil
        halted = false
    }
    
    /// 1ステップ実行
    func executeStep() -> Int {
        // 割り込み処理
        if let interrupt = pendingInterrupt, interruptEnabled {
            return handleInterrupt(interrupt)
        }
        
        // ホルト状態の場合
        if halted {
            return 4 // ホルト中は4Tステート消費
        }
        
        // 命令フェッチ
        let opcode = memory.readByte(at: registers.pc)
        registers.pc &+= 1
        
        // 命令実行
        return executeInstruction(opcode)
    }
    
    /// 指定サイクル数実行
    func executeCycles(_ cycles: Int) -> Int {
        var remainingCycles = cycles
        var executedCycles = 0
        
        while remainingCycles > 0 {
            let cyclesUsed = executeStep()
            executedCycles += cyclesUsed
            remainingCycles -= cyclesUsed
        }
        
        return executedCycles
    }
    
    /// 割り込み要求
    func requestInterrupt(_ type: InterruptType) {
        pendingInterrupt = type
    }
    
    /// 割り込み有効/無効設定
    func setInterruptEnabled(_ enabled: Bool) {
        interruptEnabled = enabled
    }
    
    // MARK: - Private Methods
    
    /// 命令実行
    private func executeInstruction(_ opcode: UInt8) -> Int {
        // デコード
        let instruction = decoder.decode(opcode, memory: memory, pc: registers.pc)
        
        // 実行
        let cycles = instruction.execute(cpu: self, registers: &registers, memory: memory, io: io)
        
        return cycles
    }
    
    /// 割り込み処理
    private func handleInterrupt(_ type: InterruptType) -> Int {
        pendingInterrupt = nil
        halted = false
        
        switch type {
        case .nmi:
            // NMI処理
            pushWord(registers.pc)
            registers.pc = 0x0066
            return 11
            
        case .int:
            // INT処理（モード1）
            if interruptEnabled {
                interruptEnabled = false
                pushWord(registers.pc)
                registers.pc = 0x0038
                return 13
            }
            return 0
        }
    }
    
    /// スタックにワード値をプッシュ
    private func pushWord(_ value: UInt16) {
        registers.sp &-= 2
        memory.writeWord(value, at: registers.sp)
    }
}

// MARK: - Z80CPU Extension for Instruction Access
extension Z80CPU {
    /// レジスタ値の取得（命令実装から使用）
    func getRegister(_ reg: RegisterType) -> UInt16 {
        switch reg {
        case .af: return registers.af
        case .bc: return registers.bc
        case .de: return registers.de
        case .hl: return registers.hl
        case .ix: return registers.ix
        case .iy: return registers.iy
        case .sp: return registers.sp
        case .pc: return registers.pc
        }
    }
    
    /// レジスタ値の設定（命令実装から使用）
    func setRegister(_ reg: RegisterType, value: UInt16) {
        switch reg {
        case .af: registers.af = value
        case .bc: registers.bc = value
        case .de: registers.de = value
        case .hl: registers.hl = value
        case .ix: registers.ix = value
        case .iy: registers.iy = value
        case .sp: registers.sp = value
        case .pc: registers.pc = value
        }
    }
}

/// レジスタタイプ
enum RegisterType {
    case af, bc, de, hl, ix, iy, sp, pc
}
