//
//  DocumentPicker.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// ドキュメントピッカーを表示するためのSwiftUIラッパー
struct DocumentPicker: UIViewControllerRepresentable {
    // 選択されたURLを受け取るクロージャ
    var onPick: (URL) -> Void
    
    // コーディネーターの作成
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // UIViewControllerの作成
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // D88ファイルとすべてのファイルを選択可能にする
        let supportedTypes: [UTType] = [
            UTType(filenameExtension: "d88") ?? UTType.data,
            UTType.data // すべてのファイルを許可
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    // UIViewControllerの更新（必要に応じて）
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // 更新が必要な場合はここに実装
    }
    
    // コーディネータークラス
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        // ドキュメントが選択された時の処理
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // セキュリティスコープ付きリソースへのアクセス権を取得
            let securityScopedURL = url.startAccessingSecurityScopedResource()
            defer {
                if securityScopedURL {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // 選択されたURLを親に通知
            parent.onPick(url)
        }
    }
}
