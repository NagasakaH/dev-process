# 親エージェント統合管理プロンプトテンプレート

親エージェント（opus-parent-agent）用の統合管理プロンプトテンプレート。

---

## 基本テンプレート

```markdown
# 統合管理プロンプト: {ticket_id} - {task_name}

## 概要

このプロンプトは、タスク計画に基づいて子エージェントを管理し、並列実行を調整するための統合管理ガイドです。

| 項目 | 値 |
|------|-----|
| チケットID | {ticket_id} |
| タスク名 | {task_name} |
| 総タスク数 | {total_task_count} |
| 並列グループ数 | {parallel_group_count} |
| 推定総時間 | {total_hours}時間 |

---

## 全タスク一覧

| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| task01 | {タスク名} | なし | 不可 | {X}h | ⬜ 未着手 |
| task02-01 | {タスク名} | task01 | 可 | {X}h | ⬜ 未着手 |
| task02-02 | {タスク名} | task01 | 可 | {X}h | ⬜ 未着手 |
| task03 | {タスク名} | task02-01, task02-02 | 不可 | {X}h | ⬜ 未着手 |

---

## 依存関係グラフ

```mermaid
graph TD
    subgraph "Phase 1: 基盤"
        task01[task01: {タスク名}]
    end

    subgraph "Phase 2: 機能実装（並列）"
        task02-01[task02-01: {タスク名}]
        task02-02[task02-02: {タスク名}]
    end

    subgraph "Phase 3: 統合"
        task03[task03: {タスク名}]
    end

    task01 --> task02-01
    task01 --> task02-02
    task02-01 --> task03
    task02-02 --> task03
```

---

## 並列実行グループ

### Group 1: 基盤準備（単独実行）

| タスク | 推定時間 | プロンプト |
|--------|----------|------------|
| task01 | {X}h | [task01.md](task01.md) |

**開始条件**: なし（初期グループ）
**完了条件**: task01が完了

---

### Group 2: 機能実装（並列実行）

| タスク | 推定時間 | プロンプト |
|--------|----------|------------|
| task02-01 | {X}h | [task02-01.md](task02-01.md) |
| task02-02 | {X}h | [task02-02.md](task02-02.md) |

**開始条件**: Group 1完了（task01完了）
**完了条件**: task02-01, task02-02 すべて完了

**並列実行の根拠**:
- 相互依存なし
- 異なるファイルを編集
- 共有状態変更なし

---

### Group 3: 統合（単独実行）

| タスク | 推定時間 | プロンプト |
|--------|----------|------------|
| task03 | {X}h | [task03.md](task03.md) |

**開始条件**: Group 2完了
**完了条件**: task03完了

---

## 実行順序

1. **Phase 1**: task01を実行
2. **Checkpoint 1**: task01の完了確認
3. **Phase 2**: task02-01, task02-02を並列実行
4. **Checkpoint 2**: 並列タスクの全完了確認
5. **Phase 3**: task03を実行
6. **Final**: 全タスク完了確認

---

## タスクプロンプト参照

各タスクの詳細プロンプト:

| タスク | プロンプトファイル |
|--------|-------------------|
| task01 | [task01.md](task01.md) |
| task02-01 | [task02-01.md](task02-01.md) |
| task02-02 | [task02-02.md](task02-02.md) |
| task03 | [task03.md](task03.md) |

---

## Worktree管理手順

### 実行開始時: メインworktreeの作成

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REQUEST_NAME="{リクエスト名}"

# リクエスト名ブランチを作成
cd $REPO_ROOT
git branch $REQUEST_NAME HEAD 2>/dev/null || echo "ブランチは既に存在"

# メインworktreeの作成
git worktree add /tmp/$REQUEST_NAME $REQUEST_NAME
echo "メインworktree作成: /tmp/$REQUEST_NAME"
```

### 各タスク実行前: サブworktreeの作成

```bash
REQUEST_NAME="{リクエスト名}"
TASK_ID="{task-id}"
REPO_ROOT=$(git rev-parse --show-toplevel)

# サブブランチ作成（メインworktreeのHEADから分岐）
cd /tmp/$REQUEST_NAME
git branch ${REQUEST_NAME}-${TASK_ID} HEAD

# サブworktreeの作成
cd $REPO_ROOT
git worktree add /tmp/${REQUEST_NAME}-${TASK_ID} ${REQUEST_NAME}-${TASK_ID}
```

### 並列タスク用: 一括作成

```bash
REQUEST_NAME="{リクエスト名}"
REPO_ROOT=$(git rev-parse --show-toplevel)

# ベースコミットを固定
cd /tmp/$REQUEST_NAME
BASE_COMMIT=$(git rev-parse HEAD)

# 並列タスクごとにworktree作成
cd $REPO_ROOT
for TASK_ID in task02-01 task02-02; do
    git branch ${REQUEST_NAME}-${TASK_ID} $BASE_COMMIT
    git worktree add /tmp/${REQUEST_NAME}-${TASK_ID} ${REQUEST_NAME}-${TASK_ID}
done
```

