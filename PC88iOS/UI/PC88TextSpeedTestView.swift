//
//  PC88TextSpeedTestView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/31.
//

import SwiftUI

/// PC-88のテキスト表示速度テスト画面
struct PC88TextSpeedTestView: View {
    /// PC-88画面
    @State private var screen = PC88ScreenBase()
    
    /// テキスト表示速度テスト
    @State private var speedTest: PC88TextSpeedTest?
    
    /// CPUクロック
    @State private var cpuClock = PC88CPUClock()
    
    /// Z80 CPU
    @State private var cpu: Z80CPU?
    
    /// メモリアクセス
    @State private var memory: PC88Memory?
    
    /// I/Oアクセス
    @State private var io: PC88IO?
    
    /// 進捗率（0.0～1.0）
    @State private var progress: Double = 0.0
    
    /// テスト実行中かどうか
    @State private var isRunning: Bool = false
    
    /// 選択されたモード
    @State private var selectedMode: PC88CPUClock.ClockMode = .mode4MHz
    
    /// 速度倍率
    @State private var speedMultiplier: Double = 1.0
    
    /// 表示用のイメージ
    @State private var displayImage: CGImage?
    
    /// 現在のクロック周波数表示
    @State private var clockFrequency: String = "4MHz"
    
    /// リセット中かどうか
    @State private var isResetting: Bool = false
    
    /// リセットカウンター
    @State private var resetCounter: Int = 0
    
    /// リセットタイマー
    @State private var resetTimer: Timer?
    
    /// CPU実行タイマー
    @State private var cpuTimer: Timer?
    
