#!/usr/bin/env bash
# =============================================================================
# project-yaml-helper.sh
# =============================================================================
# project.yaml 操作用 CLI ヘルパー。
#
# 使用方法:
#   ./scripts/project-yaml-helper.sh <command> [options]
#
# コマンド:
#   status [yaml_path]               全セクションのステータス一覧
#   validate [yaml_path]             スキーマバリデーション + 前提条件チェック
#   init-section <section> [yaml_path]  セクション雛形を生成
#   update <section> [yaml_path] [--status val] [--summary text] [--artifacts path]
#
# 依存ツール: yq (https://github.com/mikefarah/yq)
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 定数
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCHEMA_FILE="${REPO_ROOT}/project.schema.yaml"
PRECONDITIONS_FILE="${REPO_ROOT}/preconditions.yaml"

# ---------------------------------------------------------------------------
# 色出力
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ ${NC}$*"; }
success() { echo -e "${GREEN}✅ ${NC}$*"; }
warn()    { echo -e "${YELLOW}⚠️  ${NC}$*"; }
error()   { echo -e "${RED}❌ ${NC}$*"; }

# ---------------------------------------------------------------------------
# ヘルプ
# ---------------------------------------------------------------------------
show_help() {
  cat <<'EOF'
project-yaml-helper — project.yaml 操作用 CLI ヘルパー

使用方法:
  ./scripts/project-yaml-helper.sh <command> [options]

コマンド:
  status [yaml_path]
    全セクションの現在ステータスを一覧表示

  validate [yaml_path]
    スキーマバリデーション + 前提条件チェックを実行

  init-section <section> [yaml_path]
    指定セクションの雛形を project.yaml に追加

  update <section> [yaml_path] [--status val] [--summary text] [--artifacts path]
    指定セクションのフィールドを更新

  checkpoint <checkpoint_name> [yaml_path] --verdict <approved|revision_requested> [--feedback text] [--rollback-to phase]
    人間チェックポイントの結果を記録
    checkpoint_name: brainstorming_review, design_review, pr_review

  resolve-checkpoint <checkpoint_name> [yaml_path] --summary text
    差し戻しチェックポイントの対応完了を記録

  help
    このヘルプを表示

対応セクション:
  brainstorming, overview, investigation, design, plan,
  implement, verification, code_review, finishing, human_checkpoints
EOF
}

