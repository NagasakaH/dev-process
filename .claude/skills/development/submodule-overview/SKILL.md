---
name: submodule-overview
description: submodule概要を作成するスキル。指定されたsubmoduleディレクトリを分析し、README.md/CLAUDE.md/AGENTS.mdから情報を収集して概要ドキュメントを生成する。「submodule概要を作成」「submodule-overview」「サブモジュールの概要」「submoduleをドキュメント化」などのフレーズで発動。
---

# Submodule概要作成スキル

submoduleディレクトリを分析し、構造化された概要ドキュメントを生成します。

## 入力

ユーザーからsubmoduleディレクトリのパスを取得してください。

例:
- `submodules/my-library`
- `/workspaces/project/submodules/api-client`

## 処理フロー

```
submoduleディレクトリ指定
  ↓
README.md/CLAUDE.md/AGENTS.md の存在確認
  ↓
優先度A（1-6）：README.md, package.json等から情報取得
  - 情報あり → mdに記載
  - 情報不足 → ディレクトリ構造から調査補充
  ↓
優先度B（7-14）：README.md/CLAUDE.md/AGENTS.mdから情報取得
  - 情報あり → mdに記載
  - 情報なし → セクション自体をスキップ
  ↓
submodules/<フォルダ名>.md を生成
```

## 項目の優先度分類

### 優先度A（必須）- 記載がない場合は調査

1. **プロジェクト構成** - ディレクトリ構造、主要ファイル
2. **外部公開インターフェース/API** - 公開されている関数、クラス、エンドポイント
3. **テスト実行方法** - テストコマンド、テストフレームワーク
4. **ビルド実行方法** - ビルドコマンド、ビルドツール
5. **依存関係** - 外部ライブラリ、パッケージ
6. **技術スタック** - 言語、フレームワーク、ツール

### 優先度B（オプション）- 記載がなければスキップ

7. 利用方法/Getting Started
8. 環境変数/設定
9. 他submoduleとの連携
10. 既知の制約・制限事項
11. バージョニング・互換性
12. コントリビューションガイド
13. トラブルシューティング
14. ライセンス情報

## 詳細手順

### Step 1: ディレクトリ確認と情報源の特定

```bash
# ディレクトリの存在確認
test -d "{submodule_path}" || echo "ディレクトリが見つかりません"

# 情報源ファイルの確認
ls -la "{submodule_path}/README.md" 2>/dev/null
ls -la "{submodule_path}/CLAUDE.md" 2>/dev/null
ls -la "{submodule_path}/AGENTS.md" 2>/dev/null
```

### Step 2: 情報源ファイルの読み込み

存在する以下のファイルを読み込む：
- `README.md` - プロジェクト概要、使用方法
- `CLAUDE.md` - Claude向けコンテキスト
- `AGENTS.md` - エージェント向け指示

### Step 3: プロジェクトメタデータの確認

言語・フレームワークに応じて確認：

| ファイル | 取得情報 |
|---|---|
| `package.json` | name, version, scripts, dependencies, devDependencies |
| `pyproject.toml` | project.name, version, dependencies, build-system |
| `requirements.txt` | Python依存関係 |
| `go.mod` | module名, Go version, require |
| `Cargo.toml` | [package], [dependencies] |
| `*.csproj` | PropertyGroup, ItemGroup/PackageReference |
| `pom.xml` | groupId, artifactId, dependencies |
| `build.gradle` | dependencies |

### Step 4: 優先度A項目の情報収集

#### 4.1 プロジェクト構成
```bash
# ディレクトリ構造（2階層）
find "{submodule_path}" -maxdepth 2 -type d | head -30

# または tree
tree -L 2 -d "{submodule_path}" 2>/dev/null || find "{submodule_path}" -maxdepth 2 -type d
```

#### 4.2 外部公開インターフェース/API

**README.mdから取得できない場合の調査方法:**

