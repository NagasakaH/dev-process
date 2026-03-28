# 使用例リファレンス

## JSON コマンドの生成例

ツールを特定したら、以下の形式で JSON コマンドを生成する。

```json
{
  "tool": "ExecuteTerraformCommand",
  "arguments": {
    "command": "plan",
    "working_directory": "/path/to/terraform",
    "aws_region": "ap-northeast-1"
  }
}
```

## executor.py での実行

```bash
cd /workspaces/dev-process/.claude/skills/terraform
python executor.py --call '{"tool": "ExecuteTerraformCommand", "arguments": {"command": "plan", "working_directory": "/path/to/terraform", "aws_region": "ap-northeast-1"}}'
```

## ツール詳細の確認

特定ツールの引数仕様を確認するには `--describe` を使用する。

```bash
cd /workspaces/dev-process/.claude/skills/terraform
python executor.py --describe ExecuteTerraformCommand
```

## エラー対応

| エラー | 対処 |
|--------|------|
| `mcp package not found` | `pip install mcp` を実行 |
| Terraform未インストール | `terraform` コマンドがPATH上にあるか確認 |
| Checkov未インストール | `pip install checkov` を実行 |
