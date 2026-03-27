# setup.yaml スキーマ・テンプレート

生成される setup.yaml の構造とテンプレート定義です。

> **SSOT対応**: description は階層化フォーマットで、design-document や各スキルの Single Source of Truth となります。

## 1. テンプレート構造

```yaml
# =============================================================================
# 開発セットアップ設定ファイル（SSOT: Single Source of Truth）
# =============================================================================
# 自動生成元: https://github.com/{owner}/{repo}/issues/{issue_number}
# 生成日時: {timestamp}
# =============================================================================

task_name: "{task_name}"
ticket_id: "{ticket_id}"

# =============================================================================
# 説明（階層化フォーマット）
# =============================================================================
description:
  # 概要
  overview: |
{overview}

  # 目的
  purpose: |
{purpose}

  # 背景
  # investigation スキルが参照
  background: |
{background}

  # 要件
  # design スキルが参照
  requirements:
    functional:
{functional_requirements}
    non_functional:
{non_functional_requirements}

  # 受け入れ条件
  # plan スキルが参照
  acceptance_criteria:
{acceptance_criteria}

  # スコープ
  scope:
{scope}

  # スコープ外
  out_of_scope:
{out_of_scope}

  # 補足
  notes: |
{notes}

# =============================================================================
# リポジトリ設定
# =============================================================================

# 関連リポジトリ（※自動抽出結果 - 必要に応じて編集）
related_repositories:
{related_repositories_yaml}

# 修正対象リポジトリ（※自動抽出結果 - 必要に応じて編集）
target_repositories:
{target_repositories_yaml}

# オプション設定
options:
  create_design_document: true
  design_document_dir: "docs"
  submodules_dir: "submodules"
```

## 2. 出力形式の具体例

Issue #123「ユーザー認証機能の改善」の場合：

```yaml
# =============================================================================
# 開発セットアップ設定ファイル（SSOT: Single Source of Truth）
# =============================================================================
# 自動生成元: https://github.com/org/repo/issues/123
# 生成日時: 2024-01-15T10:30:00Z
# =============================================================================

task_name: "ユーザー認証機能の改善"
ticket_id: "123"

description:
  overview: |
    ユーザー認証機能を改善し、セキュリティを強化する。
  
  purpose: |
    - セキュリティの向上
    - ユーザー体験の改善
    - 業界標準への準拠
  
  background: |
    現在の認証システムでは以下の課題がある:
    - 二要素認証が未対応
    - セッションタイムアウトの設定が固定
  
  requirements:
    functional:
      - "二要素認証の導入"
      - "セッション管理の改善"
      - "パスワードポリシーの強化"
    non_functional:
      - "認証レスポンス: 500ms以内"
      - "可用性: 99.9%"
  
  acceptance_criteria:
    - "二要素認証が有効化できること"
    - "既存ユーザーの認証が維持されること"
    - "セキュリティテストをパスすること"
  
  scope:
    - "認証API"
    - "セッション管理"
  
  out_of_scope:
    - "UI変更"
    - "OAuth連携"
  
  notes: |
    参考: https://github.com/org/security-guidelines

related_repositories:
  - name: "auth-library"
    url: "https://github.com/org/auth-library"

target_repositories:
  - name: "backend-api"
    url: "https://github.com/org/backend-api"

options:
  create_design_document: true
  design_document_dir: "docs"
  submodules_dir: "submodules"
```

## 3. 配置場所

カレントディレクトリに以下の名前で出力：

```
./setup-{ticket_id}.yaml
```

例: Issue #123 の場合 → `setup-123.yaml`
