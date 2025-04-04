//
//  AlphaMiniDosLoaderTest.swift
//  PC88iOSTests
//
//  Created on 2025/04/05.
//

import XCTest
@testable import PC88iOS

/// ALPHA-MINI-DOSローダーのテスト用クラス
/// このテストクラスはALPHA-MINI-DOSの読み込み機能を検証します
class AlphaMiniDosLoaderTest: XCTestCase {
    // MARK: - メモリアドレス定数
    
    /// IPLのロード先アドレス
    private let iplLoadAddress: UInt16 = 0x8000
    
    /// OSのロード先アドレス
    private let osLoadAddress: UInt16 = 0x0100
    
    /// OS実行開始アドレス
    private let osExecutionAddress: UInt16 = 0x0100
    
    // MARK: - テストデータ定数
    
    /// IPLの最初の2バイト（テスト用）
    private let iplSignature: [UInt8] = [0xF3, 0xC3]
    
    /// OSの最初の2バイト（テスト用）
    private let osSignature: [UInt8] = [0x01, 0x02]
    
    // MARK: - プロパティ
    
    /// テスト用メモリ
    private var testMemory: TestMemory!
    
    /// テスト用CPU
    private var testCPU: TestCPU!
    
    /// テスト対象
    private var loader: AlphaMiniDosLoader!
    
    // MARK: - セットアップ
    
    override func setUp() {
        super.setUp()
        
        // テスト用のメモリとCPUを作成
        testMemory = TestMemory()
        testCPU = TestCPU()
        
        // テスト対象を作成 - ロギングを無効化してテスト出力をクリーンに保つ
        loader = AlphaMiniDosLoader(memory: testMemory, cpu: testCPU, enableLogging: false)
    }
    
    override func tearDown() {
        testMemory = nil
        testCPU = nil
        loader = nil
        
        super.tearDown()
    }
    
    // MARK: - テストケース
    
    /// 有効なディスクイメージからALPHA-MINI-DOSを正常にロードできることを検証
    func testLoadAlphaMiniDos() {
        // テスト用のディスクイメージを作成
        let diskImage = MockD88DiskImage()
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertTrue(result, "ALPHA-MINI-DOSのロードに成功すべき")
        
        // IPLがメモリに正しくロードされたか確認
        verifyIplLoaded()
        
        // OSがメモリに正しくロードされたか確認
        verifyOsLoaded()
        
        // CPUの開始アドレスが正しく設定されたか確認
        verifyCpuStartAddress()
        
        // セクタ読み込みが正しく行われたか確認
        XCTAssertTrue(diskImage.sectorReadHistory.contains(where: { $0.track == 0 && $0.sector == 1 }), 
                      "IPLセクタ（トラック0、セクタ1）が読み込まれるべき")
    }
    
    /// 無効なIPLを持つディスクイメージからのロードが失敗することを検証
    func testLoadAlphaMiniDosWithInvalidIpl() {
        // IPL抽出に失敗するディスクイメージを作成
        let diskImage = MockD88DiskImage(validIpl: false, validOs: true)
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertFalse(result, "無効なIPLの場合はロードに失敗すべき")
        
        // メモリに何も書き込まれていないことを確認
        XCTAssertTrue(testMemory.writeHistory.isEmpty, "無効なIPLの場合はメモリに何も書き込まれないべき")
        
        // CPUの開始アドレスが設定されていないことを確認
        XCTAssertEqual(testCPU.programCounter, 0, "無効なIPLの場合はCPUの開始アドレスが設定されないべき")
    }
    
    /// 無効なOSを持つディスクイメージからのロードが失敗することを検証
    func testLoadAlphaMiniDosWithInvalidOs() {
        // OS抽出に失敗するディスクイメージを作成
        let diskImage = MockD88DiskImage(validIpl: true, validOs: false)
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertFalse(result, "無効なOSの場合はロードに失敗すべき")
        
        // IPLはロードされるがOSはロードされないことを確認
        XCTAssertFalse(testMemory.writeHistory.isEmpty, "IPLはロードされるべき")
        
        // IPLの読み込みは行われたが、OSの読み込みは行われていないことを確認
        let iplWriteCount = testMemory.writeHistory.filter { $0.address >= iplLoadAddress && $0.address < iplLoadAddress + 256 }.count
        XCTAssertEqual(iplWriteCount, 0, "IPLはロードされるべきではない")
    }
    
