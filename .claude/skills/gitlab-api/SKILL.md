---
name: gitlab-api
description: "Execute GitLab REST API operations using Python 3. TRIGGER when: user asks to interact with GitLab API, manage GitLab projects/groups/repos/pipelines/merge requests/issues, or automate GitLab workflows via API. DO NOT TRIGGER when: user is working with GitHub, Bitbucket, or other non-GitLab platforms."
---

# GitLab API Skill

GitLab REST API (v4) 操作を Python 3 スクリプトで実行するスキル。カテゴリ別のモジュールを提供する。標準ライブラリのみ使用（Python 3.6+）。

## Setup

`GITLAB_TOKEN` と `GITLAB_URL` の解決優先順:

1. **環境変数** (最優先): `GITLAB_TOKEN`, `GITLAB_URL`
2. **`$HOME/.config/skills/gitlab/.env`**
3. **`$HOME/.config/skills/.env`** (最低優先)

`GITLAB_URL` 未設定時は `https://gitlab.com` がデフォルト。

📖 詳細は [reference/setup-and-usage.md](reference/setup-and-usage.md) を参照

---

## API Categories

ユーザーのリクエストに応じて適切なリファレンスドキュメントを読むこと:

| Category | Reference | Script | Use When |
|----------|-----------|--------|----------|
| Projects | [reference/projects.md](reference/projects.md) | `scripts/projects.py` | Managing projects, forking, starring, archiving |
| Groups | [reference/groups.md](reference/groups.md) | `scripts/groups.py` | Managing groups, subgroups, group settings |
| Repositories | [reference/repositories.md](reference/repositories.md) | `scripts/repositories.py` | Branches, tags, commits, files, tree |
| Merge Requests | [reference/merge-requests.md](reference/merge-requests.md) | `scripts/merge_requests.py` | MRs, approvals, reviews, merge |
| Issues | [reference/issues.md](reference/issues.md) | `scripts/issues.py` | Issues, labels, milestones, issue links |
| CI/CD | [reference/ci-cd.md](reference/ci-cd.md) | `scripts/ci_cd.py` | Pipelines, jobs, runners, variables, schedules |
| Users | [reference/users.md](reference/users.md) | `scripts/users.py` | Users, members, access tokens, SSH keys |
| Packages | [reference/packages.md](reference/packages.md) | `scripts/packages.py` | Package registry (generic, npm, pypi, maven) |
| Container Registry | [reference/container-registry.md](reference/container-registry.md) | `scripts/container_registry.py` | Container images, tags |
| Deployments | [reference/deployments.md](reference/deployments.md) | `scripts/deployments.py` | Deployments, environments, releases, deploy keys |
| Admin | [reference/admin.md](reference/admin.md) | `scripts/admin.py` | System hooks, features, broadcast messages |
| Search | [reference/search.md](reference/search.md) | `scripts/search.py` | Global, project, group search |
| Wikis | [reference/wikis.md](reference/wikis.md) | `scripts/wikis.py` | Wiki page operations |
| Snippets | [reference/snippets.md](reference/snippets.md) | `scripts/snippets.py` | Snippet operations (project & personal) |
| **Markdown** | [reference/gitlab-flavored-markdown.md](reference/gitlab-flavored-markdown.md) | — | **GLFM syntax for all text fields** |

## Instructions

1. **API カテゴリを特定** — ユーザーのリクエストから判断
2. **リファレンスドキュメントを読む** — 利用可能なエンドポイントを把握
3. **スクリプトを直接実行、またはインポートして使用**
4. **JSON レスポンスは Python で安全にパース** — `json` モジュールを使用
5. **GLFM 記法** — `description`/`body` フィールドには [reference/gitlab-flavored-markdown.md](reference/gitlab-flavored-markdown.md) を参照

📖 共通パターン・エラーハンドリング・ファイル添付は [reference/common-patterns.md](reference/common-patterns.md) を参照

---

## 使用方法

### CLI から直接実行

```bash
# プロジェクト一覧
python3 scripts/projects.py list_projects --visibility private --search test

# 単一プロジェクト取得
python3 scripts/projects.py get_project "my-group/my-project"

# MR 作成
python3 scripts/merge_requests.py create_merge_request "my-group/my-project" feature/foo main "feat: add feature"

# ヘルプ表示（利用可能な関数一覧）
python3 scripts/projects.py --help
```

### Python スクリプトからインポート

マルチラインの description や複雑な JSON ボディを扱う場合は、`create` ツールで Python スクリプトを作成して実行する:

```python
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".claude/skills/gitlab-api/scripts"))
from common import GitLabClient
from issues import create_issue

client = GitLabClient()
result = create_issue(client, "my-group/my-project", "Bug report",
                      description="## Steps to reproduce\n\n1. Step 1\n2. Step 2")
print(result["web_url"])
```

---

## JSON 安全性

Python の `json` モジュールによるシリアライズを使用するため、シェル展開の問題は発生しない。マルチラインコンテンツやユーザー入力を含む API 呼び出しも安全に処理される。

---

## 作成後の内容確認

Issue / MR / PR を作成した後は、必ず以下の手順で内容を確認すること。

1. **API で再取得** — 作成直後のレスポンス、または GET エンドポイントで `body` / `description` を取得
2. **意図した内容と一致するか確認** — タイトル、説明文、ラベル等が期待通りか検証
3. **不一致の場合は修正** — PUT エンドポイントで即座に修正を実行

作成 API のレスポンスだけで確認せず、**GET で再取得して検証**することを推奨する（レンダリング差異の検出のため）。