# ---------------------------------------------------------------------------
# yq チェック
# ---------------------------------------------------------------------------
check_yq() {
  if ! command -v yq &>/dev/null; then
    error "yq が見つかりません。インストールしてください:"
    echo "  brew install yq"
    echo "  または https://github.com/mikefarah/yq"
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# コマンド: status
# ---------------------------------------------------------------------------
cmd_status() {
  local yaml_path="${1:-${REPO_ROOT}/project.yaml}"

  if [ ! -f "$yaml_path" ]; then
    error "ファイルが見つかりません: $yaml_path"
    exit 1
  fi

  echo -e "${BOLD}📊 project.yaml ステータス一覧${NC}"
  echo -e "${BOLD}ファイル:${NC} $yaml_path"
  echo ""

  local sections=(meta brainstorming overview investigation design plan implement verification code_review finishing)
  local section_labels=("メタ情報" "ブレインストーミング" "概要" "調査" "設計" "計画" "実装" "検証" "コードレビュー" "完了")

  # ヘッダー
  printf "  %-20s %-16s %-12s %-12s\n" "セクション" "ステータス" "開始" "完了"
  printf "  %-20s %-16s %-12s %-12s\n" "────────────" "────────" "──────" "──────"

  for i in "${!sections[@]}"; do
    local section="${sections[$i]}"
    local label="${section_labels[$i]}"

    # セクションが存在するかチェック
    local exists
    exists=$(yq ".$section | type" "$yaml_path" 2>/dev/null || echo "null")

    if [ "$exists" = "!!null" ] || [ "$exists" = "null" ]; then
      printf "  %-20s ${YELLOW}%-16s${NC}\n" "$label" "未作成"
      continue
    fi

    local status
    status=$(yq ".$section.status // \"—\"" "$yaml_path" 2>/dev/null || echo "—")

    local started
    started=$(yq ".$section.started_at // \"—\"" "$yaml_path" 2>/dev/null || echo "—")
    if [ "$started" != "—" ]; then
      started=$(echo "$started" | cut -c1-10)
    fi

    local completed
    completed=$(yq ".$section.completed_at // \"—\"" "$yaml_path" 2>/dev/null || echo "—")
    if [ "$completed" != "—" ]; then
      completed=$(echo "$completed" | cut -c1-10)
    fi

    # ステータス色分け
    local status_colored
    case "$status" in
      completed|approved|pass) status_colored="${GREEN}${status}${NC}" ;;
      in_progress|pending|conditional) status_colored="${YELLOW}${status}${NC}" ;;
      failed|rejected|revision_required) status_colored="${RED}${status}${NC}" ;;
      *) status_colored="${status}" ;;
    esac

    printf "  %-20s %-28b %-12s %-12s\n" "$label" "$status_colored" "$started" "$completed"

    # レビューサブセクションがある場合
    if [ "$section" = "design" ] || [ "$section" = "plan" ]; then
      local review_exists
      review_exists=$(yq ".$section.review | type" "$yaml_path" 2>/dev/null || echo "null")
      if [ "$review_exists" != "!!null" ] && [ "$review_exists" != "null" ]; then
        local review_status
        review_status=$(yq ".$section.review.status // \"—\"" "$yaml_path" 2>/dev/null || echo "—")
        local review_round
        review_round=$(yq ".$section.review.round // 0" "$yaml_path" 2>/dev/null || echo "0")

        local review_colored
        case "$review_status" in
          approved) review_colored="${GREEN}${review_status}${NC}" ;;
          pending|conditional) review_colored="${YELLOW}${review_status}${NC}" ;;
          rejected) review_colored="${RED}${review_status}${NC}" ;;
          *) review_colored="${review_status}" ;;
        esac
        printf "    %-18s %-28b (round %s)\n" "└ レビュー" "$review_colored" "$review_round"
      fi
    fi
  done

  # 人間チェックポイントセクション
  local hc_exists
  hc_exists=$(yq ".human_checkpoints | type" "$yaml_path" 2>/dev/null || echo "null")
  if [ "$hc_exists" != "!!null" ] && [ "$hc_exists" != "null" ]; then
    echo ""
    echo -e "${BOLD}🔍 人間チェックポイント${NC}"
    echo ""
    printf "  %-24s %-20s %-8s\n" "チェックポイント" "ステータス" "ラウンド"
    printf "  %-24s %-20s %-8s\n" "──────────────" "────────" "────"

    local checkpoints=(brainstorming_review design_review pr_review)
    local checkpoint_labels=("ブレスト後レビュー" "設計完了後レビュー" "PR発行後レビュー")

    for j in "${!checkpoints[@]}"; do
      local cp="${checkpoints[$j]}"
      local cp_label="${checkpoint_labels[$j]}"

      local cp_exists
      cp_exists=$(yq ".human_checkpoints.$cp | type" "$yaml_path" 2>/dev/null || echo "null")
      if [ "$cp_exists" = "!!null" ] || [ "$cp_exists" = "null" ]; then
        printf "  %-24s ${YELLOW}%-20s${NC}\n" "$cp_label" "未作成"
        continue
      fi

      local cp_status
      cp_status=$(yq ".human_checkpoints.$cp.status // \"—\"" "$yaml_path" 2>/dev/null || echo "—")
      local cp_round
      cp_round=$(yq ".human_checkpoints.$cp.current_round // 0" "$yaml_path" 2>/dev/null || echo "0")

      local cp_colored
      case "$cp_status" in
        approved) cp_colored="${GREEN}${cp_status}${NC}" ;;
        pending) cp_colored="${YELLOW}${cp_status}${NC}" ;;
        revision_requested) cp_colored="${RED}${cp_status}${NC}" ;;
        *) cp_colored="${cp_status}" ;;
      esac
      printf "  %-24s %-32b %-8s\n" "$cp_label" "$cp_colored" "$cp_round"

      # 最新の差し戻しフィードバックがある場合表示
      if [ "$cp_status" = "revision_requested" ]; then
        local latest_feedback
        latest_feedback=$(yq ".human_checkpoints.$cp.rounds[-1].feedback // \"\"" "$yaml_path" 2>/dev/null || echo "")
        if [ -n "$latest_feedback" ] && [ "$latest_feedback" != "null" ]; then
          printf "    ${CYAN}└ 指摘: %s${NC}\n" "$latest_feedback"
        fi
      fi
    done
  fi

  echo ""
}

