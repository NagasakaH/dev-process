# General-Purpose Manager Skills

Claude AIエージェント向けの汎用作業管理スキル集です。複雑なリクエストを体系的に管理し、調査・設計・計画・実行の各プロセスを通じて作業を完遂します。

## プロジェクト概要

### 目的

このリポジトリ（`.claude/skills`）は、Claude AIエージェントが複雑なリクエストを体系的に処理するためのスキル定義を提供します。

### General-Purpose Managerの役割

General-Purpose Manager（`manager.agent.md`）は、プロジェクトマネージャーとして機能するエージェントです。直接作業を行わず、子エージェントに作業を委譲しながら、以下の責務を遂行します：

- リクエストの受け取りと分析
- ドキュメント出力先の決定と作成
- 各プロセスディレクトリの事前作成
- 子エージェントへの作業依頼
- 進行状況の追跡・監視
- 実行履歴の記録

---

## エージェント構成図

```mermaid
graph TB
    subgraph "呼び出しレイヤー"
        CM[call-manager.agent.md<br/>ラッパーエージェント]
        CGP[call-general-purpose.agent.md<br/>ラッパーエージェント]
    end
    
    subgraph "管理レイヤー"
        M[manager.agent.md<br/>作業管理エージェント<br/>プロジェクトマネージャー]
    end
    
    subgraph "実行レイヤー"
        GP[general-purpose.agent.md<br/>汎用作業エージェント]
        OC[opus-child-agent.md<br/>子エージェント]
    end
    
    subgraph "スキルレイヤー"
        INV[Investigation<br/>調査スキル]
        DES[Design<br/>設計スキル]
        PLN[Task Planning<br/>計画スキル]
        EXE[Execution<br/>実行スキル]
        WTC[Worktree Commit<br/>コミットスキル]
        CMT[Commit<br/>通常コミットスキル]
    end
    
    CM -->|Opus-4.5で呼び出し| M
    CGP -->|Opus-4.5で呼び出し| GP
    
    M -->|作業依頼| OC
    GP -->|スキル使用| INV
    GP -->|スキル使用| DES
    GP -->|スキル使用| PLN
    GP -->|スキル使用| EXE
    
    OC -->|スキル使用| INV
    OC -->|スキル使用| DES
    OC -->|スキル使用| PLN
    OC -->|スキル使用| EXE
    OC -->|スキル使用| WTC
    OC -->|スキル使用| CMT
```

### 各エージェントの役割

| エージェント | ファイル | 役割 |
|-------------|----------|------|
| call-manager | `call-manager.agent.md` | manager-agentを呼び出すラッパー。Opus-4.5を使用 |
| manager | `manager.agent.md` | 作業管理エージェント（PM）。直接作業禁止、子エージェントに委譲 |
| call-general-purpose | `call-general-purpose.agent.md` | general-purpose-agentを呼び出すラッパー |
| general-purpose | `general-purpose.agent.md` | 親から依頼された作業を実行するサブエージェント |
| opus-child-agent | `opus-child-agent.md` | 依頼された作業を完遂する子エージェント。プロセス別成果物を出力 |

---

## 全体ワークフロー（シーケンス図）

