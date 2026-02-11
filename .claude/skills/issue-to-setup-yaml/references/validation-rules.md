# バリデーションルール

生成されたsetup.yamlに対するバリデーションルール定義です。

## 1. 必須フィールドバリデーション

### 1.1 ticket_id

```yaml
field: ticket_id
required: true
rules:
  - type: not_empty
    message: "チケットIDは必須です"
  - type: pattern
    pattern: "^[a-zA-Z0-9_-]+$"
    message: "チケットIDには英数字、ハイフン、アンダースコアのみ使用可能です"
  - type: max_length
    value: 50
    message: "チケットIDは50文字以内である必要があります"
```

### 1.2 task_name

```yaml
field: task_name
required: true
rules:
  - type: not_empty
    message: "タスク名は必須です"
  - type: min_length
    value: 5
    message: "タスク名は5文字以上である必要があります"
  - type: max_length
    value: 200
    message: "タスク名は200文字以内である必要があります"
```

### 1.3 target_repositories

```yaml
field: target_repositories
required: true
rules:
  - type: array_not_empty
    message: "修正対象リポジトリは少なくとも1つ必要です"
  - type: array_items
    item_rules:
      - field: name
        required: true
        message: "リポジトリ名は必須です"
      - field: url
        required: true
        pattern: "^https://github\\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+(\\.git)?$"
        message: "有効なGitHub URLが必要です"
```

## 2. オプションフィールドバリデーション

### 2.1 description

```yaml
field: description
required: false
rules:
  - type: min_length
    value: 10
    severity: warning
    message: "説明が短すぎます（10文字以上推奨）"
  - type: max_length
    value: 10000
    severity: error
    message: "説明は10000文字以内である必要があります"
```

### 2.2 related_repositories

```yaml
field: related_repositories
required: false
rules:
  - type: array_items
    item_rules:
      - field: name
        required: true
        message: "リポジトリ名は必須です"
      - field: url
        required: true
        pattern: "^https://github\\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+(\\.git)?$"
        message: "有効なGitHub URLが必要です"
      - field: branch
        required: false
        pattern: "^[a-zA-Z0-9_/-]+$"
        message: "有効なブランチ名が必要です"
```

### 2.3 options

```yaml
field: options
required: false
rules:
  - field: create_design_document
    type: boolean
    default: true
  - field: design_document_dir
    type: string
    pattern: "^[a-zA-Z0-9_/-]+$"
    default: "docs"
  - field: submodules_dir
    type: string
    pattern: "^[a-zA-Z0-9_/-]+$"
    default: "submodules"
  - field: worktrees_dir
    type: string
    pattern: "^[a-zA-Z0-9_/-]+$"
    default: "workspaces"
```

## 3. クロスフィールドバリデーション

### 3.1 リポジトリ名の一意性

```yaml
rule: unique_repository_names
description: "target_repositoriesとrelated_repositoriesで同じリポジトリ名が重複していないこと"
severity: warning
message: "リポジトリ '{name}' が重複しています"
```

### 3.2 URL重複チェック

```yaml
rule: unique_repository_urls
description: "同じURLが複数回登場していないこと"
severity: error
message: "リポジトリURL '{url}' が重複しています"
```

### 3.3 親リポジトリの参照

```yaml
rule: parent_repo_reference
description: "修正対象に親リポジトリが含まれる場合の整合性チェック"
severity: info
message: "親リポジトリ '{name}' が修正対象に含まれています（サブモジュールとして追加されません）"
```

## 4. YAML形式バリデーション

### 4.1 構文チェック

```yaml
rule: yaml_syntax
description: "有効なYAML形式であること"
severity: error
checks:
  - valid_yaml_structure
  - proper_indentation
  - no_tab_characters  # タブ文字禁止
  - utf8_encoding
```

### 4.2 特殊文字エスケープ

```yaml
rule: special_characters
description: "特殊文字が適切にエスケープされていること"
severity: error
characters:
  - ":"   # コロン
  - "#"   # ハッシュ
  - "&"   # アンパサンド
  - "*"   # アスタリスク
  - "!"   # エクスクラメーション
  - "|"   # パイプ（ブロック記法以外）
  - ">"   # greater than（ブロック記法以外）
  - "'"   # シングルクォート
  - '"'   # ダブルクォート
```

## 5. 警告レベルの定義

### 5.1 エラー (Error)

処理を中断すべき重大な問題：

```yaml
errors:
  - "必須フィールドの欠落"
  - "無効なYAML構文"
  - "無効なURL形式"
  - "重複するリポジトリURL"
```

### 5.2 警告 (Warning)

処理は継続するが注意が必要：

```yaml
warnings:
  - "説明が短すぎる"
  - "関連リポジトリが空"
  - "リポジトリ名の重複"
  - "自動抽出の確信度が低い"
```

### 5.3 情報 (Info)

参考情報：

```yaml
info:
  - "親リポジトリを修正対象として使用"
  - "デフォルト値を適用"
  - "オプションフィールドをスキップ"
```

## 6. バリデーション結果の出力

### 6.1 成功時

```markdown
## バリデーション結果: ✅ 成功

生成されたsetup.yamlは有効です。

### 概要
- 必須フィールド: すべて存在
- オプションフィールド: 3/4 設定済み
- エラー: 0件
- 警告: 0件
```

### 6.2 警告あり

```markdown
## バリデーション結果: ⚠️ 警告あり

生成されたsetup.yamlは使用可能ですが、確認が必要です。

### 警告事項
1. **related_repositories が空です**
   - 関連リポジトリが自動検出されませんでした
   - 必要に応じて手動で追加してください

2. **説明が短すぎます**
   - 現在: 45文字
   - 推奨: 100文字以上
```

### 6.3 エラーあり

```markdown
## バリデーション結果: ❌ エラー

生成されたsetup.yamlに問題があります。

### エラー内容
1. **target_repositories が空です**
   - 修正対象リポジトリは必須です
   - 手動で追加してください

### 対処方法
上記のエラーを修正してから、init-work-branchスキルを実行してください。
```

## 7. 自動修正

一部の問題は自動修正可能：

### 7.1 自動修正可能な項目

```yaml
auto_fix:
  # URL正規化
  - issue: "URLに.gitサフィックスがない"
    action: "サフィックスを追加"
    
  # 末尾スラッシュ
  - issue: "URLに末尾スラッシュがある"
    action: "スラッシュを除去"
    
  # デフォルト値適用
  - issue: "オプションフィールドが未設定"
    action: "デフォルト値を設定"
    
  # 空白のトリム
  - issue: "フィールド値に前後空白がある"
    action: "空白を除去"
```

### 7.2 自動修正不可の項目

```yaml
manual_fix_required:
  - "必須フィールドの欠落"
  - "無効なYAML構文"
  - "修正対象リポジトリの特定失敗"
```

## 8. バリデーション実行例

### 入力YAML

```yaml
task_name: "機能追加"
ticket_id: "123"
description: "短い説明"
target_repositories: []
related_repositories:
  - name: "lib"
    url: "github.com/org/lib"  # 無効なURL
```

### バリデーション結果

```markdown
## バリデーション結果: ❌ エラー

### エラー (2件)
1. **target_repositories が空です** [必須]
   - 位置: target_repositories
   - 修正: 少なくとも1つの修正対象リポジトリを追加

2. **無効なURL形式** [required]
   - 位置: related_repositories[0].url
   - 値: "github.com/org/lib"
   - 修正: "https://github.com/org/lib" に変更

### 警告 (1件)
1. **説明が短すぎます**
   - 位置: description
   - 現在: 5文字
   - 推奨: 100文字以上
```
