---
name: init-work-branch
description: 作業ブランチ初期化スキル。セットアップYAMLを入力として、featureブランチ作成、サブモジュール追加、設計ドキュメント生成を行う。「作業ブランチを初期化」「init-work-branch」「開発セットアップ」「featureブランチを作成」などのフレーズで発動。
---

# 作業ブランチ初期化スキル

セットアップYAMLファイルを入力として、開発に必要な環境を自動構築します。

> **設計原則**: `git clone` + `git submodule init && git submodule update` だけで同等の開発環境が再現できること。

## ユーザー向け手順

### 1. テンプレートの準備

プロジェクトルートに配置されている `setup-template.yaml` をコピーして編集します：

```bash
# テンプレートをコピー
cp setup-template.yaml setup.yaml

# 内容を編集
# - task_name: タスク名を設定
# - ticket_id: チケットIDを設定
# - description: 説明を記述
# - target_repositories: 修正対象リポジトリを設定
# - related_repositories: 参照用リポジトリを設定（任意）
```

### 2. スキルの実行

YAMLファイルの準備が完了したら、このスキル（init-work-branch）を実行してください：

```
init-work-branch を実行して setup.yaml で初期化
```

### 3. 成果物

スキル実行後、以下が自動生成されます：
- `feature/{ticket_id}` ブランチ
- サブモジュール（submodules/配下）
- 設計ドキュメント（docs/{ticket_id}.md）

---

## このスキルの目的

1. **ブランチ管理** - チケットIDに基づいたfeatureブランチを作成
2. **依存リポジトリ管理** - 関連・修正対象リポジトリをサブモジュールとして追加
3. **ドキュメント準備** - 設計変更ドキュメントのテンプレートを生成

## 入力ファイル

セットアップYAMLファイルのパスをユーザーから取得してください。

**テンプレート配置場所:**
- プロジェクトルート: `/setup-template.yaml`（ユーザー用コピー元）
- スキル内参照: `/.claude/skills/development/init-work-branch/references/setup-template.yaml`

## 処理フロー

### 1. YAMLファイルのバリデーション

```bash
# YAMLファイルの存在確認
test -f "{yaml_path}" || echo "ファイルが見つかりません: {yaml_path}"
```

以下の必須フィールドを確認：
- `ticket_id` - チケットID（必須）
- `task_name` - タスク名（必須）
- `target_repositories` - 修正対象リポジトリ（少なくとも1つ必須）

オプションフィールド：
- `description` - タスクの説明
- `related_repositories` - 関連リポジトリ一覧
- `options` - オプション設定

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
SUBMODULES_DIR="{options.submodules_dir:-submodules}"
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

設計ドキュメントテンプレートを使用してドキュメントを生成：

```bash
DOCS_DIR="{options.design_document_dir:-docs}"
mkdir -p "$DOCS_DIR"

# テンプレートをコピーしてプレースホルダーを置換
TEMPLATE_PATH="/.claude/skills/development/init-work-branch/references/design-document-template.md"
OUTPUT_PATH="$DOCS_DIR/{ticket_id}.md"

# プレースホルダーを置換
# {{TICKET_ID}} -> {ticket_id}
# {{TASK_NAME}} -> {task_name}
# {{DESCRIPTION}} -> {description}
# {{CREATED_DATE}} -> $(date +%Y-%m-%d)
# {{AUTHOR}} -> $(git config user.name)
```

**置換対象プレースホルダー:**

| プレースホルダー | 置換内容 |
|------------------|----------|
| `{{TICKET_ID}}` | YAMLのticket_id |
| `{{TASK_NAME}}` | YAMLのtask_name |
| `{{DESCRIPTION}}` | YAMLのdescription |
| `{{CREATED_DATE}}` | 現在日付（YYYY-MM-DD形式） |
| `{{AUTHOR}}` | gitのuser.name |

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

### 環境の再構築方法
```bash
git clone {repository_url}
cd {repository_name}
git submodule init && git submodule update
```

### 次のステップ
1. `docs/{ticket_id}.md` を開いて調査結果を記録
2. 調査スキルを使用して現状分析を実施
3. 設計スキルを使用して詳細設計を行う
```

## エラーハンドリング

### YAMLパースエラー
```
エラー: YAMLファイルのパースに失敗しました
ファイル: {yaml_path}
原因: {error_message}

setup-template.yaml を参考に修正してください。
```

### 必須フィールド不足
```
エラー: 必須フィールドが不足しています
不足フィールド: {missing_fields}

YAMLファイルを修正してください。
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
- YAMLファイルのパスは絶対パスまたは相対パスで指定可能
- git設定（user.name, user.email）が必要

## 参照ファイル

- テンプレートYAML: `/setup-template.yaml`（プロジェクトルート）
- 設計ドキュメントテンプレート: `/.claude/skills/development/init-work-branch/references/design-document-template.md`

## 典型的なワークフロー

```
[YAML読み込み] --> YAMLをパースしてバリデーション
        |
[ブランチ作成] --> feature/{ticket_id} ブランチを作成
        |
[サブモジュール追加] --> related_repositories をサブモジュールとして追加
        |
[修正対象追加] --> target_repositories をサブモジュールとして追加、featureブランチ作成
        |
[ドキュメント生成] --> {ticket_id}.md を作成
        |
[初期コミット] --> 変更をコミット
        |
[完了レポート] --> 初期化結果を表示
```
