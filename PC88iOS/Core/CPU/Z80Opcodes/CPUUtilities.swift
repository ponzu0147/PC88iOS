//
//  CPUUtilities.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// Z80 CPU関連のユーティリティ関数

/// パリティチェック（偶数なら真）
func parityEven(_ value: UInt8) -> Bool {
    var v = value
    v ^= v >> 4
    v ^= v >> 2
    v ^= v >> 1
    return (v & 1) == 0
}
