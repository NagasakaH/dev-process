# タスク: task02 - 方式比較ドキュメント作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task02 |
| タスク名 | 方式A vs 方式B 比較ドキュメント作成 |
| 前提条件タスク | Phase 0（syncブランチ初期化） |
| 並列実行可否 | 可（task01と並列。Phase 0 完了後に開始） |
| 推定所要時間 | 10分 |
| 優先度 | 中 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/GIT-SVN-001-task02/
- **ブランチ**: GIT-SVN-001-task02
- **ターゲットリポジトリ**: submodules/git-svn-backup
- **作業ブランチ**: sync（orphan ブランチ）
- **重要**: sync ブランチ上で作業すること

---

## 前提条件

### 確認事項

- [ ] Phase 0 が完了し、sync ブランチが存在すること

---

## 作業内容

### 目的

acceptance_criteria「2つの同期方式のメリット・デメリット比較ドキュメントが存在する」を満たすための比較ドキュメントを作成する。

### 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) - 方式A/B の詳細設計・比較表・推奨案

### 実装ステップ

1. 設計書（01_implementation-approach.md）のセクション1〜3を参照
2. 方式A（マージ単位コミット方式）の概要・メリット・デメリットを記述
3. 方式B（日次バッチ方式）の概要・メリット・デメリットを記述
4. 比較表を作成
5. 推奨案と採用理由を記述

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `docs/comparison-method-a-vs-b.md` | 新規作成 | 方式A vs 方式B の比較ドキュメント |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**目的**: 実装前にファイルが存在しないことを確認し、テストが失敗する状態を記録する

```bash
# 【実装前に実行して失敗を確認すること】
# ファイルが存在しないことを確認
test -f docs/comparison-method-a-vs-b.md && echo "FAIL: already exists" || echo "PASS: not yet created"
```

**完了条件**: 上記コマンドの実行結果（失敗）をログに記録すること

### GREEN: 最小限の実装

ドキュメント作成後、以下の手動チェックで検証：

```bash
# ファイルが存在すること
test -f docs/comparison-method-a-vs-b.md

# 必須セクションが含まれること
grep -q "方式A" docs/comparison-method-a-vs-b.md
grep -q "方式B" docs/comparison-method-a-vs-b.md
grep -q "比較" docs/comparison-method-a-vs-b.md
grep -q "推奨" docs/comparison-method-a-vs-b.md
```

以下の構成でドキュメントを作成：

```markdown
# Git→SVN 同期方式の比較

## 方式A: マージ単位コミット方式
### 概要
### メリット
### デメリット
### コミット粒度の例

## 方式B: 日次バッチ方式
### 概要
### メリット
### デメリット
### コミット粒度の例

## 比較表

## 推奨案と採用理由
```

内容は設計書（01_implementation-approach.md）のセクション1〜3から抽出・再構成する。ユーザー向けのわかりやすい形式で記述。

### REFACTOR: コード改善

- 表現の統一・校正
- 図（Mermaid）の追加検討

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| 比較ドキュメント | `docs/comparison-method-a-vs-b.md` | 方式A vs 方式B の比較・推奨案 |

---

## 完了条件

### 機能的条件

- [ ] docs/comparison-method-a-vs-b.md が存在する
- [ ] 方式A（マージ単位コミット方式）の概要・メリット・デメリットが記述されている
- [ ] 方式B（日次バッチ方式）の概要・メリット・デメリットが記述されている
- [ ] 比較表が含まれている
- [ ] 方式Aが推奨である旨と推奨理由が記述されている

### 品質条件

- [ ] 設計書（01_implementation-approach.md）の内容と整合している
- [ ] Markdown として正しくレンダリングされる
- [ ] RED実行証跡（実装前のテスト失敗ログ）が記録されていること

---

## コミット

```bash
cd /tmp/GIT-SVN-001-task02/
git add docs/comparison-method-a-vs-b.md
git commit -m "task02: 方式比較ドキュメント作成

- 方式A（マージ単位コミット方式）vs 方式B（日次バッチ方式）の比較
- 比較表と推奨案を記述
- acceptance_criteria: 比較ドキュメントの存在"
```

---

## 注意事項

- 設計書の内容をコピペするのではなく、ユーザー向けに再構成する
- README.md からリンクされることを想定した構成にする
- sync ブランチ上の docs/ ディレクトリに配置する
