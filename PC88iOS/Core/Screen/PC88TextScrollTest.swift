import Foundation

/// PC-88テキストスクロールテスト用のクラス
/// OSに依存せず、Z80アセンブラコードを使用してテキストスクロールを実装
class PC88TextScrollTest {
    // MARK: - 定数
    
    /// スクロール速度の設定値（遅い→速い）
    struct ScrollSpeed: Equatable {
        let value: UInt8
        
        // 定数値を定義
        static let verySlow = ScrollSpeed(value: 30)  // 非常に遅い
        static let slow = ScrollSpeed(value: 20)      // 遅い
        static let normal = ScrollSpeed(value: 10)    // 通常
        static let fast = ScrollSpeed(value: 5)       // 速い
        static let veryFast = ScrollSpeed(value: 2)   // 非常に速い
    }
    // MARK: - プロパティ
    
    /// スクリーンへの参照
    private let screen: PC88ScreenBase
    
    /// メモリへの参照
    private let memory: MemoryAccessing
    
    /// CPUへの参照
    private let cpu: Z80CPU
    
    /// 現在のスクロール速度
    private var currentSpeed: ScrollSpeed
    
    /// テストテキスト
    private let testText = """
    *** PC-88 TEXT SCROLL TEST MODE ***
    
    このテストモードはOSに依存せず、Z80アセンブラコードを使用して
    テキストスクロールのテストを行います。
    
    FEATURES:
    - 自動スクロール
    - 複数の色とスタイルの表示
    - 画面端での折り返し
    
    このテストを終了するには、ESCキーを押してください。
    
    ABCDEFGHIJKLMNOPQRSTUVWXYZ
    abcdefghijklmnopqrstuvwxyz
    0123456789 !@#$%^&*()_+-=[]{}|;:'\",.<>/?
    
    各色のテスト:
    黒、青、赤、シアン、緑、マゼンタ、黄色、白
    
    点滅テスト: これは点滅するテキストです
    
    反転テスト: これは反転表示されたテキストです
    
    *** END OF TEST TEXT ***
    """
    
    /// Z80アセンブラコード（テキストスクロール用）
    private let scrollCode: [UInt8] = [
        // プログラム開始アドレス（0xC000から開始）
        
        // 定数定義
        // 0xC000: テキストVRAMの開始アドレス（F3C8h）
        0x21, 0xC8, 0xF3,     // LD HL, F3C8h
        0x22, 0x50, 0xC0,     // LD (TEXT_VRAM_ADDR), HL
        
        // 0xC005: スクロール間隔カウンタ初期値
        0x3E, 0x0A,           // LD A, 10
        0x32, 0x52, 0xC0,     // LD (SCROLL_COUNTER), A
        
        // 0xC00A: スクロール位置初期化
        0x21, 0x00, 0x00,     // LD HL, 0
        0x22, 0x54, 0xC0,     // LD (SCROLL_POSITION), HL
        
        // メインループ
        // 0xC00F: メインループ開始
        0x3A, 0x52, 0xC0,     // LD A, (SCROLL_COUNTER)
        0x3D,                 // DEC A
        0x32, 0x52, 0xC0,     // LD (SCROLL_COUNTER), A
        0x20, 0x0A,           // JR NZ, SKIP_SCROLL
        
        // スクロールカウンタが0になったらスクロール実行
        0x3E, 0x0A,           // LD A, 10  ; カウンタリセット
        0x32, 0x52, 0xC0,     // LD (SCROLL_COUNTER), A
        0xCD, 0x30, 0xC0,     // CALL SCROLL_TEXT
        
        // 0xC01F: SKIP_SCROLL
        // キー入力チェック
        0xDB, 0x00,           // IN A, (00h) ; キーボードステータスポート
        0xCB, 0x47,           // BIT 0, A    ; キー入力があるか
        0x28, 0x0A,           // JR Z, NO_KEY
        
        // キー入力がある場合、ESCキーかチェック
        0xDB, 0x01,           // IN A, (01h) ; キーボードデータポート
        0xFE, 0x1B,           // CP 1Bh      ; ESCキー
        0x20, 0x04,           // JR NZ, NO_KEY
        
        // ESCキーが押された場合、終了
        0xC3, 0x00, 0x00,     // JP 0000h    ; リセットベクタにジャンプして終了
        
        // 0xC029: NO_KEY
        0xC3, 0x0F, 0xC0,     // JP MAIN_LOOP
        
        // スクロール処理サブルーチン
        // 0xC030: SCROLL_TEXT
        0x2A, 0x54, 0xC0,     // LD HL, (SCROLL_POSITION)
        0x23,                 // INC HL      ; スクロール位置を1増加
        0x22, 0x54, 0xC0,     // LD (SCROLL_POSITION), HL
        
        // テキストVRAMにデータを書き込む
        0xE5,                 // PUSH HL     ; スクロール位置を保存
        0x2A, 0x50, 0xC0,     // LD HL, (TEXT_VRAM_ADDR)
        0x11, 0x00, 0xC1,     // LD DE, TEXT_DATA
        0x0E, 0x50,           // LD C, 80    ; 1行80文字
        
        // 0xC03E: WRITE_LINE
        0x1A,                 // LD A, (DE)  ; テキストデータから1バイト読み込み
        0x77,                 // LD (HL), A  ; テキストVRAMに書き込み
        0x23,                 // INC HL      ; テキストVRAMアドレス++
        0x13,                 // INC DE      ; テキストデータアドレス++
        0x0D,                 // DEC C       ; カウンタ--
        0x20, 0xFA,           // JR NZ, WRITE_LINE
        
        // 属性設定
        0x11, 0x50, 0x00,     // LD DE, 80   ; 属性は80バイト後
        0x19,                 // ADD HL, DE  ; 属性アドレスに移動
        0x0E, 0x50,           // LD C, 80    ; 1行80文字分の属性
        
        // 0xC04C: WRITE_ATTR
        0x3E, 0x07,           // LD A, 07h   ; 白色
        0x77,                 // LD (HL), A  ; 属性を書き込み
        0x23,                 // INC HL      ; 属性アドレス++
        0x0D,                 // DEC C       ; カウンタ--
        0x20, 0xFB,           // JR NZ, WRITE_ATTR
        
        0xE1,                 // POP HL      ; スクロール位置を復元
        0xC9,                 // RET
        
        // 変数領域
        // 0xC050: TEXT_VRAM_ADDR  DW F3C8h
        0xC8, 0xF3,
        // 0xC052: SCROLL_COUNTER  DB 10
        0x0A,
        // 0xC054: SCROLL_POSITION DW 0
        0x00, 0x00,
        
        // 0xC100: TEXT_DATA
        // ここからテキストデータが続く（実際のデータは実行時に設定）
    ]
    
