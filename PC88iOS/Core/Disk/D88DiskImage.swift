//
//  D88DiskImage.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

// CpuControllingプロトコルはD88OsLoader.swiftで定義されているため、ここでは定義しません

/// D88形式のディスクイメージ
class D88DiskImage: DiskImageAccessing {
    // MARK: - 定数
    
    /// D88ヘッダサイズ
    private let headerSize = 0x2B0
    
    /// ALPHA-MINI-DOSのIPLオフセット
    private let alphaMiniDosIplOffset = 0x02C0
    
    /// ALPHA-MINI-DOSのOS部分のオフセット
    private let alphaMiniDosOsOffset = 0x02C0
    
    /// 最大トラック数
    private let maxTracks = 164  // 両面82トラック
    
    /// 最大セクタ数/トラック
    private let maxSectorsPerTrack = 26
    
    /// ディスクタイプ定数
    private let diskType2D: UInt8 = 0x00   // 2D
    private let diskType2DD: UInt8 = 0x10  // 2DD
    private let diskType2HD: UInt8 = 0x20  // 2HD
    private let diskType1D: UInt8 = 0x30   // 1D
    private let diskType1DD: UInt8 = 0x40  // 1DD
    
    // MARK: - プロパティ
    
    /// ディスク名
    private var diskName: String = ""
    
    /// 書き込み保護フラグ
    private var writeProtected: Bool = false
    
    /// ディスクの種類
    private var diskType: UInt8 = 0
    
    /// トラックテーブル
    private var trackTable: [UInt32] = Array(repeating: 0, count: 164)
    
    /// セクタデータ
    private var sectorData: [TrackSectorData] = []
    
    /// ディスクイメージデータ
    private var diskData: Data = Data()
    
    /// 書き込み保護状態
    var isWriteProtected: Bool {
        return writeProtected
    }
    
    // MARK: - 初期化
    
    init() {
        // 初期化時は空のディスクイメージ
    }
    
    // MARK: - DiskImageAccessing プロトコル実装
    
    func load(from url: URL) -> Bool {
        do {
            // ファイルからデータを読み込み
            let data = try Data(contentsOf: url)
            return loadFromData(data)
        } catch {
            PC88Logger.disk.error("ディスクイメージの読み込みに失敗: \(error)")
            return false
        }
    }
    
    func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        // トラック内のセクタを検索
        // トラックインデックスは実際には使用しない
        _ = track * 2 + side
        
        for trackData in sectorData where trackData.track == track && trackData.side == side {
            for sector in trackData.sectors where sector.id.cylinder == sectorID.cylinder &&
            sector.id.head == sectorID.head &&
            sector.id.record == sectorID.record {
                return sector.data
            }
        }
        
