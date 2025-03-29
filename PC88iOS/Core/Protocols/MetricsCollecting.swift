//
//  MetricsCollecting.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import Foundation

/// メトリクス収集を担当するプロトコル
protocol MetricsCollecting {
    /// パフォーマンスメトリクスの収集開始
    func startCollecting()
    
    /// パフォーマンスメトリクスの収集停止
    func stopCollecting()
    
    /// CPU使用率の記録
    func recordCPUUsage(_ percentage: Double)
    
    /// メモリ使用量の記録
    func recordMemoryUsage(_ bytes: UInt64)
    
    /// フレームレートの記録
    func recordFrameRate(_ fps: Double)
    
    /// エミュレーション速度の記録
    func recordEmulationSpeed(_ percentage: Double)
    
    /// メトリクスデータの取得
    func getMetrics() -> MetricsData
    
    /// メトリクスデータの保存
    func saveMetrics(to url: URL) -> Bool
}

/// メトリクスデータ
struct MetricsData {
    let averageCPUUsage: Double
    let peakCPUUsage: Double
    let averageMemoryUsage: UInt64
    let peakMemoryUsage: UInt64
    let averageFrameRate: Double
    let minimumFrameRate: Double
    let averageEmulationSpeed: Double
}
