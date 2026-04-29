# 設計レビューサマリー（FRONTEND-001 / floci-apigateway-csharp Angular追加）

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 1 |
| レビュー日 | 2026-04-29 |
| 対象設計 | [docs/floci-apigateway-csharp/design/](../design/) |
| 調査結果 | [docs/floci-apigateway-csharp/investigation/](../investigation/) |

> 本ドキュメントは `review-design` スキルの統合済みレビュー結果を、人間によるレビューおよび後続の修正対応のために記録した総合サマリーである。個別7カテゴリ分析は本サマリーに統合して掲載する。

---

## 総合判定

### ⚠️ 条件付き承認 (conditional)

### 判定理由

設計の方向性は要件に合致しているが、以下の領域に Major 指摘が残っており、このまま実装に進むと受入基準とCI安定性を保証できない。

- 配信経路（nginx/S3/host volume mount）の正規経路が一意に定まっていない
- E2E の fail-fast / skip 運用が設計書間で矛盾し、実AWS流出防止の検証ゲートにならない
- web-unit / web-integration / web-e2e の CI image・DinD ネットワーク前提が再現性を欠く
- unit と integration の分離（ファイル命名・karma config・npm script）が未定義
- API Gateway の OPTIONS 戦略（APIGW MOCK vs Lambda OPTIONS）が未確定で、互換性検証が後送りになっている

Critical 指摘はないため、設計の全面再実施は不要。設計ドキュメントの修正後に再レビュー（round 2）を行う。

---

## 統合指摘事項

| ID | 重大度 | カテゴリ | 概要 | 対応状況 |
|----|--------|----------|------|----------|
| RD-001 | 🟠 Major | 配信アーキテクチャ整合性 | nginx 配信元（S3 sync / host volume mount / S3 fallback）が設計書間で矛盾、nginx 撤去案も残存 | ⬜ 未対応 |
| RD-002 | 🟠 Major | E2Eゲート / 実AWS流出防止 | WEB_BASE_URL / AWS_ENDPOINT_URL / API_BASE_URL 未設定時の挙動が skip と fail-fast で矛盾 | ⬜ 未対応 |
| RD-003 | 🟠 Major | CI再現性 / ブラウザ依存 | web-unit / web-integration の CI image が node:20 と Playwright image で揺れ、Chromium 同梱が保証されない | ⬜ 未対応 |
| RD-004 | 🟠 Major | CI再現性 / DinDネットワーク | web-e2e の DinD 設定（DOCKER_HOST/TLS/FF_NETWORK_PER_BUILD）と nginx/floci 到達性が未具体化 | ⬜ 未対応 |
| RD-005 | 🟠 Major | テスト分離設計 | unit/integration を分けるための spec 命名・karma/angular.json ターゲット・npm scripts が未定義 | ⬜ 未対応 |
| RD-006 | 🟠 Major | floci互換性 / CORS OPTIONS | APIGW OPTIONS+MOCK 互換が未確認、Lambda OPTIONS fallback が後送り、成功ステータス 200/204 で矛盾 | ⬜ 未対応 |
| RD-007 | 🟡 Minor | バージョン固定 / 依存再現性 | Angular / Playwright / Node / CI image tag が可変、Angular 18 engines.node が package.json に未反映 | ⬜ 未対応 |
| RD-008 | 🟡 Minor | カバレッジ強制 | カバレッジ目標はあるが karma coverageReporter.check.global で CI fail させる設計がない | ⬜ 未対応 |
| RD-009 | 🟡 Minor | データ契約明確化 | 実 API の JSON キー命名（createdAt vs created_at 等）が未確定で Angular Todo 型と不整合の可能性 | ⬜ 未対応 |
| RD-010 | 🟡 Minor | README検証仕様 | verify-readme-sections.sh の検証対象見出し一覧が未定義 | ⬜ 未対応 |
| RD-011 | 🟡 Minor | API Gateway CORSヘッダ透過 | AWS_PROXY ヘッダ透過依拠か method_response の許可設定かが未明記 | ⬜ 未対応 |
| RD-012 | 🟡 Minor | テスト環境準備状況 | Node20 / Chromium / Playwright browsers / Docker DinD / floci image / AWS CLI / Terraform の事前確認手順が不足 | ⬜ 未対応 |

