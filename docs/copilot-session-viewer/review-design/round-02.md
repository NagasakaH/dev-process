# 設計レビュー結果 — Round 2

| 項目 | 値 |
|---|---|
| チケット | viewer-container-local |
| 対象リポジトリ | copilot-session-viewer |
| ラウンド | 2 |
| 総合判定 | ⚠️ 条件付き承認（conditional） |
| レビュー日 | 2025-07-24 |
| レビュアー | GPT-5.3-Codex, Claude Opus 4.6 |

## 指摘サマリー

| 重大度 | 件数 |
|---|---|
| 🔴 Critical | 0 |
| 🟠 Major | 0 |
| 🟡 Minor | 2 |
| 🔵 Info | 1 |

## 判定理由

Round 1 の全 12 件（Major 5 + Minor 7）は設計修正により resolved。
新規 Critical/Major はなし。Minor 2 件 + Info 1 件が残存するため条件付き承認を維持。
いずれもドキュメント内の軽微な記載修正で対応可能であり、設計方針の変更は不要。

---

## Round 1 指摘の解決状況

| ID | 重大度 | カテゴリ | ステータス |
|---|---|---|---|
| MRD-001 | 🟠 Major | compose.yaml 起動整合性 | ✅ resolved |
| MRD-002 | 🟠 Major | 未定義ファイル参照 | ✅ resolved |
| MRD-003 | 🟠 Major | パス不整合 | ✅ resolved（残存は MRD-003-残 として起票） |
| MRD-004 | 🟠 Major | acceptance_criteria マッピングエラー | ✅ resolved |
| MRD-005 | 🟠 Major | $HOME パス不一致 | ✅ resolved |
| MRD-006 | 🟡 Minor | PAT 認証 | ✅ resolved |
| MRD-007 | 🟡 Minor | tmux 耐久性 | ✅ resolved |
| MRD-008 | 🟡 Minor | healthcheck | ✅ resolved |
| MRD-009 | 🟡 Minor | module-level const | ✅ resolved |
| MRD-010 | 🟡 Minor | Dockerfile 品質 | ✅ resolved |
| MRD-011 | 🟡 Minor | .dockerignore | ✅ resolved |
| MRD-012 | 🟡 Minor | dev-process ツールセット | ✅ resolved |

---

## 新規 Minor 指摘

### MRD-003-残: パス不整合の残存

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md` セクション 1.2
- **説明**: Round 1 の MRD-003 修正で大部分のパスが `/app/server.js` 系に統一されたが、セクション 1.2 の影響範囲説明に `node .next/standalone/server.js` という旧パス表記が 1 箇所残存。
- **改善提案**: `cd /app && node server.js` に修正し、ドキュメント全体で `.next/standalone/server.js`（コンテナ起動パス文脈）の残存がないことを確認。

### MRD-R2-001: named volume 権限

- **重大度**: 🟡 Minor
- **対象ファイル**: `design/02_interface-api-design.md`（Dockerfile セクション）、`design/01_implementation-approach.md`（Dockerfile スニペット）
- **説明**: `USER node` 設定下で named volume のマウント先 `/home/node/.copilot` がイメージ内に事前作成されていない。Docker named volume の初回マウント時、ディレクトリが存在しないと root 所有で作成されるため、node ユーザーが書き込めない可能性がある。
- **改善提案**: Dockerfile の `USER node` 行の直前に `RUN mkdir -p /home/node/.copilot && chown node:node /home/node/.copilot` を追加。

---

## 新規 Info

### MRD-R2-002: セクション番号ギャップ

- **重大度**: 🔵 Info
- **対象ファイル**: `design/01_implementation-approach.md`
- **説明**: セクション 3.x の番号が 3.4 → 3.6 → 3.7 → 3.8 と、3.5 が欠番になっている。
- **改善提案**: 3.5〜3.7 に振り直して連番化。

---

## 次のステップ

1. Minor 2 件 + Info 1 件を **design** で修正
2. 修正確認後、**plan** スキルへ進行（Round 3 レビューは不要）
