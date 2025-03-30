//
//  D88DiskImage.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// D88形式のディスクイメージ
class D88DiskImage: DiskImageAccessing {
    // MARK: - 定数
    
    /// D88ヘッダサイズ
    private let headerSize = 0x2B0
    
    /// 最大トラック数
    private let maxTracks = 164  // 両面82トラック
    
    /// 最大セクタ数/トラック
    private let maxSectorsPerTrack = 26
    
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
    private var diskImageData: Data?
    
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
    
    /// データからディスクイメージをロード
    private func loadFromData(_ data: Data) -> Bool {
        guard data.count >= headerSize else {
            print("ディスクイメージデータが小さすぎます")
            return false
        }
        
        // ディスクイメージデータを保存
        diskImageData = data
        
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
        print("ディスクタイプ: \(diskType)")
        
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
            let track = i / 2
            let side = i % 2
            
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
                let c = data[currentOffset]
                let h = data[currentOffset + 1]
                let r = data[currentOffset + 2]
                let n = data[currentOffset + 3]
                let sectorSize = Int(data.withUnsafeBytes { bytes in
                    bytes.load(fromByteOffset: currentOffset + 0x0E, as: UInt16.self)
                })
                
                // セクタデータの読み取り
                let dataOffset = currentOffset + 0x10
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
