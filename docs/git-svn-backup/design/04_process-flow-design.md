# 処理フロー設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | GIT-SVN-001 |
| タスク名 | Git→SVN一方向同期の検証環境構築 |
| 作成日 | 2026-03-07 |

本プロジェクトは新規構築のため「修正前」は存在しない。同期スクリプトの処理フローを定義する。

---

## 1. 全体同期フロー

### 1.1 メインフロー

```mermaid
flowchart TD
    START([sync-to-svn.sh 開始]) --> PARSE[引数パース]
    PARSE --> VALIDATE[環境変数チェック]
    VALIDATE -->|不足| ERR_ENV[exit 2: 環境変数未設定]
    VALIDATE -->|OK| DEPS[依存コマンドチェック]
    DEPS -->|不足| ERR_DEPS[exit 1: コマンド不足]
    DEPS -->|OK| SVN_TEST[SVN接続テスト]
    SVN_TEST -->|失敗| ERR_SVN[exit 3: SVN接続エラー]
    SVN_TEST -->|OK| FETCH[ブランチ情報取得]
    FETCH --> READ_STATE[.sync-state.yml 読み込み]
    READ_STATE --> ENSURE_SVN[svnブランチ確認/作成]
    ENSURE_SVN --> CHECKOUT_SVN[git checkout svn]
    CHECKOUT_SVN --> SETUP_GITSVN[git svn init + fetch]
    SETUP_GITSVN --> CHECK_COMMITS{新規コミットあり?}
    CHECK_COMMITS -->|なし| NO_CHANGE[ログ出力: 変更なし]
    NO_CHANGE --> EXIT_OK([exit 0])
    CHECK_COMMITS -->|あり| MODE{同期モード?}
    MODE -->|merge-unit| MERGE_UNIT[方式A: マージ単位同期]
    MODE -->|daily-batch| DAILY_BATCH[方式B: 日次バッチ同期]
    MERGE_UNIT --> DRYRUN{--dry-run?}
    DAILY_BATCH --> DRYRUN
    DRYRUN -->|Yes| DRY_LOG[ログ出力: dry-run完了]
    DRY_LOG --> EXIT_OK
    DRYRUN -->|No| DCOMMIT[git svn dcommit]
    DCOMMIT -->|失敗| ERR_DCOMMIT[exit 5: dcommitエラー]
    DCOMMIT -->|成功| PUSH_SVN[git push --force origin svn]
    PUSH_SVN -->|失敗| ERR_PUSH[exit 4: push失敗]
    PUSH_SVN -->|成功| UPDATE_STATE[.sync-state.yml 更新]
    UPDATE_STATE --> COMMIT_STATE[sync ブランチにcommit + push]
    COMMIT_STATE --> EXIT_OK
```

### 1.2 方式A: マージ単位同期（sync_merge_unit）

```mermaid
flowchart TD
    START([sync_merge_unit 開始]) --> GET_COMMITS[git log --first-parent で<br/>last_synced 以降のコミット取得]
    GET_COMMITS --> LOOP{次のコミットあり?}
    LOOP -->|なし| RETURN([コミット数を返す])
    LOOP -->|あり| GET_SHA[SHA取得]
    GET_SHA --> GET_MSG[コミットメッセージ取得]
    GET_MSG --> CLEAN[git rm -rf .]
    CLEAN --> CHECKOUT[git checkout SHA -- .]
    CHECKOUT --> ADD[git add -A]
    ADD --> DIFF{差分あり?}
    DIFF -->|なし| SKIP[スキップ（べき等性）]
    DIFF -->|あり| COMMIT[git commit -m MSG]
    SKIP --> LOOP
    COMMIT --> COUNT[カウンター+1]
    COUNT --> LOOP
```

### 1.3 方式B: 日次バッチ同期（sync_daily_batch）

```mermaid
flowchart TD
    START([sync_daily_batch 開始]) --> GET_DATES[日付一覧取得<br/>git log --format=%ad --date=short]
    GET_DATES --> SORT[日付をソート・重複排除]
    SORT --> LOOP{次の日付あり?}
    LOOP -->|なし| RETURN([コミット数を返す])
    LOOP -->|あり| GET_LAST[その日の最後のコミットSHA取得]
    GET_LAST --> GET_COUNT[その日のコミット数取得]
    GET_COUNT --> CLEAN[git rm -rf .]
    CLEAN --> CHECKOUT[git checkout SHA -- .]
    CHECKOUT --> ADD[git add -A]
    ADD --> DIFF{差分あり?}
    DIFF -->|なし| SKIP[スキップ]
    DIFF -->|あり| COMMIT["git commit -m 'sync: DATE (N commits)'"]
    SKIP --> LOOP
    COMMIT --> COUNT_UP[カウンター+1]
    COUNT_UP --> LOOP
```

---

## 2. シーケンス図

### 2.1 初回同期フロー

