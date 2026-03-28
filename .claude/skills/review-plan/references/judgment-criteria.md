# レビュー判定基準・結果フォーマット

## 重大度レベル

| レベル     | 説明                           | 対応                                                   |
| ---------- | ------------------------------ | ------------------------------------------------------ |
| 🔴 Critical | 計画を根本的に見直す必要がある | 差し戻し：planの再実施が必要                           |
| 🟠 Major    | 重要な修正が必要               | 条件付き承認：修正後に再レビュー                       |
| 🟡 Minor    | 改善が必要                     | 条件付き承認：次のフェーズに進む前に修正が必要         |
| 🔵 Info     | 情報・提案                     | 承認：ただし改善提案として記録し、可能な限り対応を推奨 |

## 総合判定

| 判定           | 条件                              | 次のステップ                 |
| -------------- | --------------------------------- | ---------------------------- |
| ✅ 承認         | Critical/Major/Minorの指摘なし    | 実装フェーズへ進行           |
| ⚠️ 条件付き承認 | Minor以上の指摘あり、Criticalなし | 指摘事項を修正後、再レビュー |
| ❌ 差し戻し     | Criticalの指摘あり                | タスク計画の再作成           |

## レビュー結果フォーマット

レビュー結果は以下の情報を含む：

```yaml
review:
  round: 1                           # レビューラウンド番号
  status: approved                   # approved / conditional / rejected
  verdict: "承認"
  completed_at: "2025-01-15T10:30:00+09:00"
  summary: "全指摘解決済み。Critical/Major/Minor指摘なし。"
  issues:
    - id: PR-001
      severity: minor                # critical / major / minor / info
      category: "見積もり"
      description: "task03の工数見積もりが過少"
      status: open                   # open / resolved
      resolved_in_round: ~           # 解決ラウンド番号（解決時に記録）
  artifacts:
    - "docs/{target}/review-plan/06_review-summary.md"
```

## ラウンド管理ルール

- **初回レビュー**: `round: 1` で開始
- **再レビュー**: 前ラウンドの `round` をインクリメント
- **issues**: 全ラウンドの指摘を累積保持（`resolved_in_round` で解決ラウンドを追跡）
- **status 遷移**: `pending` → `rejected` / `conditional` / `approved`
