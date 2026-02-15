# SHAベースコードレビュー

## 概要

コード変更をSHAベースで指定し、`code-review` スキルに従ってレビューを実施します。

詳細は `.claude/skills/code-review/SKILL.md` を参照。

---

## SHAベースレビュー依頼テンプレート

```yaml
# 基本テンプレート
- agent_type: "code-review"
  prompt: |
    ## SHAベースレビュー依頼

    ### 対象コミット
    - ベースSHA: {BASE_SHA}
    - ヘッドSHA: {HEAD_SHA}
    - 変更ファイル: {file_list}

    ### 実装内容
    {implementation_summary}

    ### 要件ドキュメント
    {requirements_path}

    ### レビュー観点
    1. 要件との整合性
    2. コード品質
    3. テストカバレッジ
    4. セキュリティ
```

---

## 運用例

### 例1: 単一タスク完了後

```bash
# SHA取得
BASE_SHA=$(git rev-parse HEAD~1)
HEAD_SHA=$(git rev-parse HEAD)

# レビュー依頼
claude --agent code-review --prompt "
## レビュー依頼: task01

### コミット範囲
- BASE: $BASE_SHA
- HEAD: $HEAD_SHA

### 実装内容
- ユーザー認証機能の追加
- JWT トークン生成/検証
- ログイン/ログアウトAPI

### 要件
docs/target-repo/plan/task01.md の内容に準拠

### 確認ポイント
- セキュリティ（トークン有効期限、HTTPS強制）
- エラーハンドリング
- テストカバレッジ
"
```

### 例2: 並列タスク統合後

```bash
# 統合前のベースと統合後のHEADを取得
BASE_SHA=$(git rev-parse HEAD~3)  # 3つの並列タスク
HEAD_SHA=$(git rev-parse HEAD)

# 統合レビュー
claude --agent code-review --prompt "
## 統合レビュー依頼

### コミット範囲
- BASE: $BASE_SHA
- HEAD: $HEAD_SHA
- 統合タスク: task02-01, task02-02, task02-03

### 確認ポイント
- 並列実装間の整合性
- 共有リソースへの影響
- 統合テストの通過
"
```

### 例3: PR作成前最終レビュー

```bash
# mainとの差分全体をレビュー
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

# 変更ファイル一覧
FILES=$(git diff $BASE_SHA..$HEAD_SHA --name-only | tr '\n' ', ')

claude --agent code-review --prompt "
## PR前最終レビュー

### ブランチ情報
- ブランチ: feature/PROJ-123
- ベース: origin/main

### コミット範囲
- BASE: $BASE_SHA
- HEAD: $HEAD_SHA

### 変更ファイル
$FILES

### 全体チェック
- [ ] Critical問題なし
- [ ] Important問題なし
- [ ] テスト全通過
- [ ] ドキュメント更新済み
"
```

---

## レビュー結果の対応

> **ゼロトレランス方針**: Minorを含む全ての指摘は修正必須です。「後で対応」「次フェーズで調整」は許容しません。

```
[Critical問題検出]
      ↓
code-review-fix で修正 → 再コミット → code-review 再レビュー
      ↓
[Major問題検出]
      ↓
code-review-fix で修正 → 再コミット → code-review 再レビュー
      ↓
[Minor問題検出]
      ↓
code-review-fix で修正 → 再コミット → code-review 再レビュー
      ↓
[全指摘解決済み]
      ↓
finishing-branch へ進む
```