---

## Cherry-pickフロー

### 単一タスク完了後

```bash
REQUEST_NAME="{リクエスト名}"
TASK_ID="{task-id}"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 1. コミットハッシュ取得
cd /tmp/${REQUEST_NAME}-${TASK_ID}
COMMIT_HASH=$(git rev-parse HEAD)

# 2. メインworktreeでcherry-pick
cd /tmp/$REQUEST_NAME
git cherry-pick $COMMIT_HASH

# 3. サブworktreeの削除
cd $REPO_ROOT
git worktree remove /tmp/${REQUEST_NAME}-${TASK_ID} --force
git branch -D ${REQUEST_NAME}-${TASK_ID}
```

### 並列タスク完了後（一括）

```bash
REQUEST_NAME="{リクエスト名}"
REPO_ROOT=$(git rev-parse --show-toplevel)

# 順番にcherry-pick
cd /tmp/$REQUEST_NAME
for TASK_ID in task02-01 task02-02; do
    cd /tmp/${REQUEST_NAME}-${TASK_ID}
    COMMIT_HASH=$(git rev-parse HEAD)
    
    cd /tmp/$REQUEST_NAME
    git cherry-pick $COMMIT_HASH
done

# サブworktreeの一括削除
cd $REPO_ROOT
for TASK_ID in task02-01 task02-02; do
    git worktree remove /tmp/${REQUEST_NAME}-${TASK_ID} --force
    git branch -D ${REQUEST_NAME}-${TASK_ID}
done
```

---

## ブロッカー管理

### ブロッカー発生時の対応

| 状況 | 対応 |
|------|------|
| タスク失敗 | 原因を分析、サブworktree削除、再依頼または代替案 |
| 依存タスク未完了 | 待機、完了後に再開 |
| cherry-pickコンフリクト | 手動解消またはabort |
| 品質チェック失敗 | 修正依頼、完了後に再チェック |

### ブロッカー記録

```markdown
## ブロッカー記録

### {発生日時}: {task-id}

- **状況**: {ブロッカーの内容}
- **影響**: {影響を受けるタスク}
- **対応**: {実施した対応}
- **解消**: {解消日時} または 未解消
```

---

## 結果統合方法

### 各タスク完了時の確認

1. result.mdの存在確認
2. 実装完了状況の確認
3. テスト結果の確認
4. 品質チェック結果の確認
5. コミットハッシュの記録

### 並列グループ完了後の統合確認

1. 全タスクのcherry-pick完了
2. コンフリクトがないことを確認
3. 統合後のビルド確認
4. 統合後のテスト実行

### 最終統合

1. 全タスク完了の確認
2. 最終ビルド確認
3. 最終テスト実行
4. design-documentの更新
5. 完了レポート作成

---

## 実行履歴

### タスク実行記録

| タスク | 開始時刻 | 完了時刻 | コミット | ステータス |
|--------|----------|----------|----------|------------|
| task01 | - | - | - | ⬜ 未着手 |
| task02-01 | - | - | - | ⬜ 未着手 |
| task02-02 | - | - | - | ⬜ 未着手 |
| task03 | - | - | - | ⬜ 未着手 |

### 進捗サマリー

- 完了: 0/{total_task_count}
- 進行中: 0
- 待機: {total_task_count}

---

## チェックポイント

| ID | タイミング | チェック内容 | 結果 |
|----|------------|--------------|------|
| CP1 | Phase 1完了後 | task01の完了確認、基盤動作確認 | ⬜ |
| CP2 | Phase 2完了後 | 並列タスク全完了、cherry-pick完了 | ⬜ |
| CP3 | Phase 3完了後 | 統合テスト通過、最終確認 | ⬜ |

---

## 完了条件

### 全体完了条件

- [ ] 全タスクが完了していること
- [ ] 全cherry-pickが完了していること
- [ ] 最終ビルドが通ること
- [ ] 最終テストが通ること
- [ ] design-documentが更新されていること
- [ ] 完了レポートが作成されていること

### design-document更新内容

タスク完了時に `docs/{ticket_id}.md` の「3.1 タスク分割」テーブルを更新:

```markdown
| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| task01 | {タスク名} | なし | 不可 | {X}h | ✅ 完了 |
| task02-01 | {タスク名} | task01 | 可 | {X}h | ✅ 完了 |
| ... | ... | ... | ... | ... | ... |
```

---

## 注意事項

- 各タスクプロンプト（task0X.md）の内容を正確に子エージェントに伝える
- 並列タスクは同じベースコミットから分岐させる
- cherry-pickの順序を守る
- コンフリクト発生時は慎重に対応
- 全タスク完了後もメインworktreeは残す（ユーザー確認用）
```

---

## 使用方法

1. 上記テンプレートを `plan/parent-agent-prompt.md` にコピー
2. `{...}` 部分を実際の値に置き換え
3. タスク数に応じてセクションを追加・削除
4. 依存関係グラフを実際の構造に更新
5. 並列実行グループを実際の構成に更新
