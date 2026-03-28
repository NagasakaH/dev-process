# ヘルパーコマンド詳細リファレンス

`scripts/project-yaml-helper.sh` の全コマンド引数・オプション一覧。

```bash
HELPER="./scripts/project-yaml-helper.sh"

# ステータス確認
$HELPER status [yaml_path]

# バリデーション（スキーマ + 前提条件）
$HELPER validate [yaml_path]

# セクション雛形生成
$HELPER init-section <section> [yaml_path]

# セクション更新
$HELPER update <section> [yaml_path] --status <val> --summary <text> --artifacts <path>

# 人間チェックポイント記録
$HELPER checkpoint <name> [yaml_path] --verdict <approved|revision_requested> [--feedback text] [--rollback-to phase]

# チェックポイント解決記録
$HELPER resolve-checkpoint <name> [yaml_path] --summary <text>

# セクションスナップショット
$HELPER snapshot-section <section> <triggered_by> [yaml_path]
```

## 引数の補足

- `[yaml_path]` — 省略時はカレントディレクトリの `project.yaml` を使用
- `<section>` — project.yaml のセクション名（例: `investigation`, `design`）
- `<name>` — チェックポイント名（例: `brainstorming_review`, `design_review`, `pr_review`）
- `--rollback-to` — 差し戻し時に戻すフェーズを指定
