//
//  PC88ScreenBase.swift
//  PC88iOS
//
//  Created on 2025/04/04.
//

import Foundation
import CoreGraphics
import UIKit

/// PC-88の画面描画を担当する基本クラス
class PC88ScreenBase: ScreenRendering {
    // MARK: - プロパティ
    
    /// メモリアクセス
    internal var memory: MemoryAccessing?
    
    /// I/Oアクセス
    internal var io: IOAccessing?
    
    /// テキストVRAM (1行120バイト: 80文字 + 40バイトの属性)
    internal var textVRAM = [UInt8](repeating: 0, count: 120 * 25)
    
    /// グラフィックVRAM（3プレーン: R, G, B）
    internal var graphicsVRAM = Array(repeating: [UInt8](repeating: 0, count: 640 * 400 / 8), count: 3)
    
    /// 画面設定
    internal var settings = PC88ScreenSettings()
    
    /// テキストVRAMの開始アドレス（デフォルト: 0xF3C8）
    internal var textVRAMStartAddress: UInt16 = 0xF3C8
    
    /// 点滅タイマー
    internal var blinkTimer: Timer?
    
    /// 点滅状態を管理するフラグ（trueの場合、点滅テキストを表示）
    internal var blinkState = true
    
    /// 点滅カウンター（60FPSでのカウント用）
    internal var blinkCounter = 0
    
    /// 現在の画面モード
    internal var currentScreenMode: ScreenMode = .text
    
    /// 画面更新リクエスト時のコールバック
    var onScreenUpdateRequested: (() -> Void)?
    
    // MARK: - コンポーネント
    
    /// カラーパレット
    internal var colorPalette = PC88ColorPalette()
    
    /// 属性ハンドラ
    internal var attributeHandler: PC88AttributeHandler
    
    /// テキストレンダラー
    internal var textRenderer: PC88TextRenderer
    
    /// グラフィックレンダラー
    internal var graphicsRenderer: PC88GraphicsRenderer
    
    // MARK: - 初期化
    
    init() {
        // 属性ハンドラの初期化
        attributeHandler = PC88AttributeHandler(textVRAM: textVRAM, settings: settings)
        
        // テキストレンダラーの初期化
        textRenderer = PC88TextRenderer(textVRAM: textVRAM, settings: settings, attributeHandler: attributeHandler, colorPalette: colorPalette)
        
        // グラフィックレンダラーの初期化
        graphicsRenderer = PC88GraphicsRenderer(graphicsVRAM: graphicsVRAM, settings: settings, colorPalette: colorPalette)
        
        // 点滅タイマーのセットアップ
        setupBlinkTimer()
    }
    
    // MARK: - ScreenRenderingプロトコル実装
    
    /// 画面の初期化
    func initialize() {
        // メモリとI/Oの初期化
        memory = nil
        io = nil
        
        // VRAMの初期化
        for i in 0..<textVRAM.count {
            textVRAM[i] = 0
        }
        
        for plane in 0..<graphicsVRAM.count {
            for i in 0..<graphicsVRAM[plane].count {
                graphicsVRAM[plane][i] = 0
            }
        }
        
        // 設定の初期化
        settings = PC88ScreenSettings()
        
        // テキストVRAMの開始アドレスを設定
        textVRAMStartAddress = 0xF3C8
        
        // 画面モードを設定
        currentScreenMode = .text
        
        // コンポーネントの参照を更新
        updateComponentReferences()
        
        // 点滅タイマーのセットアップ
        setupBlinkTimer()
    }
    
    /// テキストVRAMの更新
    func updateTextVRAM(at address: UInt16, value: UInt8) {
        // 安全なオフセット計算を行う
        if address >= textVRAMStartAddress {
            let offset = Int(address - textVRAMStartAddress)
            if offset < textVRAM.count {
                textVRAM[offset] = value
            }
        } else {
            // アドレスが範囲外の場合は何もしない
            // デバッグ情報としてログを出力することも考えられる
            #if DEBUG
            print("WARNING: テキストVRAM範囲外のアドレスへのアクセス: 0x\(String(format: "%04X", address))")
            #endif
        }
    }
    
    /// グラフィックVRAMの更新
    func updateGraphicsVRAM(at address: UInt16, value: UInt8, plane: Int) {
        graphicsRenderer.updateGraphicsVRAM(at: address, value: value, plane: plane)
    }
    
    /// 画面モード設定
    func setScreenMode(_ mode: ScreenMode) {
        currentScreenMode = mode
    }
    
    /// パレット設定
    func setPalette(index: Int, color: UInt8) {
        colorPalette.setPalette(index: index, colorCode: color)
    }
    
    /// 画面描画
    func render() -> CGImage? {
        // 描画コンテキストの作成
        let width = PC88ScreenConstants.graphicsWidth
        // 常に400ラインモードを使用（インターレース表示）
        let height = PC88ScreenConstants.graphicsHeight400
        
        guard let context = createGraphicsContext(width: width, height: height) else {
            return nil
        }
        
        // 背景を黒で塗りつぶす
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // 現在のモードに応じて描画
        switch currentScreenMode {
        case .text:
            textRenderer.renderTextScreen(context: context)
        case .graphics:
            graphicsRenderer.renderGraphicsMode(context)
        case .mixed:
            graphicsRenderer.renderGraphicsMode(context)
            textRenderer.renderTextScreen(context: context)
        }
        
        // デバッグ情報の描画
        textRenderer.renderDebugInfo(context: context)
        
        return context.makeImage()
    }
    
