# タスク: task01 - devcontainer構成ファイル作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task01 |
| タスク名 | devcontainer構成ファイル作成 |
| 前提条件タスク | なし |
| 並列実行可否 | 不可（後続タスクの前提） |
| 推定所要時間 | 15分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/WEB-DESIGN-001-task01/
- **ブランチ**: WEB-DESIGN-001-task01
- **対象リポジトリ**: submodules/web-design
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 確認事項

- [ ] submodules/web-design が空リポジトリであること

---

## 作業内容

### 目的

devcontainerの基盤構成ファイル（devcontainer.json, Dockerfile, start-code-server.sh）を作成する。これがプロジェクト全体の土台となる。

### 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) — 技術選定・ベースイメージ
- [design/02_interface-api-design.md](../design/02_interface-api-design.md) — devcontainer.json設計、Dockerfile設計、start-code-server.shインターフェース
- [design/03_data-structure-design.md](../design/03_data-structure-design.md) — ファイル構造
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) — 起動フロー

### 実装ステップ

1. `.devcontainer/` ディレクトリを作成
2. `.devcontainer/devcontainer.json` を作成（9 features, forwardPorts, customizations）
3. `.devcontainer/Dockerfile` を作成（code-serverインストール、拡張機能プリインストール、起動スクリプト配置）
4. `.devcontainer/scripts/start-code-server.sh` を作成（UID/GID調整、Docker socket修正、code-server起動）

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `.devcontainer/devcontainer.json` | 新規作成 | devcontainer features・settings定義（9 features） |
| `.devcontainer/Dockerfile` | 新規作成 | code-server + 拡張機能追加レイヤー（FROM nagasakah/web-design:base） |
| `.devcontainer/scripts/start-code-server.sh` | 新規作成 | コンテナ起動スクリプト（UID/GID調整 + code-server起動） |

---

## テスト方針

テスト戦略はE2Eのみのため、このタスクでは個別テストは作成しない。
E2Eテスト（task03）で以下を検証する:
- E2E-1: code-serverにブラウザからアクセスできること
- E2E-3: 拡張機能がインストールされていること
- E2E-4: 開発ツールが利用可能なこと
- E2E-7: Copilot CLIが利用可能なこと

### 実装時の確認

```bash
# devcontainer.jsonの構文チェック
cat .devcontainer/devcontainer.json | python3 -m json.tool > /dev/null

# Dockerfileの構文チェック（ビルドは後続タスクで実施）
docker build --check -f .devcontainer/Dockerfile .devcontainer/ 2>/dev/null || true

# start-code-server.shの実行権限確認
test -x .devcontainer/scripts/start-code-server.sh
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| devcontainer設定 | `.devcontainer/devcontainer.json` | 9 features + forwardPorts + customizations |
| Dockerfile | `.devcontainer/Dockerfile` | code-server + 5拡張機能 + start-code-server配置 |
| 起動スクリプト | `.devcontainer/scripts/start-code-server.sh` | UID/GID調整 + Docker socket修正 + code-server起動 |

---

## 完了条件

### 機能的条件

- [ ] `devcontainer.json` に9つのfeaturesが定義されていること
- [ ] `devcontainer.json` にforwardPorts [8080, 5173] が定義されていること
- [ ] `devcontainer.json` にcustomizations.vscode.extensionsが5つ定義されていること
- [ ] `Dockerfile` でcode-serverがcurl installでインストールされること
- [ ] `Dockerfile` で5つのVS Code拡張機能がプリインストールされること
- [ ] `Dockerfile` でstart-code-serverが/usr/local/binに配置されること
- [ ] `Dockerfile` でENTRYPOINTがdocker-init.sh、CMDがstart-code-serverであること
- [ ] `start-code-server.sh` でroot実行時にUID/GID調整が行われること
- [ ] `start-code-server.sh` でDocker socket存在時にchmod 666が実行されること
- [ ] `start-code-server.sh` でcode-serverが--bind-addr 0.0.0.0:8080 --auth noneで起動されること
- [ ] `start-code-server.sh` に実行権限があること

### 品質条件

- [ ] devcontainer.jsonが有効なJSONであること
- [ ] Dockerfileの構文が正しいこと
- [ ] start-code-server.shがbash構文エラーなく実行可能なこと

---

## コミット

```bash
cd /tmp/WEB-DESIGN-001-task01/
git add -A
git status
git diff --staged

git commit -m "feat(devcontainer): devcontainer構成ファイルを作成

- devcontainer.json: 9 features + forwardPorts + customizations
- Dockerfile: code-server + 拡張機能プリインストール
- start-code-server.sh: UID/GID調整 + code-server起動スクリプト

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

git rev-parse HEAD
```

---

## 注意事項

- MRD-001: code-serverはdevcontainer featureが存在しないため、Dockerfileで手動インストール
- MRD-002: GitHub Copilot拡張はOpen VSXに非公開のため、Copilot CLI（feature copilot-cli:1）で代替
- MRD-005: code-server `--auth none` はローカル開発環境専用。セキュリティガイドラインをコメントで記載
- セキュリティ: `--disable-telemetry` オプションを含めること
