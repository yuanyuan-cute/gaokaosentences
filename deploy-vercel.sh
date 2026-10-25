#!/usr/bin/env bash
# 一键部署到 Vercel（生产环境）
# 用法：
#   export VERCEL_TOKEN=xxxxxx 然后 ./scripts/deploy-vercel.sh
#   或直接 ./scripts/deploy-vercel.sh --token xxxxxx
#   也可以 ./scripts/deploy-vercel.sh --no-login 跳过登录（需要 token）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# —— 解析参数 ——
TOKEN="${VERCEL_TOKEN:-}"
NO_LOGIN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)     TOKEN="$2"; shift 2 ;;
    --no-login)  NO_LOGIN=1; shift ;;
    -h|--help)
      echo "用法：deploy-vercel.sh [--token xxxxxx] [--no-login]"
      echo "  默认读环境变量 VERCEL_TOKEN；不传 --no-login 会弹出登录提示"
      exit 0 ;;
    *) shift ;;
  esac
done

# —— 必须文件校验 ——
MISSING=()
for f in index.html sentences.js qrcode.min.js vercel.json; do
  [[ ! -f "$f" ]] && MISSING+=("$f")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "✗ 缺少关键文件：${MISSING[*]}"
  exit 1
fi

# —— vercel CLI 可用性 ——
if ! command -v vercel &>/dev/null; then
  if ! command -v npm &>/dev/null; then
    echo "✗ 未找到 npm，请先安装 Node.js（https://nodejs.org）"
    exit 1
  fi
  echo "▶ vercel CLI 未安装，正在通过 npm 全局安装…"
  npm install -g vercel --quiet
fi

# —— 构建命令（纯静态项目，跳过 build） ——
BUILD_CMD="vercel"
FLAGS=( "--prod" "--yes" )

if [[ -n "$TOKEN" ]]; then
  FLAGS+=( "--token" "$TOKEN" )
elif [[ -n "$NO_LOGIN" ]]; then
  echo "✗ 需要 VERCEL_TOKEN 才能非交互部署。"
  echo "  到 https://vercel.com/account/tokens 创建一个 Personal Token，然后："
  echo "  export VERCEL_TOKEN=你的token && ./scripts/deploy-vercel.sh"
  exit 1
fi

# —— 执行部署 ——
echo "▶ 开始部署 Vercel 生产环境…"
set +e
OUTPUT=$("$BUILD_CMD" "${FLAGS[@]}" 2>&1)
RC=$?
set -e

echo "$OUTPUT"

if [[ $RC -ne 0 ]]; then
  echo "✗ 部署失败（退出码 $RC）"
  # 给诊断提示
  if echo "$OUTPUT" | grep -qiE "login|auth|unauthorized|token"; then
    echo "  提示：鉴权失败，检查 token 是否过期或权限不足"
  elif echo "$OUTPUT" | grep -qiE "no project|scope"; then
    echo "  提示：可能需要先在 Vercel 上创建项目，然后把项目 ID 通过 vercel link 绑定"
  fi
  exit $RC
fi

# —— 尝试从输出里抓取公网 URL ——
if URL=$(echo "$OUTPUT" | grep -oE 'https://[a-zA-Z0-9.-]+\.vercel\.app' | head -1); then
  echo ""
  echo "✓ 部署完成！公网地址：$URL"
  echo "  手机浏览器打开后，点页面右上角分享按钮扫码即可。"
else
  echo ""
  echo "✓ 部署完成（查看上方日志里的 Production URL）"
fi
