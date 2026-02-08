# 実行プロセス テンプレート集

## 目次

1. [子エージェント依頼テンプレート](#子エージェント依頼テンプレート)
2. [worktree初期化コマンド](#worktree初期化コマンド)
3. [result.mdテンプレート](#resultmdテンプレート)
4. [実行履歴エントリテンプレート](#実行履歴エントリテンプレート)
5. [並列実行グループ記録](#並列実行グループ記録)
6. [cherry-pick・クリーンアップコマンド](#cherry-pickクリーンアップコマンド)

---

## 子エージェント依頼テンプレート

### 基本形式（worktree対応）

```markdown
## 作業環境
- **作業ディレクトリ（worktree）**: /tmp/{リクエスト名}-{task-id}/
- **ブランチ**: {リクエスト名}-{task-id}
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

## 作業情報
- リクエスト名: {request-name}
- 実行タスク: {task-id}（例: task01, task02-01）
- **成果物出力先**: {EXECUTION_DIR}/{task-id}/（絶対パス）
- 前提成果物: {前提条件タスクの成果物パス}

## 期待される成果物
以下のファイルを成果物出力先に作成してください:
- `result.md` - タスク実行結果レポート（必須）
- その他、タスクに関連する成果物

## 前提条件
- 前提条件タスク: {prerequisite-task-ids}
- 前提タスク成果物: {前提タスクの出力先パス一覧}

## 計画書
{計画成果物へのパス参照}

## 実行内容
以下を実施してください：
1. 前提条件タスクの結果を確認
2. {具体的なタスク内容}を実装
3. コード品質チェック（lint, test等）
4. 変更内容をドキュメント化

## コミット（必須）
作業完了後、以下の手順でコミットを実行してください:

```bash
cd /tmp/{リクエスト名}-{task-id}/
git add -A
git commit -m "タスク{task-id}: {変更内容の要約}"
```

- worktreeパス: `/tmp/{リクエスト名}-{task-id}/`
- 全変更を `git add -A` でステージング
- 日本語でコミットメッセージを生成
- `git commit` を実行

## 成果物の形式
結果レポートには以下を含めてください：
- 実装完了状況
- 変更ファイル一覧
- テスト結果
- 品質チェック結果
- コミットハッシュ
- 次のタスク依頼への依存関係
```

### 並列タスク依頼例

```markdown
## 作業環境
- **作業ディレクトリ（worktree）**: /tmp/API機能追加-task04-01/
- **ブランチ**: API機能追加-task04-01
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

## 作業情報
- リクエスト名: API機能追加
- 実行タスク: task04-01
- **成果物出力先**: /docs/20260208-0149-API機能追加/04_実行/task04-01/
- 前提成果物: /docs/20260208-0149-API機能追加/03_計画/task-plan.md

## 期待される成果物
- `result.md` - タスク実行結果レポート
- 変更されたソースファイル

## 前提条件
- 前提条件タスク: task03
- 前提タスク成果物: /docs/20260208-0149-API機能追加/03_計画/

## 実行内容
1. task-plan.mdのtask04-01の内容を確認
2. APIエンドポイント `/users` を実装
3. 単体テストを作成・実行
4. result.mdに結果を記録

## コミット（必須）
作業完了後、以下の手順でコミットを実行してください:

```bash
cd /tmp/API機能追加-task04-01/
git add -A
git commit -m "task04-01: ユーザーAPIエンドポイント実装"
```
```

---

## worktree初期化コマンド

### メインworktreeの作成（実行開始時に一度だけ）

```bash
# 変数設定
REPO_ROOT=$(git rev-parse --show-toplevel)
REQUEST_NAME="リクエスト名"  # 実際のリクエスト名に置換

# リクエスト名ブランチを作成（既存の場合はスキップ）
cd $REPO_ROOT
git branch $REQUEST_NAME HEAD 2>/dev/null || echo "ブランチ ${REQUEST_NAME} は既に存在します"

# メインworktreeの作成
git worktree add /tmp/$REQUEST_NAME $REQUEST_NAME
echo "メインworktree作成完了: /tmp/$REQUEST_NAME"
```

### サブworktreeの作成（各タスク実行前）

```bash
# 変数設定
REQUEST_NAME="リクエスト名"
TASK_ID="task01"  # 実際のタスクIDに置換
REPO_ROOT=$(git rev-parse --show-toplevel)

# サブブランチ作成（メインworktreeのHEADから分岐）
cd /tmp/$REQUEST_NAME
git branch ${REQUEST_NAME}-${TASK_ID} HEAD

# サブworktreeの作成（リポジトリルートから実行）
cd $REPO_ROOT
git worktree add /tmp/${REQUEST_NAME}-${TASK_ID} ${REQUEST_NAME}-${TASK_ID}
echo "サブworktree作成完了: /tmp/${REQUEST_NAME}-${TASK_ID}"
```

### 並列タスク用サブworktreeの一括作成

```bash
REQUEST_NAME="リクエスト名"
REPO_ROOT=$(git rev-parse --show-toplevel)

# ベースコミットを固定（全並列タスクは同じベースから分岐）
cd /tmp/$REQUEST_NAME
BASE_COMMIT=$(git rev-parse HEAD)

# 並列タスクごとにworktree作成
cd $REPO_ROOT
for TASK_ID in task02-01 task02-02 task02-03; do
    git branch ${REQUEST_NAME}-${TASK_ID} $BASE_COMMIT
    git worktree add /tmp/${REQUEST_NAME}-${TASK_ID} ${REQUEST_NAME}-${TASK_ID}
    echo "並列worktree作成: /tmp/${REQUEST_NAME}-${TASK_ID}"
done
```

---

## result.mdテンプレート

各タスク完了時に作成する結果レポートの形式。

```markdown
# タスク実行結果: {task-id}

## 概要

- **タスク識別子**: {task-id}
- **実行日時**: {timestamp}
- **ステータス**: 完了 / 一部完了 / 失敗
- **worktree**: /tmp/{リクエスト名}-{task-id}/
- **ブランチ**: {リクエスト名}-{task-id}
- **コミットハッシュ**: {commit-hash}

## 実装完了状況

### 完了した作業

- {完了項目1}
- {完了項目2}

### 未完了の作業（該当する場合）

- {未完了項目}: {理由}

## 変更ファイル一覧

| ファイル | 変更種別 | 説明 |
|----------|----------|------|
| `src/api/users.ts` | 新規作成 | ユーザーAPIエンドポイント |
| `src/models/user.ts` | 修正 | 型定義の追加 |
| `tests/api/users.test.ts` | 新規作成 | 単体テスト |

## テスト結果

```
実行コマンド: npm test
結果: PASS
テスト数: 15 passed, 0 failed
カバレッジ: 85%
```

## 品質チェック結果

| チェック項目 | 結果 | 備考 |
|--------------|------|------|
| Linter | ✓ Pass | ESLint |
| 型チェック | ✓ Pass | TypeScript |
| テスト | ✓ Pass | 15/15 |

## コミット情報

```bash
# 実行したコミットコマンド
cd /tmp/{リクエスト名}-{task-id}/
git add -A
git commit -m "{コミットメッセージ}"

# コミットハッシュ
{commit-hash}
```

## 次タスクへの依存情報

### 生成された成果物

後続タスクが参照可能:

- `src/api/users.ts` - ユーザーAPI実装
- `src/types/user.d.ts` - 型定義

### 注意事項

- {後続タスクへの申し送り事項}

## 備考

{その他特記事項}
```

---

## 実行履歴エントリテンプレート

`実行履歴.md` に追記するエントリ形式。

### タスク開始時

```markdown
### {task-id}: {タスク名}

- **ステータス**: 進行中
- **依頼時刻**: {YYYY-MM-DD HH:MM}
- **完了時刻**: -
- **worktree**: `/tmp/{リクエスト名}-{task-id}/`
- **ブランチ**: `{リクエスト名}-{task-id}`
- **前提条件**: {prerequisite-task-ids}
- **成果物出力先**: `{path}`
- **依頼内容**: {依頼プロンプト概要}
- **結果概要**: [進行中...]
```

### タスク完了時

```markdown
### {task-id}: {タスク名}

- **ステータス**: ✓ 完了
- **依頼時刻**: {YYYY-MM-DD HH:MM}
- **完了時刻**: {YYYY-MM-DD HH:MM}
- **worktree**: `/tmp/{リクエスト名}-{task-id}/`（削除済み）
- **ブランチ**: `{リクエスト名}-{task-id}`（削除済み）
- **コミット**: `{commit-hash}`（cherry-pick済み）
- **前提条件**: {prerequisite-task-ids}
- **成果物出力先**: `{path}`
- **依頼内容**: {依頼プロンプト概要}
- **生成された成果物**:
  - `result.md`
  - {その他ファイル}
- **結果概要**: {結果のサマリー}
```

### タスク失敗時

```markdown
### {task-id}: {タスク名}

- **ステータス**: ✗ 失敗
- **依頼時刻**: {YYYY-MM-DD HH:MM}
- **完了時刻**: {YYYY-MM-DD HH:MM}
- **worktree**: `/tmp/{リクエスト名}-{task-id}/`（削除済み）
- **ブランチ**: `{リクエスト名}-{task-id}`（削除済み）
- **前提条件**: {prerequisite-task-ids}
- **成果物出力先**: `{path}`
- **依頼内容**: {依頼プロンプト概要}
- **失敗理由**: {エラー内容}
- **対応**: {リトライ / 代替案 / 保留}
```

---

## 並列実行グループ記録

`実行履歴.md` の並列実行管理セクション。

```markdown
## 並列実行管理

### 並列グループ

- **Group-1**: task02-01, task02-02 (同時実行可能)
  - 共通前提条件: task01
  - ベースコミット: {base-commit-hash}
  - worktree一覧:
    - `/tmp/{リクエスト名}-task02-01/`
    - `/tmp/{リクエスト名}-task02-02/`
  - ステータス: 全完了
  - cherry-pick順序: task02-01 → task02-02
  
- **Group-2**: task04-01, task04-02, task04-03 (同時実行可能)
  - 共通前提条件: task03
  - ベースコミット: {base-commit-hash}
  - worktree一覧:
    - `/tmp/{リクエスト名}-task04-01/`
    - `/tmp/{リクエスト名}-task04-02/`
    - `/tmp/{リクエスト名}-task04-03/`
  - ステータス: 2/3完了
  - cherry-pick順序: task04-01 → task04-02 → task04-03

### クリティカルパス

```
task01 → task02-01/task02-02 → task03 → task04-01/task04-02/task04-03 → task05
```

### 実行状況サマリー

| グループ | タスク数 | 完了 | 進行中 | 待機 | cherry-pick |
|----------|----------|------|--------|------|-------------|
| Group-1 | 2 | 2 | 0 | 0 | 完了 |
| Group-2 | 3 | 2 | 1 | 0 | 待機中 |
```

---

## cherry-pick・クリーンアップコマンド

### 単一タスクのcherry-pick

```bash
REQUEST_NAME="リクエスト名"
TASK_ID="task01"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 1. コミットハッシュ取得
cd /tmp/${REQUEST_NAME}-${TASK_ID}
COMMIT_HASH=$(git rev-parse HEAD)
echo "コミットハッシュ: $COMMIT_HASH"

# 2. メインworktreeでcherry-pick
cd /tmp/$REQUEST_NAME
git cherry-pick $COMMIT_HASH

# 3. 成功確認
git log --oneline -1

# 4. サブworktreeの削除
cd $REPO_ROOT
git worktree remove /tmp/${REQUEST_NAME}-${TASK_ID} --force
git branch -D ${REQUEST_NAME}-${TASK_ID}
echo "タスク ${TASK_ID} 完了: cherry-pick済み、worktree削除済み"
```

### 並列タスクの一括cherry-pick

```bash
REQUEST_NAME="リクエスト名"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 順番にcherry-pick
for TASK_ID in task02-01 task02-02 task02-03; do
    cd /tmp/${REQUEST_NAME}-${TASK_ID}
    COMMIT_HASH=$(git rev-parse HEAD)
    
    cd /tmp/$REQUEST_NAME
    echo "cherry-pick: ${TASK_ID} (${COMMIT_HASH})"
    
    # cherry-pick実行（コンフリクト時は中断）
    if ! git cherry-pick $COMMIT_HASH; then
        echo "警告: ${TASK_ID} でコンフリクト発生"
        echo "手動で解消するか、git cherry-pick --abort で中止してください"
        exit 1
    fi
done

# 成功した場合のみworktree削除
cd $REPO_ROOT
for TASK_ID in task02-01 task02-02 task02-03; do
    git worktree remove /tmp/${REQUEST_NAME}-${TASK_ID} --force
    git branch -D ${REQUEST_NAME}-${TASK_ID}
done
echo "並列タスク完了: 全worktree削除済み"
```

### コンフリクト解消手順

```bash
# コンフリクト発生時
cd /tmp/$REQUEST_NAME
git status  # コンフリクトファイルを確認

# オプション1: 手動で解消
# 1. コンフリクトファイルを編集
# 2. git add <resolved-files>
# 3. git cherry-pick --continue

# オプション2: cherry-pickを中止
git cherry-pick --abort
echo "cherry-pickを中止しました。手動での対応が必要です。"
```

### 全タスク完了後のクリーンアップ

```bash
REQUEST_NAME="リクエスト名"
REPO_ROOT=$(git rev-parse --show-toplevel)

# メインworktreeの確認
cd /tmp/$REQUEST_NAME
git log --oneline -10

# リモートへのプッシュ（ユーザー確認後）
# git push origin $REQUEST_NAME

# メインworktreeの削除（オプション）
cd $REPO_ROOT
git worktree remove /tmp/$REQUEST_NAME
# git branch -d $REQUEST_NAME  # マージ後に削除する場合

# 不要なworktree参照をクリーンアップ
git worktree prune
```

### worktree一覧確認

```bash
# 現在のworktree一覧
git worktree list

# 詳細情報付き
git worktree list --porcelain
```

---

## ディレクトリ作成コマンド

計画書からタスク一覧を抽出後、一括でディレクトリを作成:

```bash
# 変数設定
EXECUTION_DIR="${REQUEST_DIR}/04_実行"

# タスク一覧に基づいて作成
mkdir -p "${EXECUTION_DIR}/task01"
mkdir -p "${EXECUTION_DIR}/task02-01"
mkdir -p "${EXECUTION_DIR}/task02-02"
mkdir -p "${EXECUTION_DIR}/task03"
mkdir -p "${EXECUTION_DIR}/task04-01"
mkdir -p "${EXECUTION_DIR}/task04-02"
# ... 計画書のタスク数に応じて追加
```
