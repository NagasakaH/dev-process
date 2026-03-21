# 設計レビュー結果 — Round 1

| 項目 | 値 |
|---|---|
| チケット | viewer-container-local |
| 対象リポジトリ | copilot-session-viewer |
| ラウンド | 1 |
| 総合判定 | ⚠️ 条件付き承認（conditional） |
| レビュー日 | 2025-07-24 |
| レビュアー | GPT-5.3-Codex, Claude Opus 4.6 |

## 指摘サマリー

| 重大度 | 件数 |
|---|---|
| 🔴 Critical | 0 |
| 🟠 Major | 5 |
| 🟡 Minor | 7 |
| 🔵 Info | 4 |

## 判定理由

Critical 指摘はないが、Major 5 件・Minor 7 件が存在するため条件付き承認。
compose.yaml 起動整合性、パス不整合、テストマッピングエラー等の修正が必要。
全ての Major/Minor 指摘を design で修正後、round-02 で再レビューすること。

---

## Major 指摘

### MRD-001: 実装可能性 — compose.yaml 起動整合性

- **重大度**: 🟠 Major
- **対象ファイル**: `design/02_interface-api-design.md`, `design/04_process-flow-design.md`
- **説明**: compose.yaml の viewer サービスが `depends_on: base-build: condition: service_completed_successfully` を指定しているが、base-build は `profiles: [build]` に属しており、`docker compose up -d` 実行時にプロファイル未指定だと base-build は起動されず依存解決に失敗する。処理フロー設計では `docker compose up -d` 単一コマンドで起動するフローを記載しており矛盾する。また事前手順（devcontainer build + next build）が必要だが acceptance criteria の「Starting the container...available」に対して手順定義が不足。
- **改善提案**: base-build から profiles を削除するか、depends_on を削除して README/Makefile で `devcontainer build → docker compose up` の2段階手順を明示。必要な Docker Compose 最小バージョンを明記。

### MRD-002: 実装可能性 — 未定義ファイル参照

- **重大度**: 🟠 Major
- **対象ファイル**: `design/02_interface-api-design.md`
- **説明**: compose.yaml の base-build サービスが `dockerfile: devcontainer-build.Dockerfile` を参照しているが、このファイルは新規ファイル一覧にも他の設計ドキュメントにも定義されていない。ビルドが実行不能。
- **改善提案**: devcontainer-build.Dockerfile の内容を設計に追加するか、base-build サービスを削除して `devcontainer build` CLI のみの方式に統一。

### MRD-003: 実装可能性 — パス不整合

- **重大度**: 🟠 Major
- **対象ファイル**: `design/02_interface-api-design.md`, `design/04_process-flow-design.md`
- **説明**: Dockerfile では `COPY .next/standalone ./app/` でアプリを `./app/` に配置するが、WORKDIR 未定義のためコンテナ内の絶対パスが不確定。`start-viewer.sh` では `node .next/standalone/server.js` を実行、`playwright.config.ts` の `webServer.command` も同パス。Dockerfile のコピー先と実行パスが一致しない。
- **改善提案**: Dockerfile に `WORKDIR /app` を追加、`COPY .next/standalone/ ./` に変更。`start-viewer.sh` は `cd /app && node server.js`、`playwright.config.ts` は `node /app/server.js` に統一。

### MRD-004: テスト可能性 — acceptance_criteria マッピングエラー

- **重大度**: 🟠 Major
- **対象ファイル**: `design/05_test-plan.md`
- **説明**: テスト計画の acceptance_criteria 対応表で「.env から PAT を含む認証設定を供給できる」を UT-5, UT-6 にマッピングしているが、UT-5 は `listSessions()` の空ディレクトリテスト、UT-6 は workspace.yaml パーステストで認証とは無関係。正しくは UT-9〜UT-11（middleware.ts テスト）にマッピングすべき。GITHUB_TOKEN の供給確認テストも Unit レベルに存在しない。
- **改善提案**: マッピングを UT-9, UT-10, UT-11, E2E-4 に修正。GITHUB_TOKEN がコンテナ内で利用可能であることを確認する E2E テストケースの追加を検討。

### MRD-005: データ構造 — $HOME パス不一致

