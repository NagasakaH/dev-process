---
name: session-jsonl-analyzer
description: セッションJSONLファイルの特定と解析を行う汎用スキル。現在のセッションまたは指定セッションのイベントログを解析し、ツール呼び出し履歴・サブエージェント実行履歴等を抽出する。「セッション解析」「JSONL解析」「ツール呼び出し履歴」「session-jsonl-analyzer」などのフレーズで発動。
---

# セッションJSONL解析スキル

Copilot CLIのセッションイベントログ（JSONL形式）を解析する汎用スキル。解析結果の利用方法（判定・レポート生成等）は呼び出し側が決定する。

## 主要機能

1. **セッションJSONLファイルの自動特定** — 現在または指定セッションの `events.jsonl` を検出
2. **イベント型別フィルタリング** — 任意のイベント型を抽出
3. **ツール呼び出し履歴の抽出** — ツール名・引数・結果を一覧化
4. **サブエージェント実行履歴** — 開始/完了イベントの対応付け
5. **統計・集計** — ツール呼び出し回数、イベント種別カウント等

## セッションJSONLファイルの特定方法

### パス構造

```
~/.copilot/session-state/{session-uuid}/events.jsonl
```

### 現在のセッションの特定

最終更新日時が最新の `events.jsonl` を取得する:

```bash
ls -t ~/.copilot/session-state/*/events.jsonl | head -1
```

### 特定セッションの指定

session-uuid がわかっている場合は直接アクセス:

```bash
cat ~/.copilot/session-state/{session-uuid}/events.jsonl
```

### セッション一覧の確認

```bash
# 更新日時順にセッション一覧
ls -lt ~/.copilot/session-state/*/events.jsonl
```

## イベント型一覧

| イベント型 | 説明 | 主要フィールド |
|---|---|---|
| `session.start` | セッション開始 | `sessionId`, `copilotVersion`, `context` |
| `session.shutdown` | セッション終了 | — |
| `session.plan_changed` | プラン変更 | プラン情報 |
| `user.message` | ユーザー入力 | メッセージ内容 |
| `assistant.message` | アシスタント応答 | `toolRequests` |
| `assistant.turn_start` | ターン開始 | — |
| `assistant.turn_end` | ターン終了 | — |
| `tool.execution_start` | ツール実行開始 | `toolName`, `arguments` |
| `tool.execution_complete` | ツール実行完了 | `success`, `result` |
| `subagent.started` | サブエージェント開始 | エージェント情報 |
| `subagent.completed` | サブエージェント完了 | 結果情報 |
| `skill.invoked` | スキル発動 | `name`, `path`, `description` |
| `hook.start` | フック実行開始 | フック情報 |
| `hook.end` | フック実行完了 | 結果情報 |
| `system.notification` | システム通知 | 通知内容 |
| `abort` | 中断 | — |

📖 各イベント型の詳細スキーマは [references/event-schema.md](references/event-schema.md) を参照

## 解析パターン

### ツール呼び出し一覧の抽出

```bash
JSONL=$(ls -t ~/.copilot/session-state/*/events.jsonl | head -1)
grep '"type":"tool.execution_start"' "$JSONL" | python3 -c "
import sys, json
for l in sys.stdin:
    d = json.loads(l)['data']
    print(d['toolName'], d.get('arguments', {}))
"
```

### 特定ツールの呼び出しフィルタ

```bash
# 例: skill ツールの呼び出しのみ抽出
grep '"type":"tool.execution_start"' "$JSONL" | python3 -c "
import sys, json
for l in sys.stdin:
    e = json.loads(l)
    if e['data']['toolName'] == 'skill':
        print(json.dumps(e, ensure_ascii=False, indent=2))
"
```

### skill ツールの呼び出しスキル名抽出

```bash
grep '"type":"tool.execution_start"' "$JSONL" | python3 -c "
import sys, json
for l in sys.stdin:
    d = json.loads(l)['data']
    if d['toolName'] == 'skill':
        print(d.get('arguments', {}).get('skill', '(unknown)'))
"
```

### サブエージェント実行履歴

```bash
grep -E '"type":"subagent\.(started|completed)"' "$JSONL" | python3 -c "
import sys, json
for l in sys.stdin:
    e = json.loads(l)
    print(e['type'], json.dumps(e['data'], ensure_ascii=False))
"
```

### ツール呼び出し統計（ツール名別カウント）

```bash
grep '"type":"tool.execution_start"' "$JSONL" | python3 -c "
import sys, json
from collections import Counter
counts = Counter(json.loads(l)['data']['toolName'] for l in sys.stdin)
for name, cnt in counts.most_common():
    print(f'{cnt:4d}  {name}')
"
```

### 時系列イベントフロー

```bash
python3 -c "
import json
with open('$(ls -t ~/.copilot/session-state/*/events.jsonl | head -1)') as f:
    for line in f:
        e = json.loads(line)
        ts = e.get('timestamp', '')
        print(f\"{ts}  {e['type']}\")
"
```

### エラー/失敗イベントの抽出

```bash
grep '"type":"tool.execution_complete"' "$JSONL" | python3 -c "
import sys, json
for l in sys.stdin:
    e = json.loads(l)
    if not e['data'].get('success', True):
        err = e['data'].get('error', {})
        print(e['data'].get('toolCallId', ''), err.get('message', '')[:200])
"
```

### ユーザーメッセージ一覧

```bash
grep '"user.message"' "$JSONL" | python3 -c "
import sys, json
for i, l in enumerate(sys.stdin, 1):
    e = json.loads(l)
    msg = str(e.get('data', {}).get('content', ''))[:100]
    print(f'{i}. {msg}')
"
```

## 出力形式

呼び出し側が指定する。デフォルトは構造化テキスト。

- **構造化テキスト**（デフォルト）— 人間が読みやすい形式
- **JSON** — プログラム的に後処理する場合
- **テーブル** — 統計・集計結果の表示

## 使用タイミング

- セッション中のツール呼び出し履歴を確認したいとき
- スキルの発動状況を振り返りたいとき
- サブエージェントの実行パターンを分析したいとき
- セッションのイベントフローを可視化したいとき
- デバッグ目的でセッションログを調査したいとき

## 関連スキル

- `systematic-debugging` — セッションログからバグの根本原因を調査する際に併用
- `verification-before-completion` — 作業完了前にセッション内の実行結果を確認