    /// 画面のリセット
    func reset() {
        // テキストVRAMをクリア
        textRenderer.clearScreen()
        
        // グラフィックVRAMをクリア
        graphicsRenderer.clearGraphicsVRAM()
        
        // パレットをリセット
        colorPalette.reset()
        
        // 設定をリセット
        settings = PC88ScreenSettings()
        
        // コンポーネントの参照を更新
        updateComponentReferences()
    }
    
    // MARK: - I/O処理
    
    /// I/Oポートへの書き込み
    func writeIO(port: UInt16, value: UInt8) {
        switch port {
        case PC88ScreenConstants.crtModeControlPort: // CRTモード制御ポート (0x30)
            // bit0: 40/80桁モード (0=80桁, 1=40桁)
            settings.is40ColumnMode = (value & 0x01) != 0
            
            // bit1: 20/25行モード (0=25行, 1=20行)
            settings.is20LineMode = (value & 0x02) != 0
            
            // bit2: カラー/白黒モード (0=白黒, 1=カラー)
            settings.isColorMode = (value & 0x04) != 0
            
            // コンポーネントの参照を更新
            updateComponentReferences()
            
            // 画面更新をトリガー
            requestScreenUpdate()
            
        case PC88ScreenConstants.crtLineControlPort: // CRT行数制御ポート (0x31)
            // bit7: 200/400ラインモード (0=200ライン, 1=400ライン)
            settings.is400LineMode = (value & 0x80) != 0
            
            // コンポーネントの参照を更新
            updateComponentReferences()
            
            // 画面更新をトリガー
            requestScreenUpdate()
            
        case PC88ScreenConstants.colorModeControlPort: // カラーモード制御ポート (0x32)
            // bit0: デジタル/アナログモード (0=デジタル, 1=アナログ)
            settings.isAnalogMode = (value & 0x01) != 0
            colorPalette.setAnalogMode(settings.isAnalogMode)
            
        case PC88ScreenConstants.crtcParameterPort: // CRTCパラメータポート (0x50)
            // CRTCパラメータの処理
            break
            
        case PC88ScreenConstants.crtcCommandPort: // CRTCコマンドポート (0x51)
            // CRTCコマンドの処理
            break
            
        case PC88ScreenConstants.dmacCh2AddressPort: // DMAC Ch.2アドレスポート (0x64)
            // DMAC Ch.2アドレスの処理
            break
            
        case PC88ScreenConstants.dmacCh2CountPort: // DMAC Ch.2カウントポート (0x65)
            // DMAC Ch.2カウントの処理
            break
            
        case PC88ScreenConstants.dmacControlPort: // DMAC制御ポート (0x68)
            // DMAC制御の処理
            break
            
        default:
            break
        }
    }
    
    /// I/Oポートからの読み込み
    func readIO(port: UInt16) -> UInt8 {
        switch port {
        case PC88ScreenConstants.crtModeControlPort: // CRTモード制御ポート (0x30)
            var value: UInt8 = 0
            if settings.is40ColumnMode { value |= 0x01 }
            if settings.is20LineMode { value |= 0x02 }
            if settings.isColorMode { value |= 0x04 }
            return value
            
        case PC88ScreenConstants.crtLineControlPort: // CRT行数制御ポート (0x31)
            var value: UInt8 = 0
            if settings.is400LineMode { value |= 0x80 }
            return value
            
        case PC88ScreenConstants.colorModeControlPort: // カラーモード制御ポート (0x32)
            var value: UInt8 = 0
            if settings.isAnalogMode { value |= 0x01 }
            return value
            
        default:
            return 0
        }
    }
    
    // MARK: - 補助メソッド
    
    /// 描画コンテキストの作成
    internal func createGraphicsContext(width: Int, height: Int) -> CGContext? {
        let bytesPerRow = width * 4
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        return context
    }
    