        return nil
    }
    
    func writeSector(track: Int, side: Int, sectorID: SectorID, data: Data) -> Bool {
        // 書き込み保護チェック
        if writeProtected {
            return false
        }
        
        // トラック内のセクタを検索して書き込み
        // トラックインデックスは実際には使用しない
        _ = track * 2 + side
        
        for trackIndex in 0..<sectorData.count {
            let trackData = sectorData[trackIndex]
            if trackData.track == track && trackData.side == side {
                for sectorIndex in 0..<trackData.sectors.count where trackData.sectors[sectorIndex].id.cylinder == sectorID.cylinder &&
                trackData.sectors[sectorIndex].id.head == sectorID.head &&
                trackData.sectors[sectorIndex].id.record == sectorID.record {
                    // セクタデータを更新
                    var newSector = trackData.sectors[sectorIndex]
                    newSector.data = data
                    sectorData[trackIndex].sectors[sectorIndex] = newSector
                    return true
                }
            }
        }
        
        return false
    }
    
    func getDiskStatus() -> DiskStatus {
        // トラック数とサイド数を計算
        var maxTrack = 0
        var hasSide1 = false
        
        for trackData in sectorData {
            if trackData.track > maxTrack {
                maxTrack = trackData.track
            }
            if trackData.side == 1 {
                hasSide1 = true
            }
        }
        
        return DiskStatus(
            isWriteProtected: writeProtected,
            trackCount: maxTrack + 1,
            sideCount: hasSide1 ? 2 : 1
        )
    }
    
    func getFileList() -> [DiskFileInfo] {
        // ファイル一覧の取得（PC-88のディレクトリ構造に依存）
        // 簡易実装として空の配列を返す
        return []
    }
    
    // MARK: - 追加メソッド
    
    /// ディスクイメージをロード
    func loadDiskImage(from url: URL) -> Bool {
        return load(from: url)
    }
    
    /// Dataオブジェクトから直接ディスクイメージをロード
    func load(data: Data) -> Bool {
        return loadFromData(data)
    }
    
    /// 指定トラック・サイドのセクタID一覧を取得
    func getSectorIDs(track: Int, side: Int) -> [SectorID] {
        var result: [SectorID] = []
        
        for trackData in sectorData where trackData.track == track && trackData.side == side {
            for sector in trackData.sectors {
                result.append(sector.id)
            }
            break
        }
        
        return result
    }
    
    // MARK: - プライベートメソッド
    
    /// セクタサイズ(N)の値から実際のバイト数を計算
    private func calculateSectorSizeFromN(_ n: UInt8) -> Int {
        // N値が異常に大きい場合はオーバーフローを防止
        if n > 10 { // 10を超えるとサイズが非現実的になる（128KB以上）
            return 256 // 安全な値として256バイトを返す
        }
        return 128 << Int(n) // N=0: 128バイト, N=1: 256バイト, N=2: 512バイト, N=3: 1024バイト, ...
    }
    
    /// ディスクタイプに基づいた期待されるセクタ数を取得
    private func getExpectedSectorsPerTrack() -> Int {
        switch diskType {
        case diskType2D:
            return 16  // 2D: 16セクタ/トラック
        case diskType2DD:
            return 16  // 2DD: 16セクタ/トラック
        case diskType2HD:
            return 26  // 2HD: 26セクタ/トラック
        case diskType1D, diskType1DD:
            return 8   // 1D/1DD: 8セクタ/トラック
        default:
            return 16  // デフォルト値
        }
    }
    
    /// ディスクタイプの文字列表現を取得
    private func getDiskTypeString() -> String {
        switch diskType {
        case diskType2D: return "2D"
        case diskType2DD: return "2DD"
        case diskType2HD: return "2HD"
        case diskType1D: return "1D"
        case diskType1DD: return "1DD"
        default: return "不明(\(diskType))"
        }
    }
    
    /// データからディスクイメージをロード
    private func loadFromData(_ data: Data) -> Bool {
        // データサイズの検証
        guard validateDataSize(data) else { return false }
        
        // ディスクイメージデータを保存
        diskData = data
        
        // ヘッダ情報の読み取り
        if !parseHeader(data) { return false }
        
        // トラック情報の読み取り
        if !parseTrackInfo(data) { return false }
        
        return true
    }
    
    /// データサイズの検証
    private func validateDataSize(_ data: Data) -> Bool {
        guard data.count >= headerSize else {
            PC88Logger.disk.error("ディスクイメージデータが小さすぎます")
            return false
        }
        return true
    }
    
    /// ヘッダ情報の読み取り
    private func parseHeader(_ data: Data) -> Bool {
        // ディスク名の読み取り
        let nameData = data.subdata(in: 0..<16)
        diskName = String(data: nameData, encoding: .shiftJIS) ?? ""
        diskName = diskName.trimmingCharacters(in: .controlCharacters)
        PC88Logger.disk.debug("ディスク名: \(self.diskName)")
        
        // 書き込み保護フラグ
        writeProtected = data[0x1A] != 0
        PC88Logger.disk.debug("書き込み保護: \(self.writeProtected)")
        
        // ディスクの種類
        diskType = data[0x1B]
        PC88Logger.disk.debug("ディスクタイプ: \(self.getDiskTypeString()) (\(self.diskType))")
        
        // トラックテーブルの読み取り
        for i in 0..<maxTracks {
            let offset = 0x20 + i * 4
            if offset + 4 <= data.count {
                trackTable[i] = data.withUnsafeBytes { bytes in
                    bytes.load(fromByteOffset: offset, as: UInt32.self)
                }
            }
        }
        
        return true
    }
    
    /// トラック情報の読み取り
    private func parseTrackInfo(_ data: Data) -> Bool {
        // セクタデータの読み取り
        sectorData = []
        
        for i in 0..<maxTracks {
            parseTrack(data, trackIndex: i)
        }
        
        return true
    }
    
    /// 個別トラックの解析
    private func parseTrack(_ data: Data, trackIndex: Int) {
        let trackOffset = Int(trackTable[trackIndex])
        if trackOffset == 0 || trackOffset >= data.count {
            return
        }
        
        // トラック情報の読み取り
        // D88形式では物理トラック番号は0から始まる
        let track = trackIndex / 2  // トラック番号は0から始まる
        let side = trackIndex % 2   // サイドと0（表）、1（裏）
        
        // セクタ数の読み取り
        guard trackOffset + 4 <= data.count else { return }
        
        // アライメントされていないメモリからのUInt16読み込みを避ける
        let lowByte = UInt16(data[trackOffset])
        let highByte = UInt16(data[trackOffset + 1])
        let sectorCount = Int(lowByte | (highByte << 8))
        
        if sectorCount == 0 || sectorCount > maxSectorsPerTrack {
            return
        }
        
        parseSectors(data, track: track, side: side, trackOffset: trackOffset, sectorCount: sectorCount)
    }
    
    /// セクタデータの解析
    private func parseSectors(_ data: Data, track: Int, side: Int, trackOffset: Int, sectorCount: Int) {
        var currentOffset = trackOffset + 4
        
        for _ in 0..<sectorCount {
            if let nextOffset = parseSector(data, track: track, side: side, currentOffset: currentOffset) {
                currentOffset = nextOffset
            } else {
                break
            }
        }
    }
    
    /// 個別セクタの解析
    private func parseSector(_ data: Data, track: Int, side: Int, currentOffset: Int) -> Int? {
        guard currentOffset + 0x10 <= data.count else { return nil }
        
        // セクタヘッダの読み取り
        let c = data[currentOffset]       // シリンダ番号(C)
        let h = data[currentOffset + 1]   // ヘッド/サイド(H)
        let r = data[currentOffset + 2]   // レコード番号(R)
        let n = data[currentOffset + 3]   // セクタサイズ(N)
        
        // セクタ数の確認
        _ = UInt16(data[currentOffset + 0x04]) | (UInt16(data[currentOffset + 0x05]) << 8)
        
        // 記録密度と削除フラグの確認
        _ = data[currentOffset + 0x06]  // 0x00=倍密度, 0x40=単密度, 0x01=高密度
        _ = data[currentOffset + 0x07]  // 0x00=通常, 0x10=削除
        
        // ステータスの確認
        _ = data[currentOffset + 0x08]  // 0x00=正常, 他はエラー
        
        // アライメントされていないメモリからのUInt16読み込みを避ける
        let lowByte = UInt16(data[currentOffset + 0x0E])
        let highByte = UInt16(data[currentOffset + 0x0F])
        let sectorSize = Int(lowByte | (highByte << 8))
        
        // セクタデータの読み取り用のオフセットを先に計算
        let dataOffset = currentOffset + 0x10
        
        // セクタサイズの検証と修正
        var sectors: [SectorData] = []
        var nextOffset = processSectorData(data, track: track, side: side, c: c, h: h, r: r, n: n,
                                           currentOffset: currentOffset, dataOffset: dataOffset,
                                           sectorSize: sectorSize, sectors: &sectors)
        
        // トラックデータの追加
        if !sectors.isEmpty {
            let trackData = TrackSectorData(track: track, side: side, sectors: sectors)
            sectorData.append(trackData)
        }
        
        return nextOffset
    }
    
    /// セクタデータの処理
    private func processSectorData(_ data: Data, track: Int, side: Int, c: UInt8, h: UInt8, r: UInt8, n: UInt8,
                                   currentOffset: Int, dataOffset: Int, sectorSize: Int, sectors: inout [SectorData]) -> Int? {
        // 理論上のセクタサイズと実際のセクタサイズの確認
        let theoreticalSize = calculateSectorSizeFromN(n)
        
        // セクタサイズの異常値チェック
        let isValidSectorSize = sectorSize > 0 && sectorSize <= 8192 // 8KBを上限とする
        
        if !isValidSectorSize {
            PC88Logger.disk.warning("セクタサイズが異常です - N=\(n) (理論値: \(theoreticalSize)バイト) vs 実際: \(sectorSize)バイト)")
            
            // ALPHA-MINI-DOSの特別処理
            if isAlphaMiniDos() {
                // IPLセクタ（トラック0、セクタ1）またはその他の重要なセクタの場合
                if (c == 0 && r == 1) || (track == 0 && side == 0) {
                    PC88Logger.disk.debug("  ALPHA-MINI-DOSの重要セクタを検出しました。特別処理を適用します。")
                    // 固定サイズ（256バイト）を使用 - 標準的なセクタサイズ
                    let specialSize = 256
                    let safeOffset = min(dataOffset, data.count - 1)
                    let safeSize = min(specialSize, data.count - safeOffset)
                    
                    // セクタIDを修正（異常な値の場合）
                    let correctedC = c > 80 ? UInt8(track) : c  // 異常な値の場合はトラック番号を使用
                    let correctedH = h > 1 ? UInt8(side) : h    // 異常な値の場合はサイド番号を使用
                    let correctedR = r > 26 ? UInt8(1) : r      // 異常な値の場合は1を使用
                    let correctedN = n > 3 ? UInt8(1) : n       // 異常な値の場合は1（256バイト）を使用
                    
                    let sectorID = SectorID(cylinder: correctedC, head: correctedH, record: correctedR, size: correctedN)
                    let sector = SectorData(id: sectorID, data: data.subdata(in: safeOffset..<(safeOffset + safeSize)))
                    sectors.append(sector)
                    PC88Logger.disk.debug("  修正されたセクタID: C=\(correctedC), H=\(correctedH), R=\(correctedR), N=\(correctedN) (\(safeSize)バイト)")
                    return currentOffset + 0x10 + sectorSize
                }
            }
            
            // 異常なセクタサイズの場合、理論値を使用
            if theoreticalSize > 0 && theoreticalSize <= 8192 {
                PC88Logger.disk.debug("  理論値を使用します: \(theoreticalSize)バイト")
                // 理論値を使用
                let correctedSize = min(theoreticalSize, data.count - dataOffset)
                let sectorID = SectorID(cylinder: c, head: h, record: r, size: n)
                let sector = SectorData(id: sectorID, data: data.subdata(in: dataOffset..<(dataOffset + correctedSize)))
                sectors.append(sector)
                return currentOffset + 0x10 + sectorSize
            } else {
                // 理論値も異常な場合は、固定の安全な値を使用
                PC88Logger.disk.warning("  理論値も異常なため、安全な固定値（256バイト）を使用します")
                let safeSize = min(256, data.count - dataOffset)
                let sectorID = SectorID(cylinder: c, head: h, record: r, size: 1) // N=1 (256バイト)
                let sector = SectorData(id: sectorID, data: data.subdata(in: dataOffset..<(dataOffset + safeSize)))
                sectors.append(sector)
                return currentOffset + 0x10 + sectorSize
            }
        } else if theoreticalSize != sectorSize {
            PC88Logger.disk.warning("セクタサイズの不一致 - N=\(n) (理論値: \(theoreticalSize)バイト) vs 実際: \(sectorSize)バイト)")
        }
        
        // セクタIDの異常値チェック
        let isValidID = c < 80 && h < 2 && r < 30 // 一般的な制限
        if !isValidID {
            PC88Logger.disk.warning("セクタIDが異常です - C=\(c), H=\(h), R=\(r)")
            
            // ALPHA-MINI-DOSの場合、異常なセクタIDを修正
            if isAlphaMiniDos() {
                // セクタデータの読み取り
                guard dataOffset + sectorSize <= data.count else { return nil }
                let sectorDataChunk = data.subdata(in: dataOffset..<dataOffset + sectorSize)
                
                // セクタIDを修正（異常な値の場合）
                let correctedC = c > 80 ? UInt8(track) : c  // 異常な値の場合はトラック番号を使用
                let correctedH = h > 1 ? UInt8(side) : h    // 異常な値の場合はサイド番号を使用
                let correctedR = r > 26 ? UInt8(sectors.count + 1) : r // 異常な値の場合は連番を使用
                
                PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタIDを修正しました - C=\(correctedC), H=\(correctedH), R=\(correctedR)")
                
                // 修正したセクタIDを使用
                let sectorID = SectorID(cylinder: correctedC, head: correctedH, record: correctedR, size: n)
                let sector = SectorData(id: sectorID, data: sectorDataChunk)
                sectors.append(sector)
                
                // 次のセクタへ
                return dataOffset + sectorSize
            }
        }
        
        // セクタデータの読み取り
        guard dataOffset + sectorSize <= data.count else { return nil }
        let sectorDataChunk = data.subdata(in: dataOffset..<dataOffset + sectorSize)
        
        // セクタ情報の作成
        let sectorID = SectorID(cylinder: c, head: h, record: r, size: n)
        let sector = SectorData(id: sectorID, data: sectorDataChunk)
        sectors.append(sector)
        
        // 次のセクタへ
        return currentOffset + 0x10 + sectorSize
    }