サマリー: 🔴 Critical = 0、🟠 Major = 6、🟡 Minor = 6、🔵 Info = 0

---

## 指摘事項詳細

### RD-001 配信アーキテクチャ整合性 (Major)

- **指摘**: nginx の配信元が S3 sync、host volume mount、S3 fallback/拡張で設計書間に矛盾し、受入基準『S3 + CloudFront 相当』の正規検証経路が一意に定まらない。ブレスト決定に反する nginx 撤去案も残っている。
- **対象ファイル**:
  - `docs/floci-apigateway-csharp/design/01_implementation-approach.md`
  - `docs/floci-apigateway-csharp/design/02_interface-api-design.md`
  - `docs/floci-apigateway-csharp/design/03_data-structure-design.md`
  - `docs/floci-apigateway-csharp/design/04_process-flow-design.md`
- **推奨対応**: 正規経路を1つに固定する。推奨は Angular build 成果物を floci S3 に sync し、その後ローカル検証用に同成果物を nginx 静的配信へ反映する。nginx は CloudFront 相当の静的配信のみ、API リバースプロキシなし。fallback は host volume mount のみに限定し、nginx 撤去案は却下案として削除/明記する。

### RD-002 E2Eゲート / 実AWS流出防止 (Major)

- **指摘**: `WEB_BASE_URL` / `AWS_ENDPOINT_URL` / `API_BASE_URL` 等の未設定時挙動が skip と fail-fast で矛盾。skip では品質ゲートと実AWS流出防止の検証にならない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/04_process-flow-design.md`, `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: 未設定時は shell / globalSetup とも `exit 1` / `throw` で fail-fast に統一し、skip 運用を廃止する。

### RD-003 CI再現性 / ブラウザ依存 (Major)

- **指摘**: web-unit / web-integration の CI image が `node:20` と Playwright image の併記で揺れており、ChromeHeadlessCI の Chromium 依存が保証されない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/02_interface-api-design.md`, `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: web-unit / web-integration は `mcr.microsoft.com/playwright` の Chromium 同梱イメージに統一し、web-lint の image と必要パッケージも明示する。

### RD-004 CI再現性 / DinDネットワーク (Major)

- **指摘**: web-e2e の GitLab DinD 設定、`DOCKER_HOST` / TLS / `FF_NETWORK_PER_BUILD`、ジョブコンテナから DinD 内 nginx / floci への到達性が具体化されていない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/02_interface-api-design.md`, `docs/floci-apigateway-csharp/design/04_process-flow-design.md`
- **推奨対応**: `docker:dind` service、`DOCKER_HOST=tcp://docker:2375`、`DOCKER_TLS_CERTDIR=""`、`FF_NETWORK_PER_BUILD`、ポート公開と `WEB_BASE_URL=http://docker:8080` の前提を明記する。

### RD-005 テスト分離設計 (Major)

- **指摘**: unit と integration を分けるための Angular spec 命名規則、`tsconfig` / `karma` / `angular.json` のターゲット分離、npm scripts が未定義。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/02_interface-api-design.md`, `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: `*.spec.ts` と `*.integration.spec.ts` の命名規則、`karma.conf` と `karma.integration.conf`、`npm run test:unit` / `test:integration` の具体内容を定義する。

### RD-006 floci互換性 / CORS OPTIONS (Major)

- **指摘**: APIGW OPTIONS+MOCK 互換が未確認で、失敗後に Lambda OPTIONS fallback へ切替という先送り設計になっている。OPTIONS 成功ステータスも 200/204 で矛盾。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/01_implementation-approach.md`, `docs/floci-apigateway-csharp/design/02_interface-api-design.md`, `docs/floci-apigateway-csharp/design/03_data-structure-design.md`, `docs/floci-apigateway-csharp/design/06_side-effect-verification.md`
- **推奨対応**: Lambda OPTIONS 受けをデフォルト案にする、または事前検証タスクを設計に明記する。成功ステータスは 204 か 200 に統一する。推奨は **Lambda OPTIONS fallback を標準化し 204 に統一**。

### RD-007 バージョン固定 / 依存再現性 (Minor)

- **指摘**: Angular / Playwright / Node / CI image tag が可変で CI 再現性が弱い。Angular 18 engines の Node 最小要件も `package.json` に反映されていない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/01_implementation-approach.md`, `docs/floci-apigateway-csharp/design/03_data-structure-design.md`
- **推奨対応**: Node 20.11 系、Angular 18.x、Playwright 1.45.x など具体バージョン方針と `package.json` の `engines.node` を明記する。

