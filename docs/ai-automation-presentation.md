---
marp: true
theme: default
paginate: true
---

<style>
@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap');

:root {
  --color-background: #ffffff;
  --color-foreground: #1f2937;
  --color-heading: #1e40af;
  --color-accent: #3b82f6;
  --color-code-bg: #f3f4f6;
  --color-border: #d1d5db;
  --font-default: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Meiryo', sans-serif;
  --font-code: 'Fira Code', 'Consolas', 'Monaco', monospace;
}

section {
  background-color: var(--color-background);
  color: var(--color-foreground);
  font-family: var(--font-default);
  font-weight: 400;
  box-sizing: border-box;
  border-top: 8px solid var(--color-heading);
  position: relative;
  line-height: 1.7;
  font-size: 20px;
  padding: 56px;
}

h1, h2, h3, h4, h5, h6 {
  font-weight: 700;
  color: var(--color-heading);
  margin: 0;
  padding: 0;
}

h1 {
  font-size: 48px;
  line-height: 1.3;
  text-align: left;
}

h2 {
  position: absolute;
  top: 40px;
  left: 56px;
  right: 56px;
  font-size: 36px;
  padding-bottom: 14px;
  border-bottom: 3px solid var(--color-accent);
}

h2 + * {
  margin-top: 108px;
}

h3 {
  color: var(--color-accent);
  font-size: 22px;
  margin-top: 24px;
  margin-bottom: 8px;
  font-weight: 600;
}

ul, ol {
  padding-left: 32px;
}

li {
  margin-bottom: 8px;
}

pre {
  background-color: var(--color-code-bg);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 16px;
  font-family: var(--font-code);
  font-size: 15px;
  line-height: 1.5;
}

code {
  background-color: #eff6ff;
  color: var(--color-heading);
  padding: 2px 6px;
  border-radius: 3px;
  font-family: var(--font-code);
  font-size: 0.9em;
}

pre code {
  background-color: transparent;
  color: var(--color-foreground);
}

footer {
  font-size: 14px;
  color: #6b7280;
  position: absolute;
  left: 56px;
  right: 56px;
  bottom: 36px;
  text-align: right;
}