- **重大度**: 🟠 Major
- **対象ファイル**: `design/03_data-structure-design.md`
- **説明**: `$HOME` 想定が設計内で不整合。調査結果では `/home/vscode`、設計では `/home/node`。ボリュームマウント先、スクリプト、テスト期待値が統一されていない。ベースイメージ `javascript-node:22` のデフォルトユーザーは node のため `/home/node` が正しいが、明示的な整理が必要。
- **改善提案**: 実ユーザー/HOME を `/home/node` に単一定義し、compose の mount 先・スクリプト・テスト期待値を同一値に統一。設計ドキュメントに investigation との差異について注記。

---

## Minor 指摘

### MRD-006: 要件整合性 — PAT 認証

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md`
- **説明**: PAT 注入要件に対し GITHUB_TOKEN の記載のみで、Copilot CLI 側の利用経路・必要変数・検証手順が不明確。
- **改善提案**: Copilot CLI が参照する環境変数名・反映箇所・失敗時挙動を設計に明記し、テスト項目へ追加。

### MRD-007: テスト可能性 — tmux 耐久性

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/05_test-plan.md`
- **説明**: tmux 安定性検証が30秒待機のみで「通常利用で安定」の受入基準を十分担保できない。
- **改善提案**: 長時間・操作連続・再接続を含む耐久シナリオ（例: 5-15分）を追加。

### MRD-008: 技術的妥当性 — healthcheck

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md`
- **説明**: compose.yaml に Docker healthcheck が未定義。コンテナ正常性の自動検出不可。
- **改善提案**: viewer サービスに `healthcheck: test: curl -f http://localhost:3000/api/sessions` を追加。

### MRD-009: テスト可能性 — module-level const

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md`, `design/05_test-plan.md`
- **説明**: `DISABLE_DOCKER_DETECTION` を const でモジュールスコープに定義する設計のため、テスト時に `process.env` を変更しても反映されない。UT-1, UT-2 が意図通り動作しないリスク。
- **改善提案**: `vi.resetModules()` + 動的 `import()` パターンを明示するか、関数引数で環境変数を注入可能にする設計に変更。

### MRD-010: 技術的妥当性 — Dockerfile 品質

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md`
- **説明**: Dockerfile に WORKDIR, USER, `EXPOSE 3000`, `ENV NEXT_TELEMETRY_DISABLED=1` が欠落。USER 未指定でコンテナが root 実行するリスク。
- **改善提案**: `WORKDIR /app`, `EXPOSE 3000`, `ENV NEXT_TELEMETRY_DISABLED=1`、ビルド完了後 `USER node` を追加。

### MRD-011: 実装可能性 — .dockerignore

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/01_implementation-approach.md`
- **説明**: `.dockerignore` が新規ファイル一覧に含まれているが内容未定義。`.env`（機密情報）、`node_modules`、`.git` 等の除外ルールが未指定。
- **改善提案**: `.dockerignore` の具体的内容を設計に追加（`.env`, `node_modules`, `.git`, `e2e/`, `docs/`, `.devcontainer/`, `*.md`）。

### MRD-012: 要件カバレッジ — dev-process ツールセット

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/01_implementation-approach.md`
- **説明**: 機能要件「Include a dev-process devcontainer-equivalent development toolset」に対し、何を含め何を除外するかの比較表・判断基準が不明確。
- **改善提案**: dev-process ベースイメージのツール一覧と viewer ベースイメージのツール一覧の比較表を追加。

---

## Info（参考）

### MRD-013: better-sqlite3 未使用

- **重大度**: 🔵 Info
- **説明**: `better-sqlite3` が未使用だが dependencies に残存。Dockerfile でのネイティブビルドに注意。

### MRD-014: テストカバレッジ目標

- **重大度**: 🔵 Info
- **説明**: テストカバレッジ目標が控えめ（terminal.ts 60%+）。初回導入として妥当。

### MRD-015: Next.js standalone ビルド

- **重大度**: 🔵 Info
- **説明**: Next.js standalone ビルドがホスト側事前実行前提。CI/CD では問題なし。

### MRD-016: Dockerfile apt-get 重複

- **重大度**: 🔵 Info
- **説明**: Dockerfile で `apt-get update` が2回実行される。レイヤーキャッシュ効率の観点。

---

## 次のステップ

1. **design スキル** で Major 5件 + Minor 7件の指摘事項を修正
2. **review-design** で round-02 再レビューを実施
3. 全指摘が resolved になり次第 **plan** スキルへ進行
