---
name: requesting-code-review
description: タスク完了時、主要機能実装後、またはマージ前に作業が要件を満たすことを確認するために使用。SHAベースの差分レビューを実施する。「レビュー依頼」「レビューして」などのフレーズで発動。
---

# コードレビュー依頼スキル

問題が連鎖する前にキャッチします。早期にレビュー、頻繁にレビューが原則です。

## 主要機能

### レビュー依頼方法

1. **git SHA取得**:
   ```bash
   BASE_SHA=$(git merge-base HEAD origin/main)
   HEAD_SHA=$(git rev-parse HEAD)

   # 差分確認
   git diff $BASE_SHA..$HEAD_SHA --stat
   ```

2. **レビュー実施**: 以下のコンテキストを基にレビュー
   - `WHAT_WAS_IMPLEMENTED`: 実装内容
   - `PLAN_OR_REQUIREMENTS`: 要件
   - `BASE_SHA`: 開始コミット
   - `HEAD_SHA`: 終了コミット

3. **フィードバック対応**:
   - Critical問題 → 即座に修正
   - Important問題 → 進む前に修正
   - Minor問題 → 後で対応

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

## レビュー観点

1. 要件との整合性
2. コード品質（可読性、保守性）
3. テストカバレッジ
4. セキュリティ考慮
5. パフォーマンス影響

## レビュー対応フロー

```
レビュー実施 → フィードバック
      ↓
Critical問題あり? → Yes → 即座に修正 → 再レビュー
      ↓ No
Important問題あり? → Yes → 修正 → 再レビュー
      ↓ No
Minor問題あり? → 記録して続行（後で対応）
      ↓
レビュー完了 → finishing-branch へ
```

## 使用タイミング

**必須:**
- サブエージェント駆動開発の各タスク後
- 主要機能完了後
- mainへのマージ前

**推奨:**
- 行き詰まったとき（新鮮な視点）
- リファクタリング前（ベースラインチェック）
- 複雑なバグ修正後

## レッドフラグ

**絶対にしない:**
- 「簡単だから」でレビューをスキップ
- Critical問題を無視
- 未修正のImportant問題で進む

## project.yaml への記録

レビュー依頼時、`project.yaml` の `code_review` セクションを開始してください：

```yaml
code_review:
  status: in_progress
  started_at: "2025-01-15T12:00:00+09:00"
  base_sha: "abc1234"
  head_sha: "def5678"
  rounds: []
```

### 記録タイミング

- **status**: `in_progress` で開始（`receiving-code-review`で更新）
- **started_at**: レビュー依頼時のタイムスタンプ
- **base_sha / head_sha**: 比較対象のコミット

## 関連スキル

- 前提: `verification-before-completion` - 完了前検証
- 後続: `receiving-code-review` - レビュー受信
- 関連: `review-design` / `review-plan` - 設計/計画フェーズレビュー
