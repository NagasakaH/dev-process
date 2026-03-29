# ワークフロー: submodule-overview

> ⚠️ **必須**: このステップは `submodule-overview` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

サブモジュールの構造を分析し、概要ドキュメントを生成する。

## 前提条件チェック

```bash
# サブモジュールが存在することを確認
ls submodules/*/  # サブモジュールディレクトリが存在すること
```

## コンテキスト取得

```bash
HELPER="./scripts/project-yaml-helper.sh"

# project.yaml が存在する場合のみ
if [ -f project.yaml ]; then
  TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
  TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
fi

# サブモジュール一覧
SUBMODULES=$(ls -d submodules/*/ 2>/dev/null | xargs -I{} basename {})
```

## 実行手順

1. **submodule-overview スキル** を実行
   - 各サブモジュールの README.md / CLAUDE.md / AGENTS.md を収集
   - 技術スタック、API、依存関係を分析
   - `submodules/{name}.md` に概要ドキュメントを生成

## project.yaml 更新

```bash
# project.yaml が存在する場合のみ更新
if [ -f project.yaml ]; then
  $HELPER update overview \
    --set status=completed \
    --set summary="サブモジュール概要作成完了"
fi
```

## 備考

- このステップは **条件付き実行**（サブモジュールが存在する場合のみ）
- project.yaml 生成前（brainstorming 前）でも実行可能
- 成果物は `submodules/{name}.md` に出力される
