# 依存関係調査

## NuGet パッケージ依存関係

```mermaid
graph TD
    subgraph Lambda["DotnetLambdaLogBase（Lambda関数）"]
        LC[Amazon.Lambda.Core 2.8.1]
        LS[Amazon.Lambda.Serialization.SystemTextJson 2.4.5]
        DI[Microsoft.Extensions.DependencyInjection 8.0.1]
        LOG[Microsoft.Extensions.Logging 8.0.1]
    end

    subgraph Logging["DotnetLambdaLogBase.Logging（ライブラリ）"]
        CWL[AWSSDK.CloudWatchLogs 3.7.408.2]
        DIA[Microsoft.Extensions.DependencyInjection.Abstractions 8.0.2]
        LOGA[Microsoft.Extensions.Logging.Abstractions 8.0.2]
    end

    subgraph Tests["DotnetLambdaLogBase.Logging.Tests"]
        XU[xunit 2.5.3]
        XR[xunit.runner.visualstudio 2.5.3]
        MS[Microsoft.NET.Test.Sdk 17.8.0]
        MOQ[Moq 4.20.72]
        COV[coverlet.collector 6.0.0]
    end

    Lambda -->|ProjectReference| Logging
    Tests -->|ProjectReference| Logging
```

## E2E テストで修正されたバージョン互換性

| パッケージ | 修正前 | 修正後 | 理由 |
|---|---|---|---|
| AWSSDK.CloudWatchLogs | 4.0.14.5 | 3.7.408.2 | v4 は .NET 9+ 必須 |
| Microsoft.Extensions.DependencyInjection | 10.0.3 | 8.0.1 | v10 は .NET 10 Preview |
| Microsoft.Extensions.Logging | 10.0.3 | 8.0.1 | 同上 |
| Microsoft.Extensions.DependencyInjection.Abstractions | 10.0.3 | 8.0.2 | 同上 |
| Microsoft.Extensions.Logging.Abstractions | 10.0.3 | 8.0.2 | 同上 |

## Terraform プロバイダ依存

| プロバイダ | バージョン | 用途 |
|---|---|---|
| hashicorp/aws | ~> 5.0 | AWS リソース管理 |
| terraform | >= 1.0 | IaC エンジン |