```mermaid
sequenceDiagram
    actor User
    participant CM as call-manager<br/>(call-manager.agent.md)
    participant M as manager<br/>(manager.agent.md)
    participant OC as child-agent<br/>(opus-child-agent.md)
    participant GP as general-purpose<br/>(general-purpose.agent.md)
    
    %% フェーズ1: リクエスト受け取り・初期化
    rect rgb(230, 245, 255)
        Note over User,GP: フェーズ1: リクエスト受け取り・初期化
        User->>CM: リクエスト
        CM->>M: Opus-4.5で呼び出し
        M->>M: 出力先決定<br/>(DOCS_DIR確認、タイムスタンプ生成)
        M->>M: リクエストフォルダ作成<br/>(01_調査/, 02_設計/, 03_計画/, 04_実行/)
        M->>M: 実行履歴.md初期化
    end
    
    %% フェーズ2: 調査プロセス
    rect rgb(255, 245, 230)
        Note over User,GP: フェーズ2: 調査プロセス (investigationスキル)
        M->>OC: 調査依頼<br/>(出力先: 01_調査/)
        OC->>OC: investigationスキル実行
        OC->>OC: README.md, AGENTS.md確認
        OC->>OC: リポジトリ構造調査
        OC->>OC: 依存関係・リスク分析
        OC-->>M: investigation-report.md<br/>risk-analysis.md
        M->>M: 実行履歴更新
    end
    
    %% フェーズ3: 設計プロセス
    rect rgb(245, 255, 230)
        Note over User,GP: フェーズ3: 設計プロセス (designスキル)
        M->>OC: 設計依頼<br/>(出力先: 02_設計/)
        OC->>OC: designスキル実行
        OC->>OC: 調査結果を基に設計
        OC->>OC: アーキテクチャ決定
        OC-->>M: design-document.md<br/>interface-spec.md<br/>data-structure.md<br/>flow-diagram.md
        M->>M: 実行履歴更新
    end
    
    %% フェーズ4: 計画プロセス
    rect rgb(245, 230, 255)
        Note over User,GP: フェーズ4: 計画プロセス (task-planningスキル)
        M->>OC: 計画依頼<br/>(出力先: 03_計画/)
        OC->>OC: task-planningスキル実行
        OC->>OC: タスク分割・依存関係整理
        OC-->>M: task-plan.md<br/>dependency-graph.md<br/>parallel-groups.md
        M->>M: 実行履歴更新
    end
    
    %% フェーズ5: 実行プロセス
    rect rgb(255, 230, 230)
        Note over User,GP: フェーズ5: 実行プロセス (executionスキル + worktree管理)
        M->>M: メインworktree作成<br/>(/tmp/リクエスト名/)
        
        loop 各タスク (直列/並列)
            M->>M: サブworktree作成<br/>(/tmp/リクエスト名-taskID/)
            M->>OC: タスク実行依頼<br/>(worktreeパス指定)
            OC->>OC: executionスキル実行
            OC->>OC: worktree-commitスキルでコミット
            OC-->>M: result.md + コミットハッシュ
            M->>M: メインブランチでcherry-pick
            M->>M: サブworktree削除
            M->>M: 実行履歴更新
        end
    end
    
    %% フェーズ6: 完了報告
    rect rgb(230, 255, 245)
        Note over User,GP: フェーズ6: 完了報告
        M->>M: 最終レポート作成
        M-->>CM: 完了報告
        CM-->>User: 作業完了
    end
```

---

## 各プロセスの詳細

### 調査プロセス（Investigation）

| 項目 | 内容 |
|------|------|
| **目的** | 既存コードベース、要件、リスクを把握する |
| **スキル** | `/.claude/skills/general-purpose/investigation/SKILL.md` |
| **入力（前提条件）** | リクエスト内容、リポジトリアクセス |
| **出力（成果物）** | `investigation-report.md`, `risk-analysis.md` |

**成果物の内容:**

- `investigation-report.md`: 構造概要、関連ファイル一覧、既存パターン、依存関係
- `risk-analysis.md`: 特定されたリスク、影響度・発生可能性、緩和策

---

### 設計プロセス（Design）

| 項目 | 内容 |
|------|------|
| **目的** | ソリューションのアーキテクチャを決定する |
| **スキル** | `/.claude/skills/general-purpose/design/SKILL.md` |
| **入力（前提条件）** | `investigation-report.md`（調査結果） |
| **出力（成果物）** | `design-document.md`, `interface-spec.md`, `data-structure.md`, `flow-diagram.md` |

**成果物の内容:**

- `design-document.md`: 設計書（全体）- 実装方針、コンポーネント設計、非機能要件対応
- `interface-spec.md`: API・インターフェース仕様
- `data-structure.md`: エンティティ、型定義、DBスキーマ
- `flow-diagram.md`: シーケンス図、フローチャート、状態遷移図

