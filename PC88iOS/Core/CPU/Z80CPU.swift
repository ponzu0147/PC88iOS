//
//  Z80CPU.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation
import os.log

/// アイドルループ検出用のフィルタプロトコル
protocol InstructionTraceFilterProtocol {
    func shouldTrace(pc: UInt16) -> Bool
}

/// A temporary filter that limits trace count
class TemporaryTraceFilter: InstructionTraceFilterProtocol {
    weak var cpu: Z80CPU?
    let maxCount: Int
    let originalFilter: InstructionTraceFilterProtocol?
    let originalTraceEnabled: Bool
    
    init(cpu: Z80CPU, maxCount: Int, originalFilter: InstructionTraceFilterProtocol?, originalTraceEnabled: Bool) {
        self.cpu = cpu
        self.maxCount = maxCount
        self.originalFilter = originalFilter
        self.originalTraceEnabled = originalTraceEnabled
    }
    
    func shouldTrace(pc: UInt16) -> Bool {
        guard let cpu = cpu else { return false }
        cpu.incrementInstructionTraceCount()
        if cpu.getInstructionTraceCount() >= maxCount {
            cpu.setInstructionTraceEnabled(originalTraceEnabled)
            cpu.setInstructionTraceFilter(originalFilter)
            return false
        }
        return true
    }
}

/// Z80 CPUの実装
class Z80CPU: CPUExecuting {
    // レジスタ
    private var registers = Z80Registers()
    
    // メモリアクセス
    private let memory: MemoryAccessing
    
    // I/Oアクセス
    private let ioDevice: IOAccessing
    
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
    private var idleLoopStartTime: Date?
    private var idleLoopDuration: TimeInterval = 0
    private var idleLoopLastReportTime: Date?
    private var idleLoopReportInterval: TimeInterval = 5.0 // 5秒ごとにレポート
    
    // 命令トレース用プロパティ
    private var instructionTraceFilter: InstructionTraceFilterProtocol?
    
    // アイドル検出の閾値（小さいほど検出しやすい）
    private var idleDetectionThreshold: Int = 5
    
    // アイドル状態でのスリープ時間（デフォルトは1ms）
    private var idleSleepTime: TimeInterval = 0.001
    
    // アイドルループの詳細情報
    private var idleLoopContext: [String: Any] = [:]
    
    // 命令トレース機能
    private var instructionTraceEnabled = false
    private var instructionTraceCount = 0
    private let maxInstructionTraceCount = 100 // 最大トレース数
    
    // トレース機能用のアクセサメソッド
    func incrementInstructionTraceCount() {
        instructionTraceCount += 1
    }
    
    func getInstructionTraceCount() -> Int {
        return instructionTraceCount
    }
    
    func setInstructionTraceEnabled(_ enabled: Bool) {
        instructionTraceEnabled = enabled
    }
    
