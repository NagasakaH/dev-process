---
name: submodule-overview
description: submodule概要を作成するスキル。指定されたsubmoduleディレクトリを分析し、README.md/CLAUDE.md/AGENTS.mdから情報を収集して概要ドキュメントを生成する。「submodule概要を作成」「submodule-overview」「サブモジュールの概要」「submoduleをドキュメント化」などのフレーズで発動。
---

# Submodule概要作成スキル

submoduleディレクトリを分析し、構造化された概要ドキュメントを生成します。

## 入力

ユーザーからsubmoduleディレクトリのパスを取得（例: `submodules/my-library`）。

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

📖 詳細は `references/detailed-steps.md` を参照

概要: Step 1〜6（ディレクトリ確認 → 情報源読み込み → メタデータ確認 → 優先度A収集 → 優先度B収集 → ドキュメント生成）

## 成果物

- `submodules/<フォルダ名>.md` - submodule概要ドキュメント

## テンプレート

- `references/template.md`

## エラーハンドリング

📖 詳細は `references/error-handling.md` を参照

- ディレクトリ不在 → エラー通知、正しいパスを要求
- README.md不在 → 警告、ディレクトリ構造とメタデータから収集
- メタデータ不在 → 警告、ディレクトリ構造から推測

## 注意事項

- 優先度A項目は必ず何らかの情報を記載する（調査結果または「情報なし」）
- 優先度B項目は情報がない場合セクション自体を省略
- 既存の概要ドキュメントがある場合は上書き確認を行う
- 大規模なsubmoduleの場合、主要なファイルのみに絞って分析

## 参照ファイル

- テンプレート: `references/template.md`
- 詳細手順: `references/detailed-steps.md`
- エラーハンドリング: `references/error-handling.md`