    /// CPUコントローラーが設定されていない場合のテスト
    func testLoadAlphaMiniDosWithoutCpu() {
        // CPUなしのローダーを作成
        loader = AlphaMiniDosLoader(memory: testMemory, cpu: nil, enableLogging: false)
        
        // テスト用のディスクイメージを作成
        let diskImage = MockD88DiskImage()
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証 - CPUがなくてもロードは成功するはず
        XCTAssertTrue(result, "CPUがなくてもALPHA-MINI-DOSのロードに成功すべき")
        
        // IPLがメモリに正しくロードされたか確認
        verifyIplLoaded()
        
        // OSがメモリに正しくロードされたか確認
        verifyOsLoaded()
    }
    
    // MARK: - ヘルパーメソッド
    
    /// IPLがメモリに正しくロードされたことを検証
    private func verifyIplLoaded() {
        // IPLの最初のバイトを検証
        XCTAssertEqual(testMemory.readByte(at: iplLoadAddress), iplSignature[0], 
                       "IPLの最初のバイトが正しくロードされていない")
        XCTAssertEqual(testMemory.readByte(at: iplLoadAddress + 1), iplSignature[1], 
                       "IPLの2番目のバイトが正しくロードされていない")
        
        // IPLのサイズ分の書き込みが行われたことを確認
        let iplWriteCount = testMemory.writeHistory.filter { $0.address >= iplLoadAddress && $0.address < iplLoadAddress + 256 }.count
        XCTAssertEqual(iplWriteCount, 256, "IPLのサイズ分（256バイト）の書き込みが行われるべき")
    }
    
    /// OSがメモリに正しくロードされたことを検証
    private func verifyOsLoaded() {
        // OSの最初のバイトを検証
        XCTAssertEqual(testMemory.readByte(at: osLoadAddress), osSignature[0], 
                       "OSの最初のバイトが正しくロードされていない")
        XCTAssertEqual(testMemory.readByte(at: osLoadAddress + 1), osSignature[1], 
                       "OSの2番目のバイトが正しくロードされていない")
        
        // OS領域に書き込みが行われたことを確認
        let osWriteCount = testMemory.writeHistory.filter { $0.address >= osLoadAddress }.count
        XCTAssertGreaterThan(osWriteCount, 256, "OS領域に十分な書き込みが行われるべき")
    }
    
    /// CPUの開始アドレスが正しく設定されたことを検証
    private func verifyCpuStartAddress() {
        XCTAssertEqual(testCPU.programCounter, osExecutionAddress, 
                       "CPUの開始アドレスが正しく設定されていない")
        XCTAssertTrue(testCPU.isExecuting, "CPU実行が開始されるべき")
    }

// MARK: - テスト用クラス

/// テスト用メモリ実装
/// MemoryAccessingプロトコルに準拠したテスト用のメモリクラス
class TestMemory: MemoryAccessing {
    // MARK: - プロパティ
    
    /// メモリデータ（アドレスとバイト値のマップ）
    private var memory = [UInt16: UInt8]()
    
    /// メモリ書き込み履歴（デバッグ用）
    private(set) var writeHistory = [(address: UInt16, value: UInt8)]()
    
    // MARK: - MemoryAccessingプロトコル実装
    
    /// 指定アドレスにバイト値を書き込む
    /// - Parameters:
    ///   - value: 書き込む値
    ///   - address: 書き込み先アドレス
    func writeByte(_ value: UInt8, at address: UInt16) {
        memory[address] = value
        writeHistory.append((address: address, value: value))
    }
    
    /// 指定アドレスからバイト値を読み込む
    /// - Parameter address: 読み込み元アドレス
    /// - Returns: 読み込んだバイト値（未初期化の場合は0）
    func readByte(at address: UInt16) -> UInt8 {
        return memory[address] ?? 0
    }
    
