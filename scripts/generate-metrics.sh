#!/usr/bin/env bash
# =============================================================================
# generate-metrics.sh
# =============================================================================
# project.yaml の各セクションの started_at / completed_at から
# メトリクスを自動計算し _metrics セクションに書き込む。
#
# 使用方法:
#   ./scripts/generate-metrics.sh [project.yaml へのパス]
#
# 依存ツール: yq, python3（時間差分計算用）
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TARGET="${REPO_ROOT}/project.yaml"

# ---------------------------------------------------------------------------
# 色出力
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ ${NC}$*"; }
success() { echo -e "${GREEN}✅ ${NC}$*"; }

# ---------------------------------------------------------------------------
# 依存チェック
# ---------------------------------------------------------------------------
if ! command -v yq &>/dev/null; then
  echo "❌ yq が必要です: brew install yq"
  exit 2
fi

if ! command -v python3 &>/dev/null; then
  echo "❌ python3 が必要です"
  exit 2
fi

# ---------------------------------------------------------------------------
# 引数処理
# ---------------------------------------------------------------------------
TARGET_FILE="${1:-$DEFAULT_TARGET}"

if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ ファイルが見つかりません: $TARGET_FILE"
  exit 1
fi

info "メトリクス生成: $TARGET_FILE"
echo ""

