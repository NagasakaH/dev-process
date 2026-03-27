# エラーハンドリング・完了レポート

## 1. エラーパターン

### 1.1 Issue Not Found

```
エラー: Issueが見つかりません
Issue: {owner}/{repo}#{issue_number}

確認事項:
- Issue番号が正しいか確認してください
- リポジトリ名が正しいか確認してください
- プライベートリポジトリの場合、アクセス権限を確認してください
```

### 1.2 アクセス権限エラー

```
エラー: リポジトリへのアクセス権限がありません
リポジトリ: {owner}/{repo}

確認事項:
- GitHubの認証情報を確認してください
- リポジトリへのアクセス権限を確認してください
```

### 1.3 必須情報抽出失敗

```
警告: 一部の情報を自動抽出できませんでした

抽出できなかった項目:
- {missing_field1}: {reason}
- {missing_field2}: {reason}

フォールバック処理を適用しました。
生成されたYAMLを手動で補完してください。
```

### 1.4 URL解析エラー

```
エラー: Issue URLの形式が正しくありません
入力: {input_url}

正しい形式:
- https://github.com/{owner}/{repo}/issues/{number}
```

## 2. 完了レポート

生成完了時に以下のレポートを出力：

```markdown
## setup.yaml 生成完了 ✅

### 入力情報
- Issue: {owner}/{repo}#{issue_number}
- URL: https://github.com/{owner}/{repo}/issues/{issue_number}

### 抽出された情報（SSOT階層化対応）

| description フィールド | 抽出状況 |
|------------------------|----------|
| overview | ✅ 抽出成功 |
| purpose | ✅ 抽出成功 |
| background | ⚠️ フォールバック使用 |
| requirements.functional | ✅ 抽出成功（3件） |
| requirements.non_functional | ⚠️ 未検出（手動入力推奨） |
| acceptance_criteria | ✅ 抽出成功（3件） |
| scope | ✅ 抽出成功 |
| out_of_scope | ⚠️ 未検出（手動入力推奨） |
| notes | ✅ 抽出成功 |

### 生成されたファイル
- `setup-{ticket_id}.yaml`

### 警告・注意事項
{warnings}

### 次のステップ
1. 生成された `setup-{ticket_id}.yaml` を確認・編集
2. 特に `⚠️` マークの項目を補完
3. `target_repositories` が正しいか確認
4. `init-work-branch` スキルで開発環境を初期化
```