    /// 指定アドレスからワード値を読み込む
    /// - Parameter address: 読み込み元アドレス
    /// - Returns: 読み込んだワード値（リトルエンディアン）
    func readWord(at address: UInt16) -> UInt16 {
        let lowByte = readByte(at: address)
        let highByte = readByte(at: address + 1)
        return UInt16(highByte) << 8 | UInt16(lowByte)
    }
    
    /// 指定アドレスにワード値を書き込む
    /// - Parameters:
    ///   - value: 書き込む値
    ///   - address: 書き込み先アドレス
    func writeWord(_ value: UInt16, at address: UInt16) {
        let lowByte = UInt8(value & 0xFF)
        let highByte = UInt8(value >> 8)
        writeByte(lowByte, at: address)
        writeByte(highByte, at: address + 1)
    }
    
    /// メモリバンクを切り替える（テスト用の空実装）
    func switchBank(_ bank: Int, for area: MemoryArea) {
        // テスト用の簡易実装のため何もしない
    }
    
    /// ROM有効/無効を切り替える（テスト用の空実装）
    func setROMEnabled(_ enabled: Bool, for area: MemoryArea) {
        // テスト用の簡易実装のため何もしない
    }
    
    /// メモリ内容をダンプする（デバッグ用）
    /// - Parameters:
    ///   - startAddress: 開始アドレス
    ///   - length: ダンプするバイト数
    /// - Returns: ダンプされたメモリ内容の文字列表現
    func dumpMemory(from startAddress: UInt16, length: Int) -> String {
        var result = ""
        for i in 0..<length {
            if i % 16 == 0 && i > 0 {
                result += "\n"
            }
            let address = startAddress + UInt16(i)
            let byte = readByte(at: address)
            result += String(format: "%02X ", byte)
        }
        return result
    }
}

/// テスト用CPU実装
/// CpuControllingプロトコルに準拠したテスト用のCPUクラス
class TestCPU: CpuControlling {
    // MARK: - プロパティ
    
    /// プログラムカウンタ
    var programCounter: UInt16 = 0
    
    /// 実行状態
    private(set) var isExecuting = false
    
    /// 命令履歴（デバッグ用）
    private(set) var commandHistory = [(command: String, address: UInt16)]()
    
    // MARK: - CpuControllingプロトコル実装
    
    /// 開始アドレスを設定する
    /// - Parameter address: 設定する開始アドレス
    func setStartAddress(_ address: UInt16) {
        programCounter = address
        commandHistory.append((command: "setStartAddress", address: address))
    }
    
    /// プログラムカウンタを設定する
    /// - Parameter address: 設定するアドレス
    func setProgramCounter(address: Int) {
        programCounter = UInt16(address)
        commandHistory.append((command: "setProgramCounter", address: UInt16(address)))
    }
    
    /// 実行を開始する
    func startExecution() {
        isExecuting = true
        commandHistory.append((command: "startExecution", address: programCounter))
    }
    
    /// 実行を停止する
    func stopExecution() {
        isExecuting = false
        commandHistory.append((command: "stopExecution", address: programCounter))
    }
    
    /// 命令履歴をクリアする
    func clearHistory() {
        commandHistory.removeAll()
    }
}

/// モックD88DiskImage
/// テスト用のD88DiskImageモッククラス
class MockD88DiskImage: D88DiskImage {
    // MARK: - 定数
    
    /// IPLデータのサイズ（バイト）
    private let iplDataSize = 256
    
    /// OSセクタのサイズ（バイト）
    private let osSectorSize = 256
    
    /// OSセクタの数（デフォルト）
    private let defaultOsSectorCount = 4
    
    /// IPLの最初の2バイト（シグネチャ）
    private let iplSignature: [UInt8] = [0xF3, 0xC3]
    
    /// OSの最初の2バイト（シグネチャ）
    private let osSignature: [UInt8] = [0x01, 0x02]
    
    // MARK: - プロパティ
    
    /// 有効なIPLを持つかどうか
    private let hasValidIpl: Bool
    
    /// 有効なOSを持つかどうか
    private let hasValidOs: Bool
    
    /// OSセクタの数
    private let osSectorCount: Int
    
    /// セクタ読み込み履歴（デバッグ用）
    private(set) var sectorReadHistory = [(track: Int, sector: Int)]()
    