# ---------------------------------------------------------------------------
# 時間差分計算関数（Python）
# ---------------------------------------------------------------------------
calc_duration_min() {
  local start_time="$1"
  local end_time="$2"

  if [ "$start_time" = "null" ] || [ "$end_time" = "null" ] || \
     [ -z "$start_time" ] || [ -z "$end_time" ]; then
    echo "null"
    return
  fi

  python3 -c "
from datetime import datetime, timezone
import re

def parse_iso(s):
    s = s.strip()
    # Handle timezone offset like +09:00
    s = re.sub(r'([+-]\d{2}):(\d{2})$', r'\1\2', s)
    try:
        return datetime.strptime(s, '%Y-%m-%dT%H:%M:%S%z')
    except ValueError:
        try:
            return datetime.strptime(s, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
        except ValueError:
            return None

start = parse_iso('$start_time')
end = parse_iso('$end_time')
if start and end:
    diff = (end - start).total_seconds() / 60
    print(f'{diff:.1f}')
else:
    print('null')
" 2>/dev/null || echo "null"
}

# ---------------------------------------------------------------------------
# メトリクス収集
# ---------------------------------------------------------------------------
PHASES=(brainstorming overview investigation design plan implement verification code_review finishing)
TOTAL_MIN=0
MAX_DURATION=0
BOTTLENECK=""

# _metrics.phases を初期化
yq -i '._metrics = {}' "$TARGET_FILE"
yq -i '._metrics.phases = {}' "$TARGET_FILE"

for phase in "${PHASES[@]}"; do
  # セクションが存在するかチェック
  exists=$(yq ".$phase | type" "$TARGET_FILE" 2>/dev/null || echo "null")
  if [ "$exists" = "!!null" ] || [ "$exists" = "null" ]; then
    continue
  fi

  started=$(yq ".$phase.started_at // \"null\"" "$TARGET_FILE" 2>/dev/null || echo "null")
  completed=$(yq ".$phase.completed_at // \"null\"" "$TARGET_FILE" 2>/dev/null || echo "null")

  duration=$(calc_duration_min "$started" "$completed")

  if [ "$duration" != "null" ]; then
    yq -i "._metrics.phases.$phase.duration_min = $duration" "$TARGET_FILE"
    TOTAL_MIN=$(python3 -c "print($TOTAL_MIN + $duration)")

    # ボトルネック判定
    is_bigger=$(python3 -c "print('yes' if $duration > $MAX_DURATION else 'no')")
    if [ "$is_bigger" = "yes" ]; then
      MAX_DURATION=$duration
      BOTTLENECK=$phase
    fi
  fi

  # フェーズ固有のメトリクス追加
  case "$phase" in
    design|plan)
      review_rounds=$(yq ".$phase.review.round // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
      if [ "$review_rounds" != "0" ] && [ "$review_rounds" != "null" ]; then
        yq -i "._metrics.phases.$phase.review_rounds = $review_rounds" "$TARGET_FILE"
      fi
      ;;
    implement)
      tasks_completed=$(yq ".$phase.completed_tasks // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
      total_tasks=$(yq ".$phase.total_tasks // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
      if [ "$tasks_completed" != "0" ]; then
        yq -i "._metrics.phases.$phase.tasks_completed = $tasks_completed" "$TARGET_FILE"
      fi
      ;;
    verification)
      tests_status=$(yq ".$phase.results.test.status // \"skip\"" "$TARGET_FILE" 2>/dev/null || echo "skip")
      if [ "$tests_status" = "pass" ]; then
        coverage=$(yq ".$phase.results.test.coverage // \"\"" "$TARGET_FILE" 2>/dev/null || echo "")
        if [ -n "$coverage" ] && [ "$coverage" != "null" ]; then
          yq -i "._metrics.phases.$phase.coverage = \"$coverage\"" "$TARGET_FILE"
        fi
      fi
      ;;
    code_review)
      rounds=$(yq ".$phase.round // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
      total_issues=$(yq ".$phase.issues | length" "$TARGET_FILE" 2>/dev/null || echo "0")
      fixed=$(yq ".$phase.issues | [.[] | select(.status == \"fixed\")] | length" "$TARGET_FILE" 2>/dev/null || echo "0")
      disputed=$(yq ".$phase.issues | [.[] | select(.status == \"disputed\")] | length" "$TARGET_FILE" 2>/dev/null || echo "0")
      if [ "$rounds" != "0" ] && [ "$rounds" != "null" ]; then
        yq -i "._metrics.phases.$phase.rounds = $rounds" "$TARGET_FILE"
        yq -i "._metrics.phases.$phase.total_issues = $total_issues" "$TARGET_FILE"
        yq -i "._metrics.phases.$phase.fixed = $fixed" "$TARGET_FILE"
        yq -i "._metrics.phases.$phase.disputed = $disputed" "$TARGET_FILE"
      fi
      ;;
  esac
done

# 総所要時間（時間）
TOTAL_HOURS=$(python3 -c "print(round($TOTAL_MIN / 60, 2))")
yq -i "._metrics.total_duration_hours = $TOTAL_HOURS" "$TARGET_FILE"

# ボトルネック
if [ -n "$BOTTLENECK" ]; then
  yq -i "._metrics.bottleneck = \"$BOTTLENECK\"" "$TARGET_FILE"
fi

# 完了予測（implement が in_progress の場合）
impl_status=$(yq ".implement.status // \"\"" "$TARGET_FILE" 2>/dev/null || echo "")
if [ "$impl_status" = "in_progress" ]; then
  completed_tasks=$(yq ".implement.completed_tasks // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
  total_tasks=$(yq ".implement.total_tasks // 0" "$TARGET_FILE" 2>/dev/null || echo "0")
  remaining=$((total_tasks - completed_tasks))

  if [ "$completed_tasks" -gt 0 ] && [ "$remaining" -gt 0 ]; then
    impl_started=$(yq ".implement.started_at // \"null\"" "$TARGET_FILE" 2>/dev/null || echo "null")
    now=$(date -Iseconds)
    elapsed=$(calc_duration_min "$impl_started" "$now")

    if [ "$elapsed" != "null" ]; then
      estimated_hours=$(python3 -c "
elapsed = $elapsed
completed = $completed_tasks
remaining = $remaining
avg_per_task = elapsed / completed
est = (avg_per_task * remaining) / 60
print(f'{est:.1f}')
")
      yq -i "._metrics.estimated_remaining.current_phase = \"implement\"" "$TARGET_FILE"
      yq -i "._metrics.estimated_remaining.tasks_remaining = $remaining" "$TARGET_FILE"
      yq -i "._metrics.estimated_remaining.estimated_hours = $estimated_hours" "$TARGET_FILE"
    fi
  fi
fi

# updated_at を更新
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" "$TARGET_FILE"

echo ""
echo -e "${BOLD}📊 メトリクスサマリー${NC}"
echo ""
echo -e "  総所要時間: ${GREEN}${TOTAL_HOURS}h${NC}"
if [ -n "$BOTTLENECK" ]; then
  echo -e "  ボトルネック: ${BOTTLENECK} (${MAX_DURATION}min)"
fi
echo ""
success "メトリクスを _metrics セクションに書き込みました"
