//
//  DiskImageAccessing.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// ディスクイメージアクセスを担当するプロトコル
protocol DiskImageAccessing {
    /// ディスクイメージをロード
    func loadDiskImage(from url: URL) -> Bool
    
    /// セクタ読み込み
    func readSector(track: Int, side: Int, sectorID: SectorID) -> Data?
    
    /// セクタ書き込み
    func writeSector(track: Int, side: Int, sectorID: SectorID, data: Data) -> Bool
    
    /// ディスクの状態を取得
    func getDiskStatus() -> DiskStatus
    
    /// ディスクイメージのファイル一覧を取得
    func getFileList() -> [DiskFileInfo]
    
    /// トラック上のセクタ ID 一覧を取得
    func getSectorIDs(track: Int, side: Int) -> [SectorID]
}

/// ディスク状態
struct DiskStatus {
    let isWriteProtected: Bool
    let trackCount: Int
    let sideCount: Int
}

/// ディスクファイル情報
struct DiskFileInfo {
    let filename: String
    let size: Int
    let attributes: UInt8
}