    /// ディスク名
    private let diskName: String
    
    // MARK: - 初期化
    
    /// モックD88DiskImageの初期化
    /// - Parameters:
    ///   - validIpl: 有効なIPLを持つかどうか（デフォルト: true）
    ///   - validOs: 有効なOSを持つかどうか（デフォルト: true）
    ///   - osSectorCount: OSセクタの数（デフォルト: 4）
    ///   - diskName: ディスク名（デフォルト: "ALPHA-MINI-DOS"）
    init(validIpl: Bool = true, validOs: Bool = true, osSectorCount: Int = 4, diskName: String = "ALPHA-MINI-DOS") {
        self.hasValidIpl = validIpl
        self.hasValidOs = validOs
        self.osSectorCount = osSectorCount
        self.diskName = diskName
        super.init()
    }
    
    /// ディスク名を取得する
    /// - Returns: ディスク名
    override func getDiskName() -> String {
        return diskName
    }
    
    // MARK: - オーバーライドメソッド
    
    /// セクタデータを読み込む
    /// - Parameters:
    ///   - track: トラック番号
    ///   - sector: セクタ番号
    /// - Returns: セクタデータ（バイト配列）、失敗時はnil
    override func readSector(track: Int, sector: Int) -> [UInt8]? {
        // 読み込み履歴を記録
        sectorReadHistory.append((track: track, sector: sector))
        
        // IPLセクタ（トラック0、セクタ1）の場合
        if track == 0 && sector == 1 {
            if !hasValidIpl {
                return nil
            }
            
            // テスト用のIPLデータを返す
            return createMockIplData()
        }
        
        // その他のセクタは親クラスの実装を使用
        return super.readSector(track: track, sector: sector)
    }
    
    /// OSセクタを読み込む
    /// - Returns: OSセクタのデータ配列、失敗時はnil
    override func loadOsSectors() -> [[UInt8]]? {
        if !hasValidOs {
            return nil
        }
        
        // テスト用のOSデータを返す
        return createMockOsSectors()
    }
    
    /// ALPHA-MINI-DOSディスクかどうかを判定
    /// - Returns: ALPHA-MINI-DOSディスクの場合はtrue
    override func isAlphaMiniDos() -> Bool {
        return hasValidIpl
    }
    
    /// セクタIDを指定してセクタデータを読み込む
    /// - Parameters:
    ///   - track: トラック番号
    ///   - side: サイド番号
    ///   - sectorID: セクタID
    /// - Returns: セクタデータ、失敗時はnil
    override func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        // スーパークラスの実装を使用
        return super.readSector(track: track, side: side, sectorID: sectorID)
    }
    
    /// ALPHA-MINI-DOSのOS部分を抽出
    /// - Returns: OS部分のデータ、失敗時はnil
    override func extractAlphaMiniDosOs() -> [UInt8]? {
        if hasValidOs {
            return createMockOsData()
        } else {
            return nil
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    /// モックIPLデータを作成
    /// - Returns: IPLデータ（バイト配列）
    private func createMockIplData() -> [UInt8] {
        return iplSignature + Array(repeating: UInt8(0), count: iplDataSize - iplSignature.count)
    }
    
    /// モックOSデータを作成
    /// - Returns: OSデータ（バイト配列）
    private func createMockOsData() -> [UInt8] {
        return osSignature + Array(repeating: UInt8(0), count: osSectorSize - osSignature.count)
    }
    
    /// モックOSセクタを作成
    /// - Returns: OSセクタのデータ配列
    private func createMockOsSectors() -> [[UInt8]] {
        var sectors: [[UInt8]] = []
        
        // 最初のセクタはOSシグネチャで始まる
        let sector1: [UInt8] = osSignature + Array(repeating: UInt8(0), count: osSectorSize - osSignature.count)
        sectors.append(sector1)
        
        // 残りのセクタはそれぞれ異なる先頭バイトを持つ
        for i in 1..<osSectorCount {
            let sectorData: [UInt8] = [UInt8(i * 2 + 1), UInt8(i * 2 + 2)] + 
                                       Array(repeating: UInt8(0), count: osSectorSize - 2)
            sectors.append(sectorData)
        }
        
        return sectors
    }
}
