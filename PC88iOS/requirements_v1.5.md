# 要件定義書 (v1.5 - 再構築版)

**プロジェクト名:** PC88 エミュレータ (iOS 版)

**バージョン:** 1.5 (再構築版)

**作成日:** 2025年3月29日

**最終更新日:** 2025年4月2日 _**(v1.5改訂)**_

**作成者:** ぽんず/Masato Koshikawa (原案), Gemini (改訂案), ChatGPT (正誤修正)


## 1. はじめに

### 1.1 目的

本ドキュメントは、iOS 上で動作する PC88 エミュレータの**再構築**における要件を定義することを目的とします。過去の開発における課題（コードの複雑化、エラー頻発）を踏まえ、**モジュール性、保守性、テスト容易性、拡張性**を重視した設計に基づき、安定動作するエミュレータコアを再構築します。

本エミュレータは、基本アーキテクチャとして **PC-8801mkII SR をベース**としつつ、**音源機能は YM2608 (OPNA) 相当をターゲット**とすることで、より幅広い音楽ソフトウェアへの対応を目指します。 _**(v1.4 ターゲット明確化)**_ 主な機能として、PC88 用のディスクイメージ (D88) を読み込み、IPL から OS を起動し、BASIC を実行することを提供します。さらに、BASIC からバイナリデータを D88 から読み込み、**PMD88、SPLIT-i、MUCOM88** などの FM 音源ドライバと再生プログラム、FM 音源の音色データと演奏データ、そして ADPCM データを読み込んで楽曲を再生し、画面表示を行います。

また、SwiftUI を使用して、楽曲の各パートの演奏アドレス、音名、音色、音量などのパラメータをリアルタイムで表示する UI を提供します。D88 を読み込んだ際に、自動的に音源ドライバを判別する機能も実装します。

### 1.2 スコープ

本ドキュメントでは、以下の機能をスコープとします。

* **再設計されたアーキテクチャに基づくコア機能の実装 (PC-8801mkII SR ベース、音源 YM2608 相当):** _**(v1.4 ターゲット明確化)**_
    * PC88 用 D88 ディスクイメージの読み込みと解析
    * Z80A CPU エミュレーション (テスト可能な実装)
    * メモリ管理 (RAM, ROM, VRAM, バンク切り替え - SR相当)
    * I/O ポート制御 (各デバイスへのルーティング)
    * FDC (フロッピーディスクコントローラ) エミュレーション
    * 音源チップ (YM2608/OPNA相当) エミュレーション (FM, SSG, Rhythm, ADPCM)
    * 画面表示 (CRTC, SR相当 _(v1.5修正: GDC非搭載)_のモードを含む) エミュレーションとレンダリング
* IPLからのOS起動、N88-BASIC(SR版相当)の実行
* D88からのバイナリデータ読み込み
* **PMD88、SPLIT-i、MUCOM88** 等のFM音源ドライバと再生プログラムの実行
* FM音源の音色データ・演奏データの読み込みと再生
* ADPCMデータの読み込みと再生
* 楽曲再生時の画面表示 (PC88画面)
* SwiftUIによるリアルタイムパラメータ表示UI
* 音源ドライバ自動判別機能
* エミュレーション性能のメトリクス収集と分析機能
* **基本的なユーザー支援機能 (最低限):**
    * 初回起動時の基本操作ガイド表示
    * ディスク選択時のプレビュー表示 (ディスク名、検出ドライバ情報)

以下の機能は、複雑性や開発期間を考慮し、現時点ではスコープ外とします。ただし、将来的な追加を容易にするため、アーキテクチャ設計レベルでは考慮します。_**(v1.4 理由追記)**_

* **高度な** UI/UX デザイン (基本的なレイアウトと最低限の支援機能はスコープ内とする)
* 外部システムとの高度な連携
* セーブステート機能
* デバッガ機能
* 他のディスクフォーマット対応 (D88を主軸とする)
* PC-8801mkII SR の基本機能を超える拡張機能 (例: MA以降の高速モード、拡張グラフィック等) _**(v1.4 明確化)**_

### 1.3 対象読者

* iOS アプリケーション開発者 (本プロジェクト担当者)
* テスター
* プロジェクトマネージャー
* PC88 エミュレータ、FM音源ドライバに興味のあるユーザー

## 2. 全体概要

### 2.1 製品概要

### 追加補足: SRモデルの音源仕様と本エミュレータにおけるOPNA拡張について _(v1.5追記)_

**実機の仕様:**  
PC-8801mkII SR では、標準で **YM2203 (OPN)** 音源が内蔵されており、3音のFM音源および3音のSSG音源を持つ。しかし、リズム音源やADPCMといった機能は搭載されていません。

**本エミュレータの方針:**  
本エミュレータでは **YM2608 (OPNA)** をサウンド機能としてエミュレーション対象とします。これは、以下のような追加機能を持つ上位互換チップであり、対応ソフトウェア資産を拡大するために有効です。

- FM音源 (6ch) + SSG (3ch)
- **リズム音源**（6音サンプリング）
- **ADPCM音源**（1ch 4bit ADPCM）
- タイマー拡張（2本）
- バス制御機能の拡張

**OPNA拡張に必要な主な実装タスク:** _(v1.5 追加記載)_

- YM2608 の拡張レジスタの実装
- リズム波形メモリのエミュレーション（定数サンプルまたはPCMファイル対応）
- ADPCMバッファと再生制御ロジック
- タイマーA/Bの動作再現と割り込み制御
- サンプリングレート調整とミキシング処理の拡張

これらの機能は、OPNAに対応した**PMD88**や**SPLIT-i**や**MUCOM88**の音源ドライバとの互換性確保に不可欠であり、OPNでは再現できない楽曲の忠実な再生を実現します。


本アプリケーションは、iOS デバイス上で動作する PC88 エミュレータです。**基本アーキテクチャは PC-8801mkII SR をベース**とし、**音源機能は YM2608 (OPNA) 相当**をターゲットとしています。 _**(v1.4 ターゲット明確化)**_ 再設計されたコアアーキテクチャに基づき、安定性と保守性を高めた実装を目指します。主要機能として、D88ディスクイメージからのOS起動、BASIC実行、および**PMD88、SPLIT-i、MUCOM88** を含む複数のFM音源ドライバによる楽曲再生と、関連するパラメータのリアルタイム表示を提供します。

