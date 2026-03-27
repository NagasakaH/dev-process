---
name: init-work-branch
description: 作業ブランチ初期化スキル。チケットID・タスク名・対象リポジトリ情報を入力として、featureブランチ作成、サブモジュール追加、設計ドキュメント生成を行う。「作業ブランチを初期化」「init-work-branch」「開発セットアップ」「featureブランチを作成」などのフレーズで発動。
---

# 作業ブランチ初期化スキル

チケットID・タスク名・対象リポジトリ情報を入力として、開発に必要な環境を自動構築します。

> **設計原則**: 
> - `git clone` + `git submodule init && git submodule update` だけで同等の開発環境が再現できること

## 入力情報

このスキルの実行には以下の情報が必要です。ユーザーから直接受け取るか、呼び出し元が提供してください。

### 必須入力
- **ticket_id** - チケットID（ブランチ名・ドキュメント名に使用）
- **task_name** - タスク名
- **target_repositories** - 修正対象リポジトリ（少なくとも1つ）
  - 各リポジトリに `name`, `url`, `base_branch`（デフォルト: main）を含む

### オプション入力
- **description** - タスクの説明（階層化構造を推奨）
  - overview, purpose, background, requirements（functional / non_functional）, acceptance_criteria, scope, out_of_scope, notes
- **related_repositories** - 参照用リポジトリ一覧（読み取り専用のサブモジュール）
- **base_branch** - 親リポジトリの元ブランチ（デフォルト: 現在のブランチ）
- **submodules_dir** - サブモジュール配置ディレクトリ（デフォルト: `submodules`）
- **design_document_dir** - 設計ドキュメント配置ディレクトリ（デフォルト: `docs`）

## 成果物

スキル実行後、以下が自動生成されます：
- `feature/{ticket_id}` ブランチ
- サブモジュール（submodules/配下）
- 設計ドキュメント（docs/{ticket_id}.md）- 入力された description から動的に埋め込み

---

## このスキルの目的

1. **ブランチ管理** - チケットIDに基づいたfeatureブランチを作成
2. **依存リポジトリ管理** - 関連・修正対象リポジトリをサブモジュールとして追加
3. **ドキュメント準備** - 入力された description を基に設計ドキュメントを生成

## 処理フロー

### 1. 入力のバリデーション

以下の必須入力を確認：
- `ticket_id` - チケットID（必須）
- `task_name` - タスク名（必須）
- `target_repositories` - 修正対象リポジトリ（少なくとも1つ必須）

### 2. 現在のブランチからfeatureブランチを作成

```bash
# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)

# チケットIDを使用してfeatureブランチを作成
FEATURE_BRANCH="feature/{ticket_id}"
git checkout -b "$FEATURE_BRANCH"

echo "ブランチ作成完了: $FEATURE_BRANCH (元ブランチ: $CURRENT_BRANCH)"
```

### 3. サブモジュールディレクトリの準備

```bash
# サブモジュールディレクトリを作成（デフォルト: submodules）
SUBMODULES_DIR="${submodules_dir:-submodules}"
mkdir -p "$SUBMODULES_DIR"
```

### 4. 関連リポジトリをサブモジュールとして追加

`related_repositories` に定義された各リポジトリに対して実行：

```bash
# サブモジュールとして追加
git submodule add "{repository.url}" "$SUBMODULES_DIR/{repository.name}"

# 特定ブランチが指定されている場合
if [ -n "{repository.branch}" ]; then
    cd "$SUBMODULES_DIR/{repository.name}"
    git checkout "{repository.branch}"
    cd -
fi
```

### 5. 修正対象リポジトリをサブモジュールとして追加

`target_repositories` に定義された各リポジトリに対して実行：

```bash
# リポジトリ名
REPO_NAME="{repository.name}"
BASE_BRANCH="{repository.base_branch:-main}"
FEATURE_BRANCH="feature/{ticket_id}"

# サブモジュールとして追加（存在しない場合）
if [ ! -d "$SUBMODULES_DIR/$REPO_NAME" ]; then
    git submodule add "{repository.url}" "$SUBMODULES_DIR/$REPO_NAME"
fi

# サブモジュール内でfeatureブランチを作成
cd "$SUBMODULES_DIR/$REPO_NAME"
git fetch origin
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"
git checkout -b "$FEATURE_BRANCH"
cd -

echo "サブモジュール追加完了: $SUBMODULES_DIR/$REPO_NAME (ブランチ: $FEATURE_BRANCH)"
```

### 6. 設計変更ドキュメントの作成

設計ドキュメントテンプレートを使用し、入力された description から各セクションを動的に埋め込み：

