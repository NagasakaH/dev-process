# MCP連携によるチケット情報取得の詳細

チケットIDのフォーマットに応じて、適切なMCPを使用してチケット情報を取得してください。

## GitHub Issues（MCPが利用可能な場合）

チケットIDが数値のみの場合、GitHub MCPの `github-mcp-server-issue_read` を使用：

```
method: get
owner: {リポジトリオーナー}
repo: {リポジトリ名}
issue_number: {チケットID}
```

## GitLab Issues（MCPが利用可能な場合）

GitLab MCPが利用可能な場合、該当するツールでIssue情報を取得してください。

## Jira（Atlassian MCPが利用可能な場合）

チケットIDが `PROJ-123` 形式の場合、Atlassian/Jira MCPを使用してチケット情報を取得してください。

## Redmine（Redmine MCPが利用可能な場合）

Redmine MCPが利用可能な場合、該当するツールでチケット情報を取得してください。

## MCPが利用できない場合

ブランチ名から推測できる情報のみを使用してコミットメッセージを生成してください。

- チケットID: ブランチ名から抽出したID
- タイトル: ブランチ名のID以降の部分をタイトルとして使用（ハイフンをスペースに置換）
