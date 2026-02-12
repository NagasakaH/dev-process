---
name: writing-skills
description: スキルファイル（.claude/skills/*/SKILL.md）の作成・編集時に使用。適切な構造、テスト方法、命名規則でスキル作成をガイドする。「スキル作成」「SKILL.md書いて」などのフレーズで発動。
---

# スキル作成スキル

スキルはAIエージェントへの指示です。TDDのように扱ってください：望む振る舞いを定義し、スキルを書き、シナリオでテストします。

## 主要機能

- YAMLフロントマターの作成（name, description必須）
- スキル構造の定義（Overview, When to Use, The Process, Integration）
- 命名規則の適用（kebab-case、説明的、略語なし）
- シナリオテストの実施

## スキルの形式

```markdown
---
name: skill-name
description: [trigger condition]で使用 - [スキルの内容]
---

# スキルタイトル

## 概要
[1-2文。このスキルの内容と理由]

## 使用タイミング
[具体的なトリガーと条件]

## プロセス
[ステップバイステップの指示]

## 関連スキル
[他のスキルとの接続]
```

## 品質チェックリスト

- [ ] フロントマターに`name`と`description`がある
- [ ] descriptionが「Use when」または使用条件で始まる
- [ ] 概要が2文以内
- [ ] プロセスステップが番号付きで明確
- [ ] レッドフラグセクションがある
- [ ] 関連スキルセクションがある

## 使用タイミング

- 新しいスキルの作成
- 既存スキルの編集
- dev-process用スキルの追加

## 関連スキル

- `skill-usage-protocol` - スキル発見のプロトコル
