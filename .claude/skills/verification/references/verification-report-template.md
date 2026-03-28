# 検証結果レポートテンプレート

## レポートフォーマット

検証結果を以下のフォーマットでレポートとして出力する。

```markdown
# 検証結果

## 検証情報
- プロジェクト: {project_name}
- 検証日時: {timestamp}
- テスト戦略スコープ: {test_scope}

## 単体テスト実行結果
- **ステータス**: ✅ PASS / ❌ FAIL
- **詳細**: {passed} passed, {failed} failed
- **カバレッジ**: {coverage}%

## E2Eテスト実行結果（テスト戦略に含まれる場合）
- **ステータス**: ✅ PASS / ❌ FAIL / ⚠️ NOT_EXECUTED
- **実行方法**: {e2e_method}
- **対象環境**: {e2e_environment}
- **詳細**: {detail}

## ビルド確認
- **ステータス**: ✅ PASS / ❌ FAIL
- **詳細**: {detail}

## リントチェック
- **ステータス**: ✅ PASS / ❌ FAIL
- **詳細**: {detail}

## 型チェック
- **ステータス**: ✅ PASS / ❌ FAIL
- **詳細**: {detail}

## 受け入れ基準 照合結果

| 基準 | 検証方法 | 結果 |
|------|----------|------|
| {criteria_1} | {unit_test/e2e_test/manual} | ✅ PASS / ❌ FAIL / ⚠️ NOT_VERIFIED |
| {criteria_2} | {unit_test/e2e_test/manual} | ✅ PASS / ❌ FAIL / ⚠️ NOT_VERIFIED |

## 総合結果
- **判定**: ✅ 全通過 / ❌ 失敗あり / ⚠️ 未検証項目あり
```

## 検証結果サマリー構造

以下の情報を構造化データとして出力する：

| フィールド | 説明 |
|---|---|
| `status` | `completed` または `failed` |
| `results.test` | テスト結果（status, detail, coverage） |
| `results.build` | ビルド結果（status, detail） |
| `results.lint` | リント結果（status, detail） |
| `results.typecheck` | 型チェック結果（status, detail） |
| `acceptance_criteria_check` | 各受け入れ基準の照合結果 |
| `summary` | 検証結果の要約テキスト |