/// 指定されたトラックとセクタのデータを直接読み込む
/// - Parameters:
///   - track: トラック番号（0から始まる）
///   - sector: セクタ番号（1から始まる）
/// - Returns: セクタデータ（バイト配列）

private func isValidSectorID(_ sectorID: SectorID) -> Bool {
    return sectorID.cylinder < 80 && sectorID.head < 2 && sectorID.record < 30
}

private func isValidSectorSize(_ dataSize: Int) -> Bool {
    return dataSize > 0 && dataSize <= 8192 // 8KBを上限とする
}

private func hasValidContent(_ data: Data) -> Bool {
    guard data.count >= 10 else { return false }
    
    // 先頭バイトが0xC3（JP命令）または0x18（JR命令）で始まるかチェック
    let firstByte = data[0]
    return (firstByte == 0xC3 || firstByte == 0x18)
}

private func isAllFF(_ data: Data) -> Bool {
    return data.allSatisfy { $0 == 0xFF }
}

private func createDefaultIPLSector() -> Data {
    let defaultIPLSectorSize = 256 // 標準的なIPLセクタサイズ
    var defaultIPLSector = Data(count: defaultIPLSectorSize)
    
    // デフォルトIPLセクタを0xC9 (RET命令) で埋める - 最低限のブート処理
    defaultIPLSector.withUnsafeMutableBytes { ptr in
        if let baseAddress = ptr.baseAddress {
            memset(baseAddress, 0xC9, defaultIPLSectorSize)
        }
    }
    
    return defaultIPLSector
}

