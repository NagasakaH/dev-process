# 設計実施項目の詳細

## 1. 実装方針決定（01_implementation-approach.md）

- 調査結果に基づいた最適なアプローチの選定
- 代替案の比較検討
- 採用理由の明確化
- 技術選定の根拠

## 2. インターフェース/API設計（02_interface-api-design.md）

- 公開API・エンドポイントの設計
- 関数シグネチャの定義
- リクエスト/レスポンス形式
- エラーハンドリング方式

## 3. データ構造設計（03_data-structure-design.md）

- エンティティ・モデルの設計
- スキーマ変更の定義
- 型定義・インターフェースの設計
- マイグレーション計画

## 4. 処理フロー設計（04_process-flow-design.md）

- シーケンス図（修正前/修正後の対比）
- 状態遷移図
- エラーフローの定義
- 非同期処理フロー

## 5. テスト計画（05_test-plan.md）

- 新規テストケースの洗い出し
- 既存テストの修正が必要なもの
- テスト方針（単体/結合/E2E）
- テストデータ設計
- **事前に決定されたテスト戦略を必ず参照し、定義されたテスト範囲を全て計画に含めること**
- **E2Eテストがスコープに含まれる場合**: E2Eテストの具体的な実行手順、対象環境、判定基準を記載
- **acceptance_criteria との対応表**: 各 acceptance_criteria をどのテスト種別（単体/結合/E2E）で検証するかを明記

## 6. 弊害検証計画（06_side-effect-verification.md）

- 副作用が発生しやすい箇所の特定
- 弊害検証として実行すべきテスト
- パフォーマンス検証項目
- セキュリティ検証項目
- 互換性検証項目

## 出力ファイル構成

設計結果は `docs/{target_repository}/design/` に出力：

```
docs/
└── {target_repository}/
    └── design/
        ├── 01_implementation-approach.md    # 実装方針
        ├── 02_interface-api-design.md       # インターフェース/API設計
        ├── 03_data-structure-design.md      # データ構造設計
        ├── 04_process-flow-design.md        # 処理フロー設計
        ├── 05_test-plan.md                  # テスト計画
        └── 06_side-effect-verification.md   # 弊害検証計画
```
