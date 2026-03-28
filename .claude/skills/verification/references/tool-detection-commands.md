# ツール検出と実行コマンド

プロジェクト内で利用可能なツールを検出し実行します。

## テスト実行

```bash
test -f package.json && npm test
test -f pytest.ini && python -m pytest
test -f go.mod && go test ./...
test -f Cargo.toml && cargo test
test -f *.csproj && dotnet test
test -f Makefile && make test
```

## ビルド確認

```bash
test -f package.json && npm run build
test -f go.mod && go build ./...
test -f Cargo.toml && cargo build
test -f *.csproj && dotnet build
```

## リントチェック

```bash
test -f .eslintrc* && npx eslint .
test -f .flake8 && python -m flake8
test -f .golangci.yml && golangci-lint run
test -f Cargo.toml && cargo clippy
```

## 型チェック

```bash
test -f tsconfig.json && npx tsc --noEmit
test -f mypy.ini && python -m mypy .
```
