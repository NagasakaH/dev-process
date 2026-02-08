# タスクプロンプトテンプレート

各タスク（task0X.md）用のプロンプトテンプレート。

---

## 基本テンプレート

```markdown
# タスク: {task-id} - {タスク名}

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | {task-id} |
| タスク名 | {タスク名} |
| 前提条件タスク | {prerequisite-task-ids} または なし |
| 並列実行可否 | 可（{並列グループメンバー}と並列） / 不可 |
| 推定所要時間 | {hours}時間 |
| 優先度 | 高 / 中 / 低 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/{リクエスト名}-{task-id}/
- **ブランチ**: {リクエスト名}-{task-id}
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| {prerequisite-task-id} | {path-to-result} | {参照すべき内容} |

### 確認事項

- [ ] 前提タスクが完了していること
- [ ] 前提タスクの成果物が存在すること
- [ ] 前提タスクのコミットがcherry-pick済みであること

---

## 作業内容

### 目的

{このタスクで達成すること}

### 設計参照

設計内容は以下を参照:

- [dev-design/01_implementation-approach.md](../dev-design/01_implementation-approach.md)
- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md)
- [dev-design/03_data-structure-design.md](../dev-design/03_data-structure-design.md)
- [dev-design/04_process-flow-design.md](../dev-design/04_process-flow-design.md)

### 実装ステップ

1. {作業ステップ1}
2. {作業ステップ2}
3. {作業ステップ3}

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/xxx.ts` | 新規作成 | {説明} |
| `src/yyy.ts` | 修正 | {説明} |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**目的**: 実装前に失敗するテストを先に書く

**テストファイル**: `tests/{feature}.test.ts`

**テストケース**:

```typescript
describe('{Feature}', () => {
  test('should {expected behavior 1}', () => {
    // Arrange
    const input = {/* input data */};
    
    // Act
    const result = fn(input);
    
    // Assert
    expect(result).toBe(/* expected */);
  });

  test('should {expected behavior 2}', () => {
    // Arrange
    const input = {/* input data */};
    
    // Act
    const result = fn(input);
    
    // Assert
    expect(result).toEqual(/* expected */);
  });

  test('should handle error when {error condition}', () => {
    // Arrange
    const invalidInput = {/* invalid data */};
    
    // Act & Assert
    expect(() => fn(invalidInput)).toThrow(/* expected error */);
  });
});
```

**確認コマンド**:

```bash
cd /tmp/{リクエスト名}-{task-id}/
npm test -- --grep "{Feature}"
# 結果: FAIL（まだ実装がないため）
```

---

### GREEN: 最小限の実装

**目的**: テストを通過する最小限のコードを書く

**実装ファイル**: `src/{feature}.ts`

**実装内容**:

```typescript
// 最小限の実装例
export function fn(input: InputType): OutputType {
  // テストを通過する最小限の実装
  // 最適化やリファクタリングはREFACTORフェーズで行う
}
```

**確認コマンド**:

```bash
cd /tmp/{リクエスト名}-{task-id}/
npm test -- --grep "{Feature}"
# 結果: PASS
```

---

### REFACTOR: コード改善

**目的**: テストが通る状態を維持しながらコードを改善

**改善ポイント**:

- [ ] 重複コードの排除
- [ ] 可読性の向上
- [ ] パフォーマンス最適化
- [ ] 型安全性の向上
- [ ] エラーハンドリングの強化

**確認コマンド**:

