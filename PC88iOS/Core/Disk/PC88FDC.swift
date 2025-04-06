//
//  PC88FDC.swift
//  PC88iOS
//
//  Created by 越川将人 on 2025/03/30.
//

import Foundation

/// PC-88のフロッピーディスクコントローラ実装
class PC88FDC: FDCEmulating {
    // MARK: - 定数
    
    /// FDCコマンド
    private enum FDCCommand: UInt8 {
        case readData = 0x06
        case readDiagnostic = 0x07
        case readID = 0x0A
        case formatTrack = 0x0D
        case writeData = 0x05
        case writeDeletedData = 0x09
        case scanEqual = 0x11
        case scanLowOrEqual = 0x19
        case scanHighOrEqual = 0x1D
        case recalibrate = 0x0F
        case senseInterruptStatus = 0x08
        case specify = 0x03
        case senseDriveStatus = 0x04
        case seekTrack = 0x1F
    }
    
    /// FDCステータスレジスタビット
    private struct FDCStatus {
        static let busy: UInt8 = 0x10
        static let driveReady: UInt8 = 0x20
        static let dataRequest: UInt8 = 0x40
        static let dataTransferComplete: UInt8 = 0x80
    }
    
    // MARK: - プロパティ
    
    /// I/Oアクセス
    private var inputOutput: IOAccessing?
    
    /// ディスクイメージ（最大2ドライブ）
    private var diskImages: [DiskImageAccessing?] = [nil, nil]
    
    /// 指定されたドライブにディスクイメージがセットされているかを確認
    func hasDiskImage(drive: Int) -> Bool {
        guard drive >= 0 && drive < diskImages.count else { return false }
        return diskImages[drive] != nil
    }
    
    /// 指定されたドライブのディスク名を取得
    func getDiskName(drive: Int) -> String? {
        guard drive >= 0 && drive < diskImages.count else { return nil }
        if let diskImage = diskImages[drive] as? D88DiskImage {
            return diskImage.getDiskName()
        }
        return nil
    }
    
    /// 指定されたドライブのディスクイメージを取得
    func getDiskImage(drive: Int) -> DiskImageAccessing? {
        guard drive >= 0 && drive < diskImages.count else { return nil }
        return diskImages[drive]
    }
    
    /// 現在のドライブ
    private var currentDrive: Int = 0
    
    /// 現在のトラック
    private var currentTrack: [Int] = [0, 0]
    
    /// 現在のセクタ
    private var currentSector: [Int] = [1, 1]
    
    /// 現在のヘッド
    private var currentHead: [Int] = [0, 0]
    
    /// コマンドフェーズ
    private var commandPhase: Int = 0
    
    /// コマンドバッファ
    private var commandBuffer: [UInt8] = []
    
    /// データバッファ
    private var dataBuffer: [UInt8] = []
    
    /// 結果バッファ
    private var resultBuffer: [UInt8] = []
    
    /// ステータスレジスタ
    private var statusRegister: UInt8 = 0
    
    /// 現在のコマンド
    private var currentCommand: UInt8 = 0
    
    /// 割り込み要求フラグ
    private var interruptRequest: Bool = false
    
    // MARK: - 初期化
    
    init() {
        reset()
    }
    
    // MARK: - 公開メソッド
    
    /// FDCの初期化
    func initialize() {
        // 初期化処理
        reset()
    }
    
    /// I/Oアクセスを接続
    func connectIO(_ io: IOAccessing) {
        self.inputOutput = io
    }
    
    /// ディスクイメージをロード
    func loadDiskImage(url: URL, drive: Int) -> Bool {
        guard drive >= 0 && drive < 2 else { return false }
        
        // ディスクイメージをロード
        let diskImage = PC88DiskImage()
        if diskImage.loadDiskImage(from: url) {
            diskImages[drive] = diskImage
            return true
        }
        
        return false
    }
    
