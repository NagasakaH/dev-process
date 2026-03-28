# 出力テンプレート・ステータス遷移

## 修正済み指摘の記録例

```
CR-001: status → fixed
  fixed_description: "APIレスポンスを { data, error } 形式に修正"

CR-002: status → fixed
  fixed_description: "console.log を削除"
```

## 反論の記録例

```
CR-003: status → disputed
  dispute_reason: "YAGNI違反のため対応不要"
```

## issues の status 遷移

| status     | 説明                                     |
| ---------- | ---------------------------------------- |
| `open`     | 未対応（レビューアが設定）               |
| `fixed`    | 修正済み（修正担当が設定）               |
| `disputed` | 技術的理由で反論（修正担当が設定）       |
| `resolved` | 再レビューで解決確認（レビューアが設定） |
| `wontfix`  | 再レビューで反論承認（レビューアが設定） |

## コミット

```bash
git add -A
git commit -m "fix: コードレビュー指摘を修正

- 修正: {fixed_count}件
- 反論: {disputed_count}件
- 対象: {file_list}"
```

## 完了レポート

```markdown
## コードレビュー修正完了

### 対応結果
- **修正**: {fixed_count}件
- **反論**: {disputed_count}件

### 修正内容
| ID     | 重大度 | 対応 | 説明                                  |
| ------ | ------ | ---- | ------------------------------------- |
| CR-001 | Major  | 修正 | APIレスポンス形式を設計に合わせて修正 |
| CR-002 | Minor  | 修正 | console.log を削除                    |
| CR-003 | Minor  | 反論 | YAGNI違反のため対応不要               |

### 検証結果
- テスト: ✅ 全通過
- リント: ✅ エラーなし
- 型チェック: ✅ エラーなし

### 次のステップ
再レビューを実施してください。
```
