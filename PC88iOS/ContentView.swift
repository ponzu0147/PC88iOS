//
//  ContentView.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/29.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // エミュレータ画面
            EmulatorView()
                .tabItem {
                    Label("エミュレータ", systemImage: "desktopcomputer")
                }
                .tag(0)
            
            // テキスト表示テスト画面
            PC88TextEmulatorView()
                .tabItem {
                    Label("テキスト表示", systemImage: "text.cursor")
                }
                .tag(1)
            
            // テキスト速度テスト画面
            PC88TextSpeedTestView()
                .tabItem {
                    Label("速度テスト", systemImage: "speedometer")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
