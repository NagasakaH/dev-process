# タスク: task01 - プロジェクト基盤準備

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task01 |
| タスク名 | プロジェクト基盤準備 |
| 前提条件タスク | なし |
| 並列実行可否 | 不可 |
| 推定所要時間 | 1時間 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task01/
- **ブランチ**: opentelemetry-issue-1-task01
- **対象リポジトリ**: TracingSample（submodules/opentelemtry/TracingSample/）
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

なし（初期タスク）

### 確認事項

- [ ] TracingSample.slnがビルドできること
- [ ] 既存のテストが通過すること
- [ ] Jaegerが起動できること（オプション）

---

## 作業内容

### 目的

新規ヘルパークラス群を追加するためのプロジェクト構成確認と基盤コードの準備を行う。

### 設計参照

- [dev-design/01_implementation-approach.md](../dev-design/01_implementation-approach.md)
- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md)

### 実装ステップ

1. **プロジェクト構成確認**
   - TracingSample.Tracingプロジェクトの構造確認
   - 既存コードの確認（TraceAttribute, TracingProxy, ServiceCollectionExtensions）

2. **ディレクトリ準備**
   - `TracingSample.Tracing/Helpers/` ディレクトリ作成
   - `TracingSample.Tracing/Internal/` ディレクトリ作成

3. **基盤インターフェース/型定義**
   - `TracingOptions.cs` の作成（トレースオプション設定クラス）
   - `NoOpScope.cs` の作成（ActivitySource未設定時のフォールバック）

4. **テストプロジェクト確認/準備**
   - テストプロジェクトの有無確認
   - 必要に応じてテストプロジェクト作成

5. **ビルド確認**
   - ソリューション全体のビルド確認
   - 既存テストの実行確認

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/TracingSample.Tracing/Helpers/` | 新規作成 | ヘルパー用ディレクトリ |
| `src/TracingSample.Tracing/Internal/` | 新規作成 | 内部実装用ディレクトリ |
| `src/TracingSample.Tracing/Helpers/TracingOptions.cs` | 新規作成 | トレースオプション設定 |
| `src/TracingSample.Tracing/Internal/NoOpScope.cs` | 新規作成 | 空実装スコープ |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**目的**: TracingOptions とNoOpScope の基本動作を検証

**テストファイル**: `tests/TracingSample.Tracing.Tests/Unit/TracingOptionsTests.cs`

**テストケース**:

```csharp
namespace TracingSample.Tracing.Tests.Unit;

public class TracingOptionsTests
{
    [Fact]
    public void Default_HasExpectedValues()
    {
        // Arrange & Act
        var options = TracingOptions.Default;

        // Assert
        Assert.True(options.RecordParameters);
        Assert.True(options.RecordReturnValue);
        Assert.True(options.RecordException);
        Assert.Equal(5, options.MaxSerializationDepth);
        Assert.Equal(1.0, options.SamplingRate);
    }

    [Fact]
    public void SensitiveParameters_ContainsCommonSecrets()
    {
        // Arrange
        var options = TracingOptions.Default;

        // Assert
        Assert.Contains("password", options.SensitiveParameters, StringComparer.OrdinalIgnoreCase);
        Assert.Contains("apiKey", options.SensitiveParameters, StringComparer.OrdinalIgnoreCase);
        Assert.Contains("secret", options.SensitiveParameters, StringComparer.OrdinalIgnoreCase);
        Assert.Contains("token", options.SensitiveParameters, StringComparer.OrdinalIgnoreCase);
    }
}

public class NoOpScopeTests
{
    [Fact]
    public void Instance_IsSingleton()
    {
        // Act
        var instance1 = NoOpScope.Instance;
        var instance2 = NoOpScope.Instance;

        // Assert
        Assert.Same(instance1, instance2);
    }

    [Fact]
    public void Dispose_DoesNotThrow()
    {
        // Arrange
        var scope = NoOpScope.Instance;

        // Act & Assert
        var exception = Record.Exception(() => scope.Dispose());
        Assert.Null(exception);
    }
}
```

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task01/TracingSample
dotnet test --filter "FullyQualifiedName~TracingOptionsTests|FullyQualifiedName~NoOpScopeTests"
# 結果: FAIL（まだ実装がないため）
```

---

### GREEN: 最小限の実装

**目的**: テストを通過する最小限のコードを書く

**実装ファイル1**: `src/TracingSample.Tracing/Helpers/TracingOptions.cs`

