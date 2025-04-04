#!/bin/bash

# 出力ディレクトリを設定
OUTPUT_DIR="${DERIVED_FILE_DIR}"
OUTPUT_FILE="${OUTPUT_DIR}/swiftlint_output.txt"

# 出力ディレクトリが存在しない場合は作成
mkdir -p "${OUTPUT_DIR}"

# SwiftLintのパスを設定
SWIFTLINT_PATH="/opt/homebrew/bin/swiftlint"
CONFIG_PATH="${SRCROOT}/.swiftlint.yml"

# 設定ファイルの所有者を確認し、必要に応じて所有者を変更
if [ -f "$CONFIG_PATH" ]; then
  chmod 644 "$CONFIG_PATH"
  echo "SwiftLint config file permissions updated"
fi

# SwiftLintが存在するか確認
if [ -f "$SWIFTLINT_PATH" ]; then
  # SwiftLintを実行し、結果をファイルに出力
  "$SWIFTLINT_PATH" --config "$CONFIG_PATH" > "${OUTPUT_FILE}" 2>&1
  exit_code=$?
  
  # 結果を表示
  if [ -f "${OUTPUT_FILE}" ]; then
    cat "${OUTPUT_FILE}"
  fi
  
  exit $exit_code
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint" > "${OUTPUT_FILE}"
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  exit 1
fi