### 2.2 製品の目的

安定かつ互換性の高い **PC-8801mkII SR 相当の基本動作**と、**YM2608 (OPNA) 相当の高品質なサウンド再生**環境を iOS 上に提供します。 _**(v1.4 目的明確化)**_ 特に PC88 の音楽資産を、正確なエミュレーションによるサウンドと詳細な演奏情報表示によって深く楽しめるようにすることを目的とします。クリーンなアーキテクチャを採用することで、将来的な機能拡張や改善を容易にすることも目標とします。

### 2.3 ターゲットユーザー

* PC88 (特に SR 以降、YM2608搭載機含む) の音楽に興味があるユーザー _**(v1.4 修正)**_
* レトロゲームやハードウェアに興味があるユーザー
* PC88 のエミュレータを iOS デバイス上で利用したいユーザー
* 音楽の演奏情報を詳細に確認したいユーザー
* **PMD88、SPLIT-i、MUCOM88** といったFM音源ドライバに興味があるユーザー

### 2.4 動作環境

* iOS 15.0 以降 (将来性を考慮し更新)
* iPhone (iPhone 11以降推奨) / iPad
* メモリ: 最低2GB (4GB以上推奨)
* ストレージ: 100MB以上の空き容量

## 3. システムアーキテクチャと設計原則

### 3.1 設計原則

本プロジェクトの再構築にあたり、以下の設計原則を採用します。

* **モジュール性 (Modularity):** システムを機能的に独立したコンポーネントに分割し、各コンポーネントが特定の責務に集中するようにします。(例: CPU, Memory, IO, Sound, FDC, Screen)
* **インターフェース分離 (Interface Segregation):** コンポーネント間の依存関係は、具体的な実装クラスではなく、抽象化されたインターフェース（Swift の `protocol`) を通じて行います。これにより、各コンポーネントを独立して開発・テスト・交換することが可能になります。
* **テスト容易性 (Testability):** 各コンポーネント、特にコアロジック（CPU命令、音源合成など）は、ユニットテスト可能なように設計・実装します。
* **依存性注入 (Dependency Injection):** コンポーネントが必要とする他のコンポーネント（への参照）は、外部から注入する形式をとります。これにより、テスト時のモック利用や、将来的な実装変更が容易になります。
* **明確な状態管理:** 各コンポーネントおよびシステム全体の状態遷移を明確に定義し、管理します。
* **明確なエラー処理戦略 (Clear Error Handling Strategy):** エラーが発生した際の挙動（ログ記録、ユーザー通知、可能な範囲でのリカバリー）をコンポーネントレベル・システムレベルで定義し、一貫したエラーハンドリング機構を実装します。

### 3.2 主要コンポーネントとインターフェース

再構築にあたり、以下のような主要コンポーネントと、それらの連携のためのインターフェース (`protocol`) を定義します。

* **`EmulatorCoreManaging`**: エミュレータ全体のライフサイクルと主要コンポーネント間の連携を管理。エラーハンドリングの統括も担う。
* **`CPUExecuting`**: Z80A CPU の実行、レジスタ・フラグアクセス、割り込み処理を提供。Z80内部にはALU（算術論理演算装置）が実装されており、すべての命令の算術・論理演算はこのALUを通じて処理される。 _(v1.5補足)_
    * 依存: `MemoryAccessing`, `IOAccessing`
* **`MemoryAccessing`**: メモリ（RAM, ROM, VRAM）への読み書きアクセスを提供。バンク切り替えロジックを含む。(SR相当のメモリマップ対応)
* **`IOAccessing`**: I/O ポートへの読み書きアクセスを提供。ポートアドレスに基づき、適切なデバイスハンドラへ処理を委譲。
* **`SoundChipEmulating` (e.g., `YM2608Emulating`)**: 音源チップ (YM2608相当) のレジスタ操作と音声サンプル生成を提供。(FM, SSG, Rhythm, ADPCM)
    * 依存: (タイミング管理用インターフェース)
* **`DiskImageAccessing`**: D88 ディスクイメージファイルの読み込みとセクタ単位のアクセスを提供。
* **`FDCEmulating`**: FDC の動作をエミュレート。`IOAccessing` を通じて CPU と連携し、`DiskImageAccessing` を利用。
* **`ScreenRendering`**: VRAM や CRTC (SR相当) の状態に基づき、画面データを生成。
    * 依存: `MemoryAccessing`, `IOAccessing`
* **`DriverDetecting`**: ディスクイメージの内容を解析し、FM 音源ドライバの種類を判別。
    * 依存: `DiskImageAccessing` (または FDC 経由でのアクセス)
* **`ParameterExtracting`**: エミュレーション中の状態（音源チップ、メモリ等）からリアルタイムパラメータを抽出。
    * 依存: `SoundChipEmulating`, `MemoryAccessing` 等
* **`MetricsCollecting`**: エミュレーション性能や状態に関するメトリクスを収集・分析。
    * 依存: `CPUExecuting`, `SoundChipEmulating`, その他各コンポーネント
* **`InputHandling`**: キーボード、ジョイスティック等の入力イベントを抽象化し、`IOAccessing` に渡す。

### 3.3 将来的な拡張への設計考慮

現在スコープ外とされている機能についても、将来的な拡張を容易にするため、以下の設計上の考慮点を明確にします。

* **セーブステート機能:**
    * **考慮点:** 全コアコンポーネント（CPU, Memory, IOデバイス状態等）のシリアライズ可能な状態表現を定義する。状態データは最大5MB程度（圧縮後）と想定し、効率的なシリアライズ/デシリアライズ方法を検討する (例: `Codable` 準拠、あるいはカスタムバイナリ形式)。
    * **準備:** `EmulatorCoreManaging` に `saveState() -> Data?` および `loadState(data: Data) -> Bool` の抽象インターフェースを用意しておく。各コンポーネントも自身の状態を Data または `Codable` 形式でエクスポート/インポートする責務を持つ設計とする。