    /// ディスクイメージをセット
    func setDiskImage(_ disk: DiskImageAccessing?, drive: Int) {
        guard drive >= 0 && drive < diskImages.count else { return }
        diskImages[drive] = disk
    }
    

    
    func sendCommand(_ command: UInt8) {
        // コマンドフェーズの開始
        currentCommand = command
        commandPhase = 1
        commandBuffer = [command]
        dataBuffer = []
        resultBuffer = []
        
        // ビジー状態に設定
        statusRegister = FDCStatus.busy
        
        // コマンドタイプに応じた処理
        switch command & 0x1F {
        case FDCCommand.readData.rawValue:
            // 読み込みコマンド
            statusRegister |= FDCStatus.dataRequest
            
        case FDCCommand.writeData.rawValue, FDCCommand.writeDeletedData.rawValue:
            // 書き込みコマンド
            statusRegister |= FDCStatus.dataRequest
            
        case FDCCommand.readID.rawValue:
            // ID読み込みコマンド
            executeReadID()
            
        case FDCCommand.formatTrack.rawValue:
            // フォーマットコマンド
            statusRegister |= FDCStatus.dataRequest
            
        case FDCCommand.recalibrate.rawValue:
            // キャリブレーションコマンド
            executeRecalibrate()
            
        case FDCCommand.senseInterruptStatus.rawValue:
            // 割り込み状態取得コマンド
            executeSenseInterruptStatus()
            
        case FDCCommand.specify.rawValue:
            // スペシファイコマンド
            statusRegister |= FDCStatus.dataRequest
            
        case FDCCommand.senseDriveStatus.rawValue:
            // ドライブ状態取得コマンド
            statusRegister |= FDCStatus.dataRequest
            
        case FDCCommand.seekTrack.rawValue:
            // シークコマンド
            statusRegister |= FDCStatus.dataRequest
            
        default:
            // 未実装コマンド
            PC88Logger.disk.debug("未実装のFDCコマンド: \(command)")
            completeCommand()
        }
    }
    
    func sendData(_ data: UInt8) {
        // データフェーズの処理
        if statusRegister & FDCStatus.dataRequest != 0 {
            dataBuffer.append(data)
            
            switch currentCommand & 0x1F {
            case FDCCommand.readData.rawValue:
                // 読み込みコマンドのパラメータ処理
                if dataBuffer.count == 8 {
                    executeReadData()
                }
                
            case FDCCommand.writeData.rawValue, FDCCommand.writeDeletedData.rawValue:
                // 書き込みコマンドのパラメータ処理
                if dataBuffer.count == 8 {
                    executeWriteData()
                }
                
            case FDCCommand.formatTrack.rawValue:
                // フォーマットコマンドのパラメータ処理
                if dataBuffer.count == 5 {
                    executeFormatTrack()
                }
                
            case FDCCommand.specify.rawValue:
                // スペシファイコマンドのパラメータ処理
                if dataBuffer.count == 2 {
                    completeCommand()
                }
                
            case FDCCommand.senseDriveStatus.rawValue:
                // ドライブ状態取得コマンドのパラメータ処理
                if dataBuffer.count == 1 {
                    executeSenseDriveStatus()
                }
                
            case FDCCommand.seekTrack.rawValue:
                // シークコマンドのパラメータ処理
                if dataBuffer.count == 2 {
                    executeSeekTrack()
                }
                
            default:
                break
            }
        }
    }
    
    func readStatus() -> UInt8 {
        return statusRegister
    }
    
    func readData() -> UInt8 {
        // 結果フェーズの処理
        if statusRegister & FDCStatus.dataRequest != 0 && !resultBuffer.isEmpty {
            let result = resultBuffer.removeFirst()
            
            // 結果バッファが空になったらコマンド完了
            if resultBuffer.isEmpty {
                completeCommand()
            }
            
            return result
        }
        
        return 0
    }
    

    
    func update(cycles: Int) {
        // FDCの定期更新処理
        // 実際の実装では、コマンド実行の遅延やシーク時間のシミュレーションなどを行う
    }
    
    func reset() {
        // 状態のリセット
        currentDrive = 0
        currentTrack = [0, 0]
        currentSector = [1, 1]
        currentHead = [0, 0]
        commandPhase = 0
        commandBuffer = []
        dataBuffer = []
        resultBuffer = []
        statusRegister = 0
        currentCommand = 0
        interruptRequest = false
    }
    
    // MARK: - プライベートメソッド
    
