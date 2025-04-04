//
//  AlphaMiniDosLoaderTest.swift
//  PC88iOSTests
//
//  Created on 2025/04/05.
//

import XCTest
@testable import PC88iOS

/// AlphaMiniDosLoaderのテスト用クラス
class AlphaMiniDosLoaderTest: XCTestCase {
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
        
        // テスト対象を作成
        loader = AlphaMiniDosLoader(memory: testMemory, cpu: testCPU)
    }
    
    override func tearDown() {
        testMemory = nil
        testCPU = nil
        loader = nil
        
        super.tearDown()
    }
    
    // MARK: - テストケース
    
    /// ディスクイメージの読み込みテスト
    func testLoadAlphaMiniDos() {
        // テスト用のディスクイメージを作成
        let diskImage = MockD88DiskImage()
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertTrue(result, "ALPHA-MINI-DOSのロードに成功すべき")
        
        // IPLがメモリにロードされたか確認
        XCTAssertEqual(testMemory.readByte(at: 0xC000), 0xF3, "IPLの最初のバイトが正しくロードされていない")
        XCTAssertEqual(testMemory.readByte(at: 0xC001), 0xC3, "IPLの2番目のバイトが正しくロードされていない")
        
        // OSがメモリにロードされたか確認
        XCTAssertEqual(testMemory.readByte(at: 0xD000), 0x01, "OSの最初のバイトが正しくロードされていない")
        XCTAssertEqual(testMemory.readByte(at: 0xD001), 0x02, "OSの2番目のバイトが正しくロードされていない")
        
        // CPUの開始アドレスが設定されたか確認
        XCTAssertEqual(testCPU.programCounter, 0xC000, "CPUの開始アドレスが正しく設定されていない")
    }
    
    /// IPL抽出失敗時のテスト
    func testLoadAlphaMiniDosWithInvalidIpl() {
        // IPL抽出に失敗するディスクイメージを作成
        let diskImage = MockD88DiskImage(validIpl: false, validOs: true)
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertFalse(result, "無効なIPLの場合はロードに失敗すべき")
    }
    
    /// OS抽出失敗時のテスト
    func testLoadAlphaMiniDosWithInvalidOs() {
        // OS抽出に失敗するディスクイメージを作成
        let diskImage = MockD88DiskImage(validIpl: true, validOs: false)
        
        // ローダーを実行
        let result = loader.loadAlphaMiniDos(from: diskImage)
        
        // 結果を検証
        XCTAssertFalse(result, "無効なOSの場合はロードに失敗すべき")
    }
}

// MARK: - テスト用クラス

/// テスト用メモリ
class TestMemory: MemoryAccessing {
    // MARK: - プロパティ
    
    /// メモリデータ
    private var memory = [UInt16: UInt8]()
    
    // MARK: - MemoryAccessingプロトコル実装
    
    func writeByte(_ value: UInt8, at address: UInt16) {
        memory[address] = value
    }
    
    func readByte(at address: UInt16) -> UInt8 {
        return memory[address] ?? 0
    }
    
    func readWord(at address: UInt16) -> UInt16 {
        let lowByte = readByte(at: address)
        let highByte = readByte(at: address + 1)
        return UInt16(highByte) << 8 | UInt16(lowByte)
    }
    
    func writeWord(_ value: UInt16, at address: UInt16) {
        let lowByte = UInt8(value & 0xFF)
        let highByte = UInt8(value >> 8)
        writeByte(lowByte, at: address)
        writeByte(highByte, at: address + 1)
    }
    
    func switchBank(_ bank: Int, for area: MemoryArea) {
        // テスト用の簡易実装のため何もしない
    }
    
    func setROMEnabled(_ enabled: Bool, for area: MemoryArea) {
        // テスト用の簡易実装のため何もしない
    }
}

/// テスト用CPU
class TestCPU: CpuControlling {
    // MARK: - プロパティ
    
    /// プログラムカウンタ
    var programCounter: UInt16 = 0
    
    // MARK: - CpuControllingプロトコル実装
    
    func setStartAddress(_ address: UInt16) {
        programCounter = address
    }
    
    func setProgramCounter(address: Int) {
        programCounter = UInt16(address)
    }
    
    func startExecution() {
        // テスト用の簡易実装のため何もしない
    }
    
    func stopExecution() {
        // テスト用の簡易実装のため何もしない
    }
}

/// モックD88DiskImage
class MockD88DiskImage: D88DiskImage {
    // MARK: - プロパティ
    
    /// 有効なIPLを持つかどうか
    private let hasValidIpl: Bool
    
    /// 有効なOSを持つかどうか
    private let hasValidOs: Bool
    
    // MARK: - 初期化
    
    init(validIpl: Bool = true, validOs: Bool = true) {
        self.hasValidIpl = validIpl
        self.hasValidOs = validOs
        super.init()
        
        // テスト用のセクタデータを作成
        createMockSectorData()
    }
    
    // MARK: - プライベートメソッド
    
    /// テスト用のセクタデータを作成
    private func createMockSectorData() {
        // セクタデータを作成（実際のデータはオーバーライドメソッドで提供）
        // 注：D88DiskImageの内部実装にアクセスできないため、
        // extractAlphaMiniDosIpl()とextractAlphaMiniDosOs()をオーバーライドして
        // テストデータを提供します
    }
    
    // MARK: - オーバーライド
    
    override func readSector(track: Int, sector: Int) -> [UInt8]? {
        // IPLセクタ（トラック0、セクタ1）の場合
        if track == 0 && sector == 1 {
            if !hasValidIpl {
                return nil
            }
            
            // テスト用のIPLデータを返す
            return [UInt8(0xF3), UInt8(0xC3)] + Array(repeating: UInt8(0), count: 254)
        }
        
        // その他のセクタは親クラスの実装を使用
        return super.readSector(track: track, sector: sector)
    }
    
    override func loadOsSectors() -> [[UInt8]]? {
        if !hasValidOs {
            return nil
        }
        
        // テスト用のOSデータを返す
        let sector1: [UInt8] = [0x01, 0x02] + Array(repeating: 0, count: 254)
        let sector2: [UInt8] = [0x03, 0x04] + Array(repeating: 0, count: 254)
        
        return [sector1, sector2]
    }
    
    override func isAlphaMiniDos() -> Bool {
        return hasValidIpl
    }
    
    override func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        // スーパークラスの実装を使用
        return super.readSector(track: track, side: side, sectorID: sectorID)
    }
    
    /// ALPHA-MINI-DOSのOS部分を抽出（オーバーライド）
    override func extractAlphaMiniDosOs() -> [UInt8]? {
        if hasValidOs {
            return [UInt8(0x01), UInt8(0x02)] + Array(repeating: UInt8(0), count: 254)
        } else {
            return nil
        }
    }
    

}
