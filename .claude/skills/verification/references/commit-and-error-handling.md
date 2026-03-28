# コミットとエラーハンドリング

## コミット

```bash
git add docs/
git commit -m "docs: 検証結果を記録

- テスト: {test_status}
- ビルド: {build_status}
- リント: {lint_status}
- 型チェック: {typecheck_status}"
```

## エラーハンドリング

### 実装が完了していない

```
エラー: 実装が完了していません。
実装を完了してから検証を実行してください。
```

### テスト失敗時

```
検証失敗: テスト {failed_count}件 失敗
修正が必要です。実装に戻って修正してください。
```