### RD-008 カバレッジ強制 (Minor)

- **指摘**: カバレッジ目標はあるが、`karma coverageReporter.check.global` 等で CI fail させる設計がない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: `coverageReporter.check.global` に閾値を設定し、web-unit / web-integration で未達時 `exit 1` とする。

### RD-009 データ契約明確化 (Minor)

- **指摘**: 実 API の JSON キー命名（`createdAt` vs `created_at` 等）が未確定で、Angular Todo 型と実レスポンスがずれる可能性がある。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/03_data-structure-design.md`
- **推奨対応**: Lambda `JsonOpts` / 実レスポンスに基づき JSON キー命名を設計で確定し、Angular DTO を合わせる。

### RD-010 README検証仕様 (Minor)

- **指摘**: README のローカル起動 / テスト / CI 実行方法を `verify-readme-sections.sh` で検証するとあるが、検証対象見出し一覧が未定義。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`
- **推奨対応**: 検証対象の README 見出し一覧を明記する。

### RD-011 API Gateway CORS ヘッダ透過 (Minor)

- **指摘**: POST/GET の `AWS_PROXY` レスポンスヘッダ透過に依拠するか、`method_response` で CORS ヘッダを許可するかが明記されていない。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/02_interface-api-design.md`
- **推奨対応**: `AWS_PROXY` ヘッダ透過に依拠する旨、または `method_response.response_parameters` を明記する。

### RD-012 テスト環境準備状況 (Minor)

- **指摘**: Node.js 20、Chromium、Playwright browsers、Docker / DinD、floci image、AWS CLI、Terraform などの事前確認手順が設計に不足。
- **対象ファイル**: `docs/floci-apigateway-csharp/design/05_test-plan.md`, `docs/floci-apigateway-csharp/design/06_side-effect-verification.md`
- **推奨対応**: 必要リソースと取得方法・代替案を *test environment readiness* として一覧化する。

---

## カテゴリ別所見（7カテゴリ統合）

### 1. 要件カバレッジ

機能要件の主要項目（Angular 追加 / Todo CRUD / S3 配信 / CORS）は設計書で言及されているが、受入基準『S3 + CloudFront 相当』の検証経路が RD-001 により一意化されていない。**部分カバー**。

### 2. 技術的妥当性

Angular 18、Karma + Playwright、APIGW + Lambda の組み合わせは妥当だが、CORS OPTIONS の方針が確定しておらず（RD-006）、技術選定としての完了度は不十分。

### 3. 実装可能性

設計の詳細度は概ね十分だが、unit / integration の分離（RD-005）、CI image / DinD 構成（RD-003 / RD-004）、JSON キー命名（RD-009）が未確定で、実装担当者が判断を迫られる箇所が残る。

### 4. テスト可能性

テスト計画は3層（unit / integration / e2e）構成で網羅性は高いが、fail-fast 方針の不統一（RD-002）、カバレッジ強制の欠如（RD-008）、README検証対象未定義（RD-010）により、自動検証ゲートとしての強度が弱い。

### 5. リスク・懸念事項

- 配信経路の不確定（RD-001）→ 受入基準未達リスク
- 実AWS流出（RD-002）→ コスト・セキュリティリスク
- CI 再現性欠如（RD-003 / RD-004 / RD-007）→ Flaky test / レビュー不能リスク

### 6. テスト環境準備状況

事前確認手順が未整備（RD-012）。Node20 / Chromium / Playwright / Docker DinD / floci image / AWS CLI / Terraform の入手・バージョン確認手順を明記する必要がある。現環境での不足リソース有無の確認はレビュー範囲外。

### 7. 指摘事項総括

上記の通り Major 6 / Minor 6。Critical なし。

---

## 次のステップ

1. 設計担当が RD-001〜RD-012 を順次反映（特に Major 6 件は必須）
2. 反映後 `review-design` round 2 を実施
3. 全指摘 resolved となれば planスキルへ進行
4. design_review チェックポイントは指摘解決後に承認可

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-29 | 1.0 | 初版作成（round 1 統合レビュー結果記録） | review-design |
