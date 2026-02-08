# Worktree管理ガイド

Git worktreeを使用した並列タスク実行時のブランチ・作業ディレクトリ管理ガイド。

---

## 概要

Worktreeは、単一リポジトリから複数の作業ディレクトリを作成する機能です。
並列タスク実行時に、各タスクを独立した作業環境で実行し、完了後に統合します。

### 使用場面

| 場面 | Worktree使用 |
|------|-------------|
| 単一タスク実行 | 不要 |
| 並列タスク実行 | 必要 |
| 依存タスク実行 | 不要（順次実行） |

---

## ディレクトリ構造

```
/workspaces/dev-process/              # リポジトリルート
├── submodules/
│   └── target-repo/                  # 対象リポジトリ
│       └── (通常の作業)
│
/tmp/
├── PROJ-123-task02-01/               # 並列タスク1用worktree
├── PROJ-123-task02-02/               # 並列タスク2用worktree
└── PROJ-123-task02-03/               # 並列タスク3用worktree
```

---

## Worktree作成

### 単一worktree作成

```bash
TICKET_ID="PROJ-123"
TASK_ID="task02-01"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 1. 現在のブランチ確認
git branch --show-current  # feature/PROJ-123

# 2. ベースコミット取得
BASE_COMMIT=$(git rev-parse HEAD)

# 3. タスク用ブランチ作成
BRANCH_NAME="feature/${TICKET_ID}-${TASK_ID}"
git branch "$BRANCH_NAME" "$BASE_COMMIT"

# 4. worktree作成
WORKTREE_PATH="/tmp/${TICKET_ID}-${TASK_ID}"
git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"

echo "Worktree created: $WORKTREE_PATH"
```

### 並列タスク用一括作成

```bash
TICKET_ID="PROJ-123"
PARALLEL_TASKS=("task02-01" "task02-02" "task02-03")
REPO_ROOT=$(git rev-parse --show-toplevel)

# ベースコミット固定（重要: 全並列タスクで同じベースを使用）
BASE_COMMIT=$(git rev-parse HEAD)
echo "Base commit: $BASE_COMMIT"

# 各タスク用worktree作成
for TASK_ID in "${PARALLEL_TASKS[@]}"; do
    BRANCH_NAME="feature/${TICKET_ID}-${TASK_ID}"
    WORKTREE_PATH="/tmp/${TICKET_ID}-${TASK_ID}"
    
    # ブランチ作成
    git branch "$BRANCH_NAME" "$BASE_COMMIT"
    
    # worktree作成
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    
    echo "Created: $WORKTREE_PATH on $BRANCH_NAME"
done
```

---

## Worktree内での作業

### 作業ディレクトリ移動

```bash
TICKET_ID="PROJ-123"
TASK_ID="task02-01"

cd "/tmp/${TICKET_ID}-${TASK_ID}"
pwd  # /tmp/PROJ-123-task02-01
```

### 作業状態確認

```bash
# ブランチ確認
git branch --show-current  # feature/PROJ-123-task02-01

# ベースコミット確認
git log --oneline -1

# 変更状態確認
git status
```

### コミット実行

```bash
cd "/tmp/${TICKET_ID}-${TASK_ID}"

# 変更をステージング
git add -A

# 変更確認
git status
git diff --staged

# コミット
git commit -m "${TASK_ID}: タスク概要

- 変更点1
- 変更点2
- 変更点3"

# コミットハッシュ取得
COMMIT_HASH=$(git rev-parse HEAD)
echo "Commit: $COMMIT_HASH"
```

---

## Cherry-pick統合

### 単一タスクのcherry-pick

```bash
TICKET_ID="PROJ-123"
TASK_ID="task02-01"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 1. worktreeでコミットハッシュ取得
cd "/tmp/${TICKET_ID}-${TASK_ID}"
COMMIT_HASH=$(git rev-parse HEAD)
echo "Cherry-pick target: $COMMIT_HASH"

# 2. 親ブランチに移動
cd "$REPO_ROOT"
git checkout "feature/${TICKET_ID}"

# 3. cherry-pick実行
git cherry-pick "$COMMIT_HASH"

# 4. 結果確認
git log --oneline -3
```

### 並列タスクの順次cherry-pick

```bash
TICKET_ID="PROJ-123"
PARALLEL_TASKS=("task02-01" "task02-02" "task02-03")
REPO_ROOT=$(git rev-parse --show-toplevel)

# 親ブランチに移動
cd "$REPO_ROOT"
git checkout "feature/${TICKET_ID}"

# 順番にcherry-pick
for TASK_ID in "${PARALLEL_TASKS[@]}"; do
    WORKTREE_PATH="/tmp/${TICKET_ID}-${TASK_ID}"
    
    # コミットハッシュ取得
    cd "$WORKTREE_PATH"
    COMMIT_HASH=$(git rev-parse HEAD)
    
    # cherry-pick実行
    cd "$REPO_ROOT"
    git cherry-pick "$COMMIT_HASH"
    
    echo "Cherry-picked: ${TASK_ID} -> $COMMIT_HASH"
done

# 結果確認
git log --oneline -5
```

---

## コンフリクト解消

### コンフリクト発生時