* **デバッガ機能:**
    * **考慮点:** CPU実行ログ（PC、主要レジスタ、フラグ変化）の必要性を想定する。ブレークポイント設定のためのメモリアクセス監視フックを検討する。
    * **準備:** `CPUExecuting` インターフェースに、命令実行前後のフック用メソッド（オプショナル）を追加検討。デバッグビルド時に有効化可能な命令実行ログ記録機能を組み込む。`EmulatorCoreManaging` を介して、CPUレジスタや特定メモリ領域を読み取るためのデバッグ用APIを用意しておく。
* **高度なI/O機能 / 入力デバイス抽象化:**
    * **考慮点:** 物理キーボード、ゲームコントローラー（MFi）への対応。仮想キーボードのレイアウトカスタマイズ。
    * **準備:** キーボード入力、ジョイスティック入力等を抽象化する `InputEvent` のようなデータ構造と、それを処理する `InputHandling` プロトコルを定義する。UI 層からのイベントを `InputHandling` 実装が受け取り、`IOAccessing` を通じて適切なPC88側のI/Oポート（キーボードマトリクス、ジョイスティックポート）への書き込みに変換する。

## 4. 機能要件

### 4.1 主要機能一覧

1.  **エミュレーションコア機能 (SRベース, 音源 YM2608):** _**(v1.4 修正)**_
    * Z80A CPU エミュレーション
    * メモリ管理 (RAM, ROM, VRAM, バンク - SR相当)
    * I/O ポート制御
2.  **ディスク機能:**
    * D88 ディスクイメージ読み込み・解析
    * FDC エミュレーション (IPL 実行、データ読み書き)
3.  **OS・BASIC 実行機能:**
    * IPL からの OS (N88-BASIC ROM SR版相当) 起動
    * N88-BASIC の実行
    * BASIC からのバイナリデータロード (`BLOAD "..."`)
4.  **サウンド機能 (YM2608相当):**
    * YM2608 音源チップエミュレーション (FM, SSG, リズム, ADPCM)
    * **PMD88, SPLIT-i, MUCOM88** 等のドライバによる楽曲再生
    * 音源ドライバ自動判別
5.  **画面表示機能 (SR相当):**
    * CRTCエミュレーション_(v1.5修正: GDC非搭載)
    * PC88 画面 (テキスト、グラフィック SRモード含む) のレンダリング
6.  **UI 機能:**
    * SwiftUI によるエミュレータ画面表示
    * SwiftUI によるリアルタイムパラメータ表示 (演奏アドレス、音名、音色、音量等)
    * 基本的な操作 UI (ディスク選択、リセット等)
7.  **メトリクス収集・分析機能:**
    * CPU使用率、フレームレート、音声バッファ状況などの動作メトリクス収集
    * エミュレーション精度の検証用テスト機能
8.  **ユーザー支援機能:**
    * 初回起動時の基本操作ガイド表示
    * ディスク選択時のプレビュー表示

### 4.2 各機能の詳細 (アーキテクチャを意識した記述)

#### 4.2.1 Z80 CPU エミュレーション (`CPUExecuting` 実装)

* **機能概要:** Z80A 命令セットの正確なエミュレーション。PC-8801mkII SR の動作クロック (通常/高速モード) を考慮。
* **入力:** `MemoryAccessing` (命令フェッチ、データアクセス), `IOAccessing` (IN/OUT命令), 割り込み信号。
* **処理:** 命令デコード、実行、レジスタ・フラグ更新、サイクルカウント。
* **出力:** レジスタ・フラグ状態、メモリアクセス要求、I/Oアクセス要求。
* **テスト:** 各命令の動作、フラグ変化をユニットテストで検証。Z80テストプログラム (zexdoc, zexall) での動作確認。
* **性能目標:** 実機の4MHzモードの4倍以上の処理速度（16MHz相当以上）。SRの高速モード(8MHz)も考慮。
* **正確性指標:** **Zilog公式仕様書に記載された全命令、および PC-88 ソフトウェア互換性のために必要とされる主要な未公開命令（IXH/IXL/IYH/IYL アクセス、SLL命令等を含む）について、正確な動作とフラグ変化を再現する。動作の正確性は、公開されている Z80 テストプログラム (例: zexdoc, zexall) およびターゲットとする主要な PC-88 ソフトウェア (OS, BASIC, 指定アプリケーション) での動作検証を通じて確認する。** _**(v1.4 CPU正確性指標更新)**_

#### 4.2.2 FM 音源再生機能 (`SoundChipEmulating`, `EmulatorCoreManaging` 等の連携)

* **機能概要:** `IOAccessing` 経由でYM2608音源チップへのレジスタ書き込みを受け付け、`SoundChipEmulating` が内部状態を更新し、音声サンプルを生成する。**PMD88, SPLIT-i, MUCOM88** 等のドライバが CPU によって実行されることで、適切なレジスタ書き込みが行われる。自動判別されたドライバ情報に基づき、再生やパラメータ抽出の挙動を調整する。
* **入力:** CPU からの I/O 書き込み (`IOAccessing` 経由), 楽曲データ (`MemoryAccessing` 経由)。
* **処理:** YM2608状態更新、FM/SSG/Rhythm/ADPCM 音声合成、サンプルバッファ生成。
* **出力:** オーディオサンプルデータ (44.1kHz, 16bit ステレオ)。
* **テスト:** 特定レジスタ設定時の出力波形検証、ドライバ特有の挙動に関するテスト、代表的な楽曲でのリファレンス音源との比較。
* **性能目標:** バッファアンダーラン発生率 0.01%以下（10,000サンプルに1回未満）。
* **バッファ設計:** 最大バッファサイズ 2048サンプル (約46.4ミリ秒)、最小バッファサイズ 1024サンプル (約23.2ミリ秒)。
* **音質指標:** 実機同等の音質再現を目指す (SN比 60dB以上目安)。 _**(v1.4 表現変更)**_

#### 4.2.3 リアルタイムパラメータ表示 (`ParameterExtracting`, SwiftUI連携)