# ---------------------------------------------------------------------------
# コマンド: validate
# ---------------------------------------------------------------------------
cmd_validate() {
  local yaml_path="${1:-${REPO_ROOT}/project.yaml}"

  echo -e "${BOLD}🔍 project.yaml バリデーション${NC}"
  echo ""

  # 1. スキーマバリデーション
  info "スキーマバリデーション..."
  if "${SCRIPT_DIR}/validate-project-yaml.sh" "$yaml_path" 2>&1; then
    echo ""
  else
    echo ""
    error "スキーマバリデーション失敗"
    return 1
  fi

  # 2. 前提条件チェック
  if [ -f "$PRECONDITIONS_FILE" ]; then
    info "前提条件チェック..."
    check_preconditions "$yaml_path"
  else
    warn "preconditions.yaml が見つかりません。前提条件チェックをスキップ"
  fi
}

# ---------------------------------------------------------------------------
# 前提条件チェック（内部関数）
# ---------------------------------------------------------------------------
check_preconditions() {
  local yaml_path="$1"
  local has_warning=false

  # 各セクションの前提条件を確認
  local sections
  sections=$(yq '.preconditions | keys | .[]' "$PRECONDITIONS_FILE" 2>/dev/null)

  while IFS= read -r section; do
    [ -z "$section" ] && continue

    # セクションが project.yaml に存在するかチェック
    # セクション名からYAMLキーに変換（- を _ に）
    local yaml_key="${section//-/_}"
    local section_exists
    section_exists=$(yq ".$yaml_key | type" "$yaml_path" 2>/dev/null || echo "null")

    # セクションがまだ作成されていない場合はスキップ
    if [ "$section_exists" = "!!null" ] || [ "$section_exists" = "null" ]; then
      continue
    fi

    # 前提条件を確認
    local num_requires
    num_requires=$(yq ".preconditions.\"$section\".requires | length" "$PRECONDITIONS_FILE" 2>/dev/null || echo "0")

    for (( i=0; i<num_requires; i++ )); do
      local req_path
      req_path=$(yq ".preconditions.\"$section\".requires[$i].path" "$PRECONDITIONS_FILE")
      local req_value
      req_value=$(yq ".preconditions.\"$section\".requires[$i].value" "$PRECONDITIONS_FILE")
      local req_desc
      req_desc=$(yq ".preconditions.\"$section\".requires[$i].description" "$PRECONDITIONS_FILE")

      # 実際の値を取得
      local actual_value
      actual_value=$(yq ".$req_path // \"未設定\"" "$yaml_path" 2>/dev/null || echo "未設定")

      if [ "$actual_value" = "$req_value" ]; then
        success "$section: $req_desc"
      else
        warn "$section: $req_desc （現在: $actual_value、期待: $req_value）"
        has_warning=true
      fi
    done
  done <<< "$sections"

  echo ""
  if [ "$has_warning" = true ]; then
    warn "一部の前提条件が満たされていません"
  else
    success "全前提条件が満たされています"
  fi
}

