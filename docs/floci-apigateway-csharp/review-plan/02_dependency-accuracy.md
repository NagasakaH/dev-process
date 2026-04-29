# 依存関係の正確性レビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| レビューラウンド | 1 |

## 評価サマリー

依存関係の論理は概ね妥当だが、**正本の不整合**および**暗黙依存の漏れ**が複数あり、実行順序の解釈ぶれや cherry-pick 単独失敗を引き起こす可能性がある。

## 検出された依存関係不整合

### RP-003 (Major): task-list ↔ parent-agent-prompt の不一致

- `task-list.md` と `parent-agent-prompt.md` で task02-01/02/03 の task01 依存有無など、複数箇所で実行順の解釈が割れる。
- **是正**:
  - `task-list.md` を依存関係の **正本** と定義する。
  - `parent-agent-prompt.md` および各 `taskXX.md` の前提条件を `task-list.md` と同期させる。
  - 矛盾検知チェックリストを plan 工程に追加する。

### RP-004 (Major): task08 (E2E) → task02-01 (CORS) 依存の漏れ

- E2E-3 の CORS 成立は task02-01（Lambda CORS/OPTIONS）に依存するが、task08 の前提条件に含まれていない。
- **是正**: task08 前提条件へ task02-01 を追加し、依存グラフ・並列グループを更新する。

### RP-009 (Major): task07 → task01 依存の漏れ

- task07 (scripts) は frontend build 成果物および dist パスに依存するが、task01 が前提に含まれていない。cherry-pick 順では task07 単独で失敗しうる。
- **是正**: task07 前提条件に task01 を追加し、依存グラフ・並列グループを更新する。

## 循環依存チェック

- 上記是正後も循環依存は発生しない見込み。

## 並列実行グループへの影響

- task07/task08 の前提追加により、現行 8 並列グループの構成見直しが必要。クリティカルパスの再計算を plan 側で実施すること。
