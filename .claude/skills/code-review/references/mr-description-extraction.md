# MR/PRディスクリプション取得・レビュー項目抽出

## 取得フロー

```
リモートURL取得 → プラットフォーム判定 → MR/PR検索 → ディスクリプション取得 → レビュー項目AI抽出
```

## 1. プラットフォーム判定

```bash
REMOTE_URL=$(git remote get-url origin)

# GitHub判定
if echo "$REMOTE_URL" | grep -qE 'github\.com'; then
  PLATFORM="github"
# GitLab判定
elif echo "$REMOTE_URL" | grep -qE 'gitlab'; then
  PLATFORM="gitlab"
else
  PLATFORM="unknown"
fi
```

## 2. MR/PR取得

### GitHub の場合

```bash
BRANCH=$(git branch --show-current)
# gh CLI で現在のブランチに紐づくPRを取得
gh pr view "$BRANCH" --json body,title,labels --jq '{title, body, labels}'
```

取得失敗時（PRが存在しない場合）→ スキップして標準レビューへ

### GitLab の場合

gitlab-api スキルを使用:
```
# 現在のブランチに紐づくMRを検索
GET /projects/:id/merge_requests?source_branch={branch_name}&state=opened
```

取得失敗時（MRが存在しない場合）→ スキップして標準レビューへ

## 3. レビュー項目AI抽出

取得したディスクリプションから、レビューで確認すべき項目を自動抽出:

### 抽出対象

| 抽出カテゴリ | 例 |
|-------------|-----|
| 機能要件 | 「○○機能を追加」→ 機能が正しく実装されているか |
| 非機能要件 | 「パフォーマンス改善」→ 性能指標が改善されているか |
| テスト要件 | 「E2Eテストを追加」→ テストが追加・通過しているか |
| 制約条件 | 「後方互換性を維持」→ 既存APIが破壊されていないか |
| レビュー観点 | 「セキュリティに注意」→ セキュリティチェックを重点実施 |
| チェックリスト | MRテンプレートのチェックボックス項目 |

### 抽出プロンプト

```
以下のMR/PRディスクリプションから、コードレビューで確認すべき項目を抽出してください。

## ディスクリプション
{mr_description}

## 出力形式
各項目について:
- MR-NNN: [項目名]
  - 確認内容: [具体的に何を確認するか]
  - 判定基準: [OKとNGの基準]
```

## 4. MR/PRが存在しない場合

- エラーにはしない
- レビューチェックリストの「9. MR要求項目」カテゴリをスキップ
- レポートに「MR/PR: 未検出（ローカルブランチのみ）」と記載