```mermaid
sequenceDiagram
    participant SCRIPT as sync-to-svn.sh
    participant GIT as Git Repository
    participant SVN_BR as svn ブランチ
    participant SVN_SRV as SVN Server
    participant SYNC_BR as sync ブランチ

    Note over SCRIPT,SYNC_BR: 【初回同期】全履歴を同期

    SCRIPT->>SCRIPT: validate_env / check_dependencies
    SCRIPT->>SVN_SRV: test_svn_connection (svn info)
    SVN_SRV-->>SCRIPT: OK

    SCRIPT->>GIT: git fetch origin main svn
    Note over GIT: svn ブランチが存在しない場合あり

    SCRIPT->>SYNC_BR: .sync-state.yml 読み込み
    Note over SYNC_BR: last_synced_commit = ""（初回）

    SCRIPT->>SVN_BR: git checkout --orphan svn（初回作成）
    SCRIPT->>SVN_BR: git svn init $SVN_URL --stdlayout
    SCRIPT->>SVN_SRV: git svn fetch
    SVN_SRV-->>SVN_BR: （空リポジトリ、何も取得しない）

    loop main の全 first-parent コミット
        SCRIPT->>GIT: git log --first-parent で SHA 取得
        SCRIPT->>SVN_BR: git rm -rf . && git checkout SHA -- .
        SCRIPT->>SVN_BR: git add -A && git commit
    end

    SCRIPT->>SVN_SRV: git svn dcommit
    SVN_SRV-->>SVN_BR: SHA書き換え + git-svn-id付与

    SCRIPT->>GIT: git push --force origin svn

    SCRIPT->>SYNC_BR: git checkout sync
    SCRIPT->>SYNC_BR: .sync-state.yml 更新
    SCRIPT->>GIT: git push origin sync
```

### 2.2 増分同期フロー

```mermaid
sequenceDiagram
    participant SCRIPT as sync-to-svn.sh
    participant GIT as Git Repository
    participant SVN_BR as svn ブランチ
    participant SVN_SRV as SVN Server
    participant SYNC_BR as sync ブランチ

    Note over SCRIPT,SYNC_BR: 【増分同期】前回以降の差分を同期

    SCRIPT->>SCRIPT: validate_env / check_dependencies
    SCRIPT->>SVN_SRV: test_svn_connection
    SVN_SRV-->>SCRIPT: OK

    SCRIPT->>GIT: git fetch origin main svn

    SCRIPT->>SYNC_BR: .sync-state.yml 読み込み
    Note over SYNC_BR: last_synced_commit = "abc123..."

    SCRIPT->>SVN_BR: git checkout svn
    SCRIPT->>SVN_BR: git svn init $SVN_URL --stdlayout
    SCRIPT->>SVN_SRV: git svn fetch
    SVN_SRV-->>SVN_BR: .rev_map 再構築（git-svn-idから）

    loop abc123..HEAD の first-parent コミット
        SCRIPT->>GIT: git log --first-parent abc123..origin/main
        SCRIPT->>SVN_BR: git rm -rf . && git checkout SHA -- .
        SCRIPT->>SVN_BR: git add -A && git commit
    end

    SCRIPT->>SVN_SRV: git svn dcommit
    SVN_SRV-->>SVN_BR: SHA書き換え + git-svn-id付与

    SCRIPT->>GIT: git push --force origin svn

    SCRIPT->>SYNC_BR: git checkout sync
    SCRIPT->>SYNC_BR: .sync-state.yml 更新（新しいlast_synced_commit）
    SCRIPT->>GIT: git push origin sync
```

### 2.3 CI 環境での実行フロー

```mermaid
sequenceDiagram
    participant CI as GitLab CI
    participant DOCKER as Docker
    participant GIT as Git Clone
    participant SCRIPT as sync-to-svn.sh
    participant SVN_SRV as SVN Server

    Note over CI,SVN_SRV: 【CI実行】クリーン環境からの同期

    CI->>DOCKER: debian:bookworm-slim コンテナ起動
    CI->>DOCKER: apt install git git-svn subversion yq
    CI->>GIT: git clone (sync ブランチ, GIT_DEPTH=0)
    CI->>GIT: git fetch origin main svn

    CI->>SCRIPT: ./sync-to-svn.sh 実行
    Note over SCRIPT: 環境変数は CI/CD Variables から注入

    SCRIPT->>GIT: svn ブランチ checkout
    SCRIPT->>GIT: git svn init + fetch
    Note over GIT: git-svn-id から .rev_map 自動再構築

    SCRIPT->>SCRIPT: リニア化 + dcommit + push

    SCRIPT->>GIT: sync ブランチで状態更新
    Note over GIT: CI_JOB_TOKEN で push
```

---

## 3. 状態遷移図

### 3.1 同期状態の遷移

```mermaid
stateDiagram-v2
    [*] --> Uninitialized: 初回実行
    Uninitialized --> Syncing: sync-to-svn.sh 開始
    Syncing --> Synced: 同期成功
    Syncing --> Error: エラー発生
    Synced --> Syncing: 次回実行（増分）
    Error --> Syncing: 再実行（べき等）
    Synced --> [*]: 完了

    state Syncing {
        [*] --> FetchingBranches
        FetchingBranches --> ReadingState
        ReadingState --> Linearizing
        Linearizing --> Dcommitting
        Dcommitting --> PushingSvn
        PushingSvn --> UpdatingState
        UpdatingState --> [*]
    }
```

