# ワークフロー: brainstorming

setup.yaml を基に要件探索・テスト戦略を検討し、project.yaml を初期生成する。

## 前提条件
- setup.yaml が存在すること
- init-work-branch が完了していること

## コンテキスト取得

```bash
# setup.yaml 全体を入力として使用
cat setup.yaml
```

## 実行手順

1. **brainstorming スキル** を実行
   - setup.yaml の内容を入力として渡す
   - 要件の探索、テスト戦略の確認を実施

2. **project-state スキル** で project.yaml を生成
   - brainstorming の結果を基に project.yaml を初期生成
   - 以下のセクションを作成：
     - `meta`: ticket_id, target_repo, version 等
     - `setup`: setup.yaml の description を転記
     - `brainstorming`: 結果・テスト戦略を記録

```bash
# project.yaml 初期生成後のセクション更新例
HELPER="./scripts/project-yaml-helper.sh"
$HELPER update brainstorming --status completed \
  --summary "要件探索・テスト戦略確定"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml
```

## 完了後の人間チェックポイント

```bash
HELPER="./scripts/project-yaml-helper.sh"
# brainstorming_review チェックポイントが pending 状態になる
# ユーザーの承認を待つ
```
