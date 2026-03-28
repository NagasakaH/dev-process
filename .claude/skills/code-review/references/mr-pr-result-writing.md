# MR/PR結果書き込み手順

code-reviewの結果をMR/PRに書き込む手順。

## 書き込みタイミング

```
レビュー完了 → 1. コメント投稿 → 2. description更新 → 3. [全指摘解消時] draft解除
```

## 1. レビュー結果コメント投稿

各ラウンドの `round-NN-summary.md` の内容をMR/PRコメントとして投稿。

### GitHub

```bash
PR_NUMBER=$(gh pr view --json number -q '.number')
gh pr comment "$PR_NUMBER" --body-file "docs/{target}/code-review/round-NN-summary.md"
```

### GitLab

```bash
# POST /projects/:id/merge_requests/:mr_iid/notes
# body: round-NN-summary.md の内容
```

## 2. Descriptionチェックリスト更新

MR/PR descriptionのチェックボックスをレビュー結果に基づいて更新。

### 更新対象（AI自動チェック項目）

レビュー結果に基づき、以下のチェックボックスをon/offに更新:
- テスト全パス（TC-04結果）
- ビルド成功（CI結果）
- リント通過（SA-03結果）
- CI/パイプライン成功（TC-06結果）
- カバレッジ低下なし（TC-07結果）
- シークレット混入なし（SE-01結果）
- マージコンフリクトなし（git status結果）

### 更新方法

#### GitHub

```bash
# 現在のdescriptionを取得
BODY=$(gh pr view "$PR_NUMBER" --json body -q '.body')
# チェックボックスを更新（sed等で置換）
# 更新後のdescriptionを設定
gh pr edit "$PR_NUMBER" --body "$UPDATED_BODY"
```

#### GitLab

```bash
# PUT /projects/:id/merge_requests/:mr_iid
# description: 更新後のdescription
```

### AI+人間チェック項目

AIが分析結果と根拠を記入（チェックボックスはonにしない → 人間が確認してon）:

```markdown
- [ ] Acceptance criteria充足
  > AI分析: AC-1 ✅ テストXXXで検証済み、AC-2 ✅ テストYYYで検証済み
- [ ] 破壊的変更なし
  > AI分析: 既存APIの変更なし、後方互換性維持
```

## 3. Draft解除

全指摘が解消（code-review-fixループ完了）された場合のみdraft解除。

### 条件

- レビュー結果が `approved`（Critical/Major/Minor指摘ゼロ）
- 全ACに対応するテストがpass
- 修正範囲がDR合意内

### GitHub

```bash
gh pr ready "$PR_NUMBER"
```

### GitLab

```bash
# タイトルから "Draft: " プレフィックスを除去
# PUT /projects/:id/merge_requests/:mr_iid
```

## 統合MR/PRの場合

統合MR/PR（dev-processリポ）がある場合:

1. 各submodule MR/PRのレビュー結果をそれぞれのMR/PRにコメント
2. 統合MR/PRには横断レビュー結果をコメント
3. 全submodule MR/PR approved → 統合MR/PR descriptionを更新
4. 全テスト（クロスリポ含む）pass → 各MR/PR draft解除