* **機能概要:** エミュレーション実行中のFM音源関連パラメータを抽出し、UIにリアルタイム表示する。
* **入力:** `SoundChipEmulating` 状態、`MemoryAccessing` からのドライバワークエリア情報。
* **処理:** 自動判別されたドライバ種別に応じて、メモリ上の演奏情報（アドレス、音名、音色、音量等）を解析。
* **出力:** SwiftUIに表示するためのパラメータデータ構造。
* **テスト:** 各ドライバにおける代表的な楽曲での正確なパラメータ抽出テスト。
* **性能目標:** UI更新頻度 最低15Hz以上 (理想的には30Hz)、遅延時間 100ミリ秒以下。

#### 4.2.4 音源ドライバ自動判別 (`DriverDetecting` 実装)

* **機能概要:** D88ディスクイメージから音源ドライバを自動判別する。
* **入力:** `DiskImageAccessing` を通じたディスクイメージデータ。
* **処理:** ドライバ特有のシグネチャやデータ構造を検索・分析。
* **出力:** 判別結果（ドライバ種別、バージョン、特性情報等）。
* **テスト:** 各種ドライバの代表的なディスクイメージでの判別精度テスト。
* **性能目標:** 判別処理時間 1秒以内、判別精度 95%以上。

#### 4.2.5 メトリクス収集・分析機能 (`MetricsCollecting` 実装)

* **機能概要:** エミュレーション性能や動作状況のメトリクスを収集・分析する。
* **入力:** 各コンポーネントからの動作情報（CPU使用率、フレームレート、音声バッファ状況等）。
* **処理:** メトリクス集計、閾値監視、トレンド分析。
* **出力:** 統計データ、性能警告、最適化提案。
* **テスト:** 各種負荷条件下でのメトリクス収集精度テスト。
* **性能目標:** オーバーヘッド率 3%以下（メトリクス収集による性能低下）。

#### 4.2.6 ユーザー支援機能 (UI 機能の一部として実装)

* **初回起動時ガイド:**
    * **機能概要:** アプリ初回起動時に、ディスクのロード方法、リセット操作など、基本的な使い方を示すシンプルなガイド画面を表示する。
    * **入力:** アプリ初回起動フラグ。
    * **処理:** ガイド用UI表示。既読後は表示しない。
    * **出力:** ガイド画面。
* **ディスクプレビュー:**
    * **機能概要:** ファイル選択UIでD88ファイルを選択した際、ロード前にディスク名（もしあれば解析）と自動判別された音源ドライバ情報（判別できた場合）を表示する。
    * **入力:** 選択されたD88ファイルのURL。
    * **処理:** `DiskImageAccessing` でファイルヘッダ等を読み込み解析。`DriverDetecting` を呼び出しドライバを仮判別。
    * **出力:** ディスク名、ドライバ種別情報を含むプレビューUI。

### 4.3 機能の優先度 (再構築における段階的実装順序案)

1.  **基盤:** `MemoryAccessing`, `IOAccessing` (基本), `CPUExecuting` (基本命令), テスト環境
2.  **IPLブート:** `DiskImageAccessing` (D88, **旧/新フォーマット対応考慮**), `FDCEmulating` (基本), `ScreenRendering` (テキスト), コア統合 (`EmulatorCoreManaging` 基本) -> **目標: BASIC(SR相当) プロンプト表示** _**(v1.4 追記)**_
3.  **サウンドコア:** `SoundChipEmulating` (YM2608 基本レジスタ操作、無音/テスト音生成)
4.  **BASIC実行:** `CPUExecuting` (命令網羅度向上, **未公開命令対応含む**), キーボード入力処理 (`InputHandling` 基本) _**(v1.4 修正)**_
5.  **FM音源再生 (重要):** `SoundChipEmulating` (FM/SSG 実装), 特定ドライバ (例: PMD88) での再生テスト
6.  **画面表示向上:** `ScreenRendering` (グラフィック SRモード対応)
7.  **ドライバ自動判別:** `DriverDetecting` 実装
8.  **リアルタイムパラメータ表示 (重要):** `ParameterExtracting` 実装, SwiftUI連携
9.  **サウンド機能拡充 (重要):** `SoundChipEmulating` (Rhythm, ADPCM 実装)
10. **メトリクス収集:** `MetricsCollecting` 実装、基本性能モニタリング
11. **UI改善・ユーザー支援:** SwiftUIによる操作性の向上、初回ガイド、ディスクプレビュー実装
12. **複数ドライバ対応:** SPLIT-i, MUCOM88 等への対応拡張

## 5. 非機能要件

### 5.1 性能

* **オーディオ再生 (YM2608相当):**
    * 再生遅延: 極力小さくする (具体的な目標値は実装段階で調整) _**(v1.4 表現変更)**_
    * 最大バッファサイズ: 2048サンプル (約46.4ミリ秒)
    * 最小バッファサイズ: 1024サンプル (約23.2ミリ秒)
    * サンプリングレート: 44.1kHz
    * オーバーヘッド: CPU使用率 20%以下 (音源エミュレーションのみ、YM2608は負荷高)
* **リアルタイムパラメータ表示:**
    * UI更新頻度: 最低15Hz (理想は30Hz)
    * 表示遅延: 100ミリ秒以下
* **画面描画:**
    * フレームレート: 30FPS以上 (目標60FPS)
    * GPU描画優先 (Metal/GLKit活用)
    * レンダリングレイテンシ: 33ミリ秒以下 (30FPS相当)
* **アプリケーション起動時間:** 3秒以内
* **ドライバ自動判別処理時間:** 1秒以内
* **メモリ使用量:** 最大250MB以下 (SRベース、YM2608考慮) _**(v1.4 修正)**_
* **ストレージ使用量:** アプリ本体100MB以下 (ディスクイメージ除く)

### 5.2 セキュリティ

* **ディスクイメージファイルアクセス:** iOSのファイルセキュリティモデルに準拠したアクセス管理。ユーザーが明示的に許可したファイルのみアクセス。_**(v1.4 追記)**_
* **データ保持ポリシー:** ユーザー提供データ（ディスクイメージ）は、アプリのサンドボックス内でのみ使用。
* **外部ライブラリ管理:** 使用する外部ライブラリの脆弱性チェックと定期的な更新確認。
* **アプリケーション権限:** 必要最小限の権限要求（ファイルアクセス、オーディオ）。