```bash
DOCS_DIR="${design_document_dir:-docs}"
mkdir -p "$DOCS_DIR"

TEMPLATE_PATH="/.claude/skills/init-work-branch/references/design-document-template.md"
OUTPUT_PATH="$DOCS_DIR/{ticket_id}.md"
```

**置換対象プレースホルダー:**

| プレースホルダー                  | 置換内容                                            |
| --------------------------------- | --------------------------------------------------- |
| `{{TICKET_ID}}`                   | 入力の ticket_id                                    |
| `{{TASK_NAME}}`                   | 入力の task_name                                    |
| `{{CREATED_DATE}}`                | 現在日付（YYYY-MM-DD形式）                           |
| `{{AUTHOR}}`                      | git の user.name                                    |
| `{{DESCRIPTION_OVERVIEW}}`        | description.overview                                |
| `{{DESCRIPTION_PURPOSE}}`         | description.purpose                                 |
| `{{DESCRIPTION_BACKGROUND}}`      | description.background                              |
| `{{REQUIREMENTS_FUNCTIONAL}}`     | description.requirements.functional（リスト形式）    |
| `{{REQUIREMENTS_NON_FUNCTIONAL}}` | description.requirements.non_functional（リスト形式）|
| `{{DESCRIPTION_SCOPE}}`           | description.scope（リスト形式）                      |
| `{{DESCRIPTION_OUT_OF_SCOPE}}`    | description.out_of_scope（リスト形式）               |
| `{{ACCEPTANCE_CRITERIA}}`         | description.acceptance_criteria（リスト形式）        |
| `{{DESCRIPTION_NOTES}}`           | description.notes                                   |

**リスト形式の変換例:**

```yaml
# 入力例
requirements:
  functional:
    - "ユーザーが○○を実行できること"
    - "結果が△△形式で出力されること"
```

↓ 変換後

```markdown
- ユーザーが○○を実行できること
- 結果が△△形式で出力されること
```

### 7. 初期コミット

```bash
# 変更をステージング
git add .

# コミット
git commit -m "feat: {ticket_id} 開発環境を初期化

- featureブランチを作成: feature/{ticket_id}
- サブモジュールを追加
- 設計ドキュメントを作成: docs/{ticket_id}.md"
```

### 8. 初期化完了レポート

処理完了後、以下の情報を表示：

```markdown
## 初期化完了 ✅

### ブランチ情報
- 作成ブランチ: feature/{ticket_id}
- 元ブランチ: {current_branch}

### 追加されたサブモジュール
- submodules/{repo_name1}
- submodules/{repo_name2} (feature/{ticket_id})

### 作成されたドキュメント
- docs/{ticket_id}.md

### 埋め込み済みセクション
入力された description から以下のセクションが埋め込まれました:
- 概要 (overview)
- 目的 (purpose)
- 背景 (background)
- 要件 (requirements)
- スコープ (scope)
- 受け入れ条件 (acceptance_criteria)

### 環境の再構築方法
```bash
git clone {repository_url}
cd {repository_name}
git submodule init && git submodule update
```

### 次のステップ
1. `docs/{ticket_id}.md` を開いて内容を確認
2. investigation スキルで調査を実施
3. design スキルで設計を実施
```

## エラーハンドリング

### 必須入力不足
```
エラー: 必須入力が不足しています
不足項目: {missing_fields}

ticket_id, task_name, target_repositories を指定してください。
```

### サブモジュール追加失敗
```
警告: サブモジュールの追加に失敗しました
リポジトリ: {repository_url}
原因: {error_message}

処理を続行しますか？ [y/N]
```

## 注意事項

- 既存のfeatureブランチがある場合は確認を求める
- サブモジュールが既に存在する場合はスキップして処理を続行
- git設定（user.name, user.email）が必要
- description が文字列で渡された場合は overview として処理
- **Worktree安全確認**: `/tmp/` 配下にworktreeを作成する場合、`.gitignore` に `/tmp/` パターンが含まれていることを確認し、worktreeディレクトリがリポジトリにコミットされないようにする

## 参照ファイル

- 設計ドキュメントテンプレート: `/.claude/skills/init-work-branch/references/design-document-template.md`

## 典型的なワークフロー

```
[入力受け取り] --> 必須入力（ticket_id, task_name, target_repositories）をバリデーション
        |
[ブランチ作成] --> feature/{ticket_id} ブランチを作成
        |
[サブモジュール追加] --> related_repositories をサブモジュールとして追加
        |
[修正対象追加] --> target_repositories をサブモジュールとして追加、featureブランチ作成
        |
[ドキュメント生成] --> description から動的埋め込みで {ticket_id}.md を作成
        |
[初期コミット] --> 変更をコミット
        |
[完了レポート] --> 初期化結果を表示
```
