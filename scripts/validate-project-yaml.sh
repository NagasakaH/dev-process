#!/usr/bin/env bash
# =============================================================================
# validate-project-yaml.sh
# =============================================================================
# project.yaml を project.schema.yaml でバリデーションするスクリプト。
#
# 使用方法:
#   ./scripts/validate-project-yaml.sh [options] [project.yaml へのパス]
#
# オプション:
#   --preconditions    前提条件チェックも実行する
#
# 依存ツール（いずれか1つ）:
#   - check-jsonschema (Python): pip install check-jsonschema
#   - yq + python3 (フォールバック)
#
# 終了コード:
#   0: バリデーション成功
#   1: バリデーション失敗
#   2: 必要なツールが見つからない
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCHEMA_FILE="${REPO_ROOT}/project.schema.yaml"
PRECONDITIONS_FILE="${REPO_ROOT}/preconditions.yaml"
DEFAULT_TARGET="${REPO_ROOT}/project.yaml"

# ---------------------------------------------------------------------------
# 色出力
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}ℹ ${NC}$*"; }
success() { echo -e "${GREEN}✅ ${NC}$*"; }
warn()    { echo -e "${YELLOW}⚠️  ${NC}$*"; }
error()   { echo -e "${RED}❌ ${NC}$*"; }

# ---------------------------------------------------------------------------
# 引数処理
# ---------------------------------------------------------------------------
CHECK_PRECONDITIONS=false
TARGET_FILE=""

for arg in "$@"; do
  case "$arg" in
    --preconditions) CHECK_PRECONDITIONS=true ;;
    *) TARGET_FILE="$arg" ;;
  esac
done

TARGET_FILE="${TARGET_FILE:-$DEFAULT_TARGET}"

if [ ! -f "$TARGET_FILE" ]; then
  error "ファイルが見つかりません: $TARGET_FILE"
  echo ""
  echo "使用方法: $0 [project.yaml へのパス]"
  exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
  error "スキーマファイルが見つかりません: $SCHEMA_FILE"
  exit 2
fi

info "バリデーション対象: $TARGET_FILE"
info "スキーマ: $SCHEMA_FILE"
echo ""

# ---------------------------------------------------------------------------
# バリデーション実行
# ---------------------------------------------------------------------------

# 方法1: check-jsonschema（推奨）
if command -v check-jsonschema &>/dev/null; then
  info "check-jsonschema でバリデーション中..."
  echo ""

  if check-jsonschema \
    --schemafile "$SCHEMA_FILE" \
    "$TARGET_FILE" 2>&1; then
    echo ""
    success "バリデーション成功: $TARGET_FILE はスキーマに準拠しています"
    exit 0
  else
    echo ""
    error "バリデーション失敗: スキーマ違反が検出されました"
    exit 1
  fi
fi

# 方法2: python3 + jsonschema + pyyaml
if command -v python3 &>/dev/null; then
  info "python3 でバリデーション中..."
  echo ""

  python3 -c "
import sys
import json

try:
    import yaml
except ImportError:
    print('❌ PyYAML が必要です: pip install pyyaml')
    sys.exit(2)

try:
    from jsonschema import validate, ValidationError, SchemaError
except ImportError:
    print('❌ jsonschema が必要です: pip install jsonschema')
    sys.exit(2)

# スキーマ読み込み
with open('$SCHEMA_FILE', 'r') as f:
    schema = yaml.safe_load(f)

# 対象ファイル読み込み
with open('$TARGET_FILE', 'r') as f:
    data = yaml.safe_load(f)

# バリデーション実行
try:
    validate(instance=data, schema=schema)
    print('✅ バリデーション成功: スキーマに準拠しています')
    sys.exit(0)
except SchemaError as e:
    print(f'❌ スキーマ定義エラー: {e.message}')
    sys.exit(2)
except ValidationError as e:
    print(f'❌ バリデーション失敗:')
    print(f'   パス: {\" > \".join(str(p) for p in e.absolute_path)}')
    print(f'   エラー: {e.message}')

    # 追加コンテキスト
    if e.context:
        print(f'   詳細:')
        for ctx in e.context[:5]:
            print(f'     - {ctx.message}')

    sys.exit(1)
" 2>&1

  SCHEMA_RESULT=$?

  if [ $SCHEMA_RESULT -ne 0 ]; then
    exit $SCHEMA_RESULT
  fi

  # 前提条件チェック（--preconditions 指定時）
  if [ "$CHECK_PRECONDITIONS" = true ]; then
    echo ""
    if [ ! -f "$PRECONDITIONS_FILE" ]; then
      warn "preconditions.yaml が見つかりません。前提条件チェックをスキップ"
      exit 0
    fi

    if ! command -v yq &>/dev/null; then
      warn "yq が必要です。前提条件チェックをスキップ"
      exit 0
    fi

    info "前提条件チェック..."
    echo ""

    HAS_WARNING=false

    sections=$(yq '.preconditions | keys | .[]' "$PRECONDITIONS_FILE" 2>/dev/null)

    while IFS= read -r section; do
      [ -z "$section" ] && continue
      yaml_key="${section//-/_}"
      section_exists=$(yq ".$yaml_key | type" "$TARGET_FILE" 2>/dev/null || echo "null")

      if [ "$section_exists" = "!!null" ] || [ "$section_exists" = "null" ]; then
        continue
      fi

      num_requires=$(yq ".preconditions.\"$section\".requires | length" "$PRECONDITIONS_FILE" 2>/dev/null || echo "0")

      for (( i=0; i<num_requires; i++ )); do
        req_path=$(yq ".preconditions.\"$section\".requires[$i].path" "$PRECONDITIONS_FILE")
        req_value=$(yq ".preconditions.\"$section\".requires[$i].value" "$PRECONDITIONS_FILE")
        req_desc=$(yq ".preconditions.\"$section\".requires[$i].description" "$PRECONDITIONS_FILE")

        actual_value=$(yq ".$req_path // \"未設定\"" "$TARGET_FILE" 2>/dev/null || echo "未設定")

        if [ "$actual_value" = "$req_value" ]; then
          success "$section: $req_desc"
        else
          warn "$section: $req_desc （現在: $actual_value、期待: $req_value）"
          HAS_WARNING=true
        fi
      done
    done <<< "$sections"

    echo ""
    if [ "$HAS_WARNING" = true ]; then
      warn "一部の前提条件が満たされていません"
    else
      success "全前提条件が満たされています"
    fi
  fi

  exit 0
fi

# ツールが見つからない場合
error "バリデーションツールが見つかりません"
echo ""
echo "以下のいずれかをインストールしてください:"
echo ""
echo "  推奨: pip install check-jsonschema"
echo "  代替: pip install jsonschema pyyaml"
echo ""
exit 2

