# タスク分割の妥当性レビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 1 |
| タスク計画参照 | [../plan/](../plan/) |
| 設計結果参照 | [../design/](../design/) |

## 評価サマリー

タスク分割そのものは概ね妥当（16タスク／8並列グループ、TDDタスク粒度も適切）。一方で、**タスク責務境界**および**完了条件の整合性**に複数の矛盾が見られる。具体的には以下の通り（詳細は `06_review-summary.md` の指摘事項一覧を参照）。

## 検出された主な分割不整合

### task03-01: APP_INITIALIZER 責務境界の矛盾 (RP-005, Major)

- task03-01 のタイトル/目的に「APP_INITIALIZER 登録」が含まれるが、実装ステップ・対象ファイル・完了条件には登録手順が無く、実態は task04（main.ts/app.config.ts）側に存在する。
- **是正**: task03-01 を ConfigService 実装のみに寄せ、APP_INITIALIZER 登録は task04 に一本化する（または逆方向に統合）。

### task06: UIエラー表示の実装責務漏れ (RP-012, Minor)

- task06 はテスト追加タスクだが、AppComponent 側の本体コード修正余地が残存。テストタスクに実装責務が混入している。
- **是正**: config-error 表示の実装責務は task04 へ移管。task06 はテスト追加のみに限定する。

### task05: demo spec 削除保証の漏れ (RP-018, Minor)

- `frontend/src/app/__demo__` の削除が後続タスクで漏れる構造。
- **是正**: task05 完了条件に `test ! -d frontend/src/app/__demo__` を追加し、親エージェント検証ゲートにも組み込む。

### task07: scripts 責務の曖昧さ (RP-011, Minor)

- task10 は `wait-floci-healthy.sh` を明確に呼び出すが、task07 では新規追加の対象ファイル/完了条件として明記されていない。
- **是正**: task07 の対象ファイル・完了条件に `scripts/wait-floci-healthy.sh` 新規追加を明記し、未起動時 timeout exit 1 の RED も含める。

## 設計カバレッジ

- 主要設計項目はカバー済み。ただし上記の責務境界矛盾により、実装フェーズで重複作業/抜け漏れが発生するリスクがある。

## タスク重複チェック

- 直接的な重複なし。ただし task03-01 ↔ task04（APP_INITIALIZER）、task04 ↔ task06（UIエラー表示）に責務境界の重なりあり。
