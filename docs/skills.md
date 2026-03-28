# スキル一覧

本リポジトリに含まれるすべてのスキルの分類と概要です。

---

## 3層アーキテクチャ

スキルは以下の3層に分離されており、各レイヤーの責務が明確に分かれています。

```
┌─────────────────────────────────────────────────┐
│  ワークフロープロンプト (prompts/workflow/*.md)    │  ← project.yaml の前提条件・状態更新を定義
├─────────────────────────────────────────────────┤
│  汎用スキル (.claude/skills/)                     │  ← プロジェクト非依存の再利用可能なロジック
├─────────────────────────────────────────────────┤
│  プロジェクト状態スキル (.claude/skills/project-state/) │  ← project.yaml/setup.yaml の一元管理
└─────────────────────────────────────────────────┘
```

- **汎用スキル** は project.yaml を直接参照せず、どのプロジェクトでも再利用可能
- **ワークフロープロンプト** が汎用スキルと project.yaml の橋渡しを行い、各ステップの前提条件・コンテキスト注入・状態更新を定義
- **プロジェクト状態スキル** が project.yaml/setup.yaml の読み書きを一元管理

---

## 汎用スキル（Generic Skills）

project.yaml に依存しない、再利用可能なスキル群です。

### ワークフロースキル

| スキル                   | 説明                                                   |
| ------------------------ | ------------------------------------------------------ |
| **brainstorming**        | 要件探索・テスト戦略確認・創造的な設計アイデア出し     |
| **investigation**        | 対象リポジトリの体系的調査（UML図含む）                |
| **design**               | 詳細設計（API・データ構造・処理フロー・テスト計画）    |
| **plan**                 | タスク分割・依存関係整理・TDDプロンプト生成            |
| **implement**            | タスク計画に従った実装実行（並列化対応）               |
| **verification**         | テスト・ビルド・リント実行確認 + acceptance_criteria照合 |
| **create-mr-pr**         | MR/PR作成（DRモード: 設計レビュー / Codeモード: 実装） |
| **finishing-branch**     | ~~（非推奨）~~ 実装完了後のマージ/PR/クリーンアップオプション提示 |
| **init-work-branch**     | 作業ブランチ・サブモジュール・設計ドキュメント初期化   |
| **submodule-overview**   | サブモジュールの構造分析・概要ドキュメント生成         |

### レビュースキル

| スキル              | 説明                                                               |
| ------------------- | ------------------------------------------------------------------ |
| **review-design**   | 設計結果の妥当性をレビュー                                         |
| **review-plan**     | タスク計画の妥当性をレビュー                                       |
| **code-review**     | 実装変更のチェックリストベースレビュー（8カテゴリ・SHAベース差分） |
| **code-review-fix** | コードレビュー指摘の技術的検証・修正対応                           |

### 品質ルール

| スキル                             | 説明                                                         |
| ---------------------------------- | ------------------------------------------------------------ |
| **test-driven-development**        | RED-GREEN-REFACTORサイクルでテストファーストの開発を実践     |
| **systematic-debugging**           | 根本原因を特定してから修正する体系的デバッグ手法             |
| **verification-before-completion** | 完了主張前に検証コマンドを実行し証拠を確認（汎用品質ルール） |

### ユーティリティスキル

| スキル                | 説明                                                      |
| --------------------- | --------------------------------------------------------- |
| **commit**            | MCP連携でチケット情報取得し日本語コミットメッセージを生成 |
| **commit-multi-repo** | 複数リポジトリ（サブモジュール含む）の一括コミット管理    |
| **writing-skills**    | スキルファイル（SKILL.md）の作成・編集ガイド              |
| **gitlab-api**        | GitLab REST APIを使用したプロジェクト・パイプライン操作   |
| **terraform**         | Terraform/Terragrunt実行・Checkovセキュリティスキャン     |
| **aws-knowledge**     | AWSドキュメント検索・リージョン情報取得・設計支援         |
| **aws-documentation** | AWSドキュメントページの読み取り・推奨取得                 |

---

## プロジェクト固有スキル（Project-specific Skills）

project.yaml や setup.yaml に直接関わるスキル群です。

| スキル                   | 説明                                                      |
| ------------------------ | --------------------------------------------------------- |
| **project-state**        | project.yaml/setup.yaml の読み書きを一元管理するI/Oレイヤー |
| **issue-to-setup-yaml**  | GitHub Issue 情報から setup.yaml を自動生成               |
| **create-setup-yaml**    | ユーザーとの対話で setup.yaml を0から作成                 |
| **skill-usage-protocol** | スキル発動ルール・開発フロー全体の定義                    |

---

## ワークフロープロンプト（Workflow Prompts）

`prompts/workflow/*.md` に配置され、汎用スキルと project.yaml の橋渡しを行います。各プロンプトは対応する汎用スキルを呼び出す前に、前提条件の確認・コンテキストの注入・完了後の状態更新を定義します。

| プロンプト                | 対応スキル        | 役割                                             |
| ------------------------- | ----------------- | ------------------------------------------------ |
| `brainstorming.md`        | brainstorming     | project.yaml生成・テスト戦略確認の前提条件を定義 |
| `investigation.md`        | investigation     | 調査対象・出力先の前提条件を定義                 |
| `design.md`               | design            | 設計入力・出力先・レビュー連携の前提条件を定義   |
| `review-design.md`        | review-design     | 設計レビューの入力・出力の前提条件を定義         |
| `plan.md`                 | plan              | タスク計画の入力・出力の前提条件を定義           |
| `review-plan.md`          | review-plan       | 計画レビューの入力・出力の前提条件を定義         |
| `implement.md`            | implement         | 実装タスクの入力・並列化方針の前提条件を定義     |
| `verification.md`         | verification      | 検証コマンド・acceptance_criteriaの前提条件を定義 |
| `code-review.md`          | code-review       | コードレビューの入力・チェックリストの前提条件を定義 |
| `code-review-fix.md`      | code-review-fix   | レビュー修正の入力・再検証の前提条件を定義       |
| `create-mr-pr.md`         | create-mr-pr      | MR/PR作成（DR/Codeモード）の前提条件を定義       |
| `init-work-branch.md`     | init-work-branch  | ブランチ作成・初期化の前提条件を定義             |
