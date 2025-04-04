#!/usr/bin/env ruby
# encoding: utf-8

# Xcodeプロジェクトの推奨設定を更新するスクリプト
require 'xcodeproj'

# プロジェクトのパス
project_path = '/Users/koshikawamasato/Downloads/PC88iOS/PC88iOS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# バックアップを作成
require 'fileutils'
backup_path = "#{project_path}/project.pbxproj.backup.#{Time.now.strftime('%Y%m%d%H%M%S')}"
FileUtils.cp("#{project_path}/project.pbxproj", backup_path)
puts "バックアップを作成しました: #{backup_path}"

# 最新の推奨設定を適用
project.build_configurations.each do |config|
  # Swift言語バージョンを設定
  config.build_settings['SWIFT_VERSION'] = '5.0'
  
  # 最新のiOSデプロイメントターゲットを設定
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  
  # 警告を有効化
  config.build_settings['CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING'] = 'YES'
  config.build_settings['CLANG_WARN_BOOL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_COMMA'] = 'YES'
  config.build_settings['CLANG_WARN_CONSTANT_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS'] = 'YES'
  config.build_settings['CLANG_WARN_EMPTY_BODY'] = 'YES'
  config.build_settings['CLANG_WARN_ENUM_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_INFINITE_RECURSION'] = 'YES'
  config.build_settings['CLANG_WARN_INT_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_NON_LITERAL_NULL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'YES'
  config.build_settings['CLANG_WARN_OBJC_LITERAL_CONVERSION'] = 'YES'
  config.build_settings['CLANG_WARN_RANGE_LOOP_ANALYSIS'] = 'YES'
  config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'YES'
  config.build_settings['CLANG_WARN_SUSPICIOUS_MOVE'] = 'YES'
  config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'YES'
  config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'YES'
  config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
  config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES'
  config.build_settings['GCC_WARN_64_TO_32_BIT_CONVERSION'] = 'YES'
  config.build_settings['GCC_WARN_ABOUT_RETURN_TYPE'] = 'YES_ERROR'
  config.build_settings['GCC_WARN_UNDECLARED_SELECTOR'] = 'YES'
  config.build_settings['GCC_WARN_UNINITIALIZED_AUTOS'] = 'YES_AGGRESSIVE'
  config.build_settings['GCC_WARN_UNUSED_FUNCTION'] = 'YES'
  config.build_settings['GCC_WARN_UNUSED_VARIABLE'] = 'YES'
  
  # 最新のビルド設定
  config.build_settings['CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED'] = 'YES'
  config.build_settings['CLANG_ANALYZER_NONNULL'] = 'YES'
  config.build_settings['CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION'] = 'YES_AGGRESSIVE'
  config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++20'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  config.build_settings['COPY_PHASE_STRIP'] = 'NO'
  config.build_settings['ENABLE_NS_ASSERTIONS'] = 'YES'
  
  # SwiftLint関連の設定
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

# 各ターゲットの設定も更新
project.targets.each do |target|
  target.build_configurations.each do |config|
    # ターゲット固有の設定を更新
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    
    # SwiftLintのビルドフェーズのために必要な設定
    if target.name == 'PC88iOS'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end

# プロジェクトを保存
project.save

puts "プロジェクトの推奨設定を更新しました。"
