#!/usr/bin/env bash
# 本地预览：解压 zip 后，跑 ./scripts/local-preview.sh 即可
# 自动选择 python3 > npx serve，默认端口 8000
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 必须文件存在性校验
MISSING=()
for f in index.html sentences.js qrcode.min.js; do
  if [[ ! -f "$f" ]]; then MISSING+=("$f"); fi
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "✗ 缺少关键文件：${MISSING[*]}"
  echo "  请确认在项目根目录运行此脚本。"
  exit 1
fi

PORT="${1:-8000}"

if command -v python3 &>/dev/null; then
  echo "▶ 用 python3 启动静态服务，端口 $PORT"
  echo "▶ 浏览器打开 http://localhost:$PORT"
  echo "▶ 按 Ctrl+C 停止"
  exec python3 -m http.server "$PORT"
elif command -v node &>/dev/null; then
  echo "▶ 用 npx serve 启动静态服务，端口 $PORT"
  echo "▶ 浏览器打开 http://localhost:$PORT"
  echo "▶ 按 Ctrl+C 停止"
  exec npx --yes serve . -l "$PORT"
else
  echo "✗ 未找到 python3 或 node，请先安装其中之一"
  exit 1
fi
