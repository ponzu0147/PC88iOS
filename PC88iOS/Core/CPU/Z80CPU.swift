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
    
    // CPUクロック管理
    private let cpuClock: PC88CPUClock
    
    // 実行した累積サイクル数
    private var totalCycles: UInt64 = 0
    
    // 現在のマシンサイクル
    private var currentMCycle: Int = 0
    
    // 現在のTステート
    private var currentTState: Int = 0
    
    // 現在実行中の命令のサイクル情報
    private var currentInstructionCycles: InstructionCycles?
    
    /// 初期化
    init(memory: MemoryAccessing, io: IOAccessing, cpuClock: PC88CPUClock = PC88CPUClock()) {
        self.memory = memory
        self.io = io
        self.cpuClock = cpuClock
        
        // クロックモード変更時の処理を設定
        self.cpuClock.onModeChanged = { [weak self] newMode in
            self?.handleClockModeChanged(newMode)
        }
    }
    
    /// 現在のCPUクロックモードを取得
    func getCurrentClockMode() -> PC88CPUClock.ClockMode {
        return cpuClock.currentMode
    }
    
    /// CPUクロックモードを設定
    func setClockMode(_ mode: PC88CPUClock.ClockMode) {
        // 明示的にPC88CPUClockのメソッドを呼び出す
        self.cpuClock.setClockMode(mode)
    }
    
    /// CPUクロックを設定
    func setCPUClock(_ clock: PC88CPUClock) {
        // 外部からCPUクロックを設定する場合の処理
        // 現在は特に何もしないが、必要に応じて実装を追加する
    }
    
    /// クロックモード変更時の処理
    private func handleClockModeChanged(_ mode: PC88CPUClock.ClockMode) {
        // 必要な処理があればここに追加
        print("CPUがクロックモード変更を検出: \(mode == .mode4MHz ? "4MHz" : "8MHz")")
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
        totalCycles = 0
        currentMCycle = 0
        currentTState = 0
        currentInstructionCycles = nil
    }
    
    /// 1ステップ実行
    func executeStep() -> Int {
        // 割り込み処理
        if let interrupt = pendingInterrupt, interruptEnabled {
            let cycles = handleInterrupt(interrupt)
            totalCycles = totalCycles &+ UInt64(cycles)
            return cycles
        }
        
        // ホルト状態の場合
        if halted {
            // ホルト中はオペコードフェッチサイクルと同じサイクル数を消費
            let haltCycles = MachineCycleType.opcodeFetch.tStates
            totalCycles = totalCycles &+ UInt64(haltCycles)
            return haltCycles
        }
        
        // 命令フェッチ
        let opcode = memory.readByte(at: registers.pc)
        registers.pc = registers.pc &+ 1 // 安全な加算を使用
        
        // 命令実行
        let cycles = executeInstruction(opcode)
        totalCycles = totalCycles &+ UInt64(cycles)
        return cycles
    }
    
    /// 指定サイクル数実行
    func executeCycles(_ cycles: Int) -> Int {
        // サイクル数が負の場合は0を返す
        guard cycles > 0 else { return 0 }
        
        // クロックモードに基づいてサイクル数を調整
        let adjustedCycles = adjustCyclesForClockMode(cycles)
        
        var remainingCycles = adjustedCycles
        var executedCycles = 0
        
        // 無限ループを防止するためのカウンタ
        var safetyCounter = 0
        let maxIterations = 1_000_000 // 安全な上限値
        
        while remainingCycles > 0 && safetyCounter < maxIterations {
            let cyclesUsed = executeStep()
            // 安全な整数演算
            executedCycles = executedCycles &+ cyclesUsed
            
            // cyclesUsed、0以下の場合は最小値を1にする
            let cyclesDeduct = cyclesUsed > 0 ? cyclesUsed : 1
            remainingCycles = remainingCycles &- cyclesDeduct
            
            safetyCounter += 1
        }
        
        // 安全カウンタが上限に達した場合は警告を出す
        if safetyCounter >= maxIterations {
            print("警告: CPU実行の安全上限に達しました")
        }
        
        return executedCycles
    }
    
    /// 累積サイクル数を取得
    func getTotalCycles() -> UInt64 {
        return totalCycles
    }
    
    /// 現在のマシンサイクルを取得
    func getCurrentMCycle() -> Int {
        return currentMCycle
    }
    
    /// 現在のTステートを取得
    func getCurrentTState() -> Int {
        return currentTState
    }
    
    /// クロックモードに基づいてサイクル数を調整
    private func adjustCyclesForClockMode(_ cycles: Int) -> Int {
        // 8MHzモードの場合は実行サイクル数を2倍にする
        if cpuClock.currentMode == .mode8MHz {
            return cycles * 2
        }
        return cycles
    }
    
    /// 割り込み要求
    func requestInterrupt(_ type: InterruptType) {
        pendingInterrupt = type
    }
    
    /// 割り込み有効/無効設定
    func setInterruptEnabled(_ enabled: Bool) {
        interruptEnabled = enabled
    }
    
    /// 割り込み禁止
    func disableInterrupts() {
        interruptEnabled = false
    }
    
    /// CPUをホルト状態にする
    func halt() {
        halted = true
    }
    
    /// CPUがホルト状態かどうかを取得
    func isHalted() -> Bool {
        return halted
    }
    
    /// 相対ジャンプ
    func jump(by offset: Int8) {
        // PCにオフセットを加算
        registers.pc = UInt16(Int(registers.pc) + Int(offset))
    }
    
    // MARK: - Private Methods
    
    /// 命令実行
    private func executeInstruction(_ opcode: UInt8) -> Int {
        // デコード
        let instruction = decoder.decode(opcode, memory: memory, pc: registers.pc)
        
        // 未実装命令の場合は特別処理
        if let unimplemented = instruction as? UnimplementedInstruction {
            // 安全なPCの計算
            let previousPC = registers.pc > 0 ? registers.pc - 1 : 0
            print("警告: 未実装の命令 0x\(String(opcode, radix: 16, uppercase: true)) at PC=0x\(String(previousPC, radix: 16, uppercase: true))")
            // PCを進めて次の命令に進む
            return unimplemented.cycles
        }
        
        // 命令の詳細なサイクル情報を取得
        currentInstructionCycles = instruction.cycleInfo
        currentMCycle = 0
        
        // 実行
        let cycles = instruction.execute(cpu: self, registers: &registers, memory: memory, io: io)
        
        // サイクル情報をリセット
        currentInstructionCycles = nil
        currentMCycle = 0
        currentTState = 0
        
        return cycles
    }
    
    /// 割り込み処理
    private func handleInterrupt(_ type: InterruptType) -> Int {
        pendingInterrupt = nil
        halted = false
        
        switch type {
        case .nmi:
            // NMI処理
            // NMIは割り込み応答サイクルとメモリ書き込みサイクルを2回
            let cycles = InstructionCycles.standard(
                opcodeFetch: false,
                memoryWrites: 2,
                internalCycles: 1,
                interruptAcknowledge: true
            )
            pushWord(registers.pc)
            registers.pc = 0x0066
            return cycles.tStates
            
        case .int:
            // INT処理（モード1）
            if interruptEnabled {
                interruptEnabled = false
                // INTは割り込み応答サイクルとメモリ書き込みサイクルを2回、内部処理サイクル
                let cycles = InstructionCycles.standard(
                    opcodeFetch: false,
                    memoryWrites: 2,
                    internalCycles: 2,
                    interruptAcknowledge: true
                )
                pushWord(registers.pc)
                registers.pc = 0x0038
                return cycles.tStates
            }
            return 0
        }
    }
    
    /// スタックにワード値をプッシュ
    func pushWord(_ value: UInt16, to registers: inout Z80Registers, memory: MemoryAccessing) {
        // 安全な減算処理
        if registers.sp >= 2 {
            registers.sp = registers.sp &- 2
        } else {
            // オーバーフローを防止するため、スタックポインタをメモリの最上部に設定
            registers.sp = 0xFFFF
            print("警告: スタックポインタがオーバーフローしました")
        }
        memory.writeWord(value, at: registers.sp)
    }
    
    /// スタックにワード値をプッシュ (内部用)
    private func pushWord(_ value: UInt16) {
        // 安全な減算処理
        if registers.sp >= 2 {
            registers.sp = registers.sp &- 2
        } else {
            // オーバーフローを防止するため、スタックポインタをメモリの最上部に設定
            registers.sp = 0xFFFF
            print("警告: スタックポインタがオーバーフローしました")
        }
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
