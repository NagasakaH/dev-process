# エージェント一覧と運用ガイド

本リポジトリの主要エージェントと運用ルールを示す。

## エージェント構成

| ラッパー (call-*) | 実行エージェント | 役割 |
|---|---|---|
| call-general-purpose | general-purpose | 汎用タスク実行 |
| call-environment-setup | environment-setup | 開発環境構築 |
| call-pre-implementation-planning | pre-implementation-planning | 調査・設計・計画 |
| call-plan-migration | plan-migration | 計画のリポジトリ移行 |

## 呼び出しルール

1. **ユーザーは call-* ラッパーを呼ぶ**（直接実行エージェントを呼ばない）
2. **実行エージェントは Opus-4.5 を指定**（call-* 内部でモデル指定）
3. サブエージェント起動時: `model: "claude-opus-4.5"` を必ず指定

```yaml
# 呼び出し例（call-* 内部での実行エージェント起動）
- agent_type: "general-purpose"
  model: "claude-opus-4.5"
  prompt: "タスク内容"
```

## implement スキルの並列化

- 独立タスク → 並列実行（高速化）
- 依存タスク → 順次実行（整合性確保）
- 各タスク完了時は TDD/verification スキルで検証

## 削除・統合済み

- dev-planning-manager → pre-implementation-planning に統合
- code-reviewer → 削除

## 変更履歴

- 2026-02-11: エージェント整理、3エージェント+ラッパー追加
- 2026-02-12: 並列化判断・Opus-4.5 指定ルール明確化