---

### 計画プロセス（Task Planning）

| 項目 | 内容 |
|------|------|
| **目的** | 実行可能なタスク計画を作成する |
| **スキル** | `/.claude/skills/general-purpose/task-planning/SKILL.md` |
| **入力（前提条件）** | `design-document.md`（設計結果） |
| **出力（成果物）** | `task-plan.md`, `dependency-graph.md`, `parallel-groups.md` |

**成果物の内容:**

- `task-plan.md`: タスク一覧、作業内容、完了条件、推定時間
- `dependency-graph.md`: タスク間の依存関係（mermaid図）
- `parallel-groups.md`: 並列実行可能なタスクグループ定義

---

### 実行プロセス（Execution）

| 項目 | 内容 |
|------|------|
| **目的** | 計画に従ってタスクを実行する |
| **スキル** | `/.claude/skills/general-purpose/execution/SKILL.md` |
| **入力（前提条件）** | `task-plan.md`（計画結果） |
| **出力（成果物）** | 各タスクごとの `result.md` |

**成果物の内容:**

- `result.md`: 実装完了状況、変更ファイル一覧、テスト結果、コミットハッシュ

---

## ディレクトリ構造とファイル一覧

```
.claude/skills/
├── README.md                           # このファイル
├── commit/
│   └── SKILL.md                        # 通常のgitコミットスキル
└── general-purpose/
    ├── investigation/
    │   ├── SKILL.md                    # 調査プロセススキル定義
    │   └── references/
    │       ├── investigation-report-template.md
    │       └── risk-analysis-template.md
    ├── design/
    │   ├── SKILL.md                    # 設計プロセススキル定義
    │   └── references/
    │       └── design-templates.md     # 設計書テンプレート集
    ├── task-planning/
    │   ├── SKILL.md                    # 計画プロセススキル定義
    │   └── references/
    │       └── templates.md            # 計画書テンプレート
    ├── execution/
    │   ├── SKILL.md                    # 実行プロセススキル定義
    │   └── references/
    │       └── templates.md            # 実行テンプレート集
    └── worktree-commit/
        └── SKILL.md                    # worktree環境でのコミットスキル
```

### 各ファイルの役割

| ファイル | 役割 |
|----------|------|
| `commit/SKILL.md` | ブランチ名からチケットID抽出、MCP連携でチケット情報取得、日本語コミットメッセージ生成 |
| `investigation/SKILL.md` | リポジトリ構造確認、関連ファイル特定、既存パターン調査、リスク分析のガイド |
| `investigation/references/*.md` | 調査レポート・リスク分析のテンプレート |
| `design/SKILL.md` | 実装方針決定、API設計、データ構造設計、処理フロー設計のガイド |
| `design/references/*.md` | 設計書・インターフェース仕様・データ構造定義のテンプレート |
| `task-planning/SKILL.md` | タスク分割、依存関係整理、並列実行グループ特定のガイド |
| `task-planning/references/*.md` | タスク計画書・依存関係図・並列グループ定義のテンプレート |
| `execution/SKILL.md` | worktree管理、子エージェント依頼、cherry-pick、クリーンアップのガイド |
| `execution/references/*.md` | 依頼テンプレート、result.md形式、実行履歴エントリ形式 |
| `worktree-commit/SKILL.md` | worktree環境での全変更ステージング、日本語コミットメッセージ生成 |

---

## リクエストフォルダ構造

manager.agent.mdがリクエスト開始時に作成するフォルダ構造:

```
{出力先ディレクトリ}/
└── YYYYMMDD-HHMM-{リクエスト名}/
    ├── 実行履歴.md              # リクエスト進行状況の記録
    ├── 01_調査/
    │   ├── investigation-report.md
    │   └── risk-analysis.md
    ├── 02_設計/
    │   ├── design-document.md
    │   ├── interface-spec.md
    │   ├── data-structure.md
    │   └── flow-diagram.md
    ├── 03_計画/
    │   ├── task-plan.md
    │   ├── dependency-graph.md
    │   └── parallel-groups.md
    └── 04_実行/
        ├── task01/
        │   └── result.md
        ├── task02-01/
        │   └── result.md
        ├── task02-02/
        │   └── result.md
        └── ...
```

