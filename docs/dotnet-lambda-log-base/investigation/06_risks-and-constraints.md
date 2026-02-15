# リスク・制約分析

## リスク

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| Lambda タイムアウト時のログロスト | 高 | 中 | バッファサイズを小さく保ち、頻繁に Flush。try-finally で確実に Flush を呼ぶ |
| PutLogEvents API スロットリング | 中 | 低 | バッチ送信でAPI呼び出し回数を削減。エクスポネンシャルバックオフ |
| Delivery Class の制約 | 中 | 確実 | GetLogEvents/FilterLogEvents 使用不可。リアルタイム検索が必要な場合は Standard を使用 |

## 制約

### CloudWatch Logs Delivery Class の制約
- **保持期間が2日固定**: Delivery Class のログは2日で自動削除
- **GetLogEvents/FilterLogEvents 使用不可**: ログの直接取得ができない
- **Metric Filter 使用不可**: Delivery Class ではメトリクスフィルターが使えない
- → 異常系ログは Standard Class に送信することで回避済み

### PutLogEvents API の制約
- 最大バッチサイズ: 1MB
- 最大イベント数: 10,000/バッチ
- イベント順序: タイムスタンプ昇順必須
- → バッファリングで対応

### Lambda 実行環境の制約
- 実行時間制限（最大15分）
- メモリ制限
- 一時ストレージ制限（512MB〜10GB）
- → ログバッファはメモリ内で管理し、定期的に Flush

## 技術的決定事項

1. **ログストリーム命名**: `{FunctionName}/{RequestId}/{Timestamp}` 形式で一意性を確保
2. **バッファ戦略**: メモリ内 ConcurrentQueue で管理、Lambda 実行ごとにリセット
3. **エラーハンドリング**: ログ送信失敗時はコンソール出力にフォールバック（ログ送信のエラーでアプリケーションを停止しない）