private func findTrack0Sector(sector: Int) -> (data: Data?, size: Int, sizeN: UInt8) {
    PC88Logger.disk.debug("トラック0を検索: ディスクタイプ=\(self.getDiskTypeString()), 期待セクタ数=\(self.getExpectedSectorsPerTrack())")
    
    // 有効なセクタデータを保持する変数
    var validSectorData: Data? = nil
    var validSectorSize: Int = 0
    var validSectorN: UInt8 = 0
    
    // 2Dフォーマットの場合の期待されるセクタサイズ
    let expectedSectorSize = diskType == diskType2D ? 256 : 0
    
    // トラック0のデータを検索
    let track0Data = sectorData.filter { $0.track == 0 }
    PC88Logger.disk.debug("  トラック0のデータブロック数: \(track0Data.count)")
    
    // トラック0のデータブロックをスキャン
    for trackData in track0Data {
        // すべてのセクタをチェック
        for (index, sectorInfo) in trackData.sectors.enumerated() {
            let sectorSize = self.calculateSectorSizeFromN(sectorInfo.id.size)
            PC88Logger.disk.debug("    セクタ\(index): C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record), N=\(sectorInfo.id.size) (\(sectorSize)バイト), データサイズ=\(sectorInfo.data.count)")
            
            // セクタIDの検証
            if !isValidSectorID(sectorInfo.id) {
                PC88Logger.disk.warning("    無効なセクタID - C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record)")
                continue // 無効なIDのセクタはスキップ
            }
            
            // データサイズの検証
            let dataSize = sectorInfo.data.count
            if !isValidSectorSize(dataSize) {
                PC88Logger.disk.warning("    無効なデータサイズ - \(dataSize)バイト")
                continue // 無効なサイズのセクタはスキップ
            }
            
            // シリンダ番号(C)=0、レコード番号(R)=セクタ番号のセクタを探す
            // PC-88では、セクタ番号は1から始まり、D88フォーマットのレコード番号も1から始まる
            // 柔軟な検索: 正確なマッチに加えて、レコード番号だけが一致するケースも考慮
            let exactMatch = sectorInfo.id.cylinder == 0 && sectorInfo.id.record == UInt8(sector)
            let recordOnlyMatch = sectorInfo.id.record == UInt8(sector)
            
            if exactMatch || recordOnlyMatch {
                let matchType = exactMatch ? "完全一致" : "レコード番号のみ一致"
                PC88Logger.disk.debug("  トラック0のセクタ\(sector)が見つかりました (\(matchType)): データサイズ=\(dataSize)")
                
                // データが全てFFで埋められているかチェック
                let allFF = isAllFF(sectorInfo.data)
                
                // データの内容を検証
                let hasValidContentFlag = hasValidContent(sectorInfo.data)
                
                // 2Dフォーマットの場合、期待されるセクタサイズと一致するかチェック
                let matchesExpectedSize = expectedSectorSize == 0 || dataSize == expectedSectorSize
                
                // 優先順位に基づいてセクタを選択
                if exactMatch && hasValidContentFlag && matchesExpectedSize {
                    // 最高優先度: 完全一致、有効なコンテンツ、期待サイズ
                    PC88Logger.disk.debug("  最適なセクタを発見しました: 完全一致、有効なコンテンツ、期待サイズ (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                    return (sectorInfo.data, dataSize, sectorInfo.id.size)
                } else if exactMatch && !allFF && matchesExpectedSize {
                    // 高優先度: 完全一致、FFでない、期待サイズ
                    PC88Logger.disk.debug("  有効なデータを含むセクタを発見しました (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                    validSectorData = sectorInfo.data
                    validSectorSize = dataSize
                    validSectorN = sectorInfo.id.size
                } else if exactMatch && !allFF {
                    // 中優先度: 完全一致、FFでない
                    PC88Logger.disk.debug("  有効なデータを含むセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                    validSectorData = sectorInfo.data
                    validSectorSize = dataSize
                    validSectorN = sectorInfo.id.size
                } else if recordOnlyMatch && !allFF && validSectorData == nil {
                    // 低優先度: レコード番号のみ一致、FFでない
                    PC88Logger.disk.debug("  レコード番号のみ一致するセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                    validSectorData = sectorInfo.data
                    validSectorSize = dataSize
                    validSectorN = sectorInfo.id.size
                } else if exactMatch && allFF && matchesExpectedSize && validSectorData == nil {
                    // 最低優先度: 完全一致、FF、期待サイズ
                    PC88Logger.disk.debug("  FFで埋められたセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                    validSectorData = sectorInfo.data
                    validSectorSize = dataSize
                    validSectorN = sectorInfo.id.size
                }
            }
        }
    }
    
    return (validSectorData, validSectorSize, validSectorN)
}

private func findTrack1Sector(sector: Int) -> (data: Data?, size: Int, sizeN: UInt8) {
    PC88Logger.disk.debug("  トラック0のセクタが見つからなかったため、物理トラック1を検索します")
    
    // 有効なセクタデータを保持する変数
    var validSectorData: Data? = nil
    var validSectorSize: Int = 0
    var validSectorN: UInt8 = 0
    
    let track1Data = sectorData.filter { $0.track == 1 && $0.side == 0 }
    
    for trackData in track1Data {
        for sectorInfo in trackData.sectors where sectorInfo.id.record == UInt8(sector) {
            let dataSize = sectorInfo.data.count
            if isValidSectorSize(dataSize) && !isAllFF(sectorInfo.data) {
                PC88Logger.disk.debug("  物理トラック1でセクタ\(sector)が見つかりました: データサイズ=\(dataSize)")
                validSectorData = sectorInfo.data
                validSectorSize = dataSize
                validSectorN = sectorInfo.id.size
                break
            }
        }
    }
    
    return (validSectorData, validSectorSize, validSectorN)
}

/// - Parameters:
/// - Returns: セクタデータ、失敗した場合はnil
func readSector(track: Int, sector: Int) -> [UInt8]? {
    var _: Data? = nil
    var _: Int = 0
    var _: UInt8 = 0
    
    // トラックとセクタの範囲チェック
    guard track >= 0 && track < maxTracks && sector >= 1 && sector <= maxSectorsPerTrack else {
        PC88Logger.disk.error("トラックまたはセクタが範囲外: track=\(track), sector=\(sector)")
        return nil
    }
    
    // ALPHA-MINI-DOSの特別処理: トラック0セクタ1のIPLを要求された場合
    if track == 0 && sector == 1 && isAlphaMiniDos() {
        PC88Logger.disk.debug("  ALPHA-MINI-DOSを検出しました。IPLを直接抽出します。")
        return extractAlphaMiniDosIpl()
    }
    
    // トラック0の場合は特別な処理を行う
    if track == 0 {
        return readTrack0Sector(sector: sector)
    }
    
    return readNormalTrackSector(track: track, sector: sector)
}

/// - Returns: セクタデータ、失敗した場合はnil
private func readTrack0Sector(sector: Int) -> [UInt8]? {
    // デフォルトのIPLセクタを用意（ディスクイメージが破損している場合用）
    let defaultIPLSector = createDefaultIPLSector()
    
    let (sectorData, sectorSize, sectorN) = findTrack0Sector(sector: sector)
    
    if let validData = sectorData {
        PC88Logger.disk.debug("  有効なセクタが見つかりました: サイズ=\(sectorSize), N=\(sectorN)")
        return [UInt8](validData)
    }
    
    let (track1Data, track1Size, track1N) = findTrack1Sector(sector: sector)
    
    if let validTrack1Data = track1Data {
        PC88Logger.disk.debug("  物理トラック1で有効なセクタが見つかりました: サイズ=\(track1Size), N=\(track1N)")
        return [UInt8](validTrack1Data)
    }
    
    // ここまでで有効なセクタが見つからなかった場合
    // ALPHA-MINI-DOSの特別処理を試みる
    if isAlphaMiniDos() {
        PC88Logger.disk.debug("  ALPHA-MINI-DOSを検出しました。IPLを直接抽出します。")
        return extractAlphaMiniDosIpl()
    }
    
    // レコード番号が一致するセクタを探す（最後の手段）
    let (validSectorData, validSectorSize, validSectorN) = findMatchingSectorsByRecord(sector: sector)
    
    // 有効なセクタが見つかった場合は返す
    if let data = validSectorData {
        PC88Logger.disk.debug("  トラック0のセクタ\(sector)の候補を使用します: N=\(validSectorN) (\(self.calculateSectorSizeFromN(validSectorN))バイト), データサイズ=\(validSectorSize)")
        return [UInt8](data)
    }
    
    // 最後の手段: デフォルトのIPLセクタを返す
    PC88Logger.disk.warning("  警告: 有効なセクタが見つかりませんでした。デフォルトのIPLセクタを使用します。")
    return [UInt8](defaultIPLSector)
}

private func findMatchingSectorsByRecord(sector: Int) -> (Data?, Int, UInt8) {
    var validSectorData: Data? = nil
    var validSectorSize: Int = 0
    var validSectorN: UInt8 = 0
    
    PC88Logger.disk.debug("  レコード番号のみで検索します")
    
    var matchingSectors: [(trackIndex: Int, sectorInfo: SectorData)] = []
    
    for (trackIndex, trackData) in sectorData.enumerated() {
        if trackData.track <= 1 {
            continue
        }
        for sectorInfo in trackData.sectors where sectorInfo.id.record == UInt8(sector) {
            let dataSize = sectorInfo.data.count
            if dataSize > 0 && dataSize <= 8192 {
                matchingSectors.append((trackIndex, sectorInfo))
            }
        }
    }
    
    PC88Logger.disk.debug("  レコード番号\(sector)に一致するセクタ数: \(matchingSectors.count)")
    
    if !matchingSectors.isEmpty {
        let nonEmptySectors = matchingSectors.filter { !$0.sectorInfo.data.allSatisfy { $0 == 0xFF } }
        
        if !nonEmptySectors.isEmpty {
            let (trackIndex, sectorInfo) = nonEmptySectors.first!
            let dataSize = sectorInfo.data.count
            PC88Logger.disk.debug("  トラック\(self.sectorData[trackIndex].track)で有効なセクタ\(sector)を発見しました: データサイズ=\(dataSize)")
            validSectorData = sectorInfo.data
            validSectorSize = dataSize
            validSectorN = sectorInfo.id.size
        } else if !matchingSectors.isEmpty {
            let (trackIndex, sectorInfo) = matchingSectors.first!
            let dataSize = sectorInfo.data.count
            PC88Logger.disk.debug("  トラック\(self.sectorData[trackIndex].track)でFFで埋められたセクタ\(sector)を発見しました: データサイズ=\(dataSize)")
            validSectorData = sectorInfo.data
            validSectorSize = dataSize
            validSectorN = sectorInfo.id.size
        }
    }
    
    return (validSectorData, validSectorSize, validSectorN)
}

/// - Parameters:
/// - Returns: セクタデータ、失敗した場合はnil
private func readNormalTrackSector(track: Int, sector: Int) -> [UInt8]? {
    
    // トラック0以外の場合は通常の検索を行う
    PC88Logger.disk.debug("  トラック\(track)を検索します")
    
    // 指定されたトラックのデータを検索
    let targetTrackData = sectorData.filter { $0.track == track }
    PC88Logger.disk.debug("  トラック\(track)のデータブロック数: \(targetTrackData.count)")
    
    // 指定されたトラックのデータが見つかった場合
    if !targetTrackData.isEmpty {
        // トラックデータをスキャン
        for trackData in targetTrackData {
            PC88Logger.disk.debug("  トラックデータ: track=\(trackData.track), side=\(trackData.side), sectors=\(trackData.sectors.count)")
            
            // セクタのID情報を表示
            for (index, sectorInfo) in trackData.sectors.enumerated() {
                PC88Logger.disk.debug("    セクタ\(index): C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record), N=\(sectorInfo.id.size), データサイズ=\(sectorInfo.data.count)")
            }
            
            // セクタを検索 - レコード番号(R)で検索
            for sectorInfo in trackData.sectors where sectorInfo.id.record == UInt8(sector) {
                let dataSize = sectorInfo.data.count
                if dataSize > 0 && dataSize <= 8192 { // セクタサイズの妥当性チェック
                    PC88Logger.disk.debug("  セクタ\(sector)が見つかりました: データサイズ=\(dataSize)")
                    // DataをUInt8配列に変換して返す
                    return [UInt8](sectorInfo.data)
                } else {
                    PC88Logger.disk.warning("  セクタ\(sector)のサイズが異常です: \(dataSize)バイト")
                }
            }
        }
        
        PC88Logger.disk.debug("  トラック\(track)にセクタ\(sector)が見つかりませんでした")
        return nil
    }
    
    // 物理トラック番号で見つからなかった場合、シリンダ番号(C)で再検索
    PC88Logger.disk.debug("  物理トラック\(track)が見つかりませんでした。シリンダ番号で再検索します。")
    
    // シリンダ番号で検索
    for trackData in sectorData {
        // セクタを検索 - シリンダ番号(C)とレコード番号(R)で検索
        let matchingSectors = trackData.sectors.filter {
            $0.id.cylinder == UInt8(track) && $0.id.record == UInt8(sector)
        }
        
        if let sectorInfo = matchingSectors.first {
            let dataSize = sectorInfo.data.count
            if dataSize > 0 && dataSize <= 8192 { // セクタサイズの妥当性チェック
                PC88Logger.disk.debug("  シリンダ\(track)、セクタ\(sector)が見つかりました: データサイズ=\(dataSize)")
                return [UInt8](sectorInfo.data)
            } else {
                PC88Logger.disk.warning("  シリンダ\(track)、セクタ\(sector)のサイズが異常です: \(dataSize)バイト)")
            }
        }
    }
    
    PC88Logger.disk.debug("  トラック\(track)、セクタ\(sector)が見つかりませんでした")
    return nil
}


// MARK: - ALPHA-MINI-DOS特別処理

/// デフォルトのIPLセクタを取得
private func getDefaultIplSector() -> [UInt8] {
    // 256バイトの空のIPLセクタを作成
    var defaultSector = [UInt8](repeating: 0, count: 256)
    
    // 基本的なブートローダーを設定
    // 0xF3: DI命令（割り込み禁止）
    // 0xC3 0x00 0x01: JP 0x0100（0x0100番地にジャンプ）
    defaultSector[0] = 0xF3
    defaultSector[1] = 0xC3
    defaultSector[2] = 0x00
    defaultSector[3] = 0x01
    
    return defaultSector
}

/// ディスク名を取得する
func getDiskName() -> String {
    return diskName
}

/// ディスクイメージがALPHA-MINI-DOSかどうかを判定
internal func isAlphaMiniDos() -> Bool {
    // 1. ディスク名でチェック（最も信頼性が高い）
    if diskName.contains("ALPHA-MINI") {
        return true
    }
    
    // 2. ディスクイメージのサイズが十分あるか確認
    guard diskData.count >= alphaMiniDosIplOffset + 256 else {
        return false
    }
    
    // 3. IPLの特徴的なバイトパターンをチェック
    let signatureOffset = alphaMiniDosIplOffset
    if diskData.count >= signatureOffset + 4 {
        let firstByte = diskData[signatureOffset]
        let secondByte = diskData[signatureOffset + 1]
        
        // DI命令（0xF3）で始まり、JP命令（0xC3）またはLD A,(nn)命令（0x3A）が続く
        if firstByte == 0xF3 && (secondByte == 0xC3 || secondByte == 0x3A) {
            return true
        }
    }
    
    // 4. トラック0のセクタデータをチェック
    for trackData in sectorData where trackData.track == 0 && trackData.side == 0 {
        for sector in trackData.sectors where sector.data.count >= 4 {
            let bytes = [UInt8](sector.data)
            // DI命令（0xF3）で始まり、JP命令（0xC3）またはLD A,(nn)命令（0x3A）が続く
            if bytes[0] == 0xF3 && (bytes[1] == 0xC3 || bytes[1] == 0x3A) {
                return true
            }
        }
    }
    
    return false
}

    /// ALPHA-MINI-DOSのIPLを直接抽出
    private func extractAlphaMiniDosIpl() -> [UInt8] {
        let iplSize = 256 // 標準的なIPLサイズ
        
        // IPLオフセットからデータを抽出
        guard alphaMiniDosIplOffset + iplSize <= diskData.count else {
            PC88Logger.disk.error("ALPHA-MINI-DOSのIPL抽出に失敗: ディスクイメージが小さすぎます")
            return getDefaultIplSector()
        }
        
        // IPLデータを取得
        let iplData = [UInt8](diskData.subdata(in: alphaMiniDosIplOffset..<alphaMiniDosIplOffset + iplSize))
        
        // IPLコードの典型的な特徴を確認
        if iplData.count >= 4 && iplData[0] == 0xF3 {
            // 正常なIPLを検出
            let secondByte = iplData[1]
            
            if secondByte == 0xC3 || secondByte == 0x3A {
                // 正常なIPLを返す
                return iplData
            }
        }
        
        // IPLが無効な場合、ディスクイメージ内を検索して有効なIPLを見つける
        PC88Logger.disk.debug("有効なIPLを検索中...")
        
        // ディスクイメージ内の複数の場所を検索
        let possibleOffsets = [0x02C0, 0x0000, 0x0100, 0x0200, 0x0300, 0x0400]
        
        for offset in possibleOffsets where offset != alphaMiniDosIplOffset {
            if offset + iplSize <= diskData.count {
                let candidateData = [UInt8](diskData.subdata(in: offset..<offset + iplSize))
                
                // 有効なIPLの特徴をチェック
                if candidateData.count >= 4 &&
                    candidateData[0] == 0xF3 &&
                    (candidateData[1] == 0xC3 || candidateData[1] == 0x3A) {
                    PC88Logger.disk.debug("オフセット0x\(String(format: "%04X", offset))で有効なIPLを発見")
                    return candidateData
                }
            }
        }
        
        // 有効なIPLが見つからない場合は、修正を試みる
        var modifiedIpl = iplData
        modifiedIpl[0] = 0xF3  // DI命令を先頭に設定
        
        // 2バイト目が無効な場合は修正
        if modifiedIpl[1] != 0xC3 && modifiedIpl[1] != 0x3A {
            modifiedIpl[1] = 0xC3  // JP命令を設定
            modifiedIpl[2] = 0x00  // アドレス下位バイト
            modifiedIpl[3] = 0x01  // アドレス上位バイト（0x0100にジャンプ）
        }
        
        PC88Logger.disk.debug("IPLを修正しました")
        return modifiedIpl
    }
    
    /// ALPHA-MINI-DOSのOS部分を抽出
    func extractAlphaMiniDosOs() -> [UInt8]? {
        if !isAlphaMiniDos() {
            return nil
        }
        
        // ALPHA-MINI-DOSのOS部分は大きめに取る
        let osSize = 4096 // OS部分のサイズを増やして確実に取得
        
        // OSオフセットからデータを抽出
        guard alphaMiniDosOsOffset + osSize <= diskData.count else {
            PC88Logger.disk.error("  ALPHA-MINI-DOSのOS抽出に失敗: ディスクイメージが小さすぎます")
            return nil
        }
        
        // OS部分のデータを取得
        let osData = [UInt8](diskData.subdata(in: alphaMiniDosOsOffset..<alphaMiniDosOsOffset + osSize))
        
        PC88Logger.disk.debug("  ALPHA-MINI-DOSのOS部分を抽出しました: オフセット=0x\(String(format: "%04X", self.alphaMiniDosOsOffset)), サイズ=\(osData.count)バイト")
        
        // OS部分の最初の32バイトを表示
        PC88Logger.disk.debug("  OS部分の最初の32バイト:")
        var hexLine = ""
        for i in 0..<min(32, osData.count) {
            if i % 16 == 0 && i > 0 {
                PC88Logger.disk.debug("\(hexLine)")
                hexLine = ""
            }
            hexLine += String(format: "%02X ", osData[i])
        }
        // 残りのデータがあれば出力
        if !hexLine.isEmpty {
            PC88Logger.disk.debug("\(hexLine)")
        }
        
        // OS部分の特徴を確認
        PC88Logger.disk.debug("  OS部分の特徴を確認中...")
        
        // 有効なコードか確認
        var validCodeFound = false
        for i in 0..<min(256, osData.count) {
            if osData[i] != 0 && osData[i] != 0xFF {
                validCodeFound = true
                break
            }
        }
        
        if validCodeFound {
            PC88Logger.disk.debug("  OS部分に有効なコードを確認しました")
        } else {
            PC88Logger.disk.warning("  警告: OS部分に有効なコードが見つかりません")
        }
        
        return osData
    }
    
    /// D88ディスクイメージからOSセクタを読み込む
    /// - Returns: 読み込まれたOSセクタのデータ配列、失敗した場合はnil
    func loadOsSectors() -> [[UInt8]]? {
        PC88Logger.disk.debug("D88DiskImage.loadOsSectors: OSセクタの読み込みを開始します")
        
        // ALPHA-MINI-DOSの場合は特殊処理
        if isAlphaMiniDos() {
            return loadAlphaMiniDosOsSectors()
        }
        
        // 通常のディスクイメージの場合
        // トラック0のデータを検索
        let track0Data = sectorData.filter { $0.track == 0 }
        if track0Data.isEmpty {
            PC88Logger.disk.error("  トラック0のデータが見つかりません")
            return nil
        }
        
        // ALPHA-MINI-DOSの特別処理
        if isAlphaMiniDos() {
            PC88Logger.disk.debug("  ALPHA-MINI-DOSを検出しました。OS部分を直接抽出します。")
            if let osData = extractAlphaMiniDosOs() {
                return [osData]
            }
        }
        
        // 通常のOS読み込み処理: セクタ2から連続して読み込む
        var osSectors: [[UInt8]] = []
        let maxSectors = getExpectedSectorsPerTrack()
        
        PC88Logger.disk.debug("  トラック0のセクタ2から連続読み込みを試行します (最大\(maxSectors)セクタ)")
        
        for sectorNumber in 2...maxSectors {
            if let sectorData = readSector(track: 0, sector: sectorNumber) {
                PC88Logger.disk.debug("  セクタ\(sectorNumber)を読み込みました (\(sectorData.count)バイト)")
                osSectors.append(sectorData)
            } else {
                PC88Logger.disk.debug("  セクタ\(sectorNumber)の読み込みに失敗したため、読み込みを終了します")
                break
            }
        }
        
        if osSectors.isEmpty {
            PC88Logger.disk.error("  OSセクタの読み込みに失敗しました")
            return nil
        }
        
        PC88Logger.disk.debug("  OSセクタの読み込みが完了しました: \(osSectors.count)セクタ")
        return osSectors
    }
    
    /// OSデータをメモリにロードする（仮想的なメモリ操作）
    /// - Parameters:
    ///   - memoryAddress: OSをロードするメモリアドレス
    ///   - memory: メモリアクセサ（省略時は仮想的な操作のみ）
    /// - Returns: ロードされたOSデータの合計サイズ、失敗した場合は0
    func loadOsToMemory(memoryAddress: Int, memory: MemoryAccessing? = nil) -> Int {
        guard let osSectors = loadOsSectors() else {
            PC88Logger.disk.error("  OSセクタが読み込めないため、メモリへのロードに失敗しました")
            return 0
        }
        
        var currentAddress = memoryAddress
        var totalSize = 0
        
        for (index, sectorData) in osSectors.enumerated() {
            PC88Logger.disk.debug("  セクタ\(index + 1)をメモリアドレス0x\(String(format: "%04X", currentAddress))にロード (\(sectorData.count)バイト)")
            
            // 実際のメモリに書き込み（メモリアクセサが提供されている場合）
            if let memory = memory {
                for (offset, byte) in sectorData.enumerated() {
                    let address = currentAddress + offset
                    // メモリ範囲チェック（64KBを超えないようにする）
                    if address < 0x10000 {
                        memory.writeByte(byte, at: UInt16(address))
                    } else {
                        PC88Logger.disk.warning("  警告: メモリアドレス0x\(String(format: "%04X", address))が64KB範囲を超えています")
                        break
                    }
                }
            }
            
            // 次のセクタのアドレスを計算
            currentAddress += sectorData.count
            totalSize += sectorData.count
        }
        
        PC88Logger.disk.debug("  OSデータをメモリアドレス0x\(String(format: "%04X", memoryAddress))にロードしました (合計\(totalSize)バイト)")
        return totalSize
    }
    
    /// OSの実行を開始する（仮想的な実行開始処理）
    /// - Parameter startAddress: OS実行開始アドレス
    /// - Returns: 実行開始の成否
    func executeOs(startAddress: Int) -> Bool {
        PC88Logger.disk.debug("D88DiskImage.executeOs: OSの実行を開始します (開始アドレス: 0x\(String(format: "%04X", startAddress)))")
        
        // ここでは実際の実行は行わず、成功したことにする
        // 実際のエミュレータ実装では、Z80のプログラムカウンタを設定し実行を開始する処理が必要
        
        return true
    }
    
    // MARK: - ALPHA-MINI-DOS OS読み込み特殊処理
    
    /// ALPHA-MINI-DOS用のOS部分を読み込む特殊処理
    /// - Returns: OSセクタデータの配列、失敗した場合はnil
    private func loadAlphaMiniDosOsSectors() -> [[UInt8]]? {
        PC88Logger.disk.debug("  ALPHA-MINI-DOS用のOS部分を特殊処理で読み込みます")
        
        // ALPHA-MINI-DOSの場合、トラック0のセクタ2から連続してOSが格納されている
        var osSectors: [[UInt8]] = []
        let maxSectorsToRead = 16 // ALPHA-MINI-DOSの一般的なOS部分のセクタ数
        
        for sectorNumber in 2...(maxSectorsToRead + 1) {
            // 直接データから読み込む方法を試す
            if let directData = readAlphaMiniDosSector(sectorNumber: sectorNumber) {
                // データが有効か確認（全てFFで埋められていないか）
                let isValidData = !directData.allSatisfy { $0 == 0xFF }
                if isValidData {
                    PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタ\(sectorNumber)を直接読み込みました (\(directData.count)バイト)")
                    osSectors.append(directData)
                } else {
                    PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタ\(sectorNumber)はデータが無効（全てFF）のため、スキップします")
                }
                continue
            }
            
            // 通常の方法でも試す
            if let sectorData = readSector(track: 0, sector: sectorNumber) {
                // データが有効か確認
                let isValidData = !sectorData.allSatisfy { $0 == 0xFF }
                if isValidData {
                    PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタ\(sectorNumber)を通常方法で読み込みました (\(sectorData.count)バイト)")
                    osSectors.append(sectorData)
                } else {
                    PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタ\(sectorNumber)はデータが無効（全てFF）のため、スキップします")
                }
            } else {
                PC88Logger.disk.debug("  ALPHA-MINI-DOS: セクタ\(sectorNumber)の読み込みに失敗したため、読み込みを終了します")
                break
            }
        }
        
        if osSectors.isEmpty {
            PC88Logger.disk.error("  ALPHA-MINI-DOS: OS部分の読み込みに失敗しました")
            return nil
        }
        
        PC88Logger.disk.debug("  ALPHA-MINI-DOS: OS部分の読み込みが完了しました: \(osSectors.count)セクタ")
        return osSectors
    }
    
    /// ALPHA-MINI-DOSのセクタを直接読み込む
    /// - Parameter sectorNumber: セクタ番号（1から始まる）
    /// - Returns: セクタデータ、失敗した場合はnil
    private func readAlphaMiniDosSector(sectorNumber: Int) -> [UInt8]? {
        // セクタ番号の範囲チェック
        guard sectorNumber >= 1 && sectorNumber <= 26 else { return nil }
        
        // ALPHA-MINI-DOSのディスクイメージでは、セクタデータが特定のオフセットに配置されている
        // セクタ1（IPL）は0x2C0から始まる
        let baseOffset = 0x2C0
        let sectorSize = 256 // ALPHA-MINI-DOSの標準セクタサイズ
        let sectorOffset = baseOffset + (sectorNumber - 1) * sectorSize
        
        // ディスクデータの範囲チェック
        guard sectorOffset + sectorSize <= diskData.count else {
            return nil
        }
        
        // セクタデータを抽出
        var extractedData: [UInt8] = []
        for i in 0..<sectorSize {
            extractedData.append(diskData[sectorOffset + i])
        }
        
        return extractedData
    }
    
    
    // MARK: - 補助構造体
    
    /// セクタデータ
    struct SectorData {
        let id: SectorID
        var data: Data
    }
    
    /// トラック内のセクタデータ
    struct TrackSectorData {
        let track: Int
        let side: Int
        var sectors: [SectorData]
    }
}