    // MARK: - 初期化
    
    init(screen: PC88ScreenBase, memory: MemoryAccessing, cpu: Z80CPU) {
        self.screen = screen
        self.memory = memory
        self.cpu = cpu
        self.currentSpeed = ScrollSpeed.normal
    }
    
    // MARK: - パブリックメソッド
    
    /// テキストスクロールテストを開始
    func startTest() {
        PC88Logger.screen.debug("\("テキストスクロールテストを開始します")")
        
        // 画面をクリア
        screen.forceClearScreen()
        
        // Z80アセンブラコードをメモリにロード
        loadScrollCodeToMemory()
        
        // テストテキストをメモリにロード
        loadTestTextToMemory()
        
        // 初期スクロール速度を設定
        setScrollSpeed(.normal)
        
        // CPUのPCを設定してコードを実行
        cpu.setPC(0xC000)
        
        PC88Logger.screen.debug("\("テキストスクロールテスト用のZ80コードを実行します（PC=0xC000）")")
    }
    
    /// スクロール速度を設定
    func setScrollSpeed(_ speed: ScrollSpeed) {
        PC88Logger.screen.debug("\("スクロール速度を設定します: \(speed)")") 
        self.currentSpeed = speed
        
        // メモリ上のスクロール速度カウンタを更新
        memory.writeByte(speed.value, at: 0xC052)
    }
    
    /// スクロール速度を上げる
    func increaseSpeed() {
        if currentSpeed == ScrollSpeed.verySlow {
            setScrollSpeed(ScrollSpeed.slow)
        } else if currentSpeed == ScrollSpeed.slow {
            setScrollSpeed(ScrollSpeed.normal)
        } else if currentSpeed == ScrollSpeed.normal {
            setScrollSpeed(ScrollSpeed.fast)
        } else if currentSpeed == ScrollSpeed.fast {
            setScrollSpeed(ScrollSpeed.veryFast)
        }
        // ScrollSpeed.veryFastの場合は何もしない（すでに最速）
    }
    
    /// スクロール速度を下げる
    func decreaseSpeed() {
        if currentSpeed == ScrollSpeed.slow {
            setScrollSpeed(ScrollSpeed.verySlow)
        } else if currentSpeed == ScrollSpeed.normal {
            setScrollSpeed(ScrollSpeed.slow)
        } else if currentSpeed == ScrollSpeed.fast {
            setScrollSpeed(ScrollSpeed.normal)
        } else if currentSpeed == ScrollSpeed.veryFast {
            setScrollSpeed(ScrollSpeed.fast)
        }
        // ScrollSpeed.verySlowの場合は何もしない（すでに最遅）
    }
    
    // MARK: - プライベートメソッド
    
    /// スクロールコードをメモリにロード
    private func loadScrollCodeToMemory() {
        // メモリの0xC000からスクロールコードをロード
        for (i, byte) in scrollCode.enumerated() {
            memory.writeByte(byte, at: 0xC000 + UInt16(i))
        }
    }
    
    /// テストテキストをメモリにロード
    private func loadTestTextToMemory() {
        // テキストデータを0xC100からロード
        let textBytes = Array(testText.utf8)
        
        // テキストデータをメモリにロード（最大1000バイトまで）
        let maxBytes = min(textBytes.count, 1000)
        for i in 0..<maxBytes {
            memory.writeByte(UInt8(textBytes[i]), at: 0xC100 + UInt16(i))
        }
        
        // 終端を示す0をセット
        memory.writeByte(0, at: 0xC100 + UInt16(maxBytes))
    }
}
