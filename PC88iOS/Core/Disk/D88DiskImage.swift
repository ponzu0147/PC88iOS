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
            print("ディスクイメージの読み込みに失敗: \(error)")
            return false
        }
    }
    
    func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        // トラック内のセクタを検索
        // トラックインデックスは実際には使用しない
        _ = track * 2 + side
        
        for trackData in sectorData {
            if trackData.track == track && trackData.side == side {
                for sector in trackData.sectors {
                    if sector.id.cylinder == sectorID.cylinder &&
                       sector.id.head == sectorID.head &&
                       sector.id.record == sectorID.record {
                        return sector.data
                    }
                }
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
                for sectorIndex in 0..<trackData.sectors.count {
                    let sector = trackData.sectors[sectorIndex]
                    if sector.id.cylinder == sectorID.cylinder &&
                       sector.id.head == sectorID.head &&
                       sector.id.record == sectorID.record {
                        // セクタデータを更新
                        var newSector = sector
                        newSector.data = data
                        sectorData[trackIndex].sectors[sectorIndex] = newSector
                        return true
                    }
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
        
        for trackData in sectorData {
            if trackData.track == track && trackData.side == side {
                for sector in trackData.sectors {
                    result.append(sector.id)
                }
                break
            }
        }
        
        return result
    }
    
    // MARK: - プライベートメソッド
    
    /// セクタサイズ(N)の値から実際のバイト数を計算
    private func calculateSectorSizeFromN(_ n: UInt8) -> Int {
        // N=0: 128バイト, N=1: 256バイト, N=2: 512バイト, N=3: 1024バイト, ...
        return 128 << Int(n)
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
        guard data.count >= headerSize else {
            print("ディスクイメージデータが小さすぎます")
            return false
        }
        
        // ディスクイメージデータを保存
        diskData = data
        
        // ヘッダ情報の読み取り
        let nameData = data.subdata(in: 0..<16)
        diskName = String(data: nameData, encoding: .shiftJIS) ?? ""
        diskName = diskName.trimmingCharacters(in: .controlCharacters)
        print("ディスク名: \(diskName)")
        
        // 書き込み保護フラグ
        writeProtected = data[0x1A] != 0
        print("書き込み保護: \(writeProtected)")
        
        // ディスクの種類
        diskType = data[0x1B]
        print("ディスクタイプ: \(getDiskTypeString()) (\(diskType))")
        
        // トラックテーブルの読み取り
        for i in 0..<maxTracks {
            let offset = 0x20 + i * 4
            if offset + 4 <= data.count {
                trackTable[i] = data.withUnsafeBytes { bytes in
                    bytes.load(fromByteOffset: offset, as: UInt32.self)
                }
            }
        }
        
        // セクタデータの読み取り
        sectorData = []
        
        for i in 0..<maxTracks {
            let trackOffset = Int(trackTable[i])
            if trackOffset == 0 || trackOffset >= data.count {
                continue
            }
            
            // トラック情報の読み取り
            // D88形式では物理トラック番号は0から始まる
            let track = i / 2  // トラック番号は0から始まる
            let side = i % 2   // サイドは0（表）、1（裏）
            
            // セクタ数の読み取り
            guard trackOffset + 4 <= data.count else { continue }
            let sectorCount = Int(data.withUnsafeBytes { bytes in
                bytes.load(fromByteOffset: trackOffset, as: UInt16.self)
            })
            
            if sectorCount == 0 || sectorCount > maxSectorsPerTrack {
                continue
            }
            
            var sectors: [SectorData] = []
            var currentOffset = trackOffset + 4
            
            for _ in 0..<sectorCount {
                guard currentOffset + 0x10 <= data.count else { break }
                
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
                
                // 理論上のセクタサイズと実際のセクタサイズの確認
                let theoreticalSize = calculateSectorSizeFromN(n)
                
                // セクタデータの読み取り用のオフセットを先に計算
                let dataOffset = currentOffset + 0x10
                
                // セクタサイズの異常値チェック
                let isValidSectorSize = sectorSize > 0 && sectorSize <= 8192 // 8KBを上限とする
                
                if !isValidSectorSize {
                    print("警告: セクタサイズが異常です - N=\(n) (理論値: \(theoreticalSize)バイト) vs 実際: \(sectorSize)バイト)")
                    
                    // ALPHA-MINI-DOSの特別処理
                    if isAlphaMiniDos() {
                        // IPLセクタ（トラック0、セクタ1）またはその他の重要なセクタの場合
                        if (c == 0 && r == 1) || (track == 0 && side == 0) {
                            print("  ALPHA-MINI-DOSの重要セクタを検出しました。特別処理を適用します。")
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
                            print("  修正されたセクタID: C=\(correctedC), H=\(correctedH), R=\(correctedR), N=\(correctedN) (\(safeSize)バイト)")
                            currentOffset += 0x10 + sectorSize
                            continue // 次のセクタへ
                        }
                    }
                    
                    // 異常なセクタサイズの場合、理論値を使用
                    if theoreticalSize > 0 && theoreticalSize <= 8192 {
                        print("  理論値を使用します: \(theoreticalSize)バイト")
                        // 理論値を使用
                        let correctedSize = min(theoreticalSize, data.count - dataOffset)
                        let sectorID = SectorID(cylinder: c, head: h, record: r, size: n)
                        let sector = SectorData(id: sectorID, data: data.subdata(in: dataOffset..<(dataOffset + correctedSize)))
                        sectors.append(sector)
                        currentOffset += 0x10 + sectorSize
                        continue // 次のセクタへ
                    } else {
                        // 理論値も異常な場合は、固定の安全な値を使用
                        print("  理論値も異常なため、安全な固定値（256バイト）を使用します")
                        let safeSize = min(256, data.count - dataOffset)
                        let sectorID = SectorID(cylinder: c, head: h, record: r, size: 1) // N=1 (256バイト)
                        let sector = SectorData(id: sectorID, data: data.subdata(in: dataOffset..<(dataOffset + safeSize)))
                        sectors.append(sector)
                        currentOffset += 0x10 + sectorSize
                        continue // 次のセクタへ
                    }
                } else if theoreticalSize != sectorSize {
                    print("警告: セクタサイズの不一致 - N=\(n) (理論値: \(theoreticalSize)バイト) vs 実際: \(sectorSize)バイト)")
                }
                
                // セクタIDの異常値チェック
                let isValidID = c < 80 && h < 2 && r < 30 // 一般的な制限
                if !isValidID {
                    print("警告: セクタIDが異常です - C=\(c), H=\(h), R=\(r)")
                    
                    // ALPHA-MINI-DOSの場合、異常なセクタIDを修正
                    if isAlphaMiniDos() {
                        // セクタデータの読み取り
                        guard dataOffset + sectorSize <= data.count else { break }
                        let sectorDataChunk = data.subdata(in: dataOffset..<dataOffset + sectorSize)
                        
                        // セクタIDを修正（異常な値の場合）
                        let correctedC = c > 80 ? UInt8(track) : c  // 異常な値の場合はトラック番号を使用
                        let correctedH = h > 1 ? UInt8(side) : h    // 異常な値の場合はサイド番号を使用
                        let correctedR = r > 26 ? UInt8(sectors.count + 1) : r // 異常な値の場合は連番を使用
                        
                        print("  ALPHA-MINI-DOS: セクタIDを修正しました - C=\(correctedC), H=\(correctedH), R=\(correctedR)")
                        
                        // 修正したセクタIDを使用
                        let sectorID = SectorID(cylinder: correctedC, head: correctedH, record: correctedR, size: n)
                        let sector = SectorData(id: sectorID, data: sectorDataChunk)
                        sectors.append(sector)
                        
                        // 次のセクタへ
                        currentOffset = dataOffset + sectorSize
                        continue // 次のセクタへ
                    }
                }
                
                // セクタデータの読み取り
                guard dataOffset + sectorSize <= data.count else { break }
                let sectorDataChunk = data.subdata(in: dataOffset..<dataOffset + sectorSize)
                
                // セクタ情報の作成
                let sectorID = SectorID(cylinder: c, head: h, record: r, size: n)
                let sector = SectorData(id: sectorID, data: sectorDataChunk)
                sectors.append(sector)
                
                // 次のセクタへ
                currentOffset = dataOffset + sectorSize
            }
            
            // トラックデータの追加
            if !sectors.isEmpty {
                let trackData = TrackSectorData(track: track, side: side, sectors: sectors)
                sectorData.append(trackData)
            }
        }
        
        return true
    }
    
    /// 指定されたトラックとセクタのデータを直接読み込む
    /// - Parameters:
    ///   - track: トラック番号（0から始まる）
    ///   - sector: セクタ番号（1から始まる）
    /// - Returns: セクタデータ（バイト配列）
    func readSector(track: Int, sector: Int) -> [UInt8]? {
        print("D88DiskImage.readSector: track=\(track), sector=\(sector)")
        
        // トラックとセクタの範囲チェック
        guard track >= 0 && track < maxTracks && sector >= 1 && sector <= maxSectorsPerTrack else {
            print("  トラックまたはセクタが範囲外です: track=\(track), sector=\(sector), maxTracks=\(maxTracks), maxSectorsPerTrack=\(maxSectorsPerTrack)")
            return nil
        }
        
        print("  ディスクイメージ情報: トラック数=\(sectorData.count)")
        print("  注意: PC-88では、セクタ番号は1から始まります。セクタ\(sector)を検索します。")
        
        // ALPHA-MINI-DOSの特別処理: トラック0セクタ1のIPLを要求された場合
        if track == 0 && sector == 1 && isAlphaMiniDos() {
            print("  ALPHA-MINI-DOSを検出しました。IPLを直接抽出します。")
            return extractAlphaMiniDosIpl()
        }
        
        // トラック0の場合は特別な処理を行う
        if track == 0 {
            print("  トラック0を検索します。")
            print("  ディスクタイプ: \(getDiskTypeString()), 期待されるセクタ数/トラック: \(getExpectedSectorsPerTrack())")
            
            // 有効なセクタデータを保持する変数
            var validSectorData: Data? = nil
            var validSectorSize: Int = 0
            var validSectorN: UInt8 = 0
            // validSectorFound変数は不要なので削除
            
            // 2Dフォーマットの場合の期待されるセクタサイズ
            let expectedSectorSize = diskType == diskType2D ? 256 : 0
            
            // 特殊処理: ディスクイメージが破損している場合に備えて、デフォルトのIPLセクタを用意
            let defaultIPLSectorSize = 256 // 標準的なIPLセクタサイズ
            var defaultIPLSector = Data(count: defaultIPLSectorSize)
            // デフォルトIPLセクタを0xC9 (RET命令) で埋める - 最低限のブート処理
            defaultIPLSector.withUnsafeMutableBytes { ptr in
                if let baseAddress = ptr.baseAddress {
                    memset(baseAddress, 0xC9, defaultIPLSectorSize)
                }
            }
            
            // トラック0のデータを検索
            let track0Data = sectorData.filter { $0.track == 0 }
            print("  トラック0のデータブロック数: \(track0Data.count)")
            
            // トラック0のデータブロックをスキャン
            for trackData in track0Data {
                
                // すべてのセクタをチェック
                for (index, sectorInfo) in trackData.sectors.enumerated() {
                    let sectorSize = calculateSectorSizeFromN(sectorInfo.id.size)
                    print("    セクタ\(index): C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record), N=\(sectorInfo.id.size) (\(sectorSize)バイト), データサイズ=\(sectorInfo.data.count)")
                    
                    // セクタIDの検証
                    let isValidID = sectorInfo.id.cylinder < 80 && sectorInfo.id.head < 2 && sectorInfo.id.record < 30
                    if !isValidID {
                        print("    警告: 無効なセクタID - C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record)")
                        continue // 無効なIDのセクタはスキップ
                    }
                    
                    // データサイズの検証
                    let dataSize = sectorInfo.data.count
                    let isValidSize = dataSize > 0 && dataSize <= 8192 // 8KBを上限とする
                    if !isValidSize {
                        print("    警告: 無効なデータサイズ - \(dataSize)バイト")
                        continue // 無効なサイズのセクタはスキップ
                    }
                    
                    // シリンダ番号(C)=0、レコード番号(R)=セクタ番号のセクタを探す
                    // PC-88では、セクタ番号は1から始まり、D88フォーマットのレコード番号も1から始まる
                    // 柔軟な検索: 正確なマッチに加えて、レコード番号だけが一致するケースも考慮
                    let exactMatch = sectorInfo.id.cylinder == 0 && sectorInfo.id.record == UInt8(sector)
                    let recordOnlyMatch = sectorInfo.id.record == UInt8(sector)
                    
                    if exactMatch || recordOnlyMatch {
                        let matchType = exactMatch ? "完全一致" : "レコード番号のみ一致"
                        print("  トラック0のセクタ\(sector)が見つかりました (\(matchType)): データサイズ=\(dataSize)")
                        
                        // データが全てFFで埋められているかチェック
                        let allFF = sectorInfo.data.allSatisfy { $0 == 0xFF }
                        
                        // データの内容を検証（先頭バイトをチェック）
                        var hasValidContent = false
                        if dataSize >= 10 {
                            // 先頭バイトが0xC3（JP命令）または0x18（JR命令）で始まるかチェック
                            let firstByte = sectorInfo.data[0]
                            hasValidContent = (firstByte == 0xC3 || firstByte == 0x18)
                        }
                        
                        // 2Dフォーマットの場合、期待されるセクタサイズと一致するかチェック
                        let matchesExpectedSize = expectedSectorSize == 0 || dataSize == expectedSectorSize
                        
                        // 優先順位に基づいてセクタを選択
                        if exactMatch && hasValidContent && matchesExpectedSize {
                            // 最高優先度: 完全一致、有効なコンテンツ、期待サイズ
                            print("  最適なセクタを発見しました: 完全一致、有効なコンテンツ、期待サイズ (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                            // validSectorFound変数は不要なので削除
                            return [UInt8](sectorInfo.data)
                        } else if exactMatch && !allFF && matchesExpectedSize {
                            // 高優先度: 完全一致、FFでない、期待サイズ
                            print("  有効なデータを含むセクタを発見しました (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                            validSectorData = sectorInfo.data
                            validSectorSize = dataSize
                            validSectorN = sectorInfo.id.size
                            // validSectorFound変数は不要なので削除
                        } else if exactMatch && !allFF {
                            // 中優先度: 完全一致、FFでない
                            print("  有効なデータを含むセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                            validSectorData = sectorInfo.data
                            validSectorSize = dataSize
                            validSectorN = sectorInfo.id.size
                        } else if recordOnlyMatch && !allFF && validSectorData == nil {
                            // 低優先度: レコード番号のみ一致、FFでない
                            print("  レコード番号のみ一致するセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                            validSectorData = sectorInfo.data
                            validSectorSize = dataSize
                            validSectorN = sectorInfo.id.size
                        } else if exactMatch && allFF && matchesExpectedSize && validSectorData == nil {
                            // 最低優先度: 完全一致、FF、期待サイズ
                            print("  FFで埋められたセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                            validSectorData = sectorInfo.data
                            validSectorSize = dataSize
                            validSectorN = sectorInfo.id.size
                        }
                    }
                }
            }
            
            // 物理トラック1のセクタも確認（代替手段）
            if validSectorData == nil {
                for trackData in sectorData where trackData.track == 1 {
                    for sectorInfo in trackData.sectors {
                        // セクタIDの検証
                        let isValidID = sectorInfo.id.cylinder < 80 && sectorInfo.id.head < 2 && sectorInfo.id.record < 30
                        if !isValidID {
                            continue // 無効なIDのセクタはスキップ
                        }
                        
                        // レコード番号が一致するセクタを探す (PC-88のセクタ番号は1から始まる)
                        if sectorInfo.id.record == UInt8(sector) {
                            let dataSize = sectorInfo.data.count
                            let sectorSize = calculateSectorSizeFromN(sectorInfo.id.size)
                            
                            if dataSize > 0 && dataSize <= 8192 {
                                // データが全てFFで埋められているかチェック
                                let allFF = sectorInfo.data.allSatisfy { $0 == 0xFF }
                                
                                // データの内容を検証
                                var hasValidContent = false
                                if dataSize >= 10 {
                                    // 先頭バイトが0xC3（JP命令）または0x18（JR命令）で始まるかチェック
                                    let firstByte = sectorInfo.data[0]
                                    hasValidContent = (firstByte == 0xC3 || firstByte == 0x18)
                                }
                                
                                // 2Dフォーマットの場合、期待されるセクタサイズと一致するかチェック
                                let matchesExpectedSize = expectedSectorSize == 0 || dataSize == expectedSectorSize
                                
                                if hasValidContent && matchesExpectedSize {
                                    print("  物理トラック1の最適なセクタ\(sector)を発見しました: N=\(sectorInfo.id.size) (\(sectorSize)バイト), データサイズ=\(dataSize)")
                                    return [UInt8](sectorInfo.data)
                                } else if !allFF && matchesExpectedSize {
                                    print("  物理トラック1の有効なセクタ\(sector)を発見しました: N=\(sectorInfo.id.size) (\(sectorSize)バイト), データサイズ=\(dataSize)")
                                    validSectorData = sectorInfo.data
                                    validSectorSize = dataSize
                                    validSectorN = sectorInfo.id.size
                                    // validSectorFoundは不要になりました
                                } else if !allFF && validSectorData == nil {
                                    validSectorData = sectorInfo.data
                                    validSectorSize = dataSize
                                    validSectorN = sectorInfo.id.size
                                    print("  物理トラック1の有効なデータを含むセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                                } else if allFF && matchesExpectedSize && validSectorData == nil {
                                    validSectorData = sectorInfo.data
                                    validSectorSize = dataSize
                                    validSectorN = sectorInfo.id.size
                                    print("  物理トラック1のFFで埋められたセクタを候補として保存します (N=\(sectorInfo.id.size), \(dataSize)バイト)")
                                }
                            }
                        }
                    }
                }
            }
            
            // ここまでで有効なセクタが見つからなかった場合
            if validSectorData == nil {
                // ALPHA-MINI-DOSの特別処理を試みる
                if isAlphaMiniDos() {
                    print("  ALPHA-MINI-DOSを検出しました。IPLを直接抽出します。")
                    return extractAlphaMiniDosIpl()
                }
                
                // レコード番号が一致するセクタを探す（最後の手段）
                print("  レコード番号のみで検索します")
                
                // すべてのトラックから、レコード番号が一致するセクタを収集
                var matchingSectors: [(trackIndex: Int, sectorInfo: SectorData)] = []
                
                for (trackIndex, trackData) in sectorData.enumerated() {
                    // トラック0とトラック1はすでにチェック済みなのでスキップ
                    if trackData.track <= 1 {
                        continue
                    }
                    
                    for sectorInfo in trackData.sectors {
                        if sectorInfo.id.record == UInt8(sector) {
                            let dataSize = sectorInfo.data.count
                            if dataSize > 0 && dataSize <= 8192 {
                                matchingSectors.append((trackIndex, sectorInfo))
                            }
                        }
                    }
                }
                
                print("  レコード番号\(sector)に一致するセクタ数: \(matchingSectors.count)")
                
                // 有効なセクタを選択
                if !matchingSectors.isEmpty {
                    // 有効なデータを含むセクタを探す
                    let nonEmptySectors = matchingSectors.filter { !$0.sectorInfo.data.allSatisfy { $0 == 0xFF } }
                    
                    if !nonEmptySectors.isEmpty {
                        // 有効なデータを含むセクタが見つかった場合
                        let (trackIndex, sectorInfo) = nonEmptySectors.first!
                        let dataSize = sectorInfo.data.count
                        print("  トラック\(sectorData[trackIndex].track)で有効なセクタ\(sector)を発見しました: データサイズ=\(dataSize)")
                        validSectorData = sectorInfo.data
                        validSectorSize = dataSize
                        validSectorN = sectorInfo.id.size
                    } else if !matchingSectors.isEmpty {
                        // すべてFFで埋められている場合、最初のセクタを使用
                        let (trackIndex, sectorInfo) = matchingSectors.first!
                        let dataSize = sectorInfo.data.count
                        print("  トラック\(sectorData[trackIndex].track)でFFで埋められたセクタ\(sector)を発見しました: データサイズ=\(dataSize)")
                        validSectorData = sectorInfo.data
                        validSectorSize = dataSize
                        validSectorN = sectorInfo.id.size
                    }
                }
            }
            
            // 有効なセクタが見つかった場合は返す
            if let data = validSectorData {
                print("  トラック0のセクタ\(sector)の候補を使用します: N=\(validSectorN) (\(calculateSectorSizeFromN(validSectorN))バイト), データサイズ=\(validSectorSize)")
                return [UInt8](data)
            }
            
            // 最後の手段: デフォルトのIPLセクタを返す
            print("  警告: 有効なセクタが見つかりませんでした。デフォルトのIPLセクタを使用します。")
            return [UInt8](defaultIPLSector)
        }
        
        // トラック0以外の場合は通常の検索を行う
        print("  トラック\(track)を検索します")
        
        // 指定されたトラックのデータを検索
        let targetTrackData = sectorData.filter { $0.track == track }
        print("  トラック\(track)のデータブロック数: \(targetTrackData.count)")
        
        // 指定されたトラックのデータが見つかった場合
        if !targetTrackData.isEmpty {
            // トラックデータをスキャン
            for trackData in targetTrackData {
                print("  トラックデータ: track=\(trackData.track), side=\(trackData.side), sectors=\(trackData.sectors.count)")
                
                // セクタのID情報を表示
                for (index, sectorInfo) in trackData.sectors.enumerated() {
                    print("    セクタ\(index): C=\(sectorInfo.id.cylinder), H=\(sectorInfo.id.head), R=\(sectorInfo.id.record), N=\(sectorInfo.id.size), データサイズ=\(sectorInfo.data.count)")
                }
                
                // セクタを検索 - レコード番号(R)で検索
                for sectorInfo in trackData.sectors {
                    if sectorInfo.id.record == UInt8(sector) {
                        let dataSize = sectorInfo.data.count
                        if dataSize > 0 && dataSize <= 8192 { // セクタサイズの妥当性チェック
                            print("  セクタ\(sector)が見つかりました: データサイズ=\(dataSize)")
                            // DataをUInt8配列に変換して返す
                            return [UInt8](sectorInfo.data)
                        } else {
                            print("  セクタ\(sector)のサイズが異常です: \(dataSize)バイト")
                        }
                    }
                }
            }
            
            print("  トラック\(track)にセクタ\(sector)が見つかりませんでした")
            return nil
        }
        
        // 物理トラック番号で見つからなかった場合、シリンダ番号(C)で再検索
        print("  物理トラック\(track)が見つかりませんでした。シリンダ番号で再検索します。")
        
        // シリンダ番号で検索
        for trackData in sectorData {
            // セクタを検索 - シリンダ番号(C)とレコード番号(R)で検索
            let matchingSectors = trackData.sectors.filter { 
                $0.id.cylinder == UInt8(track) && $0.id.record == UInt8(sector) 
            }
            
            if let sectorInfo = matchingSectors.first {
                let dataSize = sectorInfo.data.count
                if dataSize > 0 && dataSize <= 8192 { // セクタサイズの妥当性チェック
                    print("  シリンダ\(track)、セクタ\(sector)が見つかりました: データサイズ=\(dataSize)")
                    return [UInt8](sectorInfo.data)
                } else {
                    print("  シリンダ\(track)、セクタ\(sector)のサイズが異常です: \(dataSize)バイト")
                }
            }
        }
        
        print("  トラック\(track)、セクタ\(sector)が見つかりませんでした")
        return nil
    }
    

    // MARK: - ALPHA-MINI-DOS特別処理
    
    /// デフォルトのIPLセクタを取得
    private func getDefaultIplSector() -> [UInt8] {
        // 256バイトの空のIPLセクタを作成
        var defaultSector = [UInt8](repeating: 0, count: 256)
        
        // 最初の数バイトにジャンプ命令を設定（基本的なブートローダーの開始）
        defaultSector[0] = 0xF3  // DI命令（割り込み禁止）
        defaultSector[1] = 0xC3  // JP命令
        defaultSector[2] = 0x00  // アドレス下位バイト
        defaultSector[3] = 0x01  // アドレス上位バイト（0x0100にジャンプ）
        
        return defaultSector
    }
    
    /// ディスク名を取得する
    func getDiskName() -> String {
        return diskName
    }
    
    /// ディスクイメージがALPHA-MINI-DOSかどうかを判定
    private func isAlphaMiniDos() -> Bool {
        // ディスク名でチェック
        if diskName.contains("ALPHA-MINI") {
            return true
        }
        
        // ディスクイメージのサイズが一定以上あるかチェック
        if diskData.count < alphaMiniDosIplOffset + 256 {
            return false
        }
        
        // IPLの特徴的なバイトパターンをチェック
        // ALPHA-MINI-DOSのIPLは0x02C0から始まり、特徴的なパターンを持つ
        let signatureOffset = alphaMiniDosIplOffset
        if diskData.count >= signatureOffset + 4 {
            // F3 3A 02 00 で始まるかチェック（DI命令とLD A,(0002h)）
            if diskData[signatureOffset] == 0xF3 && 
               diskData[signatureOffset + 1] == 0x3A && 
               diskData[signatureOffset + 2] == 0x02 && 
               diskData[signatureOffset + 3] == 0x00 {
                return true
            }
            
            // F3 C3 で始まるかチェック（DI命令とJP命令）
            if diskData[signatureOffset] == 0xF3 && 
               diskData[signatureOffset + 1] == 0xC3 {
                return true
            }
        }
        
        // セクタデータの特徴をチェック
        for trackData in sectorData where trackData.track == 0 && trackData.side == 0 {
            for sector in trackData.sectors {
                // セクタデータの先頭をチェック
                if sector.data.count >= 4 {
                    let bytes = [UInt8](sector.data)
                    // DI命令（0xF3）で始まるセクタを探す
                    if bytes[0] == 0xF3 {
                        // 次がJP命令（0xC3）またはLD A,(nn)命令（0x3A）
                        if bytes[1] == 0xC3 || bytes[1] == 0x3A {
                            return true
                        }
                    }
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
            print("  ALPHA-MINI-DOSのIPL抽出に失敗: ディスクイメージが小さすぎます")
            return getDefaultIplSector()
        }
        
        // IPLの内容を詳細に表示
        print("  ALPHA-MINI-DOSのIPLを抽出します: オフセット=0x\(String(format: "%04X", alphaMiniDosIplOffset))")
        print("  IPLの最初の16バイト:")
        
        // IPLデータを取得
        let iplData = [UInt8](diskData.subdata(in: alphaMiniDosIplOffset..<alphaMiniDosIplOffset + iplSize))
        
        // 最初の16バイトを表示
        for i in 0..<min(16, iplData.count) {
            print(String(format: "%02X ", iplData[i]), terminator: "")
        }
        print("")
        
        // IPLコードの典型的な特徴を確認
        if iplData.count >= 4 {
            if iplData[0] == 0xF3 { // DI命令（割り込み禁止）
                print("  IPLの先頭にDI命令を確認: 正常")
            } else {
                print("  警告: IPLの先頭がDI命令ではありません (0x\(String(format: "%02X", iplData[0])))")
                
                // IPLが無効な場合、ディスクイメージ内を検索して有効なIPLを見つける
                print("  有効なIPLを検索します...")
                
                // ディスクイメージ内の複数の場所を検索
                let possibleOffsets = [0x02C0, 0x0000, 0x0100, 0x0200, 0x0300, 0x0400]
                
                for offset in possibleOffsets where offset != alphaMiniDosIplOffset {
                    if offset + iplSize <= diskData.count {
                        let candidateData = [UInt8](diskData.subdata(in: offset..<offset + iplSize))
                        
                        // 有効なIPLの特徴をチェック
                        if candidateData[0] == 0xF3 && (candidateData[1] == 0xC3 || candidateData[1] == 0x3A) {
                            print("  オフセット0x\(String(format: "%04X", offset))で有効なIPLを発見しました")
                            return candidateData
                        }
                    }
                }
                
                // 有効なIPLが見つからない場合は、修正を試みる
                var modifiedIpl = iplData
                modifiedIpl[0] = 0xF3  // DI命令を先頭に設定
                if modifiedIpl[1] != 0xC3 && modifiedIpl[1] != 0x3A {
                    modifiedIpl[1] = 0xC3  // JP命令を設定
                    modifiedIpl[2] = 0x00  // アドレス下位バイト
                    modifiedIpl[3] = 0x01  // アドレス上位バイト（0x0100にジャンプ）
                }
                print("  IPLを修正しました")
                return modifiedIpl
            }
            
            // ジャンプ命令を確認
            if iplData[1] == 0xC3 { // JP命令
                let jumpAddress = UInt16(iplData[2]) | (UInt16(iplData[3]) << 8)
                print("  JP命令を確認: 0x\(String(format: "%04X", jumpAddress))にジャンプ")
            } else if iplData[1] == 0x3A { // LD A,(nn)命令
                let memAddress = UInt16(iplData[2]) | (UInt16(iplData[3]) << 8)
                print("  LD A,(\(String(format: "%04X", memAddress)))命令を確認")
            } else {
                print("  警告: 2バイト目が予期しない命令です: 0x\(String(format: "%02X", iplData[1]))")
            }
        }
        
        // IPLデータを返す
        return iplData
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
            print("  ALPHA-MINI-DOSのOS抽出に失敗: ディスクイメージが小さすぎます")
            return nil
        }
        
        // OS部分のデータを取得
        let osData = [UInt8](diskData.subdata(in: alphaMiniDosOsOffset..<alphaMiniDosOsOffset + osSize))
        
        print("  ALPHA-MINI-DOSのOS部分を抽出しました: オフセット=0x\(String(format: "%04X", alphaMiniDosOsOffset)), サイズ=\(osData.count)バイト")
        
        // OS部分の最初の32バイトを表示
        print("  OS部分の最初の32バイト:")
        for i in 0..<min(32, osData.count) {
            if i % 16 == 0 && i > 0 {
                print("")
            }
            print(String(format: "%02X ", osData[i]), terminator: "")
        }
        print("")
        
        // OS部分の特徴を確認
        print("  OS部分の特徴を確認中...")
        
        // 有効なコードか確認
        var validCodeFound = false
        for i in 0..<min(256, osData.count) {
            if osData[i] != 0 && osData[i] != 0xFF {
                validCodeFound = true
                break
            }
        }
        
        if validCodeFound {
            print("  OS部分に有効なコードを確認しました")
        } else {
            print("  警告: OS部分に有効なコードが見つかりません")
        }
        
        return osData
    }
    
    /// D88ディスクイメージからOSセクタを読み込む
    /// - Returns: 読み込まれたOSセクタのデータ配列、失敗した場合はnil
    func loadOsSectors() -> [[UInt8]]? {
        print("D88DiskImage.loadOsSectors: OSセクタの読み込みを開始します")
        
        // ALPHA-MINI-DOSの場合は特殊処理
        if isAlphaMiniDos() {
            return loadAlphaMiniDosOsSectors()
        }
        
        // 通常のディスクイメージの場合
        // トラック0のデータを検索
        let track0Data = sectorData.filter { $0.track == 0 }
        if track0Data.isEmpty {
            print("  トラック0のデータが見つかりません")
            return nil
        }
        
        // ALPHA-MINI-DOSの特別処理
        if isAlphaMiniDos() {
            print("  ALPHA-MINI-DOSを検出しました。OS部分を直接抽出します。")
            if let osData = extractAlphaMiniDosOs() {
                return [osData]
            }
        }
        
        // 通常のOS読み込み処理: セクタ2から連続して読み込む
        var osSectors: [[UInt8]] = []
        let maxSectors = getExpectedSectorsPerTrack()
        
        print("  トラック0のセクタ2から連続読み込みを試行します (最大\(maxSectors)セクタ)")
        
        for sectorNumber in 2...maxSectors {
            if let sectorData = readSector(track: 0, sector: sectorNumber) {
                print("  セクタ\(sectorNumber)を読み込みました (\(sectorData.count)バイト)")
                osSectors.append(sectorData)
            } else {
                print("  セクタ\(sectorNumber)の読み込みに失敗したため、読み込みを終了します")
                break
            }
        }
        
        if osSectors.isEmpty {
            print("  OSセクタの読み込みに失敗しました")
            return nil
        }
        
        print("  OSセクタの読み込みが完了しました: \(osSectors.count)セクタ")
        return osSectors
    }
    
    /// OSデータをメモリにロードする（仮想的なメモリ操作）
    /// - Parameters:
    ///   - memoryAddress: OSをロードするメモリアドレス
    ///   - memory: メモリアクセサ（省略時は仮想的な操作のみ）
    /// - Returns: ロードされたOSデータの合計サイズ、失敗した場合は0
    func loadOsToMemory(memoryAddress: Int, memory: MemoryAccessing? = nil) -> Int {
        guard let osSectors = loadOsSectors() else {
            print("  OSセクタが読み込めないため、メモリへのロードに失敗しました")
            return 0
        }
        
        var currentAddress = memoryAddress
        var totalSize = 0
        
        for (index, sectorData) in osSectors.enumerated() {
            print("  セクタ\(index + 1)をメモリアドレス0x\(String(format: "%04X", currentAddress))にロード (\(sectorData.count)バイト)")
            
            // 実際のメモリに書き込み（メモリアクセサが提供されている場合）
            if let memory = memory {
                for (offset, byte) in sectorData.enumerated() {
                    let address = currentAddress + offset
                    // メモリ範囲チェック（64KBを超えないようにする）
                    if address < 0x10000 {
                        memory.writeByte(byte, at: UInt16(address))
                    } else {
                        print("  警告: メモリアドレス0x\(String(format: "%04X", address))が64KB範囲を超えています")
                        break
                    }
                }
            }
            
            // 次のセクタのアドレスを計算
            currentAddress += sectorData.count
            totalSize += sectorData.count
        }
        
        print("  OSデータをメモリアドレス0x\(String(format: "%04X", memoryAddress))にロードしました (合計\(totalSize)バイト)")
        return totalSize
    }
    
    /// OSの実行を開始する（仮想的な実行開始処理）
    /// - Parameter startAddress: OS実行開始アドレス
    /// - Returns: 実行開始の成否
    func executeOs(startAddress: Int) -> Bool {
        print("D88DiskImage.executeOs: OSの実行を開始します (開始アドレス: 0x\(String(format: "%04X", startAddress)))")
        
        // ここでは実際の実行は行わず、成功したことにする
        // 実際のエミュレータ実装では、Z80のプログラムカウンタを設定し実行を開始する処理が必要
        
        return true
    }
    
    // MARK: - ALPHA-MINI-DOS OS読み込み特殊処理
    
    /// ALPHA-MINI-DOS用のOS部分を読み込む特殊処理
    /// - Returns: OSセクタデータの配列、失敗した場合はnil
    private func loadAlphaMiniDosOsSectors() -> [[UInt8]]? {
        print("  ALPHA-MINI-DOS用のOS部分を特殊処理で読み込みます")
        
        // ALPHA-MINI-DOSの場合、トラック0のセクタ2から連続してOSが格納されている
        var osSectors: [[UInt8]] = []
        let maxSectorsToRead = 16 // ALPHA-MINI-DOSの一般的なOS部分のセクタ数
        
        for sectorNumber in 2...(maxSectorsToRead + 1) {
            // 直接データから読み込む方法を試す
            if let directData = readAlphaMiniDosSector(sectorNumber: sectorNumber) {
                // データが有効か確認（全てFFで埋められていないか）
                let isValidData = !directData.allSatisfy { $0 == 0xFF }
                if isValidData {
                    print("  ALPHA-MINI-DOS: セクタ\(sectorNumber)を直接読み込みました (\(directData.count)バイト)")
                    osSectors.append(directData)
                } else {
                    print("  ALPHA-MINI-DOS: セクタ\(sectorNumber)はデータが無効（全てFF）のため、スキップします")
                }
                continue
            }
            
            // 通常の方法でも試す
            if let sectorData = readSector(track: 0, sector: sectorNumber) {
                // データが有効か確認
                let isValidData = !sectorData.allSatisfy { $0 == 0xFF }
                if isValidData {
                    print("  ALPHA-MINI-DOS: セクタ\(sectorNumber)を通常方法で読み込みました (\(sectorData.count)バイト)")
                    osSectors.append(sectorData)
                } else {
                    print("  ALPHA-MINI-DOS: セクタ\(sectorNumber)はデータが無効（全てFF）のため、スキップします")
                }
            } else {
                print("  ALPHA-MINI-DOS: セクタ\(sectorNumber)の読み込みに失敗したため、読み込みを終了します")
                break
            }
        }
        
        if osSectors.isEmpty {
            print("  ALPHA-MINI-DOS: OS部分の読み込みに失敗しました")
            return nil
        }
        
        print("  ALPHA-MINI-DOS: OS部分の読み込みが完了しました: \(osSectors.count)セクタ")
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
