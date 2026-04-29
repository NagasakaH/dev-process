# TDD方針の適切性レビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| レビューラウンド | 1 |

## 評価サマリー

TDD（RED-GREEN-REFACTOR）方針は全タスクで明示されているが、**RED の強度不足**および**閾値運用の暫定性**に問題がある。テストタスクへの実装責務混入も見られる（詳細は `01_task-decomposition.md` 参照）。

## 検出された TDD 問題

### RP-010 (Major): task02-02 の RED 強度不足

- 現行 RED は `terraform validate` ベースで、ほぼ always-pass。実質的な失敗テストになっていない。
- **是正**:
  - `terraform plan -json | jq` で S3 バケット定義 / OPTIONS メソッド / `AWS_PROXY` integration / response headers の未定義を assertion する RED スクリプトを追加。
  - もしくは OPTIONS の IntegrationTest を task02-02 の RED 完了条件に紐付ける。

### RP-006 (Major): coverage 閾値の暫定運用

- task05 で一時的に低い coverage 閾値（例: statements/branches/functions/lines）を許容しているが、本番閾値（80/70/90/80）へ戻すタスク・検証手順が明示されていない。
- **是正**:
  - 暫定閾値運用を禁止し、最初から最終閾値（80/70/90/80）を `karma.conf.js` に設定。
  - task12 に `grep` 等で閾値設定が最終値であることを検証する手順を追加。

### RP-007 (Major): E2E-5 (5xx 再現性) の方式不確実性

- task08 E2E-5 は floci Lambda を `docker compose stop` して 5xx を再現する設計だが、動的 Lambda コンテナ / on-demand 実行では確実な再現が保証されない。
- **是正**:
  - **推奨**: Playwright `page.route()` で API 応答を 500 に書き換え、UI のエラー表示を検証する方式に置換。
  - 実 API 障害再現は別タスク／将来案として分離する。

### RP-011 (Minor): wait-floci-healthy.sh の RED 不足

- task07 で `wait-floci-healthy.sh` の RED（未起動時 timeout exit 1 を期待する失敗テスト）が定義されていない。
- **是正**: task07 完了条件に RED ステップを明記する。

## テストカバレッジ網羅性

- 単体 / 結合 / E2E の三層は分離済みで方針は妥当。RP-006 是正後、最終閾値での運用に統一すること。