```bash
# cherry-pick実行後にコンフリクトが発生
$ git cherry-pick $COMMIT_HASH
error: could not apply abc1234... task02-01: 機能A実装
hint: after resolving the conflicts, mark the corrected paths
hint: with 'git add <paths>' or 'git rm <paths>'
hint: and commit the result with 'git commit'

# コンフリクトファイル確認
$ git status
both modified:   src/shared-module.ts
```

### 解消手順

```bash
# 1. コンフリクト内容確認
git diff src/shared-module.ts

# 2. ファイルを編集してコンフリクト解消
# <<<<<<< HEAD
# ... 親ブランチの内容 ...
# =======
# ... cherry-pick対象の内容 ...
# >>>>>>> abc1234 (task02-01: 機能A実装)

# 3. 解消済みファイルをステージング
git add src/shared-module.ts

# 4. cherry-pick継続
git cherry-pick --continue

# 5. 結果確認
git log --oneline -1
```

### 中止する場合

```bash
# cherry-pickを中止して元の状態に戻す
git cherry-pick --abort
```

---

## Worktree破棄

### 単一worktree破棄

```bash
TICKET_ID="PROJ-123"
TASK_ID="task02-01"
REPO_ROOT=$(git rev-parse --show-toplevel)

cd "$REPO_ROOT"

# 1. worktree削除
WORKTREE_PATH="/tmp/${TICKET_ID}-${TASK_ID}"
git worktree remove "$WORKTREE_PATH" --force

# 2. ブランチ削除（オプション）
BRANCH_NAME="feature/${TICKET_ID}-${TASK_ID}"
git branch -D "$BRANCH_NAME"

echo "Removed: $WORKTREE_PATH and $BRANCH_NAME"
```

### 並列タスク用一括破棄

```bash
TICKET_ID="PROJ-123"
PARALLEL_TASKS=("task02-01" "task02-02" "task02-03")
REPO_ROOT=$(git rev-parse --show-toplevel)

cd "$REPO_ROOT"

for TASK_ID in "${PARALLEL_TASKS[@]}"; do
    WORKTREE_PATH="/tmp/${TICKET_ID}-${TASK_ID}"
    BRANCH_NAME="feature/${TICKET_ID}-${TASK_ID}"
    
    # worktree削除
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
    
    # ブランチ削除
    git branch -D "$BRANCH_NAME" 2>/dev/null || true
    
    echo "Removed: $WORKTREE_PATH"
done

# worktree一覧確認
git worktree list
```

---

## Worktree状態確認

### 一覧表示

```bash
git worktree list

# 出力例:
# /workspaces/dev-process  abc1234 [main]
# /tmp/PROJ-123-task02-01  def5678 [feature/PROJ-123-task02-01]
# /tmp/PROJ-123-task02-02  ghi9012 [feature/PROJ-123-task02-02]
```

### 個別状態確認

```bash
WORKTREE_PATH="/tmp/PROJ-123-task02-01"

cd "$WORKTREE_PATH"
git status
git log --oneline -3
```

---

## トラブルシューティング

### worktreeが残っている場合

```bash
# 残存worktreeの確認
git worktree list

# 強制削除
git worktree remove /tmp/PROJ-123-task02-01 --force

# プルーン（無効なworktree参照を削除）
git worktree prune
```

### ブランチが削除できない場合

```bash
# ブランチがworktreeで使用中
$ git branch -D feature/PROJ-123-task02-01
error: Cannot delete branch 'feature/PROJ-123-task02-01' checked out at '/tmp/PROJ-123-task02-01'

# 解決: 先にworktreeを削除
git worktree remove /tmp/PROJ-123-task02-01 --force
git branch -D feature/PROJ-123-task02-01
```

### ディレクトリが存在するがworktreeとして認識されない

```bash
# ディレクトリを手動削除
rm -rf /tmp/PROJ-123-task02-01

# worktreeプルーン
git worktree prune

# 再作成
git worktree add /tmp/PROJ-123-task02-01 feature/PROJ-123-task02-01
```

---

## ベストプラクティス

### 1. ベースコミットの固定

並列タスク開始時に同じベースコミットから分岐することで、cherry-pick時のコンフリクトを最小化。

```bash
BASE_COMMIT=$(git rev-parse HEAD)
# 全並列タスクでこのBASE_COMMITを使用
```

### 2. 作業前の状態確認

```bash
cd "$WORKTREE_PATH"
git status  # クリーンであることを確認
git branch --show-current  # 正しいブランチであることを確認
```

### 3. 完了後の確実な破棄

```bash
# 必ずリポジトリルートから実行
cd "$REPO_ROOT"
git worktree remove "$WORKTREE_PATH" --force
git branch -D "$BRANCH_NAME"
```

### 4. 依存順序でのcherry-pick

並列タスクに依存関係がある場合、依存される側を先にcherry-pick。

```bash
# task02-01 → task02-02 の依存がある場合
git cherry-pick $COMMIT_HASH_02_01  # 先に
git cherry-pick $COMMIT_HASH_02_02  # 後に
```

---

## 関連ドキュメント

- [SKILL.md](../SKILL.md) - dev-implementスキル定義
- [parallel-execution-guide.md](parallel-execution-guide.md) - 並列実行管理ガイド
