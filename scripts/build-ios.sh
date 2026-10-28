#!/usr/bin/env bash

# ==============================================================================
# 微行动助手 - iOS 本地一键打包与构建脚本
# 支持生成:
# 1. 签名正式包 (.ipa) - 用于 TestFlight / App Store 发布或 Ad-Hoc 分发
# 2. 无签名测试包 (.ipa) - 用于 TrollStore / 侧载 / 开发者自签
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../maintenance_assistant" && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/build/ios_output"

echo "=========================================="
echo "  微行动助手 iOS 打包工具"
echo "  工程目录: ${PROJECT_DIR}"
echo "=========================================="

cd "${PROJECT_DIR}"

# 1. 检查 Flutter 环境
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 未检测到 flutter 命令，请先安装 Flutter SDK 并加入 PATH。"
    exit 1
fi

# 2. 检查 CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ 错误: 未检测到 pod 命令，请在 macOS 终端执行 'sudo gem install cocoapods'。"
    exit 1
fi

# 3. 安装依赖
echo "📦 正在拉取 Flutter 依赖..."
flutter pub get

# 4. 安装 iOS Pod 依赖
echo "🍎 正在安装 CocoaPods 依赖..."
cd ios
pod install
cd ..

mkdir -p "${OUTPUT_DIR}"

echo "------------------------------------------"
echo "请选择构建模式:"
echo "1) 无签名 IPA (用于 TrollStore / AltStore / 自签工具)"
echo "2) 签名正式发布 IPA (需已在 Xcode 配置 Apple 证书及 Profile)"
echo "------------------------------------------"
read -p "请输入选项 [1 或 2，默认 1]: " BUILD_MODE
BUILD_MODE=${BUILD_MODE:-1}

if [ "$BUILD_MODE" = "1" ]; then
    echo "🚀 开始构建 Release 版本 (No CodeSign)..."
    flutter build ios --release --no-codesign

    PAYLOAD_DIR="${PROJECT_DIR}/build/ios/iphoneos/Payload"
    rm -rf "${PAYLOAD_DIR}"
    mkdir -p "${PAYLOAD_DIR}"
    cp -r "${PROJECT_DIR}/build/ios/iphoneos/Runner.app" "${PAYLOAD_DIR}/"

    TARGET_IPA="${OUTPUT_DIR}/MaintenanceAssistant_unsigned.ipa"
    cd "${PROJECT_DIR}/build/ios/iphoneos"
    zip -r -q "${TARGET_IPA}" Payload
    rm -rf "${PAYLOAD_DIR}"

    echo "✅ 构建完成！无签名 IPA 文件位于:"
    echo "   ${TARGET_IPA}"
else
    echo "🚀 开始执行 flutter build ipa..."
    flutter build ipa --release

    echo "✅ 构建完成！IPA 产物位于:"
    echo "   ${PROJECT_DIR}/build/ios/archive/Runner.xcarchive"
    echo "   ${PROJECT_DIR}/build/ios/ipa"
fi

echo "=========================================="
echo "🎉 iOS 打包流程结束！"
echo "=========================================="
