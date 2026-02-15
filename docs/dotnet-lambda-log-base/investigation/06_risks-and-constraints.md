# リスク・制約分析

## ドキュメント作成に関するリスク

| リスク | 影響度 | 対策 |
|---|---|---|
| Mermaid 図が GitHub でレンダリングされない | 中 | GitHub 公式サポートの構文のみ使用 |
| 課金情報が古くなる可能性 | 低 | 参照日を記載、AWS 公式ドキュメントへのリンクを付与 |
| テスト項目・結果がコードと乖離する可能性 | 低 | 実際のテストコード・テストレポートから正確に転記 |

## 技術的制約（ドキュメントに記載すべき事項）

### DELIVERY class の制約
- 保持期間 2 日間固定（変更不可）
- GetLogEvents / FilterLogEvents 使用不可
- Metric Filter / Subscription Filter（S3以外）使用不可
- S3 への自動配信が主な用途

### Lambda コンテナ再利用
- ServiceProvider.DisposeAsync() 禁止（FlushAsync パターン必須）
- コンストラクタは初回呼び出し時のみ実行

### PutLogEvents API 制限
- バッチ 1MB / 10,000 件上限
- 個別イベント 256KB 上限
