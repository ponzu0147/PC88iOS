#!/bin/bash

# リソースディレクトリのパス
RESOURCES_DIR="/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS/Resources"

# Xcodeプロジェクトのパス
XCODE_PROJECT="/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS.xcodeproj"

# リソースディレクトリが存在するか確認
if [ ! -d "$RESOURCES_DIR" ]; then
  echo "リソースディレクトリが見つかりません: $RESOURCES_DIR"
  exit 1
fi

# リソースディレクトリ内のファイルを一覧表示
echo "リソースディレクトリ内のファイル:"
ls -la "$RESOURCES_DIR"

# リソースファイルをアプリのバンドルにコピーする手順を表示
echo ""
echo "手順:"
echo "1. Xcodeでプロジェクトを開いてください"
echo "2. プロジェクトナビゲータで「PC88iOS」プロジェクトを選択"
echo "3. 「Build Phases」タブを選択"
echo "4. 「Copy Bundle Resources」セクションを開く"
echo "5. 「+」ボタンをクリックして「Add Other...」を選択"
echo "6. 以下のディレクトリに移動して全てのファイルを選択: $RESOURCES_DIR"
echo "7. 「Add」ボタンをクリック"
echo ""
echo "または、Finderで以下のディレクトリを開き:"
echo "$RESOURCES_DIR"
echo "全てのファイルをXcodeのプロジェクトナビゲータにドラッグ&ドロップしてください。"
echo "「Copy items if needed」と「Create groups」オプションを選択してください。"
