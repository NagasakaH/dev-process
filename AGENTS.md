# エージェント運用ガイド

本リポジトリ固有の運用ルールを示す（詳細はREADME.mdを参照）。

## エージェント構成

| ラッパー (call-\*)               | 実行エージェント            | 役割                 |
| -------------------------------- | --------------------------- | -------------------- |
| call-general-purpose             | general-purpose             | 汎用タスク実行       |
| call-environment-setup           | environment-setup           | 開発環境構築         |
| call-pre-implementation-planning | pre-implementation-planning | 調査・設計・計画     |
| call-plan-migration              | plan-migration              | 計画のリポジトリ移行 |

## モデル指定ルール（重要）

```yaml
# 呼び出し階層とモデル指定
ユーザー
  ↓
call-* ラッパー         # Opus-4.6 指定可能
  ↓
実行エージェント        # Opus-4.6 指定可能
  ↓
サブエージェント        # Opus-4.6 必須
```

### サブエージェント起動時（必須）

```yaml
- agent_type: "general-purpose"
  model: "claude-opus-4.6" # ← 必ず Opus-4.6
  prompt: "タスク内容"
```

### call-\* / 実行エージェント（オプション）

```yaml
- agent_type: "call-general-purpose"
  model: "claude-opus-4.6" # ← Opus-4.6 可能
  prompt: "タスク内容"
```

## 7ステップワークフロー

1. **init-work-branch** - ブランチ・サブモジュール・設計ドキュメント初期化
2. **submodule-overview** - サブモジュール概要作成
3. **brainstorming** - 要件探索・project.yaml 生成（全プロセスのSSOT）
4. **investigation** - 詳細調査（UML図含む）
5. **design** - 詳細設計（API、データ構造、処理フロー）
6. **plan** - タスク分割・プロンプト生成
7. **implement** - 実装実行（並列化対応）

## 品質ルール

- **TDD**: 失敗するテストなしにコードを書かない
- **verification**: 検証証拠なしに完了を主張しない
- **並列化**: 独立タスク→並列、依存タスク→順次

## 削除・統合済み

- dev-planning-manager → pre-implementation-planning に統合
- manager → 削除
- code-reviewer → requesting-code-review スキルに統合

## 変更履歴

- 2026-02-12: Opus-4.6 モデル指定ルール明確化、README.md全面更新