### 5.3 ユーザビリティ

* **基本操作の直感性:** 主要操作（ディスク選択、リセット等）は2タップ以内で可能。
* **エラーメッセージ:** ユーザーが状況を理解し、可能な場合は対処できるような明確なメッセージ表示（原因と対策を含む）。
* **リアルタイムパラメータ表示:** 情報カテゴリ別の整理、重要度によるハイライト表示。レイアウトのカスタマイズ性（将来検討）。
* **音源ドライバ自動判別:** バックグラウンド処理と結果の自動適用、手動オーバーライド可能。
* **PC88画面表示:** 実機表示の忠実な再現、アスペクト比維持/調整機能。
* **画面サイズ調整:** ピンチイン/アウト、自動フィット、固定比率オプション。
* **仮想キーボード:** SR相当のキー配列。機能キーへのアクセス容易性。ソフトウェアキーボード統合によるテキスト入力。
* **アクセシビリティ:** iOS標準アクセシビリティ機能との互換性（VoiceOver等）。
* **初回ユーザーサポート:** アプリ初回起動時に基本操作ガイドを提供。
* **ディスク選択補助:** ディスクロード前に内容（ディスク名、ドライバ）プレビューを表示。

### 5.4 信頼性

* **アプリケーション安定性:** クラッシュ率0.1%未満（起動1000回あたり1回以下）。
* **エミュレーションコア安定性:** 連続動作24時間以上での状態破綻なし。代表的なソフトウェア (BASIC, 指定ゲーム/音楽ソフト) での長時間動作テスト。
* **オーディオ再生安定性:**
    * バッファアンダーラン率: 0.01%以下（10,000サンプルに1回未満）
    * 異常ノイズ検出と自動回復機能 (可能な範囲で) _**(v1.4 追記)**_
* **音源ドライバ自動判別精度:** 95%以上（一般的なディスクイメージにおいて）。
* **エラー復旧能力:** 非致命的なエラーからの自動復旧、状態の整合性維持機能。
* **メモリリーク防止:** 長時間動作時のメモリ使用量増加率 1時間あたり1MB以下。

### 5.5 保守性 (重要)

* **コード構造:**
    * 単一責任の原則に基づくクラス設計（500行以下/クラス推奨）
    * 明確な命名規則と一貫したコーディングスタイル (例: SwiftLint導入)
    * コンポーネント間の分離度90%以上（独立テスト可能性）
* **ドキュメンテーション:**
    * クラス/メソッドレベルのドキュメント網羅率95%以上
    * アーキテクチャ概要図と主要フロー図
    * 主要アルゴリズムの実装注釈
* **変更影響度:**
    * 単一コンポーネント変更による他コンポーネントへの影響を最小化
    * 明示的なバージョン管理とリリースノート作成
* **リファクタリング容易性:** テスト網羅率を高め、安全なリファクタリングを可能に。

### 5.6 テスト容易性 (重要)

* **テスト戦略:**
    * **ユニットテスト:** 全コア機能の90%以上のコード網羅率
    * **統合テスト:** 主要ユースケースを網羅する自動テスト（IPLブート、BASIC実行、音源再生等）
    * **パフォーマンステスト:** CPU使用率、メモリ使用量、フレームレート、オーディオ安定性等の自動計測
    * **実機テスト:** 代表的なiOSデバイス（最新/最古対応機種）での動作確認
* **テスト自動化:** CI/CD環境での自動テスト実行とレポート生成
* **モック/スタブ:** 全依存インターフェースのモック実装提供
* **テストデータ:** 代表的なディスクイメージ、楽曲データセットの用意
* **リグレッションテスト:** 機能追加/修正時の既存機能検証テスト自動実行

### 5.7 移植性 と 外部依存管理

* **5.7.1 プラットフォーム依存度:** UIレイヤー以外のコアコンポーネントはiOS固有API依存を最小化。
* **5.7.2 標準フレームワーク優先:** 特殊/独自実装より標準Swift/iOSフレームワーク活用。
* **5.7.3 クロスプラットフォーム考慮:** 将来的なmacOS対応を見据えた設計。
* **5.7.4 API互換性:** iOS 15.0以降の各バージョンでの動作保証。
* **5.7.5 デバイス互換性:** 全対応iPhone/iPadモデルでの最適化。
* **5.7.6 外部依存ライブラリ管理:**
    * **主要な依存先(予定):** SwiftUI (iOS 15.0+), Combine (iOS 13.0+), Metal/GLKit (パフォーマンスによる選択), (可能性として) AudioKit。
    * **バージョン管理:** Swift Package Manager を使用し、依存バージョンは `Package.resolved` で固定する。
    * **更新・非推奨対応方針:** 年1回（WWDC後目安）にOSアップデートの影響を評価。API非推奨化や互換性問題が発生した場合、対応バージョンへの更新または代替ライブラリへの移行を検討する。代替案がない場合は、影響範囲を特定し、機能制限または対象OSバージョンの引き上げを検討する。重要セキュリティアップデートは速やかに適用する。

## 6. データ要件

### 6.1 データモデル

* **D88 ディスクイメージデータ:**
    * 形式: D88標準フォーマット準拠
    * サイズ: 
    * メタデータ: 自動抽出（ディスク名、データ構造等）
* **エミュレータ状態:**
    * CPU: レジスタ、フラグ、命令カウンタ等
    * メモリ: RAM (64KB), 拡張RAM(SR), VRAM, バンク状態
    * I/Oデバイス: 各デバイスレジスタ状態
    * 音源チップ(YM2608): 全レジスタ状態、内部合成パラメータ
* **再生パラメータ:** (ドライバ別)
    * PMD88: 演奏アドレス、音名、音色番号、音量、特殊効果
    * SPLIT-i: チャンネル情報、発音状態、パラメータ変化
    * MUCOM88: 音色データ、連携情報、パートステータス
* **判別ドライバ情報:**
    * ドライバ種別 (PMD88, SPLIT-i, MUCOM88等)
    * バージョン情報
    * 特性情報（機能セット、対応サウンド機能等）
    * 推奨パラメータ抽出方法
