# 02. 技術的妥当性（round 2）

## 概要

| 項目 | 内容 |
|------|------|
| ラウンド | 2 |
| レビュー観点 | アーキテクチャ・技術選定・実装宣言の整合性 |

## 1. round1 指摘の対応確認

| 関連 ID | round1 指摘要旨 | round2 反映先 | 状態 |
|---------|------------------|----------------|------|
| DR-005 | ASL Retry 整合性 | `02_interface-api-design.md §5`、`04_process-flow-design.md` | ✅ resolved |
| DR-006 | Terraform provider 完全 HCL | `02_interface-api-design.md §6.1` | ✅ resolved |
| DR-009 | IAM 最小権限 | `02_interface-api-design.md §6.3` | ✅ resolved |
| DR-010 | Lambda 完全属性 | `02_interface-api-design.md §6.4` | ✅ resolved |
| DR-011 | API GW deployment triggers / lifecycle | `02_interface-api-design.md §6.5` | ✅ resolved |

## 2. round2 新規確認

### 2.1 Function クラス宣言の整合性（DR2-003）

`02_interface-api-design.md §3.1` で `public sealed class Function` と宣言され、同 `§3.2` で `public sealed partial class Function` を再宣言している。C# では同一クラスを `partial` ありなしで分割宣言することはできず、コンパイルエラー（CS0260: 部分宣言は partial 修飾子を欠いている）となる。サンプル参照実装としても誤った宣言は読者を混乱させるため、両方を `public sealed partial class Function` に統一する必要がある。

→ Minor: DR2-003 として新規起票。

### 2.2 その他

- ASL は `04_process-flow-design.md` で Retry/Catch を含む整合形に修正済み。Lambda ARN は jsonencode 例で `aws_lambda_function.persist_todo.arn` 等を動的参照する形が望ましいが、現行の static ARN 例でも floci 上では問題なく動作するため Info に留める。

## 3. 結論

技術選定・アーキテクチャ整合性は概ね良好。Function クラス宣言の partial 不整合 1 件（DR2-003、Minor）を除き、技術面での Critical/Major 指摘なし。
