# MR/PR結果書き込み手順

code-reviewの結果をMR/PRに書き込む手順。

> [!CAUTION]
> **Shell展開防止（必須）**
> - `--body "$VAR"` や heredoc/echo でのbody構築は **禁止**（shell展開でMarkdownが破壊される）
> - GitHub: 必ず `--body-file` でファイル経由で渡す
> - GitLab: 必ず `create`ツールでPythonスクリプトを作成し、`requests` ライブラリ経由で渡す

## 書き込みタイミング

```
レビュー完了 → 1. コメント投稿 → 2. description更新 → 3. 書き込み確認 → 4. [全指摘解消時] draft解除
```

## 1. レビュー結果コメント投稿

各ラウンドの `round-NN-summary.md` の内容をMR/PRコメントとして投稿。

### GitHub

```bash
PR_NUMBER=$(gh pr view --json number -q '.number')
gh pr comment "$PR_NUMBER" --body-file "docs/{target}/code-review/round-NN-summary.md"
```

### GitLab

`create`ツールでPythonスクリプトを作成し、`bash`ツールで実行する。

```python
# post_mr_comment.py — createツールで作成
import requests, json, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]
comment_file = sys.argv[2]

with open(comment_file, "r") as f:
    comment_content = f.read()

response = requests.post(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/notes",
    headers={"PRIVATE-TOKEN": token},
    json={"body": comment_content}
)
response.raise_for_status()
print(f"Comment posted: note_id={response.json()['id']}")
```

```bash
python post_mr_comment.py "$MR_IID" "docs/{target}/code-review/round-NN-summary.md"
```

## 2. Descriptionチェックリスト更新

MR/PR descriptionのチェックボックスをレビュー結果に基づいて更新。

### 更新対象（AI自動チェック項目）

レビュー結果に基づき、以下のチェックボックスをon/offに更新:
- テスト全パス（TC-04結果）
- ビルド成功（CI結果）
- リント通過（SA-03結果）
- CI/パイプライン成功（TC-06結果）
- カバレッジ低下なし（TC-07結果）
- シークレット混入なし（SE-01結果）
- マージコンフリクトなし（git status結果）

### 更新方法

#### GitHub

```bash
# 現在のdescriptionを取得
gh pr view "$PR_NUMBER" --json body -q '.body' > pr-body-current.md

# pr-body-current.md の内容を読み取り、チェックボックスを更新した内容を
# editツールまたはcreateツールで pr-body-updated.md に書き出す

# 更新後のdescriptionをファイル経由で設定
gh pr edit "$PR_NUMBER" --body-file pr-body-updated.md
```

#### GitLab

`create`ツールでPythonスクリプトを作成し、`bash`ツールで実行する。

```python
# update_mr_description.py — createツールで作成
import requests, json, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]
description_file = sys.argv[2]

with open(description_file, "r") as f:
    updated_description = f.read()

response = requests.put(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}",
    headers={"PRIVATE-TOKEN": token},
    json={"description": updated_description}
)
response.raise_for_status()
print(f"Description updated: mr_iid={mr_iid}")
```

```bash
python update_mr_description.py "$MR_IID" pr-body-updated.md
```

### AI+人間チェック項目

AIが分析結果と根拠を記入（チェックボックスはonにしない → 人間が確認してon）:

```markdown
- [ ] Acceptance criteria充足
  > AI分析: AC-1 ✅ テストXXXで検証済み、AC-2 ✅ テストYYYで検証済み
- [ ] 破壊的変更なし
  > AI分析: 既存APIの変更なし、後方互換性維持
```

## 3. 書き込み後の内容確認

書き込み後、APIで内容を再取得し、意図通りに反映されたか確認する。

### GitHub

```bash
# コメント確認: 最新コメントを取得して内容を確認
gh pr view "$PR_NUMBER" --json comments --jq '.comments[-1].body' | head -5

# description確認: 更新後のbodyを取得して確認
gh pr view "$PR_NUMBER" --json body -q '.body' > pr-body-verify.md
# pr-body-verify.md の内容を確認し、チェックボックスが正しく更新されているか検証
```

### GitLab

```python
# verify_mr_content.py — createツールで作成
import requests, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]

# MR description を再取得
response = requests.get(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}",
    headers={"PRIVATE-TOKEN": token}
)
response.raise_for_status()
mr = response.json()
print("=== Description (先頭5行) ===")
for line in mr["description"].split("\n")[:5]:
    print(line)

# 最新のノート（コメント）を確認
response = requests.get(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/notes",
    headers={"PRIVATE-TOKEN": token},
    params={"sort": "desc", "per_page": 1}
)
response.raise_for_status()
notes = response.json()
if notes:
    print(f"\n=== Latest note (id={notes[0]['id']}) ===")
    for line in notes[0]["body"].split("\n")[:5]:
        print(line)
```

### 不一致時のリトライ

確認で不一致が検出された場合:
1. 書き込み内容のファイルを再確認
2. API呼び出しを再実行（最大2回リトライ）
3. 2回リトライしても不一致の場合、エラーとして報告

## 4. Draft解除

全指摘が解消（code-review-fixループ完了）された場合のみdraft解除。

### 条件

- レビュー結果が `approved`（Critical/Major/Minor指摘ゼロ）
- 全ACに対応するテストがpass
- 修正範囲がDR合意内

### GitHub

```bash
gh pr ready "$PR_NUMBER"
```

### GitLab

```python
# undraft_mr.py — createツールで作成
import requests, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]

# 現在のタイトルを取得
response = requests.get(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}",
    headers={"PRIVATE-TOKEN": token}
)
response.raise_for_status()
title = response.json()["title"]

# "Draft: " プレフィックスを除去
if title.startswith("Draft: "):
    new_title = title[len("Draft: "):]
    response = requests.put(
        f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}",
        headers={"PRIVATE-TOKEN": token},
        json={"title": new_title}
    )
    response.raise_for_status()
    print(f"Draft removed: {new_title}")
else:
    print(f"Already not draft: {title}")
```

## 統合MR/PRの場合

統合MR/PR（dev-processリポ）がある場合:

1. 各submodule MR/PRのレビュー結果をそれぞれのMR/PRにコメント
2. 統合MR/PRには横断レビュー結果をコメント
3. 全submodule MR/PR approved → 統合MR/PR descriptionを更新
4. 全テスト（クロスリポ含む）pass → 各MR/PR draft解除