* **メトリクスデータ:**
    * CPU使用率: 全体およびコンポーネント別
    * フレームレート: 平均値、最小値、変動率
    * オーディオバッファ状態: 充填率、アンダーラン発生頻度
    * メモリ使用量: 全体およびコンポーネント別
    * エミュレーション精度指標: CPUサイクル精度、音源出力品質

### 6.2 データ形式

* **D88 データ:**
    * 形式: D88標準ディスクイメージファイル形式
    * 構造: ヘッダ(ディスク情報) + セクタデータ
    * アクセス: セクタ単位での読み書き
* **内部データ:**
    * 基本型: Swift標準の数値型、構造体、列挙型
    * メモリ表現: `Data`型またはバッファポインタ
    * オブジェクトモデル: 状態を表現する構造体、プロトコル準拠クラス
* **表示用データ:**
    * SwiftUI用モデル: `ObservableObject`準拠のView Model
    * リアルタイムデータ: Combine連携による反応的更新
    * フォーマット: `String`, `Formatted Value`, カスタムフォーマッタ
* **メトリクスデータ:**
    * 収集形式: タイムスタンプ付き測定値
    * 保存形式: JSON, プロパティリスト, またはSQLite
    * 分析形式: 集計統計、トレンドデータ

### 6.3 データライフサイクル

* **D88 データ:**
    * 取得: ユーザーがファイル選択UI経由で選択
    * 読み込み: `DiskImageAccessing`によるファイル読み込みとパース (**旧/新フォーマット自動判別**) _**(v1.4 追記)**_
    * 保持: `DiskImageAccessing`がメモリ内キャッシュとして保持
    * アクセス: FDCエミュレーションによるセクタ単位アクセス
    * 解析: `DriverDetecting`によるドライバ判別利用
    * 破棄: 新しいディスクロード時またはアプリ終了時
* **エミュレータ状態:**
    * 初期化: `EmulatorCoreManaging`によるコンポーネント初期状態設定
    * 更新: CPU実行サイクル毎の各コンポーネント状態更新
    * 監視: `MetricsCollecting`による状態モニタリング
    * セーブ: (将来機能) 状態のシリアライズと保存
    * 復元: (将来機能) 保存状態のデシリアライズと復元
* **再生パラメータ:**
    * 抽出: `ParameterExtracting`による定期的なメモリ/音源チップ状態分析
    * 加工: ドライバ特性に基づいた情報解釈とデータ構築
    * 表示: SwiftUI View Modelへの反映とUI更新
    * ロギング: (オプション) パラメータ変化の時系列記録
* **判別ドライバ情報:**
    * 生成: D88ロード時に`DriverDetecting`が解析して生成
    * 保持: `EmulatorCoreManaging`がシステム全体で参照可能に保持
    * 適用: パラメータ抽出ロジック選択、最適化設定に利用
    * 更新: ディスク交換時に再判別
* **メトリクスデータ:**
    * 収集: 実行中に`MetricsCollecting`が定期サンプリング
    * 分析: リアルタイム集計と閾値モニタリング
    * 表示: 診断UIまたはログへの出力
    * エクスポート: (オプション) 詳細分析用データ出力

## 7. 再構築戦略 / フェーズ計画

### 7.0 リソース想定

本計画は、以下のリソース体制を想定して作成されています。
* **開発チーム:** 本プロジェクトに精通したiOS開発者1〜2名。
* **テスト:** 開発者による単体・統合テストに加え、必要に応じて専任テスターまたは開発者自身による実機テストを実施。

期間見積もりは、上記体制でのコア機能開発を中心としたものであり、予期せぬ技術的課題（特に YM2608 エミュレーションの複雑性）や仕様変更により変動する可能性があります。 _**(v1.4 修正)**_

### 7.1 実装フェーズ

1.  **フェーズ 0: 基盤構築 (2週間)**
    * 開発環境設定
    * コアインターフェース(`protocol`)定義
    * テスト環境構築
    * CI/CD設定
    * リスク分析と対策計画
2.  **フェーズ 1: コア実装とIPLブート (4週間)**
    * `MemoryAccessing` (SR相当) 実装と単体テスト
    * `IOAccessing` (基本) 実装と単体テスト
    * `CPUExecuting` (基本命令セット) 実装と単体テスト
    * `DiskImageAccessing` (D88, **旧/新フォーマット対応**) 実装と単体テスト _**(v1.4 修正)**_
    * `FDCEmulating` (基本) 実装と単体テスト
    * `ScreenRendering` (テキスト) 実装と単体テスト
    * `EmulatorCoreManaging` 基本実装と統合テスト
    * **マイルストーン 1:** BASIC(SR相当)プロンプト表示成功
3.  **フェーズ 2: サウンドとBASIC実行 (3週間)**
    * `SoundChipEmulating` (YM2608 基本レジスタ操作、無音/テスト音) 実装と単体テスト
    * `CPUExecuting` 命令網羅度向上(**未公開命令対応開始**)と単体テスト拡充 _**(v1.4 修正)**_
    * キーボード入力処理 (`InputHandling` 基本) 実装と統合テスト
    * `MetricsCollecting` 基本実装
    * **マイルストーン 2:** BASICコマンド実行成功
4.  **フェーズ 3: FM/SSG 音源再生 (6週間)**
    * `SoundChipEmulating` (FM/SSG 実装) 実装と単体テスト
    * オーディオ出力システム実装と統合テスト
    * PMD88ドライバによる再生テストと検証 (FM/SSG部分)
    * 音質検証と最適化
    * **マイルストーン 3:** PMD88楽曲再生成功 (FM/SSG)
5.  **フェーズ 4: 画面表示と主要機能 (4週間)**
    * `ScreenRendering` (グラフィック SRモード) 実装と単体テスト
    * `DriverDetecting` 実装と単体テスト
    * `ParameterExtracting` 実装と単体テスト
    * SwiftUI基本連携実装
    * **マイルストーン 4:** グラフィック表示とパラメータ抽出成功