    func setInstructionTraceFilter(_ filter: InstructionTraceFilterProtocol?) {
        instructionTraceFilter = filter
    }
    
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
    init(memory: MemoryAccessing, ioDevice: IOAccessing, cpuClock: PC88CPUClock = PC88CPUClock()) {
        self.memory = memory
        self.ioDevice = ioDevice
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
        
        PC88Logger.cpu.info("CPUがクロックモード変更を検出: \(mode == .mode4MHz ? "4MHz" : "8MHz")")
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
            return handleIdleLoop()
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
            PC88Logger.cpu.warning("警告: CPU実行の安全上限に達しました")
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
    
    /// 命令トレースを有効化
    func enableInstructionTrace() {
        instructionTraceEnabled = true
        instructionTraceCount = 0
        PC88Logger.cpu.debug("*** 命令トレースを開始します (PC=\(String(format: "%04X", self.registers.pc))) ***")
    }
    
    /// 命令トレースを無効化
    func disableInstructionTrace() {
        instructionTraceEnabled = false
        PC88Logger.cpu.debug("*** 命令トレースを停止しました ***")
    }
    
    /// プログラムカウンタを設定
    func setProgramCounter(_ address: UInt16) {
        registers.pc = address
        PC88Logger.cpu.debug("プログラムカウンタを設定: 0x\(String(format: "%04X", address))")
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
    
    /// アイドルループを処理する
    private func handleIdleLoop() -> Int {
        // アイドルループのサイクル数を消費して、実際の命令実行をスキップ
        totalCycles = totalCycles &+ UInt64(idleLoopCycles)
        idleLoopCounter += 1
        
        // 定期的にアイドルループの状態を報告
        if idleLoopCounter % 1000 == 0 {
            printIdleLoopInfo()
        }
        
        // 定期的にアイドルループから抜け出して実際の状態を確認（500回に1回）
        if self.idleLoopCounter >= 500 {
            exitIdleLoopForStateCheck()
        } else if idleLoopCounter > 10 {
            // アイドル状態では設定された時間だけスリープしてCPU負荷を下げる
            Thread.sleep(forTimeInterval: idleSleepTime)
        }
        
        return idleLoopCycles
    }
    
    /// アイドルループから一時的に抜け出して状態を確認する
    private func exitIdleLoopForStateCheck() {
        PC88Logger.cpu.info("アイドルループから一時的に抜け出して状態を確認します (\(self.idleLoopCounter)回実行後)")
        idleLoopDetected = false
        idleLoopCounter = 0
        
        // 命令トレースを一時的に有効化して状態を確認
        let wasTraceEnabled = instructionTraceEnabled
        instructionTraceEnabled = true
        instructionTraceCount = 0
        
        // 20命令後に自動的にトレースを元の状態に戻すフィルタを設定
        let originalFilter = instructionTraceFilter
        
        instructionTraceFilter = TemporaryTraceFilter(
            cpu: self,
            maxCount: 20,
            originalFilter: originalFilter,
            originalTraceEnabled: wasTraceEnabled
        )
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
        
        // トレース処理
        handleInstructionTrace(opcode, instruction)
        
        // 未実装命令の場合は特別処理
        if let unimplemented = instruction as? UnimplementedInstruction {
            return handleUnimplementedInstruction(opcode, unimplemented)
        }
        
        // 命令の詳細なサイクル情報を取得
        currentInstructionCycles = instruction.cycleInfo
        currentMCycle = 0
        
        // 実行
        let cycles = instruction.execute(cpu: self, registers: &registers, memory: memory, inputOutput: ioDevice)
        
        // サイクル情報をリセット
        currentInstructionCycles = nil
        currentMCycle = 0
        currentTState = 0
        
        return cycles
    }
    
    /// 命令トレース処理
    private func handleInstructionTrace(_ opcode: UInt8, _ instruction: Z80Instruction) {
        guard instructionTraceEnabled && instructionTraceCount < maxInstructionTraceCount else { return }
        
        // フィルタが設定されている場合はそれを適用
        let shouldTrace = instructionTraceFilter?.shouldTrace(pc: registers.pc) ?? true
        guard shouldTrace else { return }
        
        // トレースメッセージを生成して出力
        let traceMessage = generateTraceMessage(opcode: opcode, instruction: instruction)
        PC88Logger.cpu.debug("\(traceMessage)")
        
        instructionTraceCount += 1
        
        // トレース数が最大に達したら無効化
        checkAndDisableTraceIfNeeded()
    }
    
    /// トレースメッセージを生成
    private func generateTraceMessage(opcode: UInt8, instruction: Z80Instruction) -> String {
        let pc = registers.pc
        let opcodeStr = String(format: "%02X", opcode)
        let instructionDesc = instruction.description
        
        // レジスタ情報をフォーマット
        let registerInfo = formatRegisterInfo()
        
        // メモリダンプを取得
        let memoryDump = getMemoryDumpAroundPC(pc: pc)
        
        return "TRACE[\(instructionTraceCount)]: PC=\(String(format: "%04X", pc)) " +
               "OP=\(opcodeStr) \(instructionDesc) | " +
               "\(registerInfo) | MEM=[\(memoryDump)]"
    }
    
    /// レジスタ情報をフォーマットした文字列を返す
    private func formatRegisterInfo() -> String {
        let regA = String(format: "%02X", registers.a)
        let regBC = String(format: "%04X", registers.bc)
        let regDE = String(format: "%04X", registers.de)
        let regHL = String(format: "%04X", registers.hl)
        let regSP = String(format: "%04X", registers.sp)
        let regF = String(format: "%02X", registers.f)
        
        return "A=\(regA) F=\(regF) BC=\(regBC) DE=\(regDE) HL=\(regHL) SP=\(regSP)"
    }
    
    /// PC周辺のメモリダンプを取得
    private func getMemoryDumpAroundPC(pc: UInt16) -> String {
       var memoryDump = ""
        for offset in 0..<4 {
            let addr = pc &+ UInt16(offset)
            if addr < 0xFFFF {
                let byte = memory.readByte(at: addr)
                memoryDump += String(format: "%02X ", byte)
            }
        }
        return memoryDump
    }
    
    /// トレース数が最大に達したか確認し、必要に応じて無効化
    private func checkAndDisableTraceIfNeeded() {
        if instructionTraceCount >= maxInstructionTraceCount {
            PC88Logger.cpu.debug("命令トレースを終了しました（最大数に達しました）")
            instructionTraceEnabled = false
        }
    }
    
    /// 未実装命令の処理
    private func handleUnimplementedInstruction(_ opcode: UInt8, _ instruction: UnimplementedInstruction) -> Int {
        // 安全なPCの計算
        let previousPC = registers.pc > 0 ? registers.pc - 1 : 0
        
        // 詳細なデバッグ情報を出力
        logUnimplementedInstructionWarning(opcode: opcode, pc: previousPC)
        
        // 周辺のメモリ内容を表示（命令列を確認するため）
        logMemoryDump(aroundAddress: previousPC)
        
        // レジスタ状態も表示
        logRegisterState()
        
        // PCを進めて次の命令に進む
        return instruction.cycles
    }
    
    /// 未実装命令の警告をログに出力
    private func logUnimplementedInstructionWarning(opcode: UInt8, pc: UInt16) {
        let opcodeStr = String(opcode, radix: 16, uppercase: true)
        let pcStr = String(pc, radix: 16, uppercase: true)
        PC88Logger.cpu.warning("警告: 未実装の命令 0x\(opcodeStr) at PC=0x\(pcStr)")
    }
    
    /// 指定アドレスの周辺メモリをダンプしてログに出力
    private func logMemoryDump(aroundAddress address: UInt16) {
        let startAddr = max(0, Int(address) - 5)
        let endAddr = min(0xFFFF, Int(address) + 10)
        var memoryDump = "メモリダンプ ["
        
        for addr in startAddr...endAddr {
            let byte = memory.readByte(at: UInt16(addr))
            let prefix = addr == Int(address) ? "[" : ""
            let suffix = addr == Int(address) ? "]" : ""
            let byteStr = "0x\(String(byte, radix: 16, uppercase: true))"
            memoryDump += "\(prefix)\(byteStr)\(suffix) "
        }
        
        memoryDump += "]"
        PC88Logger.cpu.debug("\(memoryDump)")
    }
    
    /// レジスタ状態をログに出力
    private func logRegisterState() {
        let regState = "A=0x\(String(registers.a, radix: 16)) " +
                      "BC=0x\(String(registers.bc, radix: 16)) " +
                      "DE=0x\(String(registers.de, radix: 16)) " +
                      "HL=0x\(String(registers.hl, radix: 16)) " +
                      "SP=0x\(String(registers.sp, radix: 16))"
        PC88Logger.cpu.debug("レジスタ状態: \(regState)")
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
            PC88Logger.cpu.warning("警告: スタックポインタがオーバーフローしました")
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
            PC88Logger.cpu.warning("警告: スタックポインタがオーバーフローしました")
        }
        memory.writeWord(value, at: registers.sp)
    }
    
    // MARK: - アイドル検出関連
    
    /// 命令履歴を更新
    private func updateInstructionHistory(pc: UInt16, opcode: UInt8) {
        // 履歴に追加
        instructionHistory.append((pc: pc, opcode: opcode))
        
        // 履歴が長すぎる場合は古いものを削除
        let maxHistorySize = 20 // 最大20命令を記録
        if instructionHistory.count > maxHistorySize {
            instructionHistory.removeFirst()
        }
        
        // アイドルループの検出
        detectIdleLoop()
    }
    
}

// MARK: - Z80CPU Extension for Idle Loop Detection
extension Z80CPU {
    /// アイドルループを検出する
    private func detectIdleLoop() {
        // 履歴が少なすぎる場合は検出しない
        guard instructionHistory.count >= idleDetectionThreshold * 2 else { return }
        
        // 短いループを検出（閾値に基づいて検出範囲を調整）
        // 履歴が十分にある場合のみ
        for loopLength in 2...idleDetectionThreshold where instructionHistory.count >= loopLength * 2 {
            // 最新のloopLength命令と、その前のloopLength命令を比較
            let recentInstructions = Array(instructionHistory.suffix(loopLength))
            let previousInstructions = Array(instructionHistory.suffix(loopLength * 2).prefix(loopLength))
            
            // PCとオペコードが一致するか確認
            var isLoop = true
            for index in 0..<loopLength {
                if recentInstructions[index].pc != previousInstructions[index].pc || 
                   recentInstructions[index].opcode != previousInstructions[index].opcode {
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
                idleLoopStartTime = Date()
                idleLoopLastReportTime = idleLoopStartTime
                
                // ループの周辺メモリ状態を記録
                captureIdleLoopContext()
                
                // ループ情報を出力
                printIdleLoopInfo(isInitialDetection: true)
                return
            }
        }
    
    }
    
    /// アイドルループの周辺コンテキストを取得
    private func captureIdleLoopContext() {
        // レジスタ状態を記録
        idleLoopContext["registers"] = [
            "a": registers.a,
            "bc": registers.bc,
            "de": registers.de,
            "hl": registers.hl,
            "sp": registers.sp,
            "pc": idleLoopPC,
            "ix": registers.ix,
            "iy": registers.iy
            // Shadow registers are not directly accessible
        ]
        
        // フラグ状態を記録
        let flags = registers.f
        idleLoopContext["flags"] = [
            "s": (flags & 0x80) != 0,
            "z": (flags & 0x40) != 0,
            "h": (flags & 0x10) != 0,
            "p": (flags & 0x04) != 0,
            "n": (flags & 0x02) != 0,
            "c": (flags & 0x01) != 0
        ]
        
        // 周辺メモリの状態を記録
        var memoryDump: [String: UInt8] = [:]
        let memoryRangeStart = max(0, Int(idleLoopPC) - 16)
        let memoryRangeEnd = min(0xFFFF, Int(idleLoopPC) + 16)
        
        for addr in memoryRangeStart...memoryRangeEnd {
            memoryDump[String(format: "0x%04X", addr)] = readMemory(address: UInt16(addr))
        }
        idleLoopContext["memory"] = memoryDump
        
        // スタックの状態を記録（SPから数バイト）
        var stackDump: [String: UInt8] = [:]
        let stackStart = Int(registers.sp)
        let stackEnd = min(0xFFFF, stackStart + 16)
        
        for addr in stackStart...stackEnd {
            stackDump[String(format: "0x%04X", addr)] = readMemory(address: UInt16(addr))
        }
        idleLoopContext["stack"] = stackDump
    }
    
    /// アイドルループのサイクル数を計算
    private func calculateIdleLoopCycles() {
        idleLoopCycles = 0
        
        for opcode in idleLoopInstructions {
            // 命令を実行せずにサイクル数だけ取得
            let instruction = decoder.decode(opcode, memory: memory, pc: 0)
            idleLoopCycles += instruction.cycles
        }
    }
    
    /// アイドルループ情報を出力
    private func printIdleLoopInfo(isInitialDetection: Bool = false) {
        let now = Date()
        
        // 初回検出時または一定間隔でのみ詳細情報を出力
        if isInitialDetection || idleLoopLastReportTime == nil || 
           (idleLoopLastReportTime.map { now.timeIntervalSince($0) } ?? 0) >= idleLoopReportInterval {
            
            // 経過時間を計算
            if let startTime = idleLoopStartTime {
                idleLoopDuration = now.timeIntervalSince(startTime)
            }
            
            // ループ情報を出力
            PC88Logger.cpu.info("===== IDLE LOOP DETECTED =====")
            PC88Logger.cpu.info("PC: \(String(format: "0x%04X", self.idleLoopPC))")
            PC88Logger.cpu.info("Loop Length: \(self.idleLoopLength) instructions")
            PC88Logger.cpu.info("Loop Cycles: \(self.idleLoopCycles) cycles")
            PC88Logger.cpu.info("Duration: \(String(format: "%.2f", self.idleLoopDuration)) seconds")
            PC88Logger.cpu.info("Iterations: \(self.idleLoopCounter)")
            
            // 命令列を出力
            PC88Logger.cpu.info("Instructions:")
            for (index, opcode) in idleLoopInstructions.enumerated() {
                let pc = (idleLoopPC + UInt16(index)) & 0xFFFF
                let instruction = decoder.decode(opcode, memory: memory, pc: pc)
                PC88Logger.cpu.info("  \(String(format: "0x%04X", pc)): \(String(format: "%02X", opcode)) - \(instruction.description)")
            }
            
            // レジスタ状態を出力
            if let registers = idleLoopContext["registers"] as? [String: Any] {
                PC88Logger.cpu.info("Registers:")
                for (reg, value) in registers {
                    if let val = value as? UInt16 {
                        PC88Logger.cpu.info("  \(reg): \(String(format: "0x%04X", val))")
                    } else if let val = value as? UInt8 {
                        PC88Logger.cpu.info("  \(reg): \(String(format: "0x%02X", val))")
                    } else if let val = value as? Bool {
                        PC88Logger.cpu.info("  \(reg): \(val)")
                    }
                }
            }
            
            PC88Logger.cpu.info("==============================")
            
            // レポート時間を更新
            idleLoopLastReportTime = now
        }
    }
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
    func readIO(port portAddress: UInt16) -> UInt8 {
        // クロックモードに応じたI/Oアクセス時間の調整
        _ = cpuClock.getClockImpact(for: .ioPort)
        // I/Oポートアクセスは完全にクロックの影響を受ける
        
        // UInt8にキャストしてポート番号を渡す
        return ioDevice.readPort(UInt8(portAddress & 0xFF))
    }
    
    /// I/Oポートに書き込み
    func writeIO(port portAddress: UInt16, value: UInt8) {
        // クロックモードに応じたI/Oアクセス時間の調整
        _ = cpuClock.getClockImpact(for: .ioPort)
        // I/Oポートアクセスは完全にクロックの影響を受ける
        
        // UInt8にキャストしてポート番号を渡す
        ioDevice.writePort(UInt8(portAddress & 0xFF), value: value)
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
        case .afPair: return registers.af
        case .bcPair: return registers.bc
        case .dePair: return registers.de
        case .hlPair: return registers.hl
        case .ixPair: return registers.ix
        case .iyPair: return registers.iy
        case .sp: return registers.sp
        case .pc: return registers.pc
        }
    }
    
    /// レジスタ値の設定（命令実装から使用）
    func setRegister(_ reg: RegisterType, value: UInt16) {
        switch reg {
        case .afPair: registers.af = value
        case .bcPair: registers.bc = value
        case .dePair: registers.de = value
        case .hlPair: registers.hl = value
        case .ixPair: registers.ix = value
        case .iyPair: registers.iy = value
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
    case afPair, bcPair, dePair, hlPair, ixPair, iyPair, sp, pc
}
