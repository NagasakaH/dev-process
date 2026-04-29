# 設計レビューサマリー round 2（FRONTEND-001 / floci-apigateway-csharp Angular追加）

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 2 |
| レビュー日 | 2026-04-29 |
| 対象設計 | [docs/floci-apigateway-csharp/design/](../design/) |
| 調査結果 | [docs/floci-apigateway-csharp/investigation/](../investigation/) |
| round 1 サマリー | [07_review-summary.md](./07_review-summary.md) |

> 本ドキュメントは round 1 指摘の解決状況確認と、round 2 で新たに統合された指摘事項を記録した round 2 サマリーである。round 1 のサマリー（07_review-summary.md）は破壊せず、本ファイルで追跡する。

---

## 総合判定

### ⚠️ 条件付き承認 (conditional)

### 判定理由

round 1 の Major 指摘は大半が実装可能な水準まで改善されたが、CORS/OPTIONS 経路に MOCK / fallback 言及が残る Major 1 件と、配信 / fail-fast / DinD / バージョン固定の Minor 不整合が残る。
ゼロトレランス方針により conditional とし、下記 6 件（RD2-001〜RD2-006）を修正後に round 3 を実施する。

Critical 指摘なし、Major 1 件、Minor 5 件。

---

## round 1 指摘の解決状況

| ID | 重大度 | 解決状況 | round 2 への引き継ぎ |
|----|--------|----------|----------------------|
| RD-001 | 🟠 Major | mostly resolved | RD2-002 として 05_test-plan の fallback 表記残りを再指摘 |
| RD-002 | 🟠 Major | mostly resolved | RD2-003 として playwright.config.ts の baseURL fallback 残りを再指摘 |
| RD-003 | 🟠 Major | resolved | — |
| RD-004 | 🟠 Major | mostly resolved | RD2-004 として 06_side-effect-verification の 2376/TLS 前提残りを再指摘 |
| RD-005 | 🟠 Major | resolved | — |
| RD-006 | 🟠 Major | unresolved | RD2-001 / RD2-005（Lambda OPTIONS 標準化に対し MOCK/fallback 言及残り） |
| RD-007 | 🟡 Minor | unresolved | RD2-006（Angular pin 方針が `~18.2.0` と `^18.0.0` で不一致） |
| RD-008 | 🟡 Minor | resolved | — |
| RD-009 | 🟡 Minor | resolved | — |
| RD-010 | 🟡 Minor | resolved | — |
| RD-011 | 🟡 Minor | resolved | — |
| RD-012 | 🟡 Minor | mostly resolved | RD2-004 と統合（DinD readiness ポート不整合） |

サマリー（解決状況）: resolved = 6、mostly resolved = 4、unresolved = 2

---

## round 2 統合指摘事項

| ID | 重大度 | カテゴリ | 概要 |
|----|--------|----------|------|
| RD2-001 | 🟠 Major | CORS/OPTIONS経路の一意性 | Lambda OPTIONS（AWS_PROXY, 204）を唯一標準経路とする設計に修正したはずだが、APIGW MOCK 統合や fallback 検討の記述が残り、設計が自己矛盾している。 |
| RD2-002 | 🟡 Minor | 配信アーキテクチャ整合性 | 05_test-plan の E2E 手順コメントに『fallback: ./frontend/dist の volume mount』が残り、nginx host volume mount を正規配信経路とする決定と矛盾する。 |
| RD2-003 | 🟡 Minor | fail-fast方針 | E2E は未設定時 fail-fast 方針だが、Playwright 設定例に `process.env.WEB_BASE_URL ?? 'http://localhost:8080'` の localhost フォールバックが残る。 |
| RD2-004 | 🟡 Minor | DinDネットワーク整合性 | DinD readiness で `DOCKER_HOST=tcp://docker:2376` / TLS 証明書前提が残り、他設計の `2375 / TLS 無効` と不整合。 |
| RD2-005 | 🟡 Minor | CORS OPTIONS 表現統一 | 05_test-plan の切り分けフローに『Lambda fallback 検討』表記が残り、Lambda OPTIONS は標準経路で fallback ではないという設計に反する。 |
| RD2-006 | 🟡 Minor | バージョン固定 | Angular バージョン方針が `~18.2.0` と `^18.0.0` で不一致。`~18.2.0` に統一すべき。 |

サマリー: 🔴 Critical = 0、🟠 Major = 1、🟡 Minor = 5、🔵 Info = 0

---

## 指摘事項詳細

### RD2-001 CORS/OPTIONS 経路の一意性 (Major)

- **指摘**: Lambda OPTIONS（AWS_PROXY 統合、ステータス 204）を唯一の標準経路とする設計修正を行ったはずだが、`01_implementation-approach.md` / `06_side-effect-verification.md` 等に APIGW MOCK 統合や fallback 検討の記述が残り、設計が自己矛盾している。
- **対象ファイル**:
  - `docs/floci-apigateway-csharp/design/01_implementation-approach.md`
  - `docs/floci-apigateway-csharp/design/06_side-effect-verification.md`
  - `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: MOCK 言及と Lambda fallback 表記を完全に削除、または却下案として明示し、OPTIONS は AWS_PROXY → Lambda(204) のみと明記統一する。

### RD2-002 配信アーキテクチャ整合性 (Minor)

- **指摘**: `05_test-plan.md` の E2E 手順コメントに『fallback: ./frontend/dist の volume mount』が残り、nginx host volume mount を正規配信経路とする決定と矛盾する。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: fallback 表記を削除し、S3 sync は配置検証のみ・ブラウザ配信は nginx host volume mount の正規経路と明記する。

### RD2-003 fail-fast 方針 (Minor)

- **指摘**: E2E は未設定時 fail-fast 方針だが、Playwright 設定例に `process.env.WEB_BASE_URL ?? 'http://localhost:8080'` の localhost フォールバックが残っている。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: `requireEnv('WEB_BASE_URL')` など必須参照に変更し、フォールバック値を削除する。

### RD2-004 DinD ネットワーク整合性 (Minor)

- **指摘**: DinD readiness 手順で `DOCKER_HOST=tcp://docker:2376` / TLS 証明書前提が残り、他設計の `2375 / TLS 無効` と不整合。RD-012 のテスト環境準備状況とも関連する。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/06_side-effect-verification.md`
- **推奨対応**: `2375` / `DOCKER_TLS_CERTDIR=""` / `--tls=false` に統一し、TLS 証明書前提を削除する。

### RD2-005 CORS OPTIONS 表現統一 (Minor)

- **指摘**: `05_test-plan.md` の切り分けフローに『Lambda fallback 検討』表記が残り、Lambda OPTIONS は標準経路で fallback ではないという設計に反する。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: fallback の語を削除し、AWS_PROXY 統合 Terraform 定義 / Lambda OPTIONS ハンドラ確認に統一する。

### RD2-006 バージョン固定 (Minor)

- **指摘**: Angular バージョン方針が `~18.2.0` と `^18.0.0` で不一致。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/01_implementation-approach.md`
- **推奨対応**: Angular は `~18.2.0` に統一し、全設計に反映する。

---

## 次のステップ

1. 設計担当が RD2-001〜RD2-006 を順次反映（特に Major 1 件 RD2-001 は必須）
2. 反映後 `review-design` round 3 を実施
3. 全指摘 resolved となれば plan スキルへ進行
4. design_review チェックポイントは指摘解決後に承認可

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-29 | 1.0 | round 2 統合レビュー結果記録 | review-design |
