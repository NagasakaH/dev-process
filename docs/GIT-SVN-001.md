# GIT-SVN-001 - Git→SVN一方向同期の検証環境構築

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | GIT-SVN-001 |
| タスク名 | Git→SVN一方向同期の検証環境構築 |
| 作成日 | 2026-03-07 |
| 作成者 | Hiroaki |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
Dockerコンテナ上にSVNサーバーを構築し、Gitリポジトリのmainブランチの内容を
SVNに一方向同期する仕組みを検証・実装する。
最終的にはGitLab CIで定期実行し、main/masterブランチをSVNに自動同期する。

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
Gitリポジトリの変更をSVNに自動反映する同期スクリプトとインフラ構成を確立する。
マージコミットを含むGit履歴をSVN互換の形式に変換して同期する方式を検証する。

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
既存のGitワークフロー（GitLab）を維持しつつ、SVNにもバックアップ・ミラーリングが
必要なケースに対応する。git-svn dcommitはリニアな履歴しか扱えないため、
マージコミットを含むmainブランチをそのままdcommitすることはできない。
この制約を回避しつつ、意味のあるコミット粒度をSVN側でも保持する方式を検証する。
双方向同期は不要で、Git→SVNの一方向のみ。
SVNの登録者がGitLabに埋め込んだユーザーになることは許容する。

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
- compose.yamlでSVNサーバーコンテナを起動できる（検証用）
- Gitリポジトリのmainブランチの内容をSVNに同期するBashスクリプトを作成する
- マージコミットを含むGit履歴をSVN互換形式に変換して同期できる
- 同期方式として2つのアプローチを設計・比較する:
-   方式A: マージ単位コミット方式（--first-parentでマージ単位、単体コミットはそのまま）
-   方式B: 日次バッチ方式（1日のコミットをまとめて1SVNコミットに）
- 初回同期（全履歴）と増分同期（差分のみ）の両方に対応する
- 同期状態の記録・管理（最後に同期したコミットSHA）をsyncブランチに保持
- GitLab CI (.gitlab-ci.yml) をsyncブランチに配置し、定期実行する構成を作成する
- SVN接続情報（URL、ユーザー名、パスワード）は環境変数で管理する

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
- 同期スクリプトがべき等であること（再実行しても問題ない）
- エラー発生時に適切なログ出力を行うこと
- SVNリポジトリの構造が標準的なtrunk/branches/tagsレイアウトであること

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
- SVNサーバーのDocker構成（compose.yaml）
- Git→SVN同期スクリプト（Bash）
- 2つの同期方式の設計・比較
- syncブランチの構成（スクリプト、CI設定、同期履歴）
- GitLab CI定期実行構成（.gitlab-ci.yml）
- 同期状態管理の仕組み
- E2Eテスト（gitlab-ci-localで実行）

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
- SVN→Git方向の同期（双方向同期）
- main以外のブランチの同期
- 本番SVNサーバーへの接続
- SVN認証の複雑な設定（検証環境では簡易認証）
- 単体テスト・結合テスト

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
- compose.yamlでSVNサーバーが起動し、svnコマンドでアクセスできる
- 同期スクリプトがGitのmainブランチの内容をSVNに正しく反映する
- マージコミットを含む履歴が適切に変換されてSVNに記録される
- 増分同期が正しく動作する（前回同期以降の変更のみ反映）
- 同期スクリプトの再実行がべき等である
- syncブランチにGitLab CI構成（.gitlab-ci.yml）が定義されている
- gitlab-ci-localでE2Eテストが実行できる
- 2つの同期方式のメリット・デメリット比較ドキュメントが存在する

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
同期方式の選定は設計フェーズで両方を詳細比較し、ユーザーが選択する。
検証環境はcompose.yamlで完結し、ローカルで動作確認できることを重視する。
SVNサーバーはgarethflowers/svn-server等の軽量イメージを候補とする。
スクリプト・CI設定はsyncブランチに配置し、mainブランチは汚さない。
syncブランチに同期履歴（最終同期コミットSHA等）を記録してよい。

---

## 1. 調査結果

<!-- investigation スキルが更新 -->

### 1.1 現状分析

ターゲットリポジトリ（submodules/git-svn-backup）はほぼ空（README.md のみ、コミット1件）。
全て新規構築のため、既存コードの制約はない。

技術調査により以下を確認:
- git-svn dcommit は SHA を書き換える（git-svn-id 追加のため）→ svn ブランチでは force push が必須
- git-svn-id メタ情報から `.rev_map` が自動再構築される → CI 環境で毎回クリーン clone しても問題ない
- `git checkout COMMIT -- .` 方式がリニア化に最適（実験でファイル追加/削除/リネーム全て正しく処理確認）
- gitlab-ci-local は services: 非対応 → Docker Compose + `--network host` で代替
- garethflowers/svn-server が最もシンプル（svn:// プロトコル、svnserve.conf + passwd 認証）

詳細は [investigation/](./git-svn-backup/investigation/) を参照。

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| `submodules/git-svn-backup/README.md` | GitLab 初期テンプレート | 既存唯一のファイル |

### 1.3 参考情報

- [アーキテクチャ調査](./git-svn-backup/investigation/01_architecture.md)
- [データ構造調査](./git-svn-backup/investigation/02_data-structure.md)
- [依存関係調査](./git-svn-backup/investigation/03_dependencies.md)
- [既存パターン調査（git-svn詳細・リニア化手法）](./git-svn-backup/investigation/04_existing-patterns.md)
- [統合ポイント調査（gitlab-ci-local・CI構成）](./git-svn-backup/investigation/05_integration-points.md)
- [リスク・制約分析](./git-svn-backup/investigation/06_risks-and-constraints.md)

---

## 2. 設計

<!-- design スキルが更新 -->

### 2.1 設計方針

<!-- 詳細: design/01_implementation-approach.md -->

### 2.2 変更箇所

#### 追加ファイル

| ファイル | 目的 |
|----------|------|
| | |

#### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| | |

#### 削除ファイル

| ファイル | 理由 |
|----------|------|
| | |

### 2.3 インターフェース設計

<!-- 詳細: design/02_interface-api-design.md -->

### 2.4 データ構造

<!-- 詳細: design/03_data-structure-design.md -->

---

## 3. 実装計画

<!-- plan スキルが更新 -->

### 3.1 タスク分割

<!-- 詳細: plan/task-list.md -->

| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| | | | | | ⬜ 未着手 |

### 3.2 依存関係

<!-- 依存関係図は plan スキルで生成 -->

### 3.3 見積もり

| タスク | 見積もり | 実績 |
|--------|----------|------|
| | | |

---

## 4. テスト計画

<!-- design/05_test-plan.md を参照 -->

### 4.1 テスト対象

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| 1 | | | ⬜ |

### 4.3 テスト環境

---

## 5. 弊害検証

<!-- design/06_side-effect-verification.md を参照 -->

### 5.1 影響範囲

### 5.2 リスク分析

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| | | | |

### 5.3 ロールバック計画

---

## 6. レビュー・承認

### 6.1 レビュー履歴

| 日付 | レビュアー | 結果 | コメント |
|------|------------|------|----------|
| | | | |

### 6.2 承認

- [ ] 設計レビュー完了
- [ ] 実装レビュー完了
- [ ] テスト完了
- [ ] 弊害検証完了

---

## 7. 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-07 | 1.0 | 初版作成 | Hiroaki |
