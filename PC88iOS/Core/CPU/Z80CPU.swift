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
    
    // アイドル検出用プロパティ
    private var idleDetectionEnabled = true
    private var idleLoopDetected = false
    private var idleLoopPC: UInt16 = 0
    private var idleLoopLength: Int = 0
    private var idleLoopInstructions: [UInt8] = []
    private var idleLoopCycles: Int = 0
    private var idleLoopCounter: Int = 0
    private var instructionHistory: [(pc: UInt16, opcode: UInt8)] = []
    
    // アイドル検出の閾値（小さいほど検出しやすい）
    private var idleDetectionThreshold: Int = 5
    
    // アイドル状態でのスリープ時間（デフォルトは1ms）
    private var idleSleepTime: TimeInterval = 0.001
    
    // CPUクロック管理
    let cpuClock: PC88CPUClock
    
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
        
        // クロック変更に伴う内部状態の調整
        resetInstructionTiming()
    }
    
    /// 現在のCPUクロックモードを取得
    func getClockMode() -> PC88CPUClock.ClockMode {
        return self.cpuClock.currentMode
    }
    
    /// CPUクロックを設定
    func setCPUClock(_ clock: PC88CPUClock) {
        // 外部からCPUクロックを設定する場合の処理
        // 現在は特に何もしないが、必要に応じて実装を追加する
    }
    
    /// クロックモード変更時の処理
    private func handleClockModeChanged(_ mode: PC88CPUClock.ClockMode) {
        // 命令実行タイミングをリセット
        resetInstructionTiming()
        
        print("CPUがクロックモード変更を検出: \(mode == .mode4MHz ? "4MHz" : "8MHz")")
    }
    
    /// 命令実行タイミングをリセット
    private func resetInstructionTiming() {
        // 命令タイミングに関する内部状態をリセット
    }
    
    /// CPUの初期化
    func initialize() {
        reset()
        // アイドル検出の初期設定
        resetIdleDetection()
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
        resetIdleDetection()
    }
    
    /// アイドル検出をリセット
    private func resetIdleDetection() {
        idleLoopDetected = false
        idleLoopPC = 0
        idleLoopLength = 0
        idleLoopInstructions = []
        idleLoopCycles = 0
        idleLoopCounter = 0
        instructionHistory = []
    }
    
    /// 1ステップ実行
    func executeStep() -> Int {
        // 割り込み処理
        if let interrupt = pendingInterrupt, interruptEnabled {
            // 割り込みが発生したらアイドル検出をリセット
            if idleLoopDetected {
                resetIdleDetection()
            }
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
        
        // アイドルループが検出されている場合
        if idleLoopDetected {
            // アイドルループのサイクル数を消費して、実際の命令実行をスキップ
            totalCycles = totalCycles &+ UInt64(idleLoopCycles)
            idleLoopCounter += 1
            
            // 定期的にアイドルループから抜け出して実際の状態を確認（100回に1回）
            if idleLoopCounter >= 100 {
                idleLoopDetected = false
                idleLoopCounter = 0
            } else if idleLoopCounter > 10 {
                // アイドル状態では設定された時間だけスリープしてCPU負荷を下げる
                Thread.sleep(forTimeInterval: idleSleepTime)
            }
            
            return idleLoopCycles
        }
        
        // 命令フェッチ
        let pc = registers.pc
        let opcode = memory.readByte(at: pc)
        registers.pc = registers.pc &+ 1 // 安全な加算を使用
        
        // アイドル検出のための履歴更新
        if idleDetectionEnabled {
            updateInstructionHistory(pc: pc, opcode: opcode)
        }
        
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
        
        // アイドルループが検出されている場合は、サイクル数を一括で消費
        if idleLoopDetected && !halted && pendingInterrupt == nil {
            // アイドルループのサイクル数を計算
            let loopCount = adjustedCycles / idleLoopCycles
            let consumedCycles = loopCount * idleLoopCycles
            
            // 定期的にアイドルループから抜け出して実際の状態を確認
            idleLoopCounter += loopCount
            if idleLoopCounter >= 100 {
                idleLoopDetected = false
                idleLoopCounter = 0
                
                // 残りのサイクルを通常実行
                let remainingCycles = adjustedCycles - consumedCycles
                if remainingCycles > 0 {
                    let normalExecutedCycles = executeNormalCycles(remainingCycles)
                    return consumedCycles + normalExecutedCycles
                }
            }
            
            totalCycles = totalCycles &+ UInt64(consumedCycles)
            return consumedCycles
        }
        
        // 通常のサイクル実行
        return executeNormalCycles(adjustedCycles)
    }
    
    /// 通常モードでサイクル実行
    private func executeNormalCycles(_ cycles: Int) -> Int {
        var remainingCycles = cycles
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
    
    /// プログラムカウンタを設定
    func setProgramCounter(_ address: UInt16) {
        registers.pc = address
        print("プログラムカウンタを設定: 0x\(String(format: "%04X", address))")
    }
    
    /// クロックモードに基づいてサイクル数を調整
    private func adjustCyclesForClockMode(_ cycles: Int) -> Int {
        // PC88CPUClockのメソッドを使用して適切に調整
        return cpuClock.adjustCycles(cycles, impact: .full)
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
        // ホルト状態になったらアイドル検出をリセット
        resetIdleDetection()
    }
    
    /// CPUがホルト状態かどうかを取得
    func isHalted() -> Bool {
        return halted
    }
    
    /// アイドル検出の有効/無効を設定
    func setIdleDetectionEnabled(_ enabled: Bool) {
        idleDetectionEnabled = enabled
        if !enabled {
            resetIdleDetection()
        }
    }
    
    /// アイドル検出が有効かどうかを取得
    func isIdleDetectionEnabled() -> Bool {
        return idleDetectionEnabled
    }
    
    /// アイドル状態でのスリープ時間を設定
    func setIdleSleepTime(_ sleepTime: TimeInterval) {
        idleSleepTime = max(0.0001, sleepTime) // 最少0.1ms以上に制限
    }
    
    /// アイドル状態でのスリープ時間を取得
    func getIdleSleepTime() -> TimeInterval {
        return idleSleepTime
    }
    
    /// アイドル検出の閾値を設定
    /// - Parameter threshold: 閾値（小さいほど検出しやすい、デフォルトは5）
    func setIdleDetectionThreshold(_ threshold: Int) {
        idleDetectionThreshold = max(2, min(10, threshold)) // 2〜10の範囲に制限
    }
    
    /// アイドル検出の閾値を取得
    func getIdleDetectionThreshold() -> Int {
        return idleDetectionThreshold
    }
    
    /// アイドルループが検出されているかどうかを取得
    func isIdleLoopDetected() -> Bool {
        return idleLoopDetected
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
                internalCycles: 1
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
                    internalCycles: 2
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
    
    // MARK: - アイドル検出関連
    
    /// 命令履歴を更新
    private func updateInstructionHistory(pc: UInt16, opcode: UInt8) {
        // 履歴に追加
        instructionHistory.append((pc: pc, opcode: opcode))
        
        // 履歴が長すぎる場合は古いものを削除
        if instructionHistory.count > 20 { // 最大20命令を記録
            instructionHistory.removeFirst()
        }
        
        // アイドルループの検出
        detectIdleLoop()
    }
    
    /// アイドルループを検出
    private func detectIdleLoop() {
        // 履歴が少なすぎる場合は検出しない
        guard instructionHistory.count >= idleDetectionThreshold * 2 else { return }
        
        // 短いループを検出（閾値に基づいて検出範囲を調整）
        for loopLength in 2...idleDetectionThreshold {
            // 履歴が十分にある場合のみ
            if instructionHistory.count >= loopLength * 2 {
                // 最新のloopLength命令と、その前のloopLength命令を比較
                let recentInstructions = Array(instructionHistory.suffix(loopLength))
                let previousInstructions = Array(instructionHistory.suffix(loopLength * 2).prefix(loopLength))
                
                // PCとオペコードが一致するか確認
                var isLoop = true
                for i in 0..<loopLength {
                    if recentInstructions[i].pc != previousInstructions[i].pc || 
                       recentInstructions[i].opcode != previousInstructions[i].opcode {
                        isLoop = false
                        break
                    }
                }
                
                // ループが検出された場合
                if isLoop {
                    // 最初のPCを記録
                    idleLoopPC = recentInstructions[0].pc
                    idleLoopLength = loopLength
                    
                    // ループの命令を記録
                    idleLoopInstructions = recentInstructions.map { $0.opcode }
                    
                    // ループのサイクル数を計算
                    calculateIdleLoopCycles()
                    
                    // ループを検出したことを記録
                    idleLoopDetected = true
                    idleLoopCounter = 0
                    
                    print("アイドルループを検出: PC=0x\(String(idleLoopPC, radix: 16, uppercase: true)), 長さ=\(idleLoopLength), サイクル数=\(idleLoopCycles)")
                    return
                }
            }
        }
    }
    
    /// アイドルループのサイクル数を計算
    private func calculateIdleLoopCycles() {
        // 簡易的な計算: 各命令の平均サイクル数 * ループ長
        // 実際には各命令のサイクル数を正確に計算する必要がある
        idleLoopCycles = 4 * idleLoopLength // 仮の値として平均4サイクルと仮定
    }
    
    // アイドル検出の有効/無効設定と状態取得メソッドは上部で定義済み
}

// MARK: - Z80CPU Extension for Memory and IO Access
extension Z80CPU {
    /// メモリから読み込み
    func readMemory(address: UInt16) -> UInt8 {
        // VRAM領域かどうかを判定
        let isVRAMAccess = isVRAMAddress(address)
        
        // クロックモードに応じたメモリアクセス時間の調整
        let deviceType: PC88CPUClock.DeviceType = isVRAMAccess ? .vram : .memory
        _ = cpuClock.getClockImpact(for: deviceType)
        
        // 8MHzモードでVRAMアクセスの場合、ウェイトを挿入する可能性がある
        // 実際のウェイト処理はPC88メモリシステム側で実装
        
        return memory.readByte(at: address)
    }
    
    /// メモリに書き込み
    func writeMemory(address: UInt16, value: UInt8) {
        // VRAM領域かどうかを判定
        let isVRAMAccess = isVRAMAddress(address)
        
        // クロックモードに応じたメモリアクセス時間の調整
        let deviceType: PC88CPUClock.DeviceType = isVRAMAccess ? .vram : .memory
        _ = cpuClock.getClockImpact(for: deviceType)
        
        // 8MHzモードでVRAMアクセスの場合、ウェイトを挿入する可能性がある
        // 実際のウェイト処理はPC88メモリシステム側で実装
        
        memory.writeByte(value, at: address)
    }
    
    /// I/Oポートから読み込み
    func readIO(port: UInt16) -> UInt8 {
        // クロックモードに応じたI/Oアクセス時間の調整
        _ = cpuClock.getClockImpact(for: .ioPort)
        // I/Oポートアクセスは完全にクロックの影響を受ける
        
        // UInt8にキャストしてポート番号を渡す
        return io.readPort(UInt8(port & 0xFF))
    }
    
    /// I/Oポートに書き込み
    func writeIO(port: UInt16, value: UInt8) {
        // クロックモードに応じたI/Oアクセス時間の調整
        _ = cpuClock.getClockImpact(for: .ioPort)
        // I/Oポートアクセスは完全にクロックの影響を受ける
        
        // UInt8にキャストしてポート番号を渡す
        io.writePort(UInt8(port & 0xFF), value: value)
    }
    
    /// アドレスがVRAM領域かどうかを判定
    private func isVRAMAddress(_ address: UInt16) -> Bool {
        // PC-8801のVRAM領域
        // テキストVRAM: 0xC000-0xCFFF
        // グラフィックVRAM: 0x8000-0xBFFF (機種によって異なる)
        return (address >= 0xC000 && address <= 0xCFFF) || 
               (address >= 0x8000 && address <= 0xBFFF)
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
    
    /// プログラムカウンタ（PC）を設定
    func setPC(_ value: UInt16) {
        registers.pc = value
    }
    
    /// スタックポインタ（SP）を設定
    func setSP(_ value: UInt16) {
        registers.sp = value
    }
    
    /// ホルト状態を設定
    func setHalted(_ state: Bool) {
        halted = state
    }
    
    /// 現在のプログラムカウンタ（PC）を取得
    func getPC() -> UInt16 {
        return registers.pc
    }
    
    /// 現在のスタックポインタ（SP）を取得
    func getSP() -> UInt16 {
        return registers.sp
    }
}

/// レジスタタイプ
enum RegisterType {
    case af, bc, de, hl, ix, iy, sp, pc
}