| 言語 | 調査方法 |
|---|---|
| TypeScript/JavaScript | `src/index.ts`, `index.js` のexport文を確認 |
| Python | `__init__.py`, `__all__` を確認 |
| Go | 大文字で始まる関数・型をパッケージから抽出 |
| Rust | `lib.rs` の `pub` 宣言を確認 |

```bash
# TypeScript/JavaScriptの場合
grep -r "^export" "{submodule_path}/src" --include="*.ts" --include="*.js" | head -20

# Pythonの場合
grep -r "__all__" "{submodule_path}" --include="*.py" | head -10
```

#### 4.3 テスト実行方法

**README.mdから取得できない場合:**
- `package.json` の `scripts.test` を確認
- `pyproject.toml` の `[tool.pytest]` を確認
- `Makefile` の `test` ターゲットを確認

#### 4.4 ビルド実行方法

**README.mdから取得できない場合:**
- `package.json` の `scripts.build` を確認
- `Makefile` の `build` ターゲットを確認
- `setup.py`, `pyproject.toml` のbuild設定を確認

#### 4.5 依存関係

プロジェクトメタデータファイルから抽出（Step 3で取得済み）

#### 4.6 技術スタック

ファイル拡張子とメタデータから推測：

```bash
# 言語の特定
find "{submodule_path}" -type f -name "*.ts" | head -1 && echo "TypeScript"
find "{submodule_path}" -type f -name "*.py" | head -1 && echo "Python"
find "{submodule_path}" -type f -name "*.go" | head -1 && echo "Go"
find "{submodule_path}" -type f -name "*.rs" | head -1 && echo "Rust"
```

### Step 5: 優先度B項目の情報収集

README.md/CLAUDE.md/AGENTS.mdから以下のセクションを検索：

| 項目 | 検索キーワード |
|---|---|
| 利用方法 | "Usage", "Getting Started", "Quick Start", "使い方" |
| 環境変数 | "Environment", "Configuration", "Config", "ENV", ".env" |
| 他submoduleとの連携 | "Integration", "Dependencies", "Related", "連携" |
| 制約・制限 | "Limitations", "Constraints", "Known Issues", "制限" |
| バージョニング | "Versioning", "Compatibility", "Breaking Changes" |
| コントリビューション | "Contributing", "Contribution", "貢献" |
| トラブルシューティング | "Troubleshooting", "FAQ", "Common Issues" |
| ライセンス | "License", "ライセンス" |

**情報が見つからない場合はそのセクションをスキップ**

### Step 6: 概要ドキュメントの生成

テンプレート `references/template.md` を使用して、収集した情報から概要ドキュメントを生成：

```bash
# 出力先ディレクトリの確認・作成
mkdir -p submodules

# ドキュメント生成
# submodules/{folder_name}.md
```

**フォルダ名の抽出:**
```bash
basename "{submodule_path}"
```

## 成果物

- `submodules/<フォルダ名>.md` - submodule概要ドキュメント

## テンプレート

テンプレートは以下に配置：
- `/.claude/skills/development/submodule-overview/references/template.md`

## エラーハンドリング

### ディレクトリが存在しない
```
エラー: 指定されたディレクトリが見つかりません
パス: {submodule_path}

正しいパスを指定してください。
```

### README.mdが存在しない
```
警告: README.mdが見つかりません
ディレクトリ構造とプロジェクトメタデータから情報を収集します。
```

### プロジェクトメタデータが見つからない
```
警告: package.json/pyproject.toml等のメタデータファイルが見つかりません
ディレクトリ構造から可能な限り情報を推測します。
```

## 注意事項

- 優先度A項目は必ず何らかの情報を記載する（調査結果または「情報なし」）
- 優先度B項目は情報がない場合セクション自体を省略
- 既存の概要ドキュメントがある場合は上書き確認を行う
- 大規模なsubmoduleの場合、主要なファイルのみに絞って分析

## 参照ファイル

- テンプレート: `/.claude/skills/development/submodule-overview/references/template.md`