### ディレクトリ命名規則

| 項目 | 形式 | 例 |
|------|------|-----|
| リクエストフォルダ | `YYYYMMDD-HHMM-{リクエスト名}` | `20260208-0149-機能追加` |
| プロセスフォルダ | `{番号}_{プロセス名}` | `01_調査`, `02_設計` |
| 実行タスクフォルダ | `{タスク識別子}` | `task01`, `task02-01` |

---

## 成果物一覧

### プロセス別成果物

| プロセス | ファイル名 | 内容の概要 |
|----------|------------|------------|
| 調査 | `investigation-report.md` | 構造概要、関連ファイル、既存パターン、依存関係 |
| 調査 | `risk-analysis.md` | リスク特定、影響度評価、緩和策 |
| 設計 | `design-document.md` | アーキテクチャ、実装方針、コンポーネント設計 |
| 設計 | `interface-spec.md` | API仕様、内部インターフェース定義 |
| 設計 | `data-structure.md` | エンティティ、値オブジェクト、DBスキーマ |
| 設計 | `flow-diagram.md` | シーケンス図、フローチャート、状態遷移図 |
| 計画 | `task-plan.md` | タスク一覧、作業内容、完了条件、見積もり |
| 計画 | `dependency-graph.md` | タスク間依存関係（mermaid図） |
| 計画 | `parallel-groups.md` | 並列実行グループ定義 |
| 実行 | `result.md` | 各タスクの実行結果、変更ファイル、テスト結果 |
| 管理 | `実行履歴.md` | 全タスクの進行状況、ステータス、成果物リンク |

---

## Worktree管理フロー

実行プロセスではgit worktreeを活用して、各タスクを独立したブランチで実行します。

```mermaid
flowchart TD
    subgraph "初期化"
        A[実行開始] --> B["メインworktree作成<br/>/tmp/{リクエスト名}/"]
        B --> C["リクエスト名ブランチ作成"]
    end
    
    subgraph "タスク実行ループ"
        C --> D{次のタスク?}
        D -->|Yes| E["サブworktree作成<br/>/tmp/{リクエスト名}-{taskID}/"]
        E --> F["サブブランチ作成<br/>{リクエスト名}-{taskID}"]
        F --> G[子エージェントに依頼<br/>worktreeパス指定]
        G --> H[タスク実行]
        H --> I[worktree-commit<br/>日本語コミット]
        I --> J["メインworktreeで<br/>cherry-pick"]
        J --> K["サブworktree削除<br/>サブブランチ削除"]
        K --> L[実行履歴更新]
        L --> D
    end
    
    subgraph "完了"
        D -->|No| M["全タスク完了<br/>メインworktreeは残す"]
        M --> N[ユーザーがpush/マージ]
    end
```

### worktreeの関係

```mermaid
graph LR
    subgraph "リポジトリ"
        REPO[(メインリポジトリ<br/>$REPO_ROOT)]
    end
    
    subgraph "メインworktree"
        MW["/tmp/{リクエスト名}/<br/>リクエスト名ブランチ"]
    end
    
    subgraph "サブworktree群"
        SW1["/tmp/{リクエスト名}-task01/<br/>リクエスト名-task01ブランチ"]
        SW2["/tmp/{リクエスト名}-task02-01/<br/>リクエスト名-task02-01ブランチ"]
        SW3["/tmp/{リクエスト名}-task02-02/<br/>リクエスト名-task02-02ブランチ"]
    end
    
    REPO -->|git worktree add| MW
    MW -->|分岐元| SW1
    MW -->|分岐元| SW2
    MW -->|分岐元| SW3
    
    SW1 -.->|cherry-pick| MW
    SW2 -.->|cherry-pick| MW
    SW3 -.->|cherry-pick| MW
```

