#!/usr/bin/env ruby
# encoding: utf-8

# Xcodeプロジェクトファイルにビルドフェーズを追加するスクリプト
require 'xcodeproj'

# プロジェクトのパス
project_path = '/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# メインターゲットを取得
main_target = project.targets.find { |target| target.name == 'PC88iOS' }

if main_target.nil?
  puts "エラー: PC88iOSターゲットが見つかりませんでした。"
  exit 1
end

# SwiftLintのビルドフェーズが既に存在するか確認
swiftlint_phase = main_target.build_phases.find { |phase| 
  phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && 
  phase.name == "Run SwiftLint" 
}

if swiftlint_phase.nil?
  # SwiftLintのビルドフェーズを追加
  swiftlint_phase = main_target.new_shell_script_build_phase("Run SwiftLint")
  swiftlint_phase.shell_script = <<-EOS
# 出力ディレクトリを設定
OUTPUT_DIR="${DERIVED_FILE_DIR}"
OUTPUT_FILE="${OUTPUT_DIR}/swiftlint_output.txt"

# 出力ディレクトリが存在しない場合は作成
mkdir -p "${OUTPUT_DIR}"

# SwiftLintのパスを設定
SWIFTLINT_PATH="/opt/homebrew/bin/swiftlint"
CONFIG_PATH="${SRCROOT}/.swiftlint.yml"

# 設定ファイルのパーミッションを更新
if [ -f "$CONFIG_PATH" ]; then
  chmod 644 "$CONFIG_PATH"
  echo "SwiftLint config file permissions updated"
fi

if [ -f "${PODS_ROOT}/SwiftLint/swiftlint" ]; then
  "${PODS_ROOT}/SwiftLint/swiftlint" --config "$CONFIG_PATH" > "${OUTPUT_FILE}" 2>&1
elif [ -f "$SWIFTLINT_PATH" ]; then
  "$SWIFTLINT_PATH" --config "$CONFIG_PATH" > "${OUTPUT_FILE}" 2>&1
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint" > "${OUTPUT_FILE}"
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

# 結果を表示
if [ -f "${OUTPUT_FILE}" ]; then
  cat "${OUTPUT_FILE}"
fi
  EOS
  
  # 出力ファイルを指定
  swiftlint_phase.output_paths = ['$(DERIVED_FILE_DIR)/swiftlint_output.txt']
  
  # ビルドフェーズの順序を調整（コンパイル前に実行）
  main_target.build_phases.move(swiftlint_phase, 0)
  
  puts "SwiftLintのビルドフェーズが追加されました。"
else
  # 既存のビルドフェーズを更新
  swiftlint_phase.shell_script = <<-EOS
# 出力ディレクトリを設定
OUTPUT_DIR="${DERIVED_FILE_DIR}"
OUTPUT_FILE="${OUTPUT_DIR}/swiftlint_output.txt"

# 出力ディレクトリが存在しない場合は作成
mkdir -p "${OUTPUT_DIR}"

# SwiftLintのパスを設定
SWIFTLINT_PATH="/opt/homebrew/bin/swiftlint"
CONFIG_PATH="${SRCROOT}/.swiftlint.yml"

# 設定ファイルのパーミッションを更新
if [ -f "$CONFIG_PATH" ]; then
  chmod 644 "$CONFIG_PATH"
  echo "SwiftLint config file permissions updated"
fi

if [ -f "${PODS_ROOT}/SwiftLint/swiftlint" ]; then
  "${PODS_ROOT}/SwiftLint/swiftlint" --config "$CONFIG_PATH" > "${OUTPUT_FILE}" 2>&1
elif [ -f "$SWIFTLINT_PATH" ]; then
  "$SWIFTLINT_PATH" --config "$CONFIG_PATH" > "${OUTPUT_FILE}" 2>&1
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint" > "${OUTPUT_FILE}"
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi

# 結果を表示
if [ -f "${OUTPUT_FILE}" ]; then
  cat "${OUTPUT_FILE}"
fi
  EOS
  
  # 出力ファイルを指定
  swiftlint_phase.output_paths = ['$(DERIVED_FILE_DIR)/swiftlint_output.txt']
  
  puts "SwiftLintのビルドフェーズが更新されました。"
end

# プロジェクトを保存
project.save
