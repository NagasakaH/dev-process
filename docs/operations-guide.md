# 運用ガイド

開発プロセスにおける運用上のルールとベストプラクティスです。

---

## TDD（テスト駆動開発）

- **失敗するテストなしに本番コードを書かない**
- 各タスクプロンプトにTDD方針（RED-GREEN-REFACTOR）を組み込み
- テストが先、実装は最小限

---

## verification（完了前検証）

- **新しい検証証拠なしに完了を主張しない**
- テスト通過、ビルド成功、リンタークリアを実際のコマンド出力で確認
- `brainstorming.test_strategy` で定義されたテスト（単体/結合/E2E）をすべて実行
- `acceptance_criteria` の各項目と検証結果を照合し、未検証項目がないことを確認
- 「〜はず」「おそらく」は禁止

---

## 並列化判断

- 3つ以上の独立タスクが同一フェーズに存在する場合に検討
- ファイル編集の衝突がないことを確認
- 各タスクが独立したテストファイルを持つこと

### 並列化判断フローチャート

```
[タスクリスト確認]
      ↓
[Q1] 独立タスクが3つ以上ある？
      ↓ Yes                    ↓ No → 順次実行
[Q2] ファイル編集の衝突がない？
      ↓ Yes                    ↓ No → 順次実行
[Q3] 各タスクが独立テストを持つ？
      ↓ Yes                    ↓ No → 順次実行
[Q4] リスクスコア ≤ 速度スコア？
      ↓ Yes                    ↓ No → 順次実行
      ↓
[並列実行を選択]
```

### 判断アルゴリズム

```
function shouldParallelize(tasks):
  # Step 1: 独立タスク数の確認
  independentTasks = tasks.filter(t => t.dependencies.isEmpty())
  if independentTasks.count < 3:
    return false

  # Step 2: ファイル衝突チェック
  allTargetFiles = independentTasks.flatMap(t => t.targetFiles)
  if allTargetFiles.hasDuplicates():
    return false

  # Step 3: テスト独立性チェック
  for task in independentTasks:
    if not task.hasIndependentTestFile():
      return false

  # Step 4: リスク vs 速度スコアリング
  riskScore = calculateRisk(independentTasks)
  speedScore = calculateSpeedGain(independentTasks)
  return speedScore >= riskScore
```

### リスクスコアリング基準

| 要素             | 低リスク (1) | 中リスク (2)           | 高リスク (3) |
| ---------------- | ------------ | ---------------------- | ------------ |
| モジュール結合度 | 完全独立     | 共有ユーティリティ使用 | 共有状態あり |
| 変更規模         | 〜50行       | 50-200行               | 200行超      |
| テスト範囲       | 単体のみ     | 単体+結合              | E2E必要      |

### 速度スコア計算

- 並列タスク数 × 平均タスク時間 / 最大タスク時間
