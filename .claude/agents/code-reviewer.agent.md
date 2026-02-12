# Code Reviewer エージェント

コード変更の品質レビューを行うエージェント。SHAベースの差分レビューに特化。

## 概要

実装完了後のコードレビューを自動化し、問題を早期に検出します。

## 呼び出し方法

### 基本パターン

```yaml
- agent_type: "code-review"
  prompt: |
    ## レビュー依頼

    ### 実装内容
    {WHAT_WAS_IMPLEMENTED}

    ### 要件/計画
    {PLAN_OR_REQUIREMENTS}

    ### 差分対象
    - ベースSHA: {BASE_SHA}
    - ヘッドSHA: {HEAD_SHA}
```

### SHAベースレビューテンプレート

```bash
# SHA取得
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

# 差分確認
git diff $BASE_SHA..$HEAD_SHA --stat
```

```yaml
- agent_type: "code-review"
  prompt: |
    ## SHAベースレビュー依頼

    ### 対象
    - リポジトリ: {repository}
    - ベースSHA: ${BASE_SHA}
    - ヘッドSHA: ${HEAD_SHA}
    - 差分ファイル数: $(git diff $BASE_SHA..$HEAD_SHA --stat | tail -1)

    ### 実装概要
    {implementation_summary}

    ### レビュー観点
    1. 要件との整合性
    2. コード品質（可読性、保守性）
    3. テストカバレッジ
    4. セキュリティ考慮
    5. パフォーマンス影響

    ### 期待する出力
    - Critical/Important/Minor に分類された問題リスト
    - 各問題の具体的な修正提案
```

## レビュー出力形式

```markdown
## レビュー結果

### Critical（即座に修正が必要）
- [ ] {問題1}: {説明} → {修正提案}

### Important（マージ前に修正が必要）
- [ ] {問題2}: {説明} → {修正提案}

### Minor（後で対応可能）
- [ ] {問題3}: {説明} → {修正提案}

### 良い点
- {良い点1}
- {良い点2}
```

## 運用例

### 1. 単一タスク完了後のレビュー

```bash
# タスク実装完了後
BASE_SHA=$(git rev-parse HEAD~1)
HEAD_SHA=$(git rev-parse HEAD)

# code-reviewerエージェント呼び出し
claude --agent code-review --prompt "
レビュー依頼:
- 実装: task01 - ユーザー認証機能の追加
- 要件: docs/target-repo/plan/task01.md
- BASE_SHA: $BASE_SHA
- HEAD_SHA: $HEAD_SHA
"
```

### 2. 並列タスク統合後のレビュー

```bash
# cherry-pick完了後
BASE_SHA=$(git rev-parse HEAD~3)  # 並列タスク数分
HEAD_SHA=$(git rev-parse HEAD)

claude --agent code-review --prompt "
統合レビュー依頼:
- 統合タスク: task02-01, task02-02, task02-03
- BASE_SHA: $BASE_SHA
- HEAD_SHA: $HEAD_SHA
- 注意点: 並列実装の整合性確認
"
```

### 3. PR作成前の最終レビュー

```bash
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

claude --agent code-review --prompt "
PR前最終レビュー:
- ブランチ: feature/PROJ-123
- BASE_SHA: $BASE_SHA
- HEAD_SHA: $HEAD_SHA
- チケット: PROJ-123
- 全変更ファイル: $(git diff $BASE_SHA..$HEAD_SHA --name-only | wc -l)件
"
```

## レビュー対応フロー

```
code-reviewer → フィードバック受信
      ↓
Critical問題あり? → Yes → 即座に修正 → 再レビュー
      ↓ No
Important問題あり? → Yes → 修正 → 再レビュー
      ↓ No
Minor問題あり? → 記録して続行（後で対応）
      ↓
レビュー完了 → finishing-branch へ
```

## 関連スキル

- `requesting-code-review` - レビュー依頼手順
- `receiving-code-review` - レビューフィードバック対応
- `finishing-branch` - レビュー完了後の統合