### 3.2 状態定義

| 状態 | 説明 | .sync-state.yml |
|------|------|-----------------|
| Uninitialized | 初回未実行。.sync-state.yml が初期状態 | `last_synced_commit: ""` |
| Syncing | 同期処理中 | 前回の値のまま |
| Synced | 同期完了 | 最新の main コミットSHA |
| Error | エラー発生（中断） | 前回の値のまま（べき等性により安全に再実行可能） |

---

## 4. エラーフロー

### 4.1 エラーハンドリングフロー

```mermaid
flowchart TD
    A[処理開始] --> B{環境変数チェック}
    B -->|NG| C["log_error + exit 2"]
    B -->|OK| D{SVN接続テスト}
    D -->|NG| E["log_error + exit 3"]
    D -->|OK| F{ブランチ操作}
    F -->|NG| G["log_error + exit 4"]
    F -->|OK| H[リニア化処理]
    H --> I{dcommit}
    I -->|NG| J["log_error + exit 5"]
    I -->|OK| K{force push}
    K -->|NG| L["log_error + exit 4"]
    K -->|OK| M{状態更新 push}
    M -->|NG| N["log_warn（次回再実行で復旧）"]
    M -->|OK| O["exit 0"]
```

### 4.2 エラー種別と対応

| エラー種別 | 発生条件 | 対応方法 | べき等 |
|------------|----------|----------|--------|
| 環境変数未設定 | SVN_URL 等が未定義 | ログ出力して即座に終了 | Yes |
| SVN接続エラー | SVNサーバーが応答しない | リトライせず終了（CIスケジュールで再実行） | Yes |
| ブランチ操作エラー | checkout/fetch 失敗 | ログ出力して終了 | Yes |
| dcommit エラー | SVN側でコンフリクト等 | ログ出力して終了。.sync-state 未更新のため再実行安全 | Yes |
| push エラー | force push 拒否 | ブランチ保護設定を確認するよう案内 | Yes |
| 状態更新 push エラー | sync ブランチの push 失敗 | 警告のみ。次回実行時に同じコミットを再処理（べき等） | Yes |

### 4.3 べき等性の保証メカニズム

```mermaid
flowchart TD
    A["sync-to-svn.sh 開始"] --> B["last_synced_commit 読み込み"]
    B --> C{"last_synced_commit<br/>以降にコミットあり?"}
    C -->|なし| D["何もせず exit 0"]
    C -->|あり| E["リニア化処理"]
    E --> F["git diff --cached --quiet"]
    F -->|差分なし| G["コミットスキップ"]
    F -->|差分あり| H["git commit"]
    G --> I["次のコミットへ"]
    H --> I
    I --> J["dcommit"]
    J --> K[".sync-state.yml 更新"]

    style D fill:#afa
    style G fill:#afa
    note1["べき等性ポイント1:<br/>変更なしなら何もしない"]
    note2["べき等性ポイント2:<br/>差分なしならスキップ"]
    note3["べき等性ポイント3:<br/>dcommit は未送信コミットのみ処理"]
```

**べき等性が保証される理由:**

1. **状態ベース**: `.sync-state.yml` の `last_synced_commit` を基準に差分を計算。同じ状態で再実行すれば同じ結果
2. **差分チェック**: `git diff --cached --quiet` で実際に変更がない場合はコミットをスキップ
3. **dcommit の性質**: `git svn dcommit` は未送信のコミットのみをSVNに送信。既に送信済みのコミットは処理しない
4. **エラー時の安全性**: `.sync-state.yml` は同期成功後にのみ更新。エラー中断時は前回の状態が保持され、次回実行で同じ処理を再試行

---

## 5. ブランチ操作フロー

### 5.1 CI 内のブランチ切り替え

```mermaid
sequenceDiagram
    participant WD as Working Directory
    participant SYNC as sync ブランチ
    participant SVN as svn ブランチ
    participant MAIN as main ブランチ

    Note over WD,MAIN: CI 開始時は sync ブランチ

    WD->>SYNC: git clone (sync ブランチ)
    WD->>WD: git fetch origin main svn

    WD->>SYNC: .sync-state.yml 読み込み
    Note over WD: last_synced_commit 取得

    WD->>SVN: git checkout svn
    Note over WD: 作業ディレクトリ = svn のファイル群

    WD->>SVN: git svn init + fetch

    loop リニア化
        WD->>MAIN: git checkout SHA -- .
        Note over WD: main のスナップショットを取得
        WD->>SVN: git add -A && git commit
    end

    WD->>SVN: git svn dcommit
    WD->>SVN: git push --force origin svn

    WD->>SYNC: git checkout sync
    Note over WD: 作業ディレクトリ = sync のファイル群
    WD->>SYNC: .sync-state.yml 更新
    WD->>SYNC: git commit + push
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-07 | 1.0 | 初版作成 | Copilot |
