// 修正版executeOs関数
func executeOs(startAddress: Int, cpu: Any? = nil) -> Bool {
    PC88Logger.disk.debug("D88DiskImage.executeOs: OSの実行を開始します (開始アドレス: 0x\(String(format: "%04X", startAddress)))")
    
    // 実際のCPUが提供されている場合は、プログラムカウンタを設定して実行開始
    if let cpuController = cpu as? CpuControlling {
        cpuController.setProgramCounter(address: startAddress)
        cpuController.startExecution()
        PC88Logger.cpu.debug("  CPU実行を開始しました (PC=0x\(String(format: "%04X", startAddress)))")
    } else {
        PC88Logger.cpu.warning("  CPU制御が提供されていないか、互換性がないため、仮想的な実行のみ行います")
    }
    
    return true
}