    /// コマンド完了処理
    private func completeCommand() {
        statusRegister = 0
        commandPhase = 0
        interruptRequest = true
        
        // 割り込み要求を送信
        if let io = inputOutput as? PC88IO {
            io.requestInterrupt(from: .fdc)
        }
    }
    
    /// 読み込みコマンドの実行
    private func executeReadData() {
        guard dataBuffer.count >= 8 else { return }
        
        // パラメータの取得
        let drive = Int(dataBuffer[0] & 0x03)
        let head = Int((dataBuffer[0] >> 2) & 0x01)
        let cylinder = Int(dataBuffer[1])
        let _ = Int(dataBuffer[2]) // head2
        let sector = Int(dataBuffer[3])
        let sizeCode = Int(dataBuffer[4])
        let _ = Int(dataBuffer[5]) // endSector
        let _ = Int(dataBuffer[6]) // gapLength
        let _ = Int(dataBuffer[7]) // dataLength
        
        // 現在の状態を更新
        currentDrive = drive
        currentHead[drive] = head
        currentTrack[drive] = cylinder
        currentSector[drive] = sector
        
        // ディスクイメージが存在するか確認
        guard let disk = diskImages[drive] else {
            // ディスクなしエラー
            resultBuffer = [0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
            return
        }
        
        // セクタIDの作成
        let sectorID = SectorID(cylinder: UInt8(cylinder), head: UInt8(head), record: UInt8(sector), size: UInt8(sizeCode))
        
        // セクタデータの読み込み
        if let sectorData = disk.readSector(track: cylinder, side: head, sectorID: sectorID) {
            // 成功
            resultBuffer = [0x00, UInt8(cylinder), UInt8(head), UInt8(sector), UInt8(sizeCode), 0x00, 0x00]
            
            // データをバッファに追加
            resultBuffer.append(contentsOf: sectorData)
            
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
        } else {
            // セクタ見つからずエラー
            resultBuffer = [0x40, UInt8(cylinder), UInt8(head), UInt8(sector), UInt8(sizeCode), 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
        }
    }
    
    /// 書き込みコマンドの実行
    private func executeWriteData() {
        guard dataBuffer.count >= 8 else { return }
        
        // パラメータの取得
        let drive = Int(dataBuffer[0] & 0x03)
        let head = Int((dataBuffer[0] >> 2) & 0x01)
        let cylinder = Int(dataBuffer[1])
        let _ = Int(dataBuffer[2]) // head2
        let sector = Int(dataBuffer[3])
        // sizeCodeは後で使用するかもしれないが、現在は使用していないため_に変更
        let _ = Int(dataBuffer[4]) // sizeCode
        let _ = Int(dataBuffer[5]) // endSector
        let _ = Int(dataBuffer[6]) // gapLength
        let _ = Int(dataBuffer[7]) // dataLength
        
        // 現在の状態を更新
        currentDrive = drive
        currentHead[drive] = head
        currentTrack[drive] = cylinder
        currentSector[drive] = sector
        
        // ディスクイメージが存在するか確認
        guard diskImages[drive] != nil else {
            // ディスクなしエラー
            resultBuffer = [0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
            return
        }
        
        // 書き込みデータの受け取り準備
        statusRegister = FDCStatus.dataRequest
        
        // 実際の書き込み処理は別途実装
    }
    
    /// ID読み込みコマンドの実行
    private func executeReadID() {
        guard commandBuffer.count >= 2 else { return }
        
        // パラメータの取得
        let drive = Int(commandBuffer[1] & 0x03)
        let head = Int((commandBuffer[1] >> 2) & 0x01)
        
        // 現在の状態を更新
        currentDrive = drive
        currentHead[drive] = head
        
        // ディスクイメージが存在するか確認
        guard let disk = diskImages[drive] else {
            // ディスクなしエラー
            resultBuffer = [0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
            return
        }
        
        // セクタIDの取得（実際には現在のトラックの最初のセクタを返す）
        let sectorIDs = disk.getSectorIDs(track: currentTrack[drive], side: head)
        if let firstSector = sectorIDs.first {
            // 成功
            resultBuffer = [0x00, firstSector.cylinder, firstSector.head, firstSector.record, firstSector.size, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
        } else {
            // セクタ見つからずエラー
            resultBuffer = [0x40, UInt8(currentTrack[drive]), UInt8(head), 0x01, 0x00, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
        }
    }
    
    /// フォーマットコマンドの実行
    private func executeFormatTrack() {
        guard dataBuffer.count >= 5 else { return }
        
        // パラメータの取得
        let drive = Int(dataBuffer[0] & 0x03)
        let head = Int((dataBuffer[0] >> 2) & 0x01)
        let _ = Int(dataBuffer[1]) // sizeCode
        let _ = Int(dataBuffer[2]) // sectorsPerTrack
        let _ = Int(dataBuffer[3]) // gapLength
        let _ = dataBuffer[4] // fillByte
        
        // 現在の状態を更新
        currentDrive = drive
        currentHead[drive] = head
        
        // ディスクイメージが存在するか確認
        guard diskImages[drive] != nil else {
            // ディスクなしエラー
            resultBuffer = [0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
            return
        }
        
        // フォーマットデータの受け取り準備
        statusRegister = FDCStatus.dataRequest
        
        // 実際のフォーマット処理は別途実装
    }
    
    /// キャリブレーションコマンドの実行
    private func executeRecalibrate() {
        guard commandBuffer.count >= 2 else { return }
        
        // パラメータの取得
        let drive = Int(commandBuffer[1] & 0x03)
        
        // トラック0に移動
        currentTrack[drive] = 0
        
        // 完了
        completeCommand()
    }
    
    /// 割り込み状態取得コマンドの実行
    private func executeSenseInterruptStatus() {
        // 割り込み状態を返す
        if interruptRequest {
            resultBuffer = [0x00, UInt8(currentTrack[currentDrive])]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
            interruptRequest = false
        } else {
            // 割り込みなしエラー
            resultBuffer = [0x80, 0x00]
            statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
        }
    }
    
    /// ドライブ状態取得コマンドの実行
    private func executeSenseDriveStatus() {
        guard dataBuffer.count >= 1 else { return }
        
        // パラメータの取得
        let drive = Int(dataBuffer[0] & 0x03)
        let _ = Int((dataBuffer[0] >> 2) & 0x01) // head
        
        // ドライブ状態を返す
        var status: UInt8 = 0
        
        // ディスクイメージが存在するか確認
        if let disk = diskImages[drive] {
            // ディスクあり
            status |= 0x20  // Ready
            
            // 書き込み保護状態
            if disk.getDiskStatus().isWriteProtected {
                status |= 0x40  // Write protected
            }
            
            // トラック0状態
            if currentTrack[drive] == 0 {
                status |= 0x10  // Track 0
            }
        }
        
        // 結果を設定
        resultBuffer = [status]
        statusRegister = FDCStatus.dataRequest | FDCStatus.dataTransferComplete
    }
    
    /// シークコマンドの実行
    private func executeSeekTrack() {
        guard dataBuffer.count >= 2 else { return }
        
        // パラメータの取得
        let drive = Int(dataBuffer[0] & 0x03)
        let track = Int(dataBuffer[1])
        
        // トラックに移動
        currentTrack[drive] = track
        
        // 完了
        completeCommand()
    }
    
    /// セクタデータを直接読み込む（IPL用）
    func readSector(drive: Int, track: Int, sector: Int) -> [UInt8]? {
        guard drive >= 0 && drive < diskImages.count,
              let diskImage = diskImages[drive] as? D88DiskImage else {
            return nil
        }
        
        PC88Logger.disk.debug("FDC: トラック\(track)、セクタ\(sector)を読み込みます")
        
        // セクタデータを読み込む
        return diskImage.readSector(track: track, sector: sector)
    }
    
    /// DiskImageAccessingプロトコルに準拠したセクタ読み込みメソッド
    func readSector(drive: Int, track: Int, side: Int, sectorID: SectorID) -> Data? {
        guard drive >= 0 && drive < diskImages.count,
              let diskImage = diskImages[drive] else {
            return nil
        }
        
        // セクタデータを読み込む
        return diskImage.readSector(track: track, side: side, sectorID: sectorID)
    }
}