6.  **フェーズ 5: ADPCM/Rhythm 再生と UI 連携 (6週間)**
    * `SoundChipEmulating` (ADPCM/Rhythm) 実装と単体テスト
    * SwiftUIによる高度な表示・操作UI実装
    * ユーザー支援機能(ガイド、プレビュー)実装
    * 複数ドライバ(SPLIT-i, MUCOM88)対応と検証
    * パフォーマンス最適化とメトリクス収集強化
    * 期間に余裕を持たせ、バグ修正と安定化に注力
    * **マイルストーン 5:** YM2608全機能再生、主要機能完成、ベータ版相当
7.  **フェーズ 6: 安定化・予備期間 (2週間)**
    * 総合テスト、リグレッションテスト (Z80テストプログラム含む) _**(v1.4 追記)**_
    * 発見されたバグの集中修正
    * パフォーマンス最終調整
    * ドキュメント最終化
    * **マイルストーン 6:** リリース候補版完成

**(合計期間: 27週間)**

### 7.2 各フェーズのリスクと対策

1.  **フェーズ 0-1のリスク:**
    * **リスク:** インターフェース設計の不備により後工程で大幅な修正が必要になる
        * **発生確率:** 中
        * **影響度:** 高
        * **対策:** 事前に主要ユースケース（音源再生フロー、画面更新フロー等）をシーケンス図等で詳細検討。主要インターフェースはプロトタイプコードで早期に検証。設計レビューを実施。
    * **リスク:** CPU実装の不具合や未公開命令の考慮不足によりIPLブートや特定ソフトが動作しない _**(v1.4 修正)**_
        * **発生確率:** 中
        * **影響度:** 高
        * **対策:** 公開されているZ80テストプログラム（例: zexdoc, zexall）を活用し、命令単位での網羅的なテストを実施。実機トレースログとの比較検証を可能な範囲で行う。早期から未公開命令の調査・実装計画を立てる。
    * **リスク:** D88の旧/新フォーマット対応漏れによるディスク読み込み失敗 _**(v1.4 追加)**_
        * **発生確率:** 中 (旧フォーマットの流通度による)
        * **影響度:** 中
        * **対策:** D88ヘッダ解析時にフォーマットを判定するロジックを実装。両フォーマットに対応したテストデータを用意し、読み込み・アクセスが正しく行えることを確認する。

2.  **フェーズ 2-3, フェーズ 5 のリスク:**
    * **リスク:** YM2608 エミュレーションの精度/性能のバランスが取れない (特に FM 音源, ADPCM/Rhythm) _**(v1.4 修正)**_
        * **発生確率:** 高
        * **影響度:** 高
        * **対策:** 初期実装では精度を優先し、必要に応じてテーブルベース合成等の最適化手法を導入検討。性能ボトルネックはXcode Instrumentsで特定し、ターゲットを絞って最適化。明確な精度基準（例: 特定楽曲の波形比較）と性能予算（CPU使用率）をフェーズ開始時に設定。YM2608のドキュメント化されていない挙動の解析に時間を要する可能性を考慮。
    * **リスク:** オーディオ出力の遅延やバッファリング問題の発生
        * **発生確率:** 中
        * **影響度:** 中
        * **対策:** Audio Unit (またはAudioKit) の設定を慎重に行い、低遅延設定を試す。バッファサイズは状況に応じて動的に調整する機構を検討。オーディオ処理専用のスレッド（高優先度）を設ける。様々な負荷状況下でのストレステストを実施。
    * **リスク:** ADPCM/Rhythm の実装と既存部分との同期が複雑化する
        * **発生確率:** 中
        * **影響度:** 中
        * **対策:** YM2608のデータシートを精読し、各機能間の相互作用を理解する。段階的に実装し、各機能追加ごとに統合テストを十分に行う。特にADPCMのデータ転送タイミングとCPU/メモリバスとの連携に注意する。

3.  **フェーズ 4-5のリスク:**
    * **リスク:** ドライバ判別の精度が不十分で一部楽曲が正しく再生されない
        * **発生確率:** 低 (十分なサンプルがあれば)
        * **影響度:** 中
        * **対策:** 様々なバージョン、改造版を含む多様なD88イメージを用いて判別ロジックの精度を検証。判別不能または誤判別の可能性がある場合に備え、ユーザーが手動でドライバ種別を選択できるUIを用意。未知のパターンはログ出力し、継続的に改善。
    * **リスク:** SwiftUI連携部分での性能問題 (特にリアルタイムパラメータ表示)
        * **発生確率:** 中
        * **影響度:** 中
        * **対策:** Combineフレームワークの `throttle` や `debounce` を利用し、UI更新頻度を適切に制御（目標15-30Hz）。Viewの再描画範囲を最小限にするよう`EquatableView` 等を活用。複雑なデータ加工処理はViewModel内で非同期に行い、UIスレッドをブロックしない。InstrumentsでView描画パフォーマンスを計測・最適化。

### 7.3 テスト戦略

1.  **ユニットテスト重点コンポーネント:**
    * `CPUExecuting`: 全Z80A命令の挙動とフラグ変化 (**主要な未公開命令含む**) _**(v1.4 修正)**_
    * `SoundChipEmulating`: YM2608の各機能(FM, SSG, Rhythm, ADPCM)のレジスタ設定と音声合成
    * `MemoryAccessing`: バンク切り替えとマッピング(SR)
    * `DiskImageAccessing`: D88 旧/新フォーマットの読み込みとセクタアクセス _**(v1.4 追加)**_
2.  **統合テスト重点シナリオ:**
    * IPLブートからBASIC(SR)起動までの一連の流れ
    * BASIC上での各種コマンド実行
    * ディスクからのデータロードとプログラム実行 (旧/新フォーマット混在含む) _**(v1.4 修正)**_
    * FMドライバロードから楽曲再生(全機能利用)までの流れ
3.  **パフォーマンステスト:**
    * CPU負荷測定 (特に音源エミュレーション部分 YM2608)
    * メモリ使用量の推移観測
    * バッテリー消費率測定
    * フレームレート安定性測定
    * オーディオバッファ充填率と安定性測定
4.  **精度検証テスト:**
    * 実機(SR相当、可能なら YM2608 搭載機)との比較テスト (特定シーケンスでの動作比較) _**(v1.4 修正)**_
    * リファレンス音源(YM2608)との波形比較
    * Z80テストプログラム (zexdoc, zexall) の実行結果検証 _**(v1.4 修正)**_
    * ターゲットソフトウェアの動作検証

