---
name: requesting-code-review
description: タスク完了時、主要機能実装後、またはマージ前に作業が要件を満たすことを確認するために使用。code-reviewerエージェントを呼び出す。「レビュー依頼」「レビューして」などのフレーズで発動。
---

# コードレビュー依頼スキル

`code-reviewer`エージェントを呼び出して、問題が連鎖する前にキャッチします。早期にレビュー、頻繁にレビューが原則です。

## 主要機能

### レビュー依頼方法

1. **git SHA取得**:
   ```bash
   BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
   HEAD_SHA=$(git rev-parse HEAD)
   ```

2. **code-reviewerエージェント呼び出し**: 以下のコンテキストを提供
   - `WHAT_WAS_IMPLEMENTED`: 実装内容
   - `PLAN_OR_REQUIREMENTS`: 要件
   - `BASE_SHA`: 開始コミット
   - `HEAD_SHA`: 終了コミット

3. **フィードバック対応**:
   - Critical問題 → 即座に修正
   - Important問題 → 進む前に修正
   - Minor問題 → 後で対応

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

## 関連スキル

- 前提: `verification-before-completion` - 完了前検証
- 後続: `receiving-code-review` - レビュー受信
- 関連: `review-design` / `review-plan` - 設計/計画フェーズレビュー
