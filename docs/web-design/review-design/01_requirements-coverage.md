# 要件カバレッジレビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| レビューラウンド | 1 |
| レビュー日 | 2026-02-27 |

---

## 1. 機能要件カバレッジ

| No | 機能要件 | 設計対応 | カバー状況 | 備考 |
|----|----------|----------|------------|------|
| FR-1 | devcontainerのfeatureとしてcode-serverを追加し、コンテナ起動時にcode-serverを自動起動する | 02_interface-api-design.md §3: Dockerfileでcurl installによりインストール | ⚠️ 部分的 | MRD-001: 要件は「feature」だが設計はDockerfileインストール。手段の合意が必要 |
| FR-2 | copilot CLI、git、playwright、prettierをdevcontainerに含める | 02_interface-api-design.md §2.2: features一覧で全て対応 | ✅ 完全 | copilot-cli, github-cli(git), playwright, prettier が feature として定義済み |
| FR-3 | dev-processと同様のDooD/DinD起動切り替え機構を実装する | 04_process-flow-design.md §6: 状態遷移図で設計済み | ✅ 完全 | dev-container.sh で DOCKER_MODE 環境変数による切替 |
| FR-4 | Reactプロジェクトを初期化し、画面コンポーネントを作成できる環境を整える | 03_data-structure-design.md §1.1: ファイル構造設計済み | ✅ 完全 | Vite + React + TypeScript で初期化 |
| FR-5 | code-server上でReactアプリをプレビュー（ホットリロード対応）する方法を確立する | 04_process-flow-design.md §5: React開発ワークフロー設計済み | ✅ 完全 | Vite HMR + usePolling 設定 |
| FR-6 | 画面のみを作成し、バックエンドはモックで代替する構成にする | 03_data-structure-design.md §3: MSWハンドラー設計済み | ✅ 完全 | MSW 2.x によるブラウザ内APIモック |
| FR-7 | code-serverにReact開発に必要なVS Code拡張機能をプリインストールする | 02_interface-api-design.md §3: Dockerfileで5つの拡張機能インストール | ✅ 完全 | ESLint, Prettier, Tailwind CSS, YAML, React Snippets |
| FR-8 | code-serverにGitHub Copilot拡張機能をプリインストールする | 02_interface-api-design.md §3: `\|\| true`で失敗許容 | ❌ 未達 | MRD-002: Open VSXにCopilot非公開。100%失敗する設計。代替手段の明確化が必要 |

## 2. 非機能要件カバレッジ

| No | 非機能要件 | 設計対応 | カバー状況 | 備考 |
|----|------------|----------|------------|------|
| NFR-1 | code-serverがブラウザからアクセス可能であること | 02_interface-api-design.md §5: bind-addr 0.0.0.0:8080 | ✅ 完全 | |
| NFR-2 | Reactアプリのホットリロードがcode-server環境で動作すること | 03_data-structure-design.md §2.2: vite.config.ts usePolling設定 | ✅ 完全 | |
| NFR-3 | Playwrightによる画面スクリーンショット・テストが実行可能であること | 05_test-plan.md: Playwright E2Eテスト設計済み | ✅ 完全 | |

## 3. 過剰設計チェック

| 項目 | 判定 | 備考 |
|------|------|------|
| claude-code feature | 🔵 Info | MRD-010: スコープ外だが追加されている。影響は軽微 |
| Prettier feature + npm | 🔵 Info | MRD-011: featureとnpm devDependencies両方に存在。重複だが実害なし |

---

## 4. 指摘事項

| ID | 重大度 | 指摘内容 |
|----|--------|----------|
| MRD-001 | 🟠 Major | setup.yamlの要件「devcontainerのfeatureとしてcode-serverを追加」に対し、設計はDockerfileでの手動インストール前提。要件を「feature相当の組み込み方式」へ合意変更するか、実現手段を明記 |
| MRD-002 | 🟠 Major | Copilot拡張のDockerfileインストールが `\|\| true` で失敗許容。Open VSXにCopilotは非公開で100%失敗する。VSIX取得元・固定バージョン・検証手順・Copilot CLIフォールバックの設計方針を明確化する必要あり |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