    /// 点滅タイマーをセットアップ
    internal func setupBlinkTimer() {
        // 既存のタイマーを停止
        blinkTimer?.invalidate()
        
        // 新しいタイマーを作成（0.5秒間隔）
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 点滅状態を切り替え
            self.blinkState = !self.blinkState
            
            // テキストレンダラーに点滅状態を通知
            self.textRenderer.updateBlinkState(self.blinkState)
            
            // 属性ハンドラに点滅状態を通知
            self.attributeHandler.updateBlinkState(self.blinkState)
        }
    }
    
    /// コンポーネントの参照を更新
    internal func updateComponentReferences() {
        attributeHandler.updateTextVRAMReference(textVRAM)
        textRenderer.updateTextVRAMReference(textVRAM)
        graphicsRenderer.updateGraphicsVRAMReference(graphicsVRAM)
    }
    
    // MARK: - 公開メソッド
    
    /// メモリアクセスを設定
    func setMemory(_ memory: MemoryAccessing) {
        self.memory = memory
    }
    
    /// メモリアクセスを接続
    func connectMemory(_ memory: MemoryAccessing) {
        self.memory = memory
    }
    
    /// I/Oアクセスを設定
    func setIO(_ io: IOAccessing) {
        self.io = io
    }
    
    /// I/Oアクセスを接続
    func connectIO(_ io: IOAccessing) {
        self.io = io
    }
    
    /// フォントデータを設定
    func setFontData(_ data: [UInt8]) {
        textRenderer.setFontData(data)
    }
    
    /// 特定の文字コードに対するフォントデータを設定
    func setFontData(charCode: UInt8, data: [UInt8]) {
        // PC88TextRendererに渡す前に文字コードごとのフォントデータを設定する必要がある場合はここで処理
        // 現在は単純にtextRendererに渡す
        textRenderer.setFontData(data)
    }
    
    /// 画面を描画してCGImageを返す
    func renderScreen() -> CGImage? {
        // テキストモードの場合はテキストレンダラーを使用
        return render()
    }
    
    /// 画面の幅（ピクセル単位）
    var screenWidth: Int {
        return PC88ScreenConstants.graphicsWidth
    }
    
    /// 画面の高さ（ピクセル単位）
    var screenHeight: Int {
        // 常に400ラインモードを使用（インターレース表示）
        return PC88ScreenConstants.graphicsHeight400
    }
    
    /// 指定されたCGContextに画面を描画
    func render(to context: CGContext) {
        // テキストモードの場合はテキストレンダラーを使用
        switch currentScreenMode {
        case .text:
            textRenderer.renderTextScreen(context: context)
        case .graphics:
            graphicsRenderer.renderGraphicsMode(context)
        case .mixed:
            graphicsRenderer.renderGraphicsMode(context)
            textRenderer.renderTextScreen(context: context)
        }
    }
    
    /// テスト画面を表示（デバッグ用）
    func displayTestScreen() {
        // テストクラスを使用してテスト画面を表示
        let screenTest = PC88ScreenTest(screen: self)
        screenTest.displayTestScreen()
    }
    
    /// 画面を強制的にクリア（テスト画面を消すために使用）
    func forceClearScreen() {
        // テキストVRAMをクリア
        for i in 0..<textVRAM.count {
            textVRAM[i] = 0x20 // スペース文字
        }
        // グラフィックスVRAMもクリア
        graphicsRenderer.clearGraphicsVRAM()
    }
    
    /// 行のテキストモードを設定
    func setLineTextMode(line: Int, mode: PC88TextMode) {
        textRenderer.setLineTextMode(line: line, mode: mode)
    }
    
    /// 色属性を設定
    func setColorAttribute(line: Int, startColumn: Int, color: UInt8) {
        attributeHandler.setColorAttribute(line: line, startColumn: startColumn, color: color)
    }
    
    /// 装飾属性を設定
    func setDecorationAttribute(line: Int, startColumn: Int, decoration: PC88Decoration, underline: Bool = false, upperline: Bool = false) {
        attributeHandler.setDecorationAttribute(line: line, startColumn: startColumn, decoration: decoration, underline: underline, upperline: upperline)
    }
    

    

    
    /// 詳細なテスト画面を表示
    func displayDetailedTestScreen() {
        textRenderer.displayDetailedTestScreen()
        graphicsRenderer.drawTestPattern()
    }
    
    /// 画面をクリアする
    func clear() {
        forceClearScreen()
    }
    
    /// テキストVRAMから読み込む
    func readTextVRAM(offset: Int) -> UInt8 {
        guard offset >= 0 && offset < textVRAM.count else { return 0x20 } // 範囲外の場合はスペース
        return textVRAM[offset]
    }
    
    /// テキストVRAMに書き込む
    func writeTextVRAM(offset: Int, value: UInt8) {
        guard offset >= 0 && offset < textVRAM.count else { return }
        textVRAM[offset] = value
    }
    
    /// テキストVRAMへの書き込み
    func writeTextVRAM(address: UInt16, value: UInt8) {
        let offset = Int(address)
        if offset < textVRAM.count {
            textVRAM[offset] = value
        }
    }
    
    /// テキストVRAMからの読み込み
    func readTextVRAM(address: UInt16) -> UInt8 {
        let offset = Int(address)
        if offset < textVRAM.count {
            return textVRAM[offset]
        }
        return 0
    }
    
    /// 指定位置に文字を書き込む
    func writeCharacter(_ char: UInt8, atLine line: Int, column: Int) {
        guard line >= 0 && line < PC88ScreenConstants.textHeight25 else { return }
        guard column >= 0 && column < PC88ScreenConstants.textWidth80 else { return }
        
        let offset = line * PC88ScreenConstants.textVRAMBytesPerLine + column
        if offset < textVRAM.count {
            textVRAM[offset] = char
        }
    }
    
    /// 画面更新をリクエストする
    func requestScreenUpdate() {
        // 画面更新リクエストコールバックを実行
        onScreenUpdateRequested?()
    }
}
