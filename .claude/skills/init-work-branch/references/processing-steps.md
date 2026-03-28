# 処理フロー詳細手順

init-work-branch スキルの各ステップの詳細手順・コード例。

## 1. 入力のバリデーション

以下の必須入力を確認：
- `ticket_id` - チケットID（必須）
- `task_name` - タスク名（必須）
- `target_repositories` - 修正対象リポジトリ（少なくとも1つ必須）

## 2. 現在のブランチからfeatureブランチを作成

```bash
# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)

# チケットIDを使用してfeatureブランチを作成
FEATURE_BRANCH="feature/{ticket_id}"
git checkout -b "$FEATURE_BRANCH"

echo "ブランチ作成完了: $FEATURE_BRANCH (元ブランチ: $CURRENT_BRANCH)"
```

## 3. サブモジュールディレクトリの準備

```bash
# サブモジュールディレクトリを作成（デフォルト: submodules）
SUBMODULES_DIR="${submodules_dir:-submodules}"
mkdir -p "$SUBMODULES_DIR"
```

## 4. 関連リポジトリをサブモジュールとして追加

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

## 5. 修正対象リポジトリをサブモジュールとして追加

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

## 6. 設計変更ドキュメントの作成

設計ドキュメントテンプレートを使用し、入力された description から各セクションを動的に埋め込み：

```bash
DOCS_DIR="${design_document_dir:-docs}"
mkdir -p "$DOCS_DIR"

TEMPLATE_PATH="/.claude/skills/init-work-branch/references/design-document-template.md"
OUTPUT_PATH="$DOCS_DIR/{ticket_id}.md"
```

### 置換対象プレースホルダー

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

### リスト形式の変換例

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

## 7. 初期コミット

```bash
# 変更をステージング
git add .

# コミット
git commit -m "feat: {ticket_id} 開発環境を初期化

- featureブランチを作成: feature/{ticket_id}
- サブモジュールを追加
- 設計ドキュメントを作成: docs/{ticket_id}.md"
```

## 8. 初期化完了レポート

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
