# テスト可能性レビュー

## 1. テスト設計

| 評価項目 | 判定 | コメント |
|----------|------|----------|
| コンポーネントの独立テスト可能性 | ⚠️ | api-handler と ValidateTodo の責務分離が曖昧（**DR-002**）なため UT/IT が二重化または欠落するリスク。 |
| テスト計画の網羅性 | ⚠️ | 単体/結合/E2E のレイヤ分けは妥当だが、**DR-013**（description 正規化 UT）、**DR-015**（IT のテーブル準備方式）の確定が必要。 |
| テストデータ設計の妥当性 | ⚠️ | id 生成位置が確定しないため POST レスポンスの id と GET リクエストの id を結合する E2E 期待値が一意に決まらない（**DR-002**）。 |
| 弊害検証計画の十分性 | ⚠️ | **DR-016**: var.endpoint と FLOCI_HOSTNAME の混入検証観点がない。**DR-001** に対する「実 AWS 接続なし」を確認するテスト観点が欠落。 |

## 2. テストレイヤごとの懸念

### 2.1 単体テスト（xUnit）
- description 正規化（DR-013）の期待値を明確化した UT が未計画。
- AWS_ENDPOINT_URL 未設定時に起動失敗となる fail-fast UT（DR-001）を追加すべき。

### 2.2 結合テスト（Lambda + AWS SDK）
- DR-015: テーブル作成方式（Terraform vs AWSSDK CreateTableAsync）が二択のまま。xUnit fixture に固定する必要あり。
- DR-002: ValidateTodo IT の入出力 DTO に id を含めるか否かで期待値が変わる。

### 2.3 E2E（API GW 経由）
- DR-007/DR-008/DR-012: CI 環境（docker-compose, Runner privileged 前提）が固定されないと E2E の実行可能性が担保できない。
- AC7 検証として、E2E ジョブ実行中に `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` が外部 AWS 向きで使われないこと（dummy 値で動作）を verify するテスト観点が欠落。

## 3. 判定

テスト計画の枠組みは存在するが、設計矛盾（DR-002）と環境定義不足（DR-007/008/012）に依存しており、現状のテスト計画は **そのままでは実装/検証段階で破綻する**。設計修正と同時にテスト期待値・fixture 方式の固定が必要。