section.lead {
  border-top: 8px solid var(--color-heading);
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: linear-gradient(135deg, #ffffff 0%, #eff6ff 100%);
}

section.lead h1 {
  margin-bottom: 24px;
}

section.lead p {
  font-size: 22px;
  color: var(--color-foreground);
  font-weight: 500;
}

strong {
  color: var(--color-heading);
  font-weight: 700;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 18px;
}

th {
  background-color: var(--color-heading);
  color: #ffffff;
  padding: 10px 16px;
  border: 1px solid var(--color-border);
  font-weight: 700;
}

td {
  padding: 10px 16px;
  border: 1px solid var(--color-border);
  background-color: #ffffff;
  color: var(--color-foreground);
}

tr:nth-child(even) td {
  background-color: #f9fafb;
}

.flow {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 20px 0;
  justify-content: center;
}

.flow-step {
  background-color: #eff6ff;
  border: 2px solid var(--color-accent);
  border-radius: 8px;
  padding: 10px 18px;
  color: var(--color-foreground);
  font-size: 17px;
  text-align: center;
  line-height: 1.5;
}

.flow-arrow {
  color: var(--color-accent);
  font-size: 24px;
  font-weight: bold;
  flex-shrink: 0;
}

.vflow {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  margin: 16px 0;
}

.vflow .flow-step {
  width: 72%;
}

.hpair {
  display: flex;
  gap: 16px;
  width: 72%;
}

section.skills {
  padding: 38px 30px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

section.skills h2 {
  left: 30px;
  right: 30px;
  top: 30px;
}

section.skills h2 + * {
  margin-top: 52px;
}
</style>



<!-- _class: lead -->

# 生成AIを使った業務の自動化事例紹介

生成AIでソフトウェア開発ワークフローを自律実行する

---
## アジェンダ

- **AIで自動化するアプローチ**: ツール連携・スキル化・オーケストレーションの3つの柱
- **ツール連携**: AIにシステム操作手段を与える
- **現状の業務フロー**: 今回の自動化範囲
- **ワークフローの説明**: 7フェーズの詳細と各スキルの役割
- **スキル・エージェントを育てる**: 継続的改善サイクル
---

## AIで自動化するアプローチ

> **人間がやっていた各ステップをAIが実行できる単位に分解する**

### 3つの柱

- **ツール連携**: AIにシステムを操作する手段を与える
- **スキル化**: 各作業をAIが実行できる単位に分解
- **オーケストレーション**: スキルをつなげてAIにやり切らせる

---

## AIにシステム操作手段を与える

> ツールがなければAIは外の世界と対話できない

### 連携システム

| システム | 操作できること |
|---------|--------------|
| **GitLab** | リポジトリ構造把握・Issue取得・MR作成 |
| **Jira** | チケット取得・進捗更新・ステータス変更 |
| **プロジェクトツール** | プロジェクト固有ツールの操作 |

### 重要な原則
- APIを通じてシステムを操作するスキルを整備する
- スキルは**再利用可能**な単位で設計する

---

## 現状の業務フロー

<div class="flow">
  <div class="flow-step">マイルストーン設定</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step">作業分割<br>(Jiraチケット化)</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step" style="border-color:#16a34a; background:#dcfce7; color:#166534; position:relative;">
    計画を立てて<br>チケットを順番に実行
    <br><small style="color:#16a34a; font-size:13px; font-weight:bold;">今回の自動化範囲</small>
  </div>
</div>

### チケット1件の実行フロー

<div style="border:2px solid #16a34a; border-radius:8px; overflow:hidden; font-size:16px;">
<div style="display:flex; background:#15803d; color:#fff; font-weight:700;">
<div style="width:32%; padding:8px 14px; border-right:1px solid #166534;">ステップ</div>
<div style="flex:1; padding:8px 14px;">内容</div>
</div>
<div style="display:flex; background:#f0fdf4; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">① 詳細化</div>
<div style="flex:1; padding:7px 14px;">実現したいこと・修正対象の確認と現状把握</div>
</div>
<div style="display:flex; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">② 修正案検討</div>
<div style="flex:1; padding:7px 14px;">解決策の検討</div>
</div>
<div style="display:flex; background:#f0fdf4; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">③ 修正案レビュー</div>
<div style="flex:1; padding:7px 14px;">方針の妥当性確認</div>
</div>
<div style="display:flex; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">④ 実装</div>
<div style="flex:1; padding:7px 14px;">コーディング</div>
</div>
<div style="display:flex; background:#f0fdf4; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">⑤ 動作確認</div>
<div style="flex:1; padding:7px 14px;">テスト・検証</div>
</div>
<div style="display:flex; border-top:1px solid #bbf7d0;">
<div style="width:32%; padding:7px 14px; border-right:1px solid #bbf7d0; color:#166534; font-weight:600;">⑥ レビュー → マージ</div>
<div style="flex:1; padding:7px 14px;">コードレビュー後に統合</div>
</div>
</div>

---



<!-- _class: skills -->

## ワークフロー全体像

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e3a8a; color:#fff; border-radius:8px; padding:7px 16px; text-align:center; font-weight:700; font-size:13px;">🤖 dev-workflow エージェントが実行順番を制御</div>
<div style="display:flex; gap:0; align-items:flex-start;">
<div style="flex:1; border:2px solid #db2777; border-radius:8px; overflow:hidden;">
<div style="background:#9d174d; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">準備</div>
<div style="padding:9px; background:#fdf2f8;">
<div style="background:#fff; border:1px solid #f9a8d4; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#9d174d; font-size:12px;">issue-to-setup-yaml</div>
<div style="font-size:11px; color:#6b7280;">JiraチケットからYAML生成</div>
</div>
<div style="background:#9d174d; padding:4px 6px; font-size:10px; color:#fff; text-align:center; font-weight:700;">◉ 人確認（作業対象・スコープ）</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:1; border:2px solid #0f766e; border-radius:8px; overflow:hidden;">
<div style="background:#0f766e; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">セットアップ</div>
<div style="padding:9px; background:#f0fdfa;">
<div style="background:#fff; border:1px solid #99f6e4; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#0f766e; font-size:12px;">init-work-branch</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">リポジトリを取得</div>
<div style="background:#fff; border:1px solid #99f6e4; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#0f766e; font-size:12px;">submodule-overview</div>
<div style="font-size:11px; color:#6b7280;">リポジトリ概要を把握</div>
</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:5; display:flex; flex-direction:column; gap:4px;">
<div style="display:flex; gap:0; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">調査・分析</div>
<div style="padding:9px; background:#eff6ff;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#1e40af; font-size:12px;">investigation</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">リポジトリを詳細調査</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#1e40af; font-size:12px;">brainstorming</div>
<div style="font-size:11px; color:#6b7280;">実施内容の詳細化</div>
</div>
<div style="background:#1e40af; padding:4px 6px; font-size:10px; color:#fff; text-align:center; font-weight:700;">◉ 人確認（要件・方針）</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:1; border:2px solid #7c3aed; border-radius:8px; overflow:hidden;">
<div style="background:#5b21b6; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">設計</div>
<div style="padding:9px; background:#f5f3ff;">
<div style="background:#fff; border:1px solid #c4b5fd; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#5b21b6; font-size:12px;">design</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">修正案の設計・検討</div>
<div style="background:#fff; border:1px solid #c4b5fd; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#5b21b6; font-size:12px;">review-design</div>
<div style="font-size:11px; color:#6b7280;">設計の妥当性レビュー</div>
</div>
<div style="background:#5b21b6; padding:4px 6px; font-size:10px; color:#fff; text-align:center; font-weight:700;">◉ 人確認（設計レビュー）</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:1; border:2px solid #0891b2; border-radius:8px; overflow:hidden;">
<div style="background:#0e7490; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">計画</div>
<div style="padding:9px; background:#ecfeff;">
<div style="background:#fff; border:1px solid #a5f3fc; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#0e7490; font-size:12px;">plan</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">タスク分割・計画作成</div>
<div style="background:#fff; border:1px solid #a5f3fc; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#0e7490; font-size:12px;">review-plan</div>
<div style="font-size:11px; color:#6b7280;">計画の妥当性レビュー</div>
</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:1; border:2px solid #16a34a; border-radius:8px; overflow:hidden;">
<div style="background:#15803d; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">実装</div>
<div style="padding:9px; background:#f0fdf4;">
<div style="background:#fff; border:1px solid #86efac; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#15803d; font-size:12px;">implement</div>
<div style="font-size:11px; color:#6b7280;">並列化対応で実装実行</div>
</div>
</div>
<div style="color:#3b82f6; font-size:18px; font-weight:bold; align-self:flex-start; margin-top:28px; padding:0 3px; flex-shrink:0;">→</div>
<div style="flex:1; border:2px solid #d97706; border-radius:8px; overflow:hidden;">
<div style="background:#b45309; color:#fff; font-weight:700; font-size:13px; text-align:center; padding:6px 4px;">検証・レビュー</div>
<div style="padding:9px; background:#fffbeb;">
<div style="background:#fff; border:1px solid #fcd34d; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#b45309; font-size:12px;">verification</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">テスト・ビルド確認</div>
<div style="background:#fff; border:1px solid #fcd34d; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#b45309; font-size:12px;">code-review</div>
<div style="font-size:11px; color:#6b7280; margin-bottom:6px;">ソースコードレビュー</div>
<div style="background:#fff; border:1px solid #fcd34d; border-radius:4px; padding:4px 6px; margin-bottom:3px; font-family:monospace; color:#b45309; font-size:12px;">code-review-fix</div>
<div style="font-size:11px; color:#6b7280;">指摘の修正対応</div>
</div>
<div style="background:#b45309; padding:4px 6px; font-size:10px; color:#fff; text-align:center; font-weight:700;">◉ 人確認（PRレビュー）</div>
</div>
</div>
<div style="display:flex; gap:0; align-items:center;">
<div style="flex:1; text-align:center; color:#3b82f6; font-size:12px; font-weight:600;">↓ 作成</div>
<div style="width:24px;"></div>
<div style="flex:1; text-align:center; color:#3b82f6; font-size:12px; font-weight:600;">↓ 更新</div>
<div style="width:24px;"></div>
<div style="flex:1; text-align:center; color:#3b82f6; font-size:12px; font-weight:600;">↓ 更新</div>
<div style="width:24px;"></div>
<div style="flex:1; text-align:center; color:#3b82f6; font-size:12px; font-weight:600;">↓ 更新</div>
<div style="width:24px;"></div>
<div style="flex:1; text-align:center; color:#3b82f6; font-size:12px; font-weight:600;">↓ 更新</div>
</div>
<div style="background:#fef9c3; border:2px solid #eab308; border-radius:8px; padding:7px 16px; text-align:center; font-weight:700; color:#713f12; font-size:13px;">📄 project.yaml &nbsp;—&nbsp; 進捗状況・決定事項を管理</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：準備

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">Jiraチケットをもとにユーザーと対話しながらゴール・スコープを確定し、AIが実行可能なYAMLに変換する</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-weight:600; color:#1e40af; font-size:12px;">📋 Jiraチケット</div>
<div style="font-size:11px; color:#6b7280; text-align:center;">実施内容・背景情報</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:4px;">⚙ issue-to-setup-yaml</div>
<div style="display:flex; gap:6px; align-items:flex-start;">
<div style="flex:1; display:flex; flex-direction:column; gap:3px;">
<div style="font-size:11px; color:#374151; font-weight:600;">AIが選択肢を提示</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「ゴールは？」A.機能追加 B.バグ修正 C.改善 D.自由入力</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「スコープ・制約は？」選択肢 or 自由入力</div>
</div>
<div style="width:1px; background:#bfdbfe; flex-shrink:0;"></div>
<div style="flex:1; display:flex; flex-direction:column; gap:3px;">
<div style="font-size:11px; color:#374151; font-weight:600; text-align:right;">ユーザーが選択 or 自由入力</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「B」（シンプル選択）</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「B、でも既存動作は維持して」（自由入力）</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「DBマイグレーション不可」（制約を追記）</div>
</div>
</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:4px; padding:3px 8px; font-size:10px; color:#1e40af; margin-top:4px; text-align:center;">↻ 対話を繰り返しYAML内容を洗練 → 最終確認で確定</div>
<div style="background:#eff6ff; border:1px solid #3b82f6; border-radius:4px; padding:3px 8px; font-size:10px; color:#1e40af; margin-top:3px; display:inline-block;">🔗 Jira — チケット情報を取得</div>
<div style="background:#f5f3ff; border:1px solid #c4b5fd; border-radius:4px; padding:5px 8px; font-size:11px; color:#5b21b6; margin-top:6px; font-weight:700; border-left:3px solid #7c3aed;">👤 ここが最重要 — AIと対話してゴール・スコープを徹底的に確定する</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-family:monospace; font-weight:600; color:#1e40af; font-size:12px;">setup.yaml</div>
<div style="font-size:11px; color:#6b7280; text-align:center;">ゴール・スコープ・制約を構造化</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：セットアップ

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">作業に必要なリポジトリを取得し、構造を把握してproject.yamlを初期化する</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-family:monospace; font-weight:600; color:#1e40af; font-size:12px;">setup.yaml</div>
<div style="font-size:11px; color:#6b7280; text-align:center;">ゴール・対象リポジトリ情報</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ init-work-branch</div>
<div style="font-size:11px; color:#374151;">・作業ブランチを作成してサブモジュールを初期化</div>
<div style="font-size:11px; color:#374151;">・project.yaml を初期化（以降の進捗管理の起点）</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — ブランチ作成 · リポジトリクローン</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ submodule-overview</div>
<div style="font-size:11px; color:#374151;">・各リポジトリの構造・責務・依存関係を解析</div>
<div style="font-size:11px; color:#374151;">・サブモジュールの役割をドキュメント化</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — ファイル構造 · README を参照</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:12px; color:#1e40af; font-weight:600;">作業ブランチ</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml</div>
<div style="font-size:11px; color:#6b7280; text-align:center;">進捗管理の初期化</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：調査・分析

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">修正対象を具体的に特定し、UML図を含む詳細な調査レポートを作成する</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">setup.yaml</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:12px; color:#1e40af; font-weight:600;">リポジトリ</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:4px;">⚙ brainstorming</div>
<div style="display:flex; gap:6px; align-items:flex-start;">
<div style="flex:1; display:flex; flex-direction:column; gap:3px;">
<div style="font-size:11px; color:#374151; font-weight:600;">AIが確認事項を提示</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「具体的にどんな動作を期待する？」</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「実装アプローチはどれが近い？」選択肢 or 自由入力</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「テストはどの粒度まで？」単体/結合/E2E</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e40af;">「考慮すべきリスク・制約は？」</div>
</div>
<div style="width:1px; background:#bfdbfe; flex-shrink:0;"></div>
<div style="flex:1; display:flex; flex-direction:column; gap:3px;">
<div style="font-size:11px; color:#374151; font-weight:600; text-align:right;">ユーザーが選択 or 自由入力</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「〇〇を入力したら△△になること」</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「Bパターン、ただし既存APIは維持」</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「単体+E2Eで十分」</div>
<div style="background:#dbeafe; border:1px solid #93c5fd; border-radius:3px; padding:3px 6px; font-size:10px; color:#1e3a8a; text-align:right;">「後方互換必須」</div>
</div>
</div>
<div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:4px; padding:3px 8px; font-size:10px; color:#1e40af; margin-top:4px; text-align:center;">↻ 対話で要件・アプローチ・テスト戦略・受け入れ条件を確定</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ investigation</div>
<div style="font-size:11px; color:#374151;">・対象コードの詳細調査・影響範囲のマッピング</div>
<div style="font-size:11px; color:#374151;">・UML図（クラス図・シーケンス図）を自動生成</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — コード参照 · ファイル解析</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">調査レポート</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">UML図</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml 更新</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：設計

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">修正案を設計し、2つのAIモデルをサブエージェントとして使用してレビューする</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">調査レポート</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="border:2px dashed #f59e0b; border-radius:8px; padding:5px; background:#fffbeb; display:flex; flex-direction:column; gap:5px;">
<div style="font-size:10px; color:#b45309; font-weight:700; text-align:right;">↻ 差し戻し時に再実行するループ区間</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ design</div>
<div style="font-size:11px; color:#374151;">・API仕様・データ構造・処理フローを設計</div>
<div style="font-size:11px; color:#374151;">・テスト計画を含む詳細設計書を作成</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ review-design</div>
<div style="font-size:11px; color:#374151;">・複数モデルで設計をレビューして指摘事項を統合</div>
<div style="background:#dbeafe; border-radius:4px; padding:3px 7px; font-size:10px; color:#1e3a8a; margin-top:4px; display:flex; gap:5px; align-items:center;">🤖 サブエージェント: <span style="background:#1e40af; color:#fff; border-radius:3px; padding:1px 5px;">Claude Opus 4.6</span><span style="background:#374151; color:#fff; border-radius:3px; padding:1px 5px;">Codex</span><span>→ 結果を統合</span></div>
</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ create-mr-pr <span style="background:#dbeafe; color:#1e3a8a; border-radius:3px; padding:1px 5px; font-family:sans-serif; font-size:10px; font-weight:600;">DRモード</span></div>
<div style="font-size:11px; color:#374151;">・設計内容をドラフトMRとして作成・人間にレビューを依頼</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — ドラフトMRを作成</div>
</div>
<div style="background:#f5f3ff; border:1px solid #c4b5fd; border-radius:6px; padding:7px 9px; border-left:3px solid #7c3aed;">
<div style="font-weight:700; color:#5b21b6; font-size:12px; margin-bottom:4px;">👤 人間レビュー — GitLabのドラフトMRで設計を確認</div>
<div style="display:flex; gap:5px;">
<div style="flex:1; background:#f0fdf4; border:1px solid #86efac; border-radius:4px; padding:5px 7px; font-size:10px; color:#15803d; text-align:center; font-weight:600;">✅ 承認<br>→ 次フェーズ（計画）へ</div>
<div style="flex:2; background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:5px 7px; font-size:10px; color:#9a3412;">↩ 差し戻し<br>→ design に戻りループ区間を再実行</div>
</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">詳細設計書</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">ドラフトMR</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：計画

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">設計を実装タスクに分割し、2つのAIモデルをサブエージェントとして使用してレビューする</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">詳細設計書</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="border:2px dashed #f59e0b; border-radius:8px; padding:5px; background:#fffbeb; display:flex; flex-direction:column; gap:5px;">
<div style="font-size:10px; color:#b45309; font-weight:700; text-align:right;">↻ 指摘がなくなるまでループ</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ plan</div>
<div style="font-size:11px; color:#374151;">・タスクを細かく分割して依存関係を整理</div>
<div style="font-size:11px; color:#374151;">・並列実行可能なタスクを識別 · E2Eテスト計画を作成</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ review-plan</div>
<div style="font-size:11px; color:#374151;">・複数モデルで実装計画をレビューして指摘事項を統合</div>
<div style="background:#dbeafe; border-radius:4px; padding:3px 7px; font-size:10px; color:#1e3a8a; margin-top:4px; display:flex; gap:5px; align-items:center;">🤖 サブエージェント: <span style="background:#1e40af; color:#fff; border-radius:3px; padding:1px 5px;">Claude Opus 4.6</span><span style="background:#374151; color:#fff; border-radius:3px; padding:1px 5px;">Codex</span><span>→ 結果を統合</span></div>
</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">タスクリスト</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">E2Eテスト計画</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml 更新</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：実装

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">独立タスクをサブエージェントで並列実行してTDDで品質を確保し、テストで検証する</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">タスクリスト</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="border:2px dashed #f59e0b; border-radius:8px; padding:5px; background:#fffbeb; display:flex; flex-direction:column; gap:5px;">
<div style="font-size:10px; color:#b45309; font-weight:700; text-align:right;">↻ テスト失敗時に再実行するループ</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ implement</div>
<div style="font-size:11px; color:#374151;">・TDD: 失敗テストを先に書いてから実装コードを書く</div>
<div style="background:#dbeafe; border-radius:4px; padding:3px 7px; font-size:10px; color:#1e3a8a; margin-top:4px; display:flex; gap:5px; align-items:center;">🤖 サブエージェント: 独立タスクを <span style="background:#1e40af; color:#fff; border-radius:3px; padding:1px 5px;">並列実行 ⇉</span></div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:3px; display:inline-block;">🦊 GitLab — 実装コードを Push · コミット管理</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ verification</div>
<div style="font-size:11px; color:#374151;">・テスト / ビルド / リント / E2E を実行して検証</div>
<div style="font-size:11px; color:#374151;">・受け入れ条件との照合 → 不合格なら implement に戻る</div>
</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">実装コード</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">テスト結果</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml 更新</div>
</div>
</div>
</div>
</div>

---

<!-- _class: skills -->

## フェーズ詳細：検証・レビュー

<div style="display:flex; flex-direction:column; gap:8px; font-size:13px;">
<div style="background:#1e40af; color:#fff; border-radius:6px; padding:6px 14px; font-size:12px;">2つのAIモデルをサブエージェントとして使用してコードをレビューし、MRを完成させる</div>
<div style="display:flex; gap:5px; align-items:flex-start;">
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📥 入力</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">実装コード</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:5px; text-align:center; font-family:monospace; font-size:11px; color:#1e40af; font-weight:600;">project.yaml</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:3; display:flex; flex-direction:column; gap:5px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ create-mr-pr <span style="background:#dbeafe; color:#1e3a8a; border-radius:3px; padding:1px 5px; font-family:sans-serif; font-size:10px; font-weight:600;">Codeモード</span></div>
<div style="font-size:11px; color:#374151;">・ドラフトMRを作成してレビュー用の場所を用意</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — ドラフトMRを作成</div>
</div>
<div style="border:2px dashed #f59e0b; border-radius:8px; padding:5px; background:#fffbeb; display:flex; flex-direction:column; gap:5px;">
<div style="font-size:10px; color:#b45309; font-weight:700; text-align:right;">↻ 指摘がなくなるまでループ</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ code-review</div>
<div style="font-size:11px; color:#374151;">・チェックリストベースで精査 → MRにレビュー結果を記載</div>
<div style="background:#dbeafe; border-radius:4px; padding:3px 7px; font-size:10px; color:#1e3a8a; margin-top:4px; display:flex; gap:5px; align-items:center;">🤖 サブエージェント: <span style="background:#1e40af; color:#fff; border-radius:3px; padding:1px 5px;">Claude Opus 4.6</span><span style="background:#374151; color:#fff; border-radius:3px; padding:1px 5px;">Codex</span><span>→ 結果を統合</span></div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">⚙ code-review-fix</div>
<div style="font-size:11px; color:#374151;">・指摘事項を修正 → 再レビューへ</div>
</div>
</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:6px; padding:7px 9px; border-left:3px solid #3b82f6;">
<div style="font-family:monospace; font-weight:700; color:#1e40af; font-size:12px; margin-bottom:3px;">ドラフト解除</div>
<div style="font-size:11px; color:#374151;">・指摘なしで完了 → ドラフトを解除して人間レビューへ</div>
<div style="background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:2px 7px; font-size:10px; color:#9a3412; margin-top:4px; display:inline-block;">🦊 GitLab — ドラフト解除・MRを正式化</div>
<div style="background:#eff6ff; border:1px solid #3b82f6; border-radius:4px; padding:2px 7px; font-size:10px; color:#1e40af; margin-top:3px; display:inline-block;">🔗 Jira — チケットを完了ステータスに更新</div>
</div>
<div style="background:#f5f3ff; border:1px solid #c4b5fd; border-radius:6px; padding:7px 9px; border-left:3px solid #7c3aed;">
<div style="font-weight:700; color:#5b21b6; font-size:12px; margin-bottom:4px;">👤 人間レビュー — GitLabのMRで最終コードを確認</div>
<div style="display:flex; gap:5px;">
<div style="flex:1; background:#f0fdf4; border:1px solid #86efac; border-radius:4px; padding:5px 7px; font-size:10px; color:#15803d; text-align:center; font-weight:600;">✅ 承認<br>→ MRをマージ</div>
<div style="flex:2; background:#fff7ed; border:1px solid #fed7aa; border-radius:4px; padding:5px 7px; font-size:10px; color:#9a3412;">↩ 差し戻し<br>→ code-review-fix に戻りループを再実行</div>
</div>
</div>
</div>
<div style="color:#3b82f6; font-size:20px; font-weight:bold; flex-shrink:0; margin-top:28px;">→</div>
<div style="flex:1; border:2px solid #3b82f6; border-radius:8px; overflow:hidden;">
<div style="background:#1e40af; color:#fff; font-weight:700; font-size:12px; text-align:center; padding:5px;">📤 成果物</div>
<div style="padding:8px; background:#eff6ff; display:flex; flex-direction:column; gap:4px;">
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">正式MR</div>
<div style="background:#fff; border:1px solid #bfdbfe; border-radius:5px; padding:6px; text-align:center; font-size:11px; color:#1e40af; font-weight:600;">完了 Jiraチケット</div>
</div>
</div>
</div>
</div>

---

## スキル・エージェントを育てる

> うまくいかなかった部分はセッションを振り返って改善に反映

### 継続的改善サイクル

<div class="flow">
  <div class="flow-step">実行</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step" style="border-color:#dc2626; background:#fef2f2; color:#991b1b;">うまくいかない</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step">原因を特定</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step" style="border-color:#7c3aed; background:#f5f3ff; color:#4c1d95;">スキルを更新</div>
  <div class="flow-arrow">→</div>
  <div class="flow-step" style="border-color:#16a34a; background:#dcfce7; color:#166534;">品質向上</div>
</div>

### ポイント

- ユーザーの指摘はすぐにスキルへフィードバック
- プロジェクト固有の知識をスキルに蓄積していく

---

## まとめ

### 生成AI自動化の3ステップ

1. **連携**: AIにシステム操作の手段（ツール）を与える
2. **分解**: 業務をAIが実行できる単位（スキル）に分解する
3. **統合**: スキルをオーケストレーションして自律実行させる

### 成功の鍵

> **スキルとエージェントを活用しながら**
> **プロジェクト固有の知識を蓄えて育てていくことが大事！**

---



<!-- _class: lead -->

# ありがとうございました

生成AIと人間が協調して、より良い開発サイクルを実現しましょう