### 並列タスクのcherry-pick

並列タスクは全て同じベースコミットから分岐し、完了後に順次cherry-pickします:

1. 全並列タスクのサブworktreeを作成（同じベースから分岐）
2. 各タスクを並列実行
3. 全タスク完了後、順番にcherry-pick
4. コンフリクト発生時は手動解消またはabort
5. 全cherry-pick完了後、サブworktreeを一括削除

---

## 関連ファイルの参照表

### エージェント定義ファイル（`/.github/agents/`配下）

| ファイル | 役割 |
|----------|------|
| `call-manager.agent.md` | manager-agentを呼び出すラッパー。Opus-4.5使用 |
| `manager.agent.md` | 作業管理エージェント（PM）。直接作業禁止、子エージェントに委譲 |
| `call-general-purpose.agent.md` | general-purpose-agentを呼び出すラッパー |
| `general-purpose.agent.md` | 親から依頼された作業を実行するサブエージェント |
| `opus-child-agent.md` | 子エージェント。親から受け取った情報を信頼して使用 |

### スキル定義ファイル（`/.claude/skills/`配下）

| ファイル | 役割 |
|----------|------|
| `general-purpose/investigation/SKILL.md` | 調査プロセスのガイド |
| `general-purpose/design/SKILL.md` | 設計プロセスのガイド |
| `general-purpose/task-planning/SKILL.md` | 計画プロセスのガイド |
| `general-purpose/execution/SKILL.md` | 実行プロセスのガイド（worktree管理含む） |
| `general-purpose/worktree-commit/SKILL.md` | worktree環境でのコミットスキル |
| `commit/SKILL.md` | 通常のgitコミットスキル（MCP連携） |

### リファレンステンプレート

| ファイル | 内容 |
|----------|------|
| `investigation/references/investigation-report-template.md` | 調査レポートテンプレート |
| `investigation/references/risk-analysis-template.md` | リスク分析テンプレート |
| `design/references/design-templates.md` | 設計書テンプレート集（design-document, interface-spec, data-structure, flow-diagram） |
| `task-planning/references/templates.md` | タスク計画テンプレート（task-plan, dependency-graph, parallel-groups） |
| `execution/references/templates.md` | 実行テンプレート（子エージェント依頼、worktree初期化、result.md、実行履歴エントリ、cherry-pick・クリーンアップコマンド） |

---

## 使用方法

### 基本的な呼び出し

1. **call-managerエージェントを呼び出す**
   ```
   call-managerエージェントを使用して、〇〇の機能を実装してください。
   ```

2. **managerエージェントが自動的に以下を実行**
   - リクエストフォルダの作成
   - 調査→設計→計画→実行の各プロセスを順次実行
   - 子エージェントへの作業委譲
   - 進行状況の追跡・記録

### 個別スキルの直接使用

各スキルは単独でも使用可能です:

```
investigationスキルを使用して、このリポジトリの構造を調査してください。
```

```
designスキルを使用して、ログイン機能の設計を行ってください。
```

---

## 注意事項

### managerエージェントの制約

- **直接作業禁止**: コード編集、ファイル操作は一切行わない（ディレクトリ作成は例外）
- **サブエージェント経由**: 全ての作業を子エージェントに依頼
- **追跡機能**: 実行履歴ファイルで全てのタスクの進行状況を記録
- **出力先明記**: 子エージェントへの依頼には必ず成果物出力先の絶対パスを含める

### 子エージェントの制約

- **環境変数の再確認禁止**: 親から渡された情報を信頼して使用
- **パスの加工禁止**: 提供された絶対パスをそのまま使用
- **コミットメッセージは日本語**: 必ず日本語でコミットメッセージを生成

### コミットに関する制約

- **日本語コミットメッセージ必須**: 全てのコミットメッセージは日本語で記述
- **worktree環境ではpushしない**: プッシュは親エージェントまたはユーザーが実行