    var body: some View {
        VStack {
            // 現在のクロック周波数表示
            Text("現在のクロック: \(clockFrequency)")
                .font(.headline)
                .foregroundColor(isRunning ? .green : .primary)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isRunning ? Color.green.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            
            // 画面表示エリア
            if let image = displayImage {
                Image(image, scale: 1.0, label: Text("PC-88 Screen"))
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .border(Color.gray, width: 2)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(4/3, contentMode: .fit)
                    .border(Color.gray, width: 2)
            }
            
            // 進捗バー
            ProgressView(value: progress)
                .padding()
            
            // コントロールパネル
            HStack {
                // モード選択
                VStack(alignment: .leading) {
                    Text("CPUモード:")
                    Picker("", selection: $selectedMode) {
                        Text("4MHz (N-BASIC)").tag(PC88CPUClock.ClockMode.mode4MHz)
                        Text("8MHz (N88-BASIC)").tag(PC88CPUClock.ClockMode.mode8MHz)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(isRunning || isResetting)
                    .frame(width: 250)
                    .onChange(of: selectedMode) { oldValue, newValue in
                        cpuClock.setClockMode(newValue)
                        clockFrequency = newValue == .mode4MHz ? "4MHz" : "8MHz"
                        if !isRunning {
                            simulateReset()
                        }
                    }
                    
                    // クロックモード切り替えボタン
                    HStack {
                        Button(action: {
                            selectedMode = .mode4MHz
                            cpuClock.setClockMode(.mode4MHz)
                            clockFrequency = "4MHz"
                            simulateReset()
                        }) {
                            Text("4MHzモード")
                                .frame(width: 100)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isRunning || isResetting || selectedMode == .mode4MHz)
                        
                        Button(action: {
                            selectedMode = .mode8MHz
                            cpuClock.setClockMode(.mode8MHz)
                            clockFrequency = "8MHz"
                            simulateReset()
                        }) {
                            Text("8MHzモード")
                                .frame(width: 100)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isRunning || isResetting || selectedMode == .mode8MHz)
                    }
                    .padding(.top, 5)
                }
                
                Spacer()
                
                // 速度調整スライダー
                VStack {
                    Text("速度: x\(String(format: "%.1f", speedMultiplier))")
                    Slider(value: $speedMultiplier, in: 0.1...10.0, step: 0.1)
                        .onChange(of: speedMultiplier) { oldValue, newValue in
                            speedTest?.setDisplaySpeed(multiplier: newValue)
                            cpuClock.speedMultiplier = newValue
                        }
                        .frame(width: 200)
                        .disabled(isResetting)
                }
                
                Spacer()
                
                // ボタン群
                VStack(spacing: 10) {
                    // 実行/停止ボタン
                    Button(action: {
                        if isRunning {
                            stopTest()
                        } else {
                            startTest()
                        }
                    }) {
                        Text(isRunning ? "停止" : "実行")
                            .frame(width: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isResetting)
                    
                    // リセットボタン
                    Button(action: {
                        simulateReset()
                    }) {
                        Text("リセット")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRunning || isResetting)
                    
                    // 4MHzモード切り替えボタン
                    Button(action: {
                        selectedMode = .mode4MHz
                        cpuClock.setClockMode(.mode4MHz)
                        clockFrequency = "4MHz"
                        simulateReset()
                    }) {
                        Text("4MHz")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(isRunning || isResetting || selectedMode == .mode4MHz)
                    
                    // 8MHzモード切り替えボタン
                    Button(action: {
                        selectedMode = .mode8MHz
                        cpuClock.setClockMode(.mode8MHz)
                        clockFrequency = "8MHz"
                        simulateReset()
                    }) {
                        Text("8MHz")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .disabled(isRunning || isResetting || selectedMode == .mode8MHz)
                }
            }
            .padding()
            
            // リセット状態表示
            if isResetting {
                Text("リセット中...")
                    .foregroundColor(.orange)
                    .padding(.top, 5)
            }
        }
        .padding()
        .onAppear {
            setupTest()
            renderScreen()
        }
        .onDisappear {
            speedTest?.stopTest()
            resetTimer?.invalidate()
            resetTimer = nil
        }
    }
    
    /// テストのセットアップ
    private func setupTest() {
        // メモリとI/Oを初期化
        memory = PC88Memory()
        io = PC88IO()
        
        // CPUクロックを設定
        cpuClock.setClockMode(selectedMode)
        clockFrequency = selectedMode == .mode4MHz ? "4MHz" : "8MHz"
        
        // Z80 CPUを初期化
        if let memory = memory, let io = io {
            cpu = Z80CPU(memory: memory, io: io, cpuClock: cpuClock)
            cpu?.initialize()
        }
        
        // テキスト表示速度テストを初期化
        let test = PC88TextSpeedTest(screen: screen)
        
        // テスト完了時のコールバック
        test.onTestCompleted = {
            isRunning = false
            renderScreen()
        }
        
        // テスト進捗時のコールバック
        test.onTestProgress = { newProgress in
            progress = newProgress
            renderScreen()
        }
        
        speedTest = test
        
        // CPUクロックモード変更時のコールバックを設定
        cpuClock.onModeChanged = { newMode in
            clockFrequency = newMode == .mode4MHz ? "4MHz" : "8MHz"
            if !isRunning && !isResetting {
                simulateReset()
            }
        }
    }
    
    /// テストを開始
    private func startTest() {
        guard let test = speedTest, !isRunning, !isResetting else { return }
        
        isRunning = true
        progress = 0.0
        
        // 速度倍率を設定
        test.setDisplaySpeed(multiplier: speedMultiplier)
        cpuClock.speedMultiplier = speedMultiplier
        
        // CPUクロックモードを設定
        cpu?.setClockMode(selectedMode)
        
        // クロック周波数表示を更新
        clockFrequency = selectedMode == .mode4MHz ? "4MHz (実行中)" : "8MHz (実行中)"
        
        // CPU実行を開始
        startCPUExecution()
        
        // 選択されたモードでテストを実行
        if selectedMode == .mode4MHz {
            test.runTest4MHz(text: PC88TextSpeedTest.generateSampleText())
        } else {
            test.runTest8MHz(text: PC88TextSpeedTest.generateSampleText())
        }
    }
    
    /// テストを停止
    private func stopTest() {
        guard let test = speedTest, isRunning else { return }
        
        // CPU実行を停止
        stopCPUExecution()
        
        // クロック周波数表示を更新
        clockFrequency = selectedMode == .mode4MHz ? "4MHz" : "8MHz"
        
        test.stopTest()
        isRunning = false
    }
    
    /// リセットをシミュレート
    private func simulateReset() {
        guard !isResetting, !isRunning else { return }
        
        // リセット状態に設定
        isResetting = true
        resetCounter = 0
        
        // Z80 CPUをリセット
        cpu?.reset()
        
        // 画面をクリア
        screen.clear()
        renderScreen()
        
        // リセットタイマーを設定
        resetTimer?.invalidate()
        
        // 現在のCPUクロックモードに基づいて表示速度を調整
        // 表示速度を遅くしてクロック速度の差を視覚化
        let displayInterval = selectedMode == .mode4MHz ? 0.5 : 0.25  // 8MHzは4MHzの2倍の速度
        
        resetTimer = Timer.scheduledTimer(withTimeInterval: displayInterval, repeats: true) { timer in
            resetCounter += 1
            
            // リセット中の表示を更新
            if resetCounter <= 5 {
                // 「PC-88」の文字を1文字ずつ表示
                let chars = ["P", "C", "-", "8", "8"]
                if resetCounter <= chars.count {
                    let char = chars[resetCounter - 1]
                    let charCode = UInt8(char.first?.asciiValue ?? 0x20)
                    screen.writeCharacter(charCode, atLine: 0, column: resetCounter - 1)
                    renderScreen()
                }
            } else if resetCounter == 6 {
                // モード表示
                let modeText = selectedMode == .mode4MHz ? "N-BASIC MODE" : "N88-BASIC MODE"
                for (i, char) in modeText.enumerated() {
                    let charCode = UInt8(String(char).first?.asciiValue ?? 0x20)
                    screen.writeCharacter(charCode, atLine: 1, column: i)
                }
                renderScreen()
                
                // CPUクロックモードを設定
                cpu?.setClockMode(selectedMode)
            } else if resetCounter == 10 {
                // クロック周波数表示
                let freqText = selectedMode == .mode4MHz ? "CPU CLOCK: 4MHz" : "CPU CLOCK: 8MHz"
                for (i, char) in freqText.enumerated() {
                    let charCode = UInt8(String(char).first?.asciiValue ?? 0x20)
                    screen.writeCharacter(charCode, atLine: 2, column: i)
                }
                renderScreen()
            } else if resetCounter == 15 {
                // メモリチェック表示
                let memText = "MEMORY CHECK..."
                for (i, char) in memText.enumerated() {
                    let charCode = UInt8(String(char).first?.asciiValue ?? 0x20)
                    screen.writeCharacter(charCode, atLine: 3, column: i)
                }
                renderScreen()
                
                // CPUを実行開始
                startCPUExecution()
            } else if resetCounter == 20 {
                // 完了表示
                let readyText = "READY"
                for (i, char) in readyText.enumerated() {
                    let charCode = UInt8(String(char).first?.asciiValue ?? 0x20)
                    screen.writeCharacter(charCode, atLine: 5, column: i)
                }
                renderScreen()
                
                // リセット完了
                isResetting = false
                timer.invalidate()
                resetTimer = nil
            }
        }
    }
    
    /// CPU実行を開始
    private func startCPUExecution() {
        // 既存のタイマーを無効化
        cpuTimer?.invalidate()
        
        // CPUクロックモードに基づいて実行間隔を設定
        // 実行間隔を遅くしてクロック速度の差を視覚化
        let interval = selectedMode == .mode4MHz ? 0.1 : 0.05  // 8MHzは4MHzの2倍の速度
        
        // CPU実行タイマーを設定
        cpuTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // CPUサイクルを実行
            let cyclesPerFrame = selectedMode == .mode4MHz ? 100 : 200
            _ = cpu?.executeCycles(cyclesPerFrame)
            
            // 画面を更新
            renderScreen()
            
            // CPUクロックモードに基づいてクロック周波数表示を更新
            clockFrequency = selectedMode == .mode4MHz ? "4MHz (実行中)" : "8MHz (実行中)"
        }
    }
    
    /// CPU実行を停止
    private func stopCPUExecution() {
        cpuTimer?.invalidate()
        cpuTimer = nil
    }
    
    /// 画面を描画
    private func renderScreen() {
        // CGContextを作成
        let width = screen.screenWidth
        let height = screen.screenHeight
        let bytesPerRow = width * 4
        
        if let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) {
            // 画面を描画
            screen.render(to: context)
            
            // CGImageを取得
            if let image = context.makeImage() {
                displayImage = image
            }
        }
    }
}

#Preview {
    PC88TextSpeedTestView()
}
