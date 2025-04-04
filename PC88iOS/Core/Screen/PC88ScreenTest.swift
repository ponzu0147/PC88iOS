import Foundation

/// PC-88画面テスト用のクラス
class PC88ScreenTest {
    private let screen: PC88Screen
    
    init(screen: PC88Screen) {
        self.screen = screen
    }
    
    /// テスト画面を表示
    func displayTestScreen() {
        // カラーモードを有効化
        screen.settings.isColorMode = true
        
        // テキストVRAMに文字を書き込む（1行目）
        let title = "PC-88 Screen Test"
        writeText(title, line: 0, column: (80 - title.count) / 2)
        screen.setColorAttribute(line: 0, startColumn: (80 - title.count) / 2, color: 0x07) // 白色
        
        // 1行目にテスト情報
        let testInfo = "Color and Decoration Attribute Test"
        writeText(testInfo, line: 1, column: (80 - testInfo.count) / 2)
        screen.setColorAttribute(line: 1, startColumn: (80 - testInfo.count) / 2, color: 0x07) // 白色
        
        // 3行目にアルファベット大文字を表示
        let upperAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        writeText(upperAlphabet, line: 3, column: 0)
        screen.setColorAttribute(line: 3, startColumn: 0, color: 0x07) // 白色
        
        // 4行目にアルファベット小文字を表示
        let lowerAlphabet = "abcdefghijklmnopqrstuvwxyz"
        writeText(lowerAlphabet, line: 4, column: 0)
        screen.setColorAttribute(line: 4, startColumn: 0, color: 0x07) // 白色
        
        // 5行目に数字を表示
        let numbers = "0123456789"
        writeText(numbers, line: 5, column: 0)
        screen.setColorAttribute(line: 5, startColumn: 0, color: 0x06) // 黄色
        
        // 6行目に記号を表示
        let symbols = "!@#$%^&*()_+-=[]{}|;:'\",.<>/?"
        writeText(symbols, line: 6, column: 0)
        screen.setColorAttribute(line: 6, startColumn: 0, color: 0x05) // マゼンタ
        
        // 8行目に各色のカラーサンプルを表示
        let colorSample = "Color Sample:"
        writeText(colorSample, line: 8, column: 0)
        screen.setColorAttribute(line: 8, startColumn: 0, color: 0x07) // 白色
        
        // 各色のサンプルを表示（PC-88の色コードに合わせる）
        let colorLabels = ["K", "B", "R", "C", "G", "M", "Y", "W"]
        let colorCodes: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]
        
        for (i, label) in colorLabels.enumerated() {
            let x = 14 + i * 3
            writeText(label, line: 8, column: x)
            screen.setColorAttribute(line: 8, startColumn: x, color: colorCodes[i])
        }
        
        // 9行目に色コードの説明
        writeText("Color Codes: 000=K, 001=B, 010=R, 011=C, 100=G, 101=M, 110=Y, 111=W", line: 9, column: 0)
        screen.setColorAttribute(line: 9, startColumn: 0, color: 0x07) // 白色
        
        // 11行目に装飾テスト
        let decorationTest = "Decoration Test:"
        writeText(decorationTest, line: 11, column: 0)
        screen.setColorAttribute(line: 11, startColumn: 0, color: 0x07) // 白色
        
        // 装飾サンプルを表示
        let decorLabels = ["Normal", "Reverse", "Blink", "RevBlink", "Secret", "RevSecret"]
        let decorCodes: [PC88Decoration] = [.normal, .reverse, .blink, .reverseBlink, .secret, .reverseSecret]
        
        for (i, label) in decorLabels.enumerated() {
            let x = 16 + i * 10
            writeText(label, line: 11, column: x)
            screen.setDecorationAttribute(line: 11, startColumn: x, decoration: decorCodes[i])
            screen.setColorAttribute(line: 11, startColumn: x, color: 0x07) // 白色
        }
        
        // 13行目に色と装飾の組み合わせテスト
        let combinedTest = "Combined Color and Decoration Test:"
        writeText(combinedTest, line: 13, column: 0)
        screen.setColorAttribute(line: 13, startColumn: 0, color: 0x07) // 白色
        
        // 色と装飾の組み合わせサンプル
        let samples = ["R+Blink", "G+Rev", "B+RevBlink", "Y+Secret"]
        let colors: [UInt8] = [0x04, 0x02, 0x01, 0x06] // 赤、緑、青、黄
        let decorations: [PC88Decoration] = [.blink, .reverse, .reverseBlink, .secret]
        
        for (i, sample) in samples.enumerated() {
            let x = 5 + i * 15
            writeText(sample, line: 14, column: x)
            screen.setColorAttribute(line: 14, startColumn: x, color: colors[i])
            screen.setDecorationAttribute(line: 14, startColumn: x, decoration: decorations[i])
        }
        
        // 16行目にアンダーライン/アッパーラインテスト
        let lineTest = "Underline and Upperline Test:"
        writeText(lineTest, line: 16, column: 0)
        screen.setColorAttribute(line: 16, startColumn: 0, color: 0x07) // 白色
        
        // アンダーラインのみ
        writeText("Underline", line: 17, column: 5)
        screen.setDecorationAttribute(line: 17, startColumn: 5, decoration: .normal, underline: true)
        screen.setColorAttribute(line: 17, startColumn: 5, color: 0x04) // 赤
        
        // アッパーラインのみ
        writeText("Upperline", line: 17, column: 20)
        screen.setDecorationAttribute(line: 17, startColumn: 20, decoration: .normal, upperline: true)
        screen.setColorAttribute(line: 17, startColumn: 20, color: 0x02) // 緑
        
        // 両方
        writeText("Both", line: 17, column: 35)
        screen.setDecorationAttribute(line: 17, startColumn: 35, decoration: .normal, underline: true, upperline: true)
        screen.setColorAttribute(line: 17, startColumn: 35, color: 0x06) // 黄色
        
        // 19行目にブリンクテスト
        let blinkTest = "Blink Test (0.5s interval):"
        writeText(blinkTest, line: 19, column: 0)
        screen.setColorAttribute(line: 19, startColumn: 0, color: 0x07) // 白色
        
        // 各色でブリンク
        for i in 0..<8 {
            let x = 30 + i * 3
            writeText(String(i), line: 19, column: x)
            screen.setColorAttribute(line: 19, startColumn: x, color: UInt8(i))
            screen.setDecorationAttribute(line: 19, startColumn: x, decoration: .blink)
        }
        
        // 21行目に説明
        let explanation = "Press any key to return to normal operation"
        writeText(explanation, line: 21, column: (80 - explanation.count) / 2)
        screen.setColorAttribute(line: 21, startColumn: (80 - explanation.count) / 2, color: 0x07) // 白色
    }
    
    // MARK: - ヘルパーメソッド
    
    /// テキストを指定位置に書き込む（PC88Screenのprivateメソッドの代替）
    private func writeText(_ text: String, line: Int, column: Int) {
        guard line >= 0 && line < 25 else { return }
        guard column >= 0 && column < 80 else { return }
        
        for (i, char) in text.utf8.enumerated() {
            if i + column < 80 { // 80桁を超えないようにする
                // textVRAMに直接アクセスできないので、1文字ずつ書き込む
                // これはPC88Screenのprivateメソッドを回避するための方法
                screen.writeCharacter(char, atLine: line, column: column + i)
            }
        }
    }
}