```csharp
namespace TracingSample.Tracing.Helpers;

/// <summary>
/// トレースの動作オプションを定義します。
/// </summary>
public class TracingOptions
{
    /// <summary>
    /// デフォルトのオプション
    /// </summary>
    public static TracingOptions Default { get; } = new TracingOptions();

    /// <summary>
    /// パラメータを記録するかどうか
    /// </summary>
    public bool RecordParameters { get; set; } = true;

    /// <summary>
    /// 戻り値を記録するかどうか
    /// </summary>
    public bool RecordReturnValue { get; set; } = true;

    /// <summary>
    /// 例外を記録するかどうか
    /// </summary>
    public bool RecordException { get; set; } = true;

    /// <summary>
    /// JSONシリアライズの最大深度
    /// </summary>
    public int MaxSerializationDepth { get; set; } = 5;

    /// <summary>
    /// 機密パラメータ名のセット（自動マスク対象）
    /// </summary>
    public HashSet<string> SensitiveParameters { get; set; } = new(StringComparer.OrdinalIgnoreCase)
    {
        "password", "secret", "token", "apiKey", "apikey", "api_key",
        "accessToken", "access_token", "refreshToken", "refresh_token",
        "connectionString", "connection_string", "credentials"
    };

    /// <summary>
    /// 機密情報のマスク文字列
    /// </summary>
    public string SensitiveMask { get; set; } = "***MASKED***";

    /// <summary>
    /// サンプリングレート（0.0-1.0）
    /// </summary>
    public double SamplingRate { get; set; } = 1.0;
}
```

**実装ファイル2**: `src/TracingSample.Tracing/Internal/NoOpScope.cs`

```csharp
namespace TracingSample.Tracing.Internal;

/// <summary>
/// 何もしないスコープ（ActivitySource未設定時のフォールバック）
/// </summary>
internal sealed class NoOpScope : IDisposable
{
    /// <summary>
    /// シングルトンインスタンス
    /// </summary>
    public static NoOpScope Instance { get; } = new NoOpScope();

    private NoOpScope() { }

    /// <summary>
    /// 何もしない
    /// </summary>
    public void Dispose()
    {
        // 意図的に空実装
    }
}
```

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task01/TracingSample
dotnet test --filter "FullyQualifiedName~TracingOptionsTests|FullyQualifiedName~NoOpScopeTests"
# 結果: PASS
```

---

### REFACTOR: コード改善

**目的**: テストが通る状態を維持しながらコードを改善

**改善ポイント**:

- [ ] XMLドキュメントの追加
- [ ] nullability 属性の追加
- [ ] 命名規則の確認

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task01/TracingSample
dotnet build  # ビルド確認
dotnet test   # 全テスト通過を確認
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| TracingOptions.cs | `src/TracingSample.Tracing/Helpers/TracingOptions.cs` | オプション設定クラス |
| NoOpScope.cs | `src/TracingSample.Tracing/Internal/NoOpScope.cs` | 空実装スコープ |
| テストコード | `tests/TracingSample.Tracing.Tests/Unit/` | 単体テスト |
| result.md | `docs/opentelemtry/dev-plan/results/task01-result.md` | タスク実行結果 |

### result.md に含める内容

- 実装完了状況
- 変更ファイル一覧
- テスト結果（通過数）
- ビルド確認結果
- コミットハッシュ
- 次タスクへの依存情報

---

## 完了条件

### 機能的条件

- [ ] Helpersディレクトリが作成されている
- [ ] Internalディレクトリが作成されている
- [ ] TracingOptionsクラスが作成され、デフォルト値が設定されている
- [ ] NoOpScopeクラスがシングルトンパターンで実装されている

### 品質条件

- [ ] ソリューション全体がビルドできること
- [ ] 既存テストが全て通過すること
- [ ] 新規テストが通過すること
- [ ] リントエラーがないこと

### ドキュメント条件

- [ ] result.md が作成されていること
- [ ] コードにXMLドキュメントがあること

---

## コミット

作業完了後、以下の手順でコミットを実行:

```bash
cd /tmp/opentelemetry-issue-1-task01/TracingSample

# ステージング
git add -A

# 変更確認
git status
git diff --staged

# コミット
git commit -m "task01: プロジェクト基盤準備

- Helpers/ディレクトリ作成
- Internal/ディレクトリ作成
- TracingOptions: トレースオプション設定クラス追加
- NoOpScope: フォールバック用空実装スコープ追加
- 単体テスト追加"

# コミットハッシュ確認
git rev-parse HEAD
```

---

## 注意事項

- worktree内で作業すること
- 既存のコードは変更しないこと
- 新規追加のみ行うこと
- ビルドが通ることを確認してからコミットすること