各フェーズの完了時にマイルストーンレビューと総合テストを実施し、次フェーズへの移行判断を行う。

## 8. まとめ

### 8.1 主要成果物

* モジュール化されたPC88エミュレータコア（iOS対応, SRベース, 音源 YM2608） _**(v1.4 修正)**_
* Z80A CPUエミュレーション実装 (**未公開命令含む**) _**(v1.4 修正)**_
* YM2608音源チップエミュレーション実装
* FDC/ディスクイメージハンドリング実装 (**旧/新D88フォーマット対応**) _**(v1.4 修正)**_
* 画面表示エンジン実装 (SRモード含む)
* 音源ドライバ自動判別/パラメータ抽出システム
* SwiftUIベースのユーザーインターフェース
* 単体/統合テストスイート
* パフォーマンス計測・分析ツール
* プロジェクトドキュメンテーション

### 8.2 成功基準

* 主要な音楽ソフト（PMD88, SPLIT-i, MUCOM88）の正確な再生 (YM2608機能含む)
* リアルタイムパラメータ表示の実現
* 安定したエミュレーション（クラッシュなし、性能要件達成）
* モジュール化による高い保守性の実現
* 将来的な機能拡張の容易性確保
* 自動テストによる品質保証 (CPUテストプログラムのパスを含む) _**(v1.4 追記)**_

### 8.3 以降の発展方向

* macOS版への展開
* セーブステート機能の追加
* デバッガ機能の開発
* 演奏データエクスポート機能
* 標準MIDIへの変換機能
* クラウド連携機能
* UIのカスタマイズ機能拡充
* サポート楽曲フォーマットの拡張
* 他のPC-88モデル (MA/FA/VA等) への対応拡張

本プロジェクトは、単なるエミュレータの再実装ではなく、PC88の音楽資産を現代のプラットフォームで活用するための基盤となることを目指しています。モジュール性と拡張性を重視した設計により、将来的な機能拡張や他プラットフォームへの展開も視野に入れています。

## 9. 付録

### 9.1 用語集

* **PC-8801mkII SR**: PC-8801シリーズの主要モデルの一つ。FM音源(YM2203)搭載。本プロジェクトでは基本アーキテクチャのベースとする。 _**(v1.4 修正)**_
* **YM2608 (OPNA)**: YAMAHAが開発したFM音源チップ。YM2203に加え、リズム音源、ADPCM機能を持つ。PC-8801 SR後期モデルやPC-9801シリーズの一部に搭載。本プロジェクトの音源エミュレーションターゲット。 _**(v1.4 修正)**_
* **未公開命令 (Undocumented Instructions)**: CPUメーカーの公式仕様書には記載されていないが、特定の操作で実行される命令。互換性のためにエミュレータでの実装が必要な場合がある。 _**(v1.4 追加)**_
* **D88**: PC-8801シリーズ用のディスクイメージフォーマット
* **IPL**: Initial Program Loader (初期プログラムローダ)
* **FDC**: Floppy Disk Controller (フロッピーディスクコントローラ)
* **FM音源**: Frequency Modulation技術を用いた音源合成方式
* **SSG**: Software-controlled Sound Generator (プログラム制御音源)
* **ADPCM**: Adaptive Differential Pulse Code Modulation (適応差分パルス符号変調)
* **PMD88**: PC-8801用の代表的な音楽ドライバ
* **SPLIT-i**: PC-8801用の音楽ドライバ
* **MUCOM88**: PC-8801用の音楽ドライバ
* **CRTC**: Cathode Ray Tube Controller (ブラウン管表示制御回路)
* **protocol**: Swift言語における、メソッドやプロパティの設計図を定義する機能。インターフェースとして利用される。
* **Dependency Injection (DI)**: 依存性注入。コンポーネントが必要とする他のオブジェクトを外部から与える設計パターン。
* **Unit Test**: 単体テスト。プログラムの最小単位（関数、メソッド、クラス）を個別に検証するテスト。
* **Integration Test**: 結合テスト。複数のコンポーネントを組み合わせて連携動作を検証するテスト。
* **CI/CD**: Continuous Integration / Continuous Delivery (継続的インテグレーション/継続的デリバリー)。コード変更時に自動でビルド、テスト、デプロイを行う仕組み。
* **zexdoc / zexall**: Z80命令セットの動作を検証するための広く使われているテストプログラム。 _**(v1.4 追加)**_

### 9.2 参考資料

* PC-8801mkII SR テクニカルマニュアル (または相当資料)
* Z80 CPU マニュアル (および未公開命令に関する情報源) _**(v1.4 追記)**_
* YM2608 技術仕様書
* 各音源ドライバ資料 (PMD88, SPLIT-i, MUCOM88)
* D88フォーマット仕様
* Z80テストプログラム (zexdoc, zexall)
* (関連するオープンソースエミュレータのソースコード等)

### 9.3 変更履歴

* 2025年3月29日 - v1.0: 初版作成
* 2025年3月29日 - v1.1: レビュー反映、リスク管理、具体的性能指標などの詳細追加
* 2025年3月29日 - v1.2: v1.1へのレビューフィードバックを反映。リスク管理具体化、UI/UX要件補強、リソース想定と予備期間追加、将来拡張考慮の具体化、外部依存管理方針を追加。
* 2025年4月1日 - v1.3: v1.2へのレビューフィードバックを反映。ターゲットモデル(PC-8801mkII SR相当、YM2608音源)を明確化。エラー処理戦略の明記。フェーズ計画とリスク評価をターゲットモデルに合わせて更新。その他全体的な整合性向上。
* 2025年4月1日 - v1.4: v1.3全体を精査し、表現の明確化と整合性向上。特にターゲットモデル(SRベース/YM2608音源)の関係性を明確化。Z80 CPUの正確性指標を未公開命令を含む形に修正。D88旧フォーマット対応をリスク・計画に反映。その他、細部の表現を調整。
* 2025年4月2日 - v1.5: SR実機のハード構造に基づき、GDC非搭載の訂正、FDCがサブCPU制御である点の明示、ALU構造の補足、YM2608(OPNA)対応を前提とした音源仕様と実装要件の追記。
