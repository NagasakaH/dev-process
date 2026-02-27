# ブレインストーミング結果: WEB-DESIGN-001

## 概要

ウェブデザイン要件定義プロジェクトの環境構築について、技術スタック・devcontainer構成・テスト戦略を対話的に検討し決定した。

## 決定事項

### 1. 技術スタック

| カテゴリ | 選定技術 |
|----------|----------|
| フレームワーク | React + Vite + TypeScript |
| CSSフレームワーク | Tailwind CSS |
| APIモック | MSW (Mock Service Worker) |
| テスト | Playwright (E2Eのみ) |
| フォーマッター | Prettier |

### 2. devcontainer構成

- **ベースイメージ**: `mcr.microsoft.com/devcontainers/javascript-node:lts`
- **プリビルドイメージ**: `nagasakah/web-design:base` (DockerHubにプッシュ)
- **起動方法**: code-server (tmux起動の代替)
- **DooD/DinD切り替え**: dev-processと同様の`DOCKER_MODE`環境変数による切り替え機構
- **開発ツール**: copilot CLI, git, Playwright, Prettier

### 3. VS Code拡張機能

| 拡張機能 | ID |
|----------|-----|
| GitHub Copilot | `GitHub.copilot` |
| GitHub Copilot Chat | `GitHub.copilot-chat` |
| ES7+ React/Redux/React-Native snippets | `dsznajder.es7-react-js-snippets` |
| ESLint | `dbaeumer.vscode-eslint` |
| Prettier - Code formatter | `esbenp.prettier-vscode` |
| Tailwind CSS IntelliSense | `bradlc.vscode-tailwindcss` |
| YAML | `redhat.vscode-yaml` |

### 4. テスト戦略

- **テスト範囲**: E2Eテストのみ
- **テストフレームワーク**: Playwright
- **実行方法**: devcontainerをビルド→起動→Playwrightで動作確認
- **テスト対象**:
  - code-serverがブラウザからアクセス可能か
  - Reactアプリがプレビューできるか
  - VS Code拡張機能がインストールされているか
  - DooD/DinD切り替えが動作するか

### 5. プレビュー方法

- code-server内のターミナルで `npm run dev` でVite開発サーバーを起動
- code-serverのポートフォワード機能でブラウザからプレビュー

## 将来の拡張

- dev-processと同様のCopilot向けスキル（`.claude/skills/`）設定をweb-designリポジトリにも組み込む予定
- 初回スコープでは環境構築に集中
