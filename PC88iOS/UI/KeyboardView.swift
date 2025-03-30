//
//  KeyboardView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import SwiftUI

/// PC-88用の仮想キーボード表示ビュー
struct KeyboardView: View {
    // キー入力を処理するクロージャ
    var onKeyPress: (String) -> Void
    
    // キーボードの表示状態
    @Binding var isVisible: Bool
    
    // キーボードの行
    private let keyRows: [[KeyDefinition]] = [
        // ファンクションキー行
        [
            KeyDefinition(key: "f1", label: "F1", width: 1),
            KeyDefinition(key: "f2", label: "F2", width: 1),
            KeyDefinition(key: "f3", label: "F3", width: 1),
            KeyDefinition(key: "f4", label: "F4", width: 1),
            KeyDefinition(key: "f5", label: "F5", width: 1),
            KeyDefinition(key: "f6", label: "F6", width: 1),
            KeyDefinition(key: "f7", label: "F7", width: 1),
            KeyDefinition(key: "f8", label: "F8", width: 1),
            KeyDefinition(key: "f9", label: "F9", width: 1),
            KeyDefinition(key: "f10", label: "F10", width: 1)
        ],
        // 数字キー行
        [
            KeyDefinition(key: "1", label: "1", width: 1),
            KeyDefinition(key: "2", label: "2", width: 1),
            KeyDefinition(key: "3", label: "3", width: 1),
            KeyDefinition(key: "4", label: "4", width: 1),
            KeyDefinition(key: "5", label: "5", width: 1),
            KeyDefinition(key: "6", label: "6", width: 1),
            KeyDefinition(key: "7", label: "7", width: 1),
            KeyDefinition(key: "8", label: "8", width: 1),
            KeyDefinition(key: "9", label: "9", width: 1),
            KeyDefinition(key: "0", label: "0", width: 1),
            KeyDefinition(key: "-", label: "-", width: 1),
            KeyDefinition(key: "^", label: "^", width: 1),
            KeyDefinition(key: "\\", label: "\\", width: 1),
            KeyDefinition(key: "backspace", label: "BS", width: 1.5)
        ],
        // QWERTYキー行
        [
            KeyDefinition(key: "q", label: "Q", width: 1),
            KeyDefinition(key: "w", label: "W", width: 1),
            KeyDefinition(key: "e", label: "E", width: 1),
            KeyDefinition(key: "r", label: "R", width: 1),
            KeyDefinition(key: "t", label: "T", width: 1),
            KeyDefinition(key: "y", label: "Y", width: 1),
            KeyDefinition(key: "u", label: "U", width: 1),
            KeyDefinition(key: "i", label: "I", width: 1),
            KeyDefinition(key: "o", label: "O", width: 1),
            KeyDefinition(key: "p", label: "P", width: 1),
            KeyDefinition(key: "@", label: "@", width: 1),
            KeyDefinition(key: "[", label: "[", width: 1),
            KeyDefinition(key: "return", label: "Return", width: 1.5)
        ],
        // ASDFGキー行
        [
            KeyDefinition(key: "a", label: "A", width: 1),
            KeyDefinition(key: "s", label: "S", width: 1),
            KeyDefinition(key: "d", label: "D", width: 1),
            KeyDefinition(key: "f", label: "F", width: 1),
            KeyDefinition(key: "g", label: "G", width: 1),
            KeyDefinition(key: "h", label: "H", width: 1),
            KeyDefinition(key: "j", label: "J", width: 1),
            KeyDefinition(key: "k", label: "K", width: 1),
            KeyDefinition(key: "l", label: "L", width: 1),
            KeyDefinition(key: ";", label: ";", width: 1),
            KeyDefinition(key: ":", label: ":", width: 1),
            KeyDefinition(key: "]", label: "]", width: 1)
        ],
        // ZXCVBキー行
        [
            KeyDefinition(key: "z", label: "Z", width: 1),
            KeyDefinition(key: "x", label: "X", width: 1),
            KeyDefinition(key: "c", label: "C", width: 1),
            KeyDefinition(key: "v", label: "V", width: 1),
            KeyDefinition(key: "b", label: "B", width: 1),
            KeyDefinition(key: "n", label: "N", width: 1),
            KeyDefinition(key: "m", label: "M", width: 1),
            KeyDefinition(key: ",", label: ",", width: 1),
            KeyDefinition(key: ".", label: ".", width: 1),
            KeyDefinition(key: "/", label: "/", width: 1),
            KeyDefinition(key: "_", label: "_", width: 1)
        ],
        // スペースキー行
        [
            KeyDefinition(key: "space", label: "Space", width: 7),
            KeyDefinition(key: "kana", label: "かな", width: 1),
            KeyDefinition(key: "graph", label: "GRPH", width: 1),
            KeyDefinition(key: "close", label: "閉じる", width: 1.5)
        ]
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            // キーボードのタイトルバー
            HStack {
                Text("PC-88 キーボード")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    isVisible = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            
            // キーボードの各行
            ForEach(0..<keyRows.count, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(0..<keyRows[rowIndex].count, id: \.self) { keyIndex in
                        let keyDef = keyRows[rowIndex][keyIndex]
                        KeyButton(
                            key: keyDef.key,
                            label: keyDef.label,
                            width: keyDef.width,
                            onPress: { key in
                                if key == "close" {
                                    isVisible = false
                                } else {
                                    onKeyPress(key)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .shadow(radius: 5)
    }
}

/// キーボードのキー定義
struct KeyDefinition {
    let key: String
    let label: String
    let width: CGFloat
}

/// キーボタン
struct KeyButton: View {
    let key: String
    let label: String
    let width: CGFloat
    let onPress: (String) -> Void
    
    var body: some View {
        Button(action: {
            onPress(key)
        }) {
            Text(label)
                .font(.system(size: 14))
                .frame(minWidth: 30 * width, minHeight: 40)
                .padding(.horizontal, 4)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(6)
                .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView(onKeyPress: { _ in }, isVisible: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}
