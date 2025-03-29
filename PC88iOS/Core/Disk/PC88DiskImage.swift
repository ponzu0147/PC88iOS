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
            print("ディスクイメージの読み込みに失敗: \(error)")
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
        // 実際のディスクイメージ形式に合わせて実装する必要があります
        // ここでは簡易的な実装として、N88-BASICディスクフォーマットを想定
        
        sectorMap = [:]
        
        // ディスクイメージがない場合は何もしない
        guard let _ = diskData else { return }
        
        // 各トラックに対して
        for track in 0..<80 {
            sectorMap[track] = [:]
            
            // 各サイドに対して
            for side in 0..<2 {
                sectorMap[track]![side] = [:]
                
                // 各セクタに対して（PC-88は通常1トラックあたり16セクタ）
                for sector in 1...16 {
                    // セクタIDを作成（PC-88の標準的なフォーマット）
                    let sectorID = SectorID(cylinder: UInt8(track), head: UInt8(side), record: UInt8(sector), size: 1)
                    
                    // セクタのオフセットを計算（単純化した例）
                    // 実際には、ディスクイメージ形式によって異なる計算が必要
                    let offset = (track * 2 * 16 + side * 16 + (sector - 1)) * 256
                    
                    // セクタマップに追加
                    sectorMap[track]![side]![sectorID] = offset
                }
            }
        }
    }
    
    /// ファイル一覧を解析
    private func parseFileList() {
        // 実際のディスクイメージ形式に合わせて実装する必要があります
        // ここでは簡易的な実装として空のリストを返す
        fileList = []
    }
}