# ---------------------------------------------------------------------------
# コマンド: init-section
# ---------------------------------------------------------------------------
cmd_init_section() {
  local section="${1:-}"
  local yaml_path="${2:-${REPO_ROOT}/project.yaml}"

  if [ -z "$section" ]; then
    error "セクション名を指定してください"
    echo "  使用方法: $0 init-section <section> [yaml_path]"
    exit 1
  fi

  if [ ! -f "$yaml_path" ]; then
    error "ファイルが見つかりません: $yaml_path"
    exit 1
  fi

  local timestamp
  timestamp=$(date -Iseconds)

  case "$section" in
    brainstorming)
      yq -i ".brainstorming.status = \"pending\" |
             .brainstorming.started_at = \"$timestamp\" |
             .brainstorming.summary = \"\" |
             .brainstorming.decisions = [] |
             .brainstorming.refined_requirements = [] |
             .brainstorming.artifacts = \"\"" "$yaml_path"
      ;;
    overview)
      yq -i ".overview.status = \"pending\" |
             .overview.started_at = \"$timestamp\" |
             .overview.summary = \"\" |
             .overview.artifacts = \"\"" "$yaml_path"
      ;;
    investigation)
      yq -i ".investigation.status = \"pending\" |
             .investigation.started_at = \"$timestamp\" |
             .investigation.summary = \"\" |
             .investigation.key_findings = [] |
             .investigation.risks = [] |
             .investigation.artifacts = \"\"" "$yaml_path"
      ;;
    design)
      yq -i ".design.status = \"pending\" |
             .design.started_at = \"$timestamp\" |
             .design.summary = \"\" |
             .design.approach = \"\" |
             .design.key_decisions = [] |
             .design.review.round = 0 |
             .design.review.status = \"pending\" |
             .design.artifacts = \"\"" "$yaml_path"
      ;;
    plan)
      yq -i ".plan.status = \"pending\" |
             .plan.started_at = \"$timestamp\" |
             .plan.summary = \"\" |
             .plan.total_tasks = 0 |
             .plan.tasks = [] |
             .plan.review.round = 0 |
             .plan.review.status = \"pending\" |
             .plan.artifacts = \"\"" "$yaml_path"
      ;;
    implement)
      yq -i ".implement.status = \"in_progress\" |
             .implement.started_at = \"$timestamp\" |
             .implement.completed_tasks = 0 |
             .implement.total_tasks = 0 |
             .implement.tasks = [] |
             .implement.artifacts = \"\"" "$yaml_path"
      ;;
    verification)
      yq -i ".verification.status = \"pending\" |
             .verification.started_at = \"$timestamp\" |
             .verification.results.test.status = \"skip\" |
             .verification.results.test.detail = \"\" |
             .verification.results.build.status = \"skip\" |
             .verification.results.build.detail = \"\" |
             .verification.results.lint.status = \"skip\" |
             .verification.results.lint.detail = \"\" |
             .verification.results.typecheck.status = \"skip\" |
             .verification.results.typecheck.detail = \"\" |
             .verification.acceptance_criteria_check = [] |
             .verification.summary = \"\" |
             .verification.evidence = [] |
             .verification.artifacts = []" "$yaml_path"
      ;;
    code_review)
      yq -i ".code_review.status = \"pending\" |
             .code_review.started_at = \"$timestamp\" |
             .code_review.round = 1 |
             .code_review.rounds = [] |
             .code_review.review_checklist = {} |
             .code_review.issues = [] |
             .code_review.artifacts = []" "$yaml_path"
      ;;
    finishing)
      yq -i ".finishing.status = \"pending\" |
             .finishing.started_at = \"$timestamp\" |
             .finishing.action = \"keep\"" "$yaml_path"
      ;;
    human_checkpoints)
      yq -i ".human_checkpoints.brainstorming_review.status = \"pending\" |
             .human_checkpoints.brainstorming_review.current_round = 0 |
             .human_checkpoints.brainstorming_review.rounds = [] |
             .human_checkpoints.design_review.status = \"pending\" |
             .human_checkpoints.design_review.current_round = 0 |
             .human_checkpoints.design_review.rounds = [] |
             .human_checkpoints.pr_review.status = \"pending\" |
             .human_checkpoints.pr_review.current_round = 0 |
             .human_checkpoints.pr_review.rounds = []" "$yaml_path"
      ;;
    *)
      error "不明なセクション: $section"
      echo "  対応セクション: brainstorming, overview, investigation, design,"
      echo "                  plan, implement, verification, code_review, finishing,"
      echo "                  human_checkpoints"
      exit 1
      ;;
  esac

  # updated_at を更新
  yq -i ".meta.updated_at = \"$timestamp\"" "$yaml_path"

  success "セクション '$section' を初期化しました"
}

