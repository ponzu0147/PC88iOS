//
//  PC88DiskImage.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// PC-88のディスクイメージ実装
class PC88DiskImage: DiskImageAccessing {
    // MARK: - プロパティ
    
    /// ディスクイメージデータ
    private var diskData: Data?
    
    /// ディスク状態
    private var diskStatus: DiskStatus
    
    /// セクタマップ（トラック、サイド、セクタID）→データオフセット
    private var sectorMap: [Int: [Int: [SectorID: Int]]] = [:]
    
    /// ファイル一覧
    private var fileList: [DiskFileInfo] = []
    
    // MARK: - 初期化
    
    init() {
        diskStatus = DiskStatus(isWriteProtected: true, trackCount: 80, sideCount: 2)
    }
    
    // MARK: - DiskImageAccessing プロトコル実装
    
    /// ディスクイメージをロード
    func loadDiskImage(from url: URL) -> Bool {
        do {
            // ディスクイメージを読み込み
            diskData = try Data(contentsOf: url)
            
            // セクタマップを構築
            buildSectorMap()
            
            // ファイル一覧を解析
            parseFileList()
            
            // 書き込み保護状態を設定（デフォルトは保護）
            diskStatus = DiskStatus(isWriteProtected: true, trackCount: 80, sideCount: 2)
            
            return true
        } catch {
            PC88Logger.disk.debug("ディスクイメージの読み込みに失敗: \(error)")
            return false
        }
    }
    
    /// セクタ読み込み
    func readSector(track: Int, side: Int, sectorID: SectorID) -> Data? {
        guard let diskData = diskData else { return nil }
        
        // セクタマップから位置を取得
        guard let trackMap = sectorMap[track],
              let sideMap = trackMap[side],
              let offset = sideMap[sectorID] else {
            return nil
        }
        
        // セクタデータを返す
        let sectorSize = sectorID.sizeInBytes
        let endOffset = min(offset + sectorSize, diskData.count)
        return diskData.subdata(in: offset..<endOffset)
    }
    
    /// セクタ書き込み
    func writeSector(track: Int, side: Int, sectorID: SectorID, data: Data) -> Bool {
        // 書き込み保護チェック
        if diskStatus.isWriteProtected {
            return false
        }
        
        guard var diskData = diskData else { return false }
        
        // セクタマップから位置を取得
        guard let trackMap = sectorMap[track],
              let sideMap = trackMap[side],
              let offset = sideMap[sectorID] else {
            return false
        }
        
        // セクタデータを書き込み
        let sectorSize = sectorID.sizeInBytes
        let dataSize = min(data.count, sectorSize)
        let endOffset = min(offset + dataSize, diskData.count)
        
        // データ範囲が有効かチェック
        if offset >= 0 && endOffset <= diskData.count {
            // データを書き込み
            for i in 0..<dataSize {
                if offset + i < diskData.count {
                    diskData[offset + i] = data[i]
                }
            }
            self.diskData = diskData
            return true
        }
        
        return false
    }
    
    /// ディスクの状態を取得
    func getDiskStatus() -> DiskStatus {
        return diskStatus
    }
    
    /// ディスクイメージのファイル一覧を取得
    func getFileList() -> [DiskFileInfo] {
        return fileList
    }
    
    /// トラック上のセクタID一覧を取得
    func getSectorIDs(track: Int, side: Int) -> [SectorID] {
        // セクタマップから該当トラック・サイドのセクタID一覧を取得
        guard let trackMap = sectorMap[track],
              let sideMap = trackMap[side] else {
            return []
        }
        
        return Array(sideMap.keys)
    }
    
    // MARK: - 内部メソッド
    
