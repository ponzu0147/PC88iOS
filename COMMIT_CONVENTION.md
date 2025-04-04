# PC88iOS コミットメッセージ規約

PC88iOSプロジェクトでは、以下のコミットメッセージ規約を採用しています。この規約は、変更履歴の明確化、自動化ツールとの連携、開発者間のコミュニケーション向上を目的としています。

## コミットメッセージの構造

```
<タイプ>(<スコープ>): <タイトル>

<本文>

<フッター>
```

### タイプ

コミットの種類を表す接頭辞：

- **feat**: 新機能
- **fix**: バグ修正
- **docs**: ドキュメントのみの変更
- **style**: コードの意味に影響を与えない変更（空白、フォーマット、セミコロンの欠落など）
- **refactor**: バグ修正や機能追加ではないコードの変更
- **perf**: パフォーマンスを向上させるコードの変更
- **test**: 不足しているテストの追加や既存のテストの修正
- **chore**: ビルドプロセスやドキュメント生成などの補助ツールやライブラリの変更

### スコープ

変更の範囲を表す名詞（オプション）：

- **core**: コア機能
- **cpu**: CPU関連
- **memory**: メモリ関連
- **disk**: ディスク関連
- **screen**: 画面表示関連
- **sound**: 音声関連
- **ui**: ユーザーインターフェース
- **test**: テスト関連
- **build**: ビルド関連
- **ci**: CI関連
- **deps**: 依存関係

### タイトル

- 命令形、現在形で記述（"changed"や"changes"ではなく"change"）
- 最初の文字は大文字にしない
- 文末にピリオドを付けない
- 50文字以内に収める

### 本文（オプション）

- コミットの詳細な説明
- 72文字で改行
- 「なぜ」変更したのかを説明
- 「何を」変更したのかではなく、「なぜ」変更したのかを説明

### フッター（オプション）

- 破壊的変更（BREAKING CHANGE）の場合は記載
- Issue参照（Closes #123, Fixes #456など）

## 例

```
feat(disk): implement ALPHA-MINI-DOS loader

- Add support for loading ALPHA-MINI-DOS from D88 disk images
- Implement IPL and OS extraction logic
- Add memory management for loading

Closes #42
```

```
fix(memory): correct memory access for ALPHA-MINI-DOS

Memory access was incorrectly handling the IPL load address.
This fixes the issue by properly setting the memory offset.

Fixes #57
```

```
refactor(disk): improve AlphaMiniDosLoader class structure

- Separate IPL and OS extraction logic
- Add logging for better debugging
- Improve error handling

Closes #63
```

## 自動化ツールとの連携

この規約は、以下のツールとの連携を想定しています：

- **Semantic Release**: バージョン管理の自動化
- **Conventional Changelog**: 変更履歴の自動生成
- **Commitlint**: コミットメッセージの検証

## 参考

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)