# ---------------------------------------------------------------------------
# コマンド: update
# ---------------------------------------------------------------------------
cmd_update() {
  local section="${1:-}"
  local yaml_path="${2:-${REPO_ROOT}/project.yaml}"
  shift 2 2>/dev/null || true

  if [ -z "$section" ]; then
    error "セクション名を指定してください"
    echo "  使用方法: $0 update <section> [yaml_path] [--status val] [--summary text] [--artifacts path]"
    exit 1
  fi

  if [ ! -f "$yaml_path" ]; then
    error "ファイルが見つかりません: $yaml_path"
    exit 1
  fi

  local timestamp
  timestamp=$(date -Iseconds)
  local updated=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)
        yq -i ".$section.status = \"$2\"" "$yaml_path"
        if [ "$2" = "completed" ] || [ "$2" = "approved" ] || [ "$2" = "failed" ]; then
          yq -i ".$section.completed_at = \"$timestamp\"" "$yaml_path"
        fi
        updated=true
        shift 2
        ;;
      --summary)
        yq -i ".$section.summary = \"$2\"" "$yaml_path"
        updated=true
        shift 2
        ;;
      --artifacts)
        yq -i ".$section.artifacts = \"$2\"" "$yaml_path"
        updated=true
        shift 2
        ;;
      *)
        warn "不明なオプション: $1"
        shift
        ;;
    esac
  done

  if [ "$updated" = true ]; then
    yq -i ".meta.updated_at = \"$timestamp\"" "$yaml_path"
    success "セクション '$section' を更新しました"
  else
    warn "更新するフィールドが指定されていません"
  fi
}

# ---------------------------------------------------------------------------
# コマンド: checkpoint
# ---------------------------------------------------------------------------
cmd_checkpoint() {
  local checkpoint_name="${1:-}"
  local yaml_path="${2:-${REPO_ROOT}/project.yaml}"
  shift 2 2>/dev/null || true

  if [ -z "$checkpoint_name" ]; then
    error "チェックポイント名を指定してください"
    echo "  使用方法: $0 checkpoint <brainstorming_review|design_review|pr_review> [yaml_path] --verdict <approved|revision_requested> [--feedback text] [--rollback-to phase]"
    exit 1
  fi

  # チェックポイント名バリデーション
  case "$checkpoint_name" in
    brainstorming_review|design_review|pr_review) ;;
    *)
      error "不明なチェックポイント: $checkpoint_name"
      echo "  対応チェックポイント: brainstorming_review, design_review, pr_review"
      exit 1
      ;;
  esac

  if [ ! -f "$yaml_path" ]; then
    error "ファイルが見つかりません: $yaml_path"
    exit 1
  fi

  local timestamp
  timestamp=$(date -Iseconds)
  local verdict=""
  local feedback=""
  local rollback_to=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verdict)
        verdict="$2"
        shift 2
        ;;
      --feedback)
        feedback="$2"
        shift 2
        ;;
      --rollback-to)
        rollback_to="$2"
        shift 2
        ;;
      *)
        warn "不明なオプション: $1"
        shift
        ;;
    esac
  done

  if [ -z "$verdict" ]; then
    error "--verdict オプションは必須です（approved または revision_requested）"
    exit 1
  fi

  if [ "$verdict" != "approved" ] && [ "$verdict" != "revision_requested" ]; then
    error "verdict は approved または revision_requested を指定してください"
    exit 1
  fi

  # human_checkpoints セクションが存在しない場合は初期化
  local hc_exists
  hc_exists=$(yq ".human_checkpoints.$checkpoint_name | type" "$yaml_path" 2>/dev/null || echo "null")
  if [ "$hc_exists" = "!!null" ] || [ "$hc_exists" = "null" ]; then
    yq -i ".human_checkpoints.$checkpoint_name.status = \"pending\" |
           .human_checkpoints.$checkpoint_name.current_round = 0 |
           .human_checkpoints.$checkpoint_name.rounds = []" "$yaml_path"
  fi

  # ラウンド番号を取得・インクリメント
  local current_round
  current_round=$(yq ".human_checkpoints.$checkpoint_name.current_round // 0" "$yaml_path" 2>/dev/null || echo "0")
  local new_round=$((current_round + 1))

  # ステータス更新
  yq -i ".human_checkpoints.$checkpoint_name.status = \"$verdict\" |
         .human_checkpoints.$checkpoint_name.current_round = $new_round" "$yaml_path"

  # ラウンド記録を追加
  yq -i ".human_checkpoints.$checkpoint_name.rounds += [{\"round\": $new_round, \"reviewed_at\": \"$timestamp\", \"verdict\": \"$verdict\"}]" "$yaml_path"

  # フィードバックがある場合
  if [ -n "$feedback" ]; then
    yq -i ".human_checkpoints.$checkpoint_name.rounds[-1].feedback = \"$feedback\"" "$yaml_path"
  fi

  # 差し戻し先がある場合
  if [ -n "$rollback_to" ] && [ "$verdict" = "revision_requested" ]; then
    yq -i ".human_checkpoints.$checkpoint_name.rounds[-1].rollback_to = \"$rollback_to\"" "$yaml_path"
  fi

  # updated_at を更新
  yq -i ".meta.updated_at = \"$timestamp\"" "$yaml_path"

  if [ "$verdict" = "approved" ]; then
    success "チェックポイント '$checkpoint_name' を承認しました (round $new_round)"
  else
    warn "チェックポイント '$checkpoint_name' で差し戻しが発生しました (round $new_round)"
    if [ -n "$feedback" ]; then
      echo -e "  ${CYAN}指摘内容: $feedback${NC}"
    fi
    if [ -n "$rollback_to" ]; then
      echo -e "  ${CYAN}差し戻し先: $rollback_to${NC}"
    fi
  fi
}