    /// セクタマップを構築
    private func buildSectorMap() {
        // D88フォーマットに対応したセクタマップの構築
        sectorMap = [:]
        
        // ディスクイメージがない場合は何もしない
        guard let diskData = diskData, diskData.count > 0x2B0 else { return }
        
        // D88ヘッダの解析
        // ディスク名 (0x00-0x0F)
        // ライトプロテクト (0x1A) - 0:書き込み可能, 0x10:書き込み禁止
        let writeProtected = diskData[0x1A] == 0x10
        
        // ディスクの種類 (0x1B) - 0:2D, 0x10:2DD, 0x20:2HD
        let diskType = diskData[0x1B]
        
        // トラック数の推定
        var estimatedTracks = 80
        if diskType == 0x20 { // 2HD
            estimatedTracks = 77
        }
        
        // ディスク状態の更新
        diskStatus = DiskStatus(isWriteProtected: writeProtected, trackCount: estimatedTracks, sideCount: 2)
        
        // トラックテーブルの解析 (0x20-0x2AF)
        var trackOffset = 0
        for track in 0..<164 { // 最大164トラック (0-163)
            let tableOffset = 0x20 + track * 4
            if tableOffset + 4 > diskData.count {
                break
            }
            
            // トラックオフセットを取得
            trackOffset = Int(diskData[tableOffset]) |
                         (Int(diskData[tableOffset + 1]) << 8) |
                         (Int(diskData[tableOffset + 2]) << 16) |
                         (Int(diskData[tableOffset + 3]) << 24)
            
            if trackOffset == 0 || trackOffset >= diskData.count {
                continue // このトラックにはデータがない
            }
            
            // 物理トラック番号とサイド番号を計算
            let physicalTrack = track / 2
            let side = track % 2
            
            if sectorMap[physicalTrack] == nil {
                sectorMap[physicalTrack] = [:]
            }
            if sectorMap[physicalTrack]![side] == nil {
                sectorMap[physicalTrack]![side] = [:]
            }
            
            // トラックヘッダの解析
            var offset = trackOffset
            if offset + 4 > diskData.count {
                continue
            }
            
            // セクタ数を取得
            let sectorCount = Int(diskData[offset + 3])
            offset += 4
            
            // 各セクタの情報を解析
            for _ in 0..<sectorCount {
                if offset + 16 > diskData.count {
                    break
                }
                
                // セクタヘッダの解析
                let c = diskData[offset] // シリンダ番号
                let h = diskData[offset + 1] // ヘッド番号
                let r = diskData[offset + 2] // レコード番号
                let n = diskData[offset + 3] // セクタサイズ (0:128, 1:256, 2:512, 3:1024...)
                
                // セクタIDの作成
                let sectorID = SectorID(cylinder: c, head: h, record: r, size: n)
                
                // セクタサイズの取得
                let sectorSize = Int(diskData[offset + 14]) |
                                (Int(diskData[offset + 15]) << 8)
                
                // セクタデータのオフセット
                let sectorDataOffset = offset + 16
                
                // セクタマップに追加
                sectorMap[physicalTrack]![side]![sectorID] = sectorDataOffset
                
                // 次のセクタへ
                offset += 16 + sectorSize
            }
        }
    }
    
    /// ファイル一覧を解析 - PC-88のディレクトリ構造から
    private func parseFileList() {
        fileList = []
        
        // ディスクイメージがない場合は何もしない
        guard let diskData = diskData else { return }
        
        // PC-88のディレクトリ領域は通常トラック1、セクタ1から
        guard let track = sectorMap[1],
              let side = track[0],
              let dirSectorID = side.keys.first,
              let dirOffset = side[dirSectorID] else {
            return
        }
        
        // ディレクトリエントリの処理
        var offset = dirOffset
        let entrySize = 32 // 各ディレクトリエントリは32バイト
        
        // 最大16エントリまで読み取り（簡易実装）
        for _ in 0..<16 {
            if offset + entrySize > diskData.count {
                break
            }
            
            // 削除されたファイルはスキップ
            if diskData[offset] == 0xFF {
                offset += entrySize
                continue
            }
            
            // ファイル名を取得（最大8文字）
            var filename = ""
            for i in 0..<8 {
                let char = diskData[offset + i]
                if char == 0 || char == 0x20 {
                    break
                }
                filename.append(Character(UnicodeScalar(char)))
            }
            
            // 拡張子を取得（最大3文字）
            if diskData[offset + 8] != 0 && diskData[offset + 8] != 0x20 {
                filename.append(".")
                for i in 0..<3 {
                    let char = diskData[offset + 8 + i]
                    if char == 0 || char == 0x20 {
                        break
                    }
                    filename.append(Character(UnicodeScalar(char)))
                }
            }
            
            // ファイルサイズを取得
            let size = diskData.withUnsafeBytes { pointer in
                pointer.load(fromByteOffset: offset + 16, as: UInt16.self)
            }
            
            // 属性を取得
            let attributes = diskData[offset + 11]
            
            // ファイル情報を追加
            if !filename.isEmpty {
                let fileInfo = DiskFileInfo(filename: filename, size: Int(size), attributes: attributes)
                fileList.append(fileInfo)
            }
            
            offset += entrySize
        }
    }
}
