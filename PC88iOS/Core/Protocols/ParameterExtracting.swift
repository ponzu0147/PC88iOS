//
//  ParameterExtracting.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// 音楽パラメータの抽出を担当するプロトコル
protocol ParameterExtracting {
    /// メモリからパラメータを抽出
    func extractParameters(from memory: MemoryAccessing, driverInfo: DriverInformation) -> MusicParameters?
    
    /// 特定のアドレスからパラメータを抽出
    func extractParametersAt(address: UInt16, memory: MemoryAccessing, driverType: DriverType) -> MusicParameters?
    
    /// 曲データからパラメータを抽出
    func extractParametersFromMusicData(_ data: Data, driverType: DriverType) -> MusicParameters?
}
