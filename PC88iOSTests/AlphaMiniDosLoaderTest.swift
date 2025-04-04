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
        
        // テスト用のディスク名を設定
        self.diskName = hasValidIpl ? "ALPHA-MINI TEST" : "NORMAL DISK"
        
        // テスト用のディスクタイプを設定
        self.diskType = diskType2D
        
        // テスト用のセクタデータを作成
        createMockSectorData()
    }
    
    // MARK: - プライベートメソッド
    
    /// テスト用のセクタデータを作成
    private func createMockSectorData() {
        // トラック0のセクタデータを作成
        let track0 = TrackData(track: 0, side: 0)
        
        // IPLセクタ（セクタ1）
        let iplData = hasValidIpl ? [0xF3, 0xC3] + Array(repeating: 0, count: 254) : Array(repeating: 0xFF, count: 256)
        let iplSector = SectorData(
            id: SectorID(cylinder: 0, head: 0, record: 1, size: 1), // N=1 は256バイト
            data: Data(iplData),
            status: 0
        )
        track0.sectors.append(iplSector)
        
        // OSセクタ（セクタ2〜）
        if hasValidOs {
            let sector2Data = [0x01, 0x02] + Array(repeating: 0, count: 254)
            let sector2 = SectorData(
                id: SectorID(cylinder: 0, head: 0, record: 2, size: 1),
                data: Data(sector2Data),
                status: 0
            )
            track0.sectors.append(sector2)
            
            let sector3Data = [0x03, 0x04] + Array(repeating: 0, count: 254)
            let sector3 = SectorData(
                id: SectorID(cylinder: 0, head: 0, record: 3, size: 1),
                data: Data(sector3Data),
                status: 0
            )
            track0.sectors.append(sector3)
        }
        
        // セクタデータを追加
        sectorData.append(track0)
    }
    
    // MARK: - オーバーライド
    
    override func readSector(track: Int, sector: Int) -> [UInt8]? {
        if !hasValidIpl && track == 0 && sector == 1 {
            return nil
        }
        
        // スーパークラスの実装を使用
        return super.readSector(track: track, sector: sector)
    }
    
    override func loadOsSectors() -> [[UInt8]]? {
        if !hasValidOs {
            return nil
        }
        
        // テスト用のOSデータを返す
        let sector1 = [0x01, 0x02] + Array(repeating: 0, count: 254)
        let sector2 = [0x03, 0x04] + Array(repeating: 0, count: 254)
        
        return [sector1, sector2]
    }
    
    override func isAlphaMiniDos() -> Bool {
        return hasValidIpl
    }
    
    override func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        // スーパークラスの実装を使用
        return super.readSector(track: track, side: side, sectorID: sectorID)
    }
}