# ---------------------------------------------------------------------------
# コマンド: resolve-checkpoint
# ---------------------------------------------------------------------------
cmd_resolve_checkpoint() {
  local checkpoint_name="${1:-}"
  local yaml_path="${2:-${REPO_ROOT}/project.yaml}"
  shift 2 2>/dev/null || true

  if [ -z "$checkpoint_name" ]; then
    error "チェックポイント名を指定してください"
    echo "  使用方法: $0 resolve-checkpoint <brainstorming_review|design_review|pr_review> [yaml_path] --summary text"
    exit 1
  fi

  # チェックポイント名バリデーション
  case "$checkpoint_name" in
    brainstorming_review|design_review|pr_review) ;;
    *)
      error "不明なチェックポイント: $checkpoint_name"
      exit 1
      ;;
  esac

  if [ ! -f "$yaml_path" ]; then
    error "ファイルが見つかりません: $yaml_path"
    exit 1
  fi

  local timestamp
  timestamp=$(date -Iseconds)
  local summary=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --summary)
        summary="$2"
        shift 2
        ;;
      *)
        warn "不明なオプション: $1"
        shift
        ;;
    esac
  done

  if [ -z "$summary" ]; then
    error "--summary オプションは必須です"
    exit 1
  fi

  # 現在のステータスを確認
  local current_status
  current_status=$(yq ".human_checkpoints.$checkpoint_name.status // \"pending\"" "$yaml_path" 2>/dev/null || echo "pending")

  if [ "$current_status" != "revision_requested" ]; then
    error "チェックポイント '$checkpoint_name' は差し戻し状態ではありません（現在: $current_status）"
    exit 1
  fi

  # 最新ラウンドの resolved_at と resolution_summary を更新
  yq -i ".human_checkpoints.$checkpoint_name.rounds[-1].resolved_at = \"$timestamp\" |
         .human_checkpoints.$checkpoint_name.rounds[-1].resolution_summary = \"$summary\" |
         .human_checkpoints.$checkpoint_name.status = \"pending\"" "$yaml_path"

  # updated_at を更新
  yq -i ".meta.updated_at = \"$timestamp\"" "$yaml_path"

  success "チェックポイント '$checkpoint_name' の差し戻し対応を記録しました"
  echo -e "  ${CYAN}対応内容: $summary${NC}"
  info "再レビューのため、checkpoint コマンドで再度判定を記録してください"
}

# ---------------------------------------------------------------------------
# メインルーティング
# ---------------------------------------------------------------------------
check_yq

case "${1:-help}" in
  status)
    shift
    cmd_status "$@"
    ;;
  validate)
    shift
    cmd_validate "$@"
    ;;
  init-section)
    shift
    cmd_init_section "$@"
    ;;
  update)
    shift
    cmd_update "$@"
    ;;
  checkpoint)
    shift
    cmd_checkpoint "$@"
    ;;
  resolve-checkpoint)
    shift
    cmd_resolve_checkpoint "$@"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    error "不明なコマンド: $1"
    echo ""
    show_help
    exit 1
    ;;
esac
