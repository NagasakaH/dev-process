# 技術的妥当性レビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| レビューラウンド | 1 |
| レビュー日 | 2026-02-27 |

---

## 1. アーキテクチャパターン評価

### 1.1 2段階ビルドパターン

| 項目 | 評価 |
|------|------|
| dev-process踏襲 | ✅ 適切。既存の運用ノウハウを活用できる |
| Base → Latest構成 | ✅ 適切。feature installとcode-server追加を分離 |
| ビルドスクリプト | ✅ 適切。build-and-push-devcontainer.sh で自動化 |

### 1.2 code-server方式

| 項目 | 評価 |
|------|------|
| Dockerfileインストール | ✅ 技術的に妥当。公式インストーラ使用 |
| 認証なし（--auth none） | ⚠️ MRD-005: セキュリティガード不足。ローカル限定を明文化すべき |
| 拡張機能プリインストール | ✅ 適切。code-server --install-extension で対応 |

### 1.3 DooD/DinD切り替え

| 項目 | 評価 |
|------|------|
| DOCKER_MODE環境変数 | ✅ dev-processパターン踏襲 |
| entrypoint切り替え | ✅ 適切 |
| テスト設計 | ⚠️ MRD-006: モード別テストの実行方法が未設計 |

---

## 2. 技術選定の妥当性

| 技術 | 妥当性 | 備考 |
|------|--------|------|
| Node.js LTS (devcontainer公式) | ✅ | 安定したベースイメージ |
| code-server | ✅ | ブラウザベースVS Code環境として最適 |
| Vite 6.x | ✅ | 高速HMR、React公式推奨 |
| React 19.x | ✅ | UIモック作成に適切 |
| TypeScript 5.x | ✅ | Vite標準対応 |
| Tailwind CSS 4.x | ✅ | ただしMRD-007参照 |
| MSW 2.x | ✅ | ブラウザ内APIモックに最適 |
| Playwright | ✅ | E2Eテストフレームワークとして適切 |

---

## 3. 既存パターンとの整合性

investigation結果との比較:

| 項目 | investigation結果 | 設計 | 整合性 |
|------|------------------|------|--------|
| 2段階ビルド | dev-processで確認 | 踏襲 | ✅ |
| DooD/DinD | dev-container.shで実装 | 移植 | ✅ |
| UID/GID調整 | start-tmux.shで実装 | start-code-server.shに移植 | ✅ |
| マウント構成 | build_mounts()で実装 | .aws除去、.claude追加 | ✅ |
| ファイル構造 | tailwind.config.js が調査時に言及 | 設計では未記載 | ⚠️ MRD-007 |

---

## 4. 指摘事項

| ID | 重大度 | 指摘内容 |
|----|--------|----------|
| MRD-005 | 🟡 Minor | code-server --auth none等のリスクガード不足。「ローカル限定」「公開ネットワーク禁止」を明文化 |
| MRD-006 | 🟡 Minor | DooD/DinDモード切替テストの実行方法が未設計 |
| MRD-007 | 🟡 Minor | investigation文書との tailwind.config.js 不整合。Tailwind CSS v4ではCSS-first設定で不要であることをdesign内に明記すべき |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