```bash
cd /tmp/{リクエスト名}-{task-id}/
npm test  # 全テスト通過を確認
npm run lint  # リントチェック
npm run typecheck  # 型チェック
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| 実装コード | `src/{feature}.ts` | {説明} |
| テストコード | `tests/{feature}.test.ts` | {説明} |
| result.md | `{成果物出力先}/result.md` | タスク実行結果レポート |

### result.md に含める内容

- 実装完了状況
- 変更ファイル一覧
- テスト結果（通過数、カバレッジ）
- 品質チェック結果
- コミットハッシュ
- 次タスクへの依存情報

---

## 完了条件

### 機能的条件

- [ ] {機能的条件1}
- [ ] {機能的条件2}
- [ ] {機能的条件3}

### 品質条件

- [ ] 全テストが通過すること
- [ ] リントエラーがないこと
- [ ] 型エラーがないこと
- [ ] テストカバレッジが{X}%以上であること

### ドキュメント条件

- [ ] result.md が作成されていること
- [ ] 変更内容が適切にコメントされていること

---

## コミット

作業完了後、以下の手順でコミットを実行:

```bash
cd /tmp/{リクエスト名}-{task-id}/

# ステージング
git add -A

# 変更確認
git status
git diff --staged

# コミット
git commit -m "{task-id}: {変更内容の要約}

- {変更点1}
- {変更点2}
- {変更点3}"

# コミットハッシュ確認
git rev-parse HEAD
```

---

## 注意事項

- worktree内で作業すること
- TDDサイクル（RED → GREEN → REFACTOR）を守ること
- テストが通らない状態でコミットしないこと
- 前提タスクの成果物を必ず確認すること
- 並列タスクの場合、他タスクと同じファイルを編集しないこと
```

---

## タスク種別ごとのバリエーション

### 基盤準備タスク（task01系）

```markdown
## 作業内容

### 目的

開発環境・基盤コードの準備

### 実装ステップ

1. 開発環境のセットアップ確認
2. 必要なパッケージのインストール
3. 基盤となる型定義・インターフェースの作成
4. 設定ファイルの更新

### テスト方針

- 基盤コードの単体テスト
- 型定義の正当性確認
- 設定の動作確認
```

### API実装タスク（task0X系）

```markdown
## 作業内容

### 目的

APIエンドポイントの実装

### 設計参照

- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md)

### 実装ステップ

1. エンドポイントハンドラの作成
2. リクエスト検証の実装
3. ビジネスロジックの呼び出し
4. レスポンス生成

### テスト方針

- エンドポイントの単体テスト
- リクエスト検証のテスト
- エラーレスポンスのテスト
```

### データモデル実装タスク（task0X系）

```markdown
## 作業内容

### 目的

データモデル・エンティティの実装

### 設計参照

- [dev-design/03_data-structure-design.md](../dev-design/03_data-structure-design.md)

### 実装ステップ

1. 型定義・インターフェースの作成
2. エンティティクラスの実装
3. バリデーションロジックの実装
4. マイグレーションの作成（必要な場合）

### テスト方針

- エンティティの単体テスト
- バリデーションのテスト
- エッジケースのテスト
```

### 統合テストタスク（task0X系）

```markdown
## 作業内容

### 目的

複数コンポーネントの統合テスト

### 設計参照

- [dev-design/05_test-plan.md](../dev-design/05_test-plan.md)

### 実装ステップ

1. 統合テストシナリオの確認
2. テストフィクスチャの準備
3. 統合テストの実装
4. テスト実行と結果確認

### テスト方針

- エンドツーエンドフローのテスト
- コンポーネント間連携のテスト
- 異常系シナリオのテスト
```

### 弊害検証タスク（task0X系）

```markdown
## 作業内容

### 目的

変更による弊害がないことを検証

### 設計参照

- [dev-design/06_side-effect-verification.md](../dev-design/06_side-effect-verification.md)

### 実装ステップ

1. 回帰テストの実行
2. パフォーマンス測定
3. 既存機能の動作確認
4. 弊害検証レポートの作成

### テスト方針

- 既存テストの全通過確認
- パフォーマンスベンチマーク
- 後方互換性の確認
```

---

## 使用方法

1. 上記テンプレートを `dev-plan/task{XX}.md` にコピー
2. `{...}` 部分を実際の値に置き換え
3. 設計内容に応じてセクションを追加・削除
4. TDDセクションを具体的なテストケースに更新
5. 完了条件をタスク固有の内容に更新
