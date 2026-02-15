# タスク: task01 - .NET プロジェクト基盤セットアップ

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task01 |
| タスク名 | .NET プロジェクト基盤セットアップ |
| 前提条件タスク | なし |
| 並列実行可否 | 可（task06 と並列） |
| 推定所要時間 | 10分 |

## 作業内容

### 目的

.NET 8 Lambda プロジェクトの基盤構造（ソリューション、プロジェクト、テストプロジェクト）を作成する。

### 実装ステップ

1. ソリューションファイル `DotnetLambdaLogBase.sln` を作成
2. Lambda 関数プロジェクト `src/DotnetLambdaLogBase/` を作成（classlib として。Lambda ハンドラーは task05 で実装）
3. ログライブラリプロジェクト `src/DotnetLambdaLogBase.Logging/` を作成
4. テストプロジェクト `tests/DotnetLambdaLogBase.Logging.Tests/` を作成
5. プロジェクト参照を追加
6. NuGet パッケージを追加
7. ビルド確認

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `DotnetLambdaLogBase.sln` | 新規作成 | ソリューション |
| `src/DotnetLambdaLogBase/DotnetLambdaLogBase.csproj` | 新規作成 | Lambda プロジェクト |
| `src/DotnetLambdaLogBase.Logging/DotnetLambdaLogBase.Logging.csproj` | 新規作成 | ログライブラリ |
| `tests/DotnetLambdaLogBase.Logging.Tests/DotnetLambdaLogBase.Logging.Tests.csproj` | 新規作成 | テスト |

### NuGet パッケージ

**ログライブラリ:**
- Microsoft.Extensions.Logging.Abstractions
- Microsoft.Extensions.DependencyInjection.Abstractions
- AWSSDK.CloudWatchLogs
- System.Text.Json（.NET 8 組み込み）

**Lambda:**
- Amazon.Lambda.Core
- Amazon.Lambda.Serialization.SystemTextJson
- プロジェクト参照: DotnetLambdaLogBase.Logging

**テスト:**
- xunit
- xunit.runner.visualstudio
- Microsoft.NET.Test.Sdk
- Moq
- coverlet.collector
- プロジェクト参照: DotnetLambdaLogBase.Logging

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 基盤確認テスト

```csharp
// tests/DotnetLambdaLogBase.Logging.Tests/SanityTests.cs
public class SanityTests
{
    [Fact]
    public void Project_ShouldBuild()
    {
        Assert.True(true); // プロジェクト構造の確認
    }
}
```

### GREEN: プロジェクト作成

dotnet CLI でプロジェクト作成・参照追加・ビルド成功を確認。

## 完了条件

- [ ] `dotnet build` が成功すること
- [ ] `dotnet test` が成功すること（SanityTest）
- [ ] 全プロジェクト参照が正しいこと
- [ ] NuGet パッケージが追加されていること
