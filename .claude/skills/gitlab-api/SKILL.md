---
name: gitlab-api
description: "Execute GitLab REST API operations using curl. TRIGGER when: user asks to interact with GitLab API, manage GitLab projects/groups/repos/pipelines/merge requests/issues, or automate GitLab workflows via API. DO NOT TRIGGER when: user is working with GitHub, Bitbucket, or other non-GitLab platforms."
---

# GitLab API Skill

GitLab REST API (v4) 操作を curl シェルスクリプトで実行するスキル。カテゴリ別のプリビルド関数を提供する。

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
| Projects | [reference/projects.md](reference/projects.md) | `scripts/projects.sh` | Managing projects, forking, starring, archiving |
| Groups | [reference/groups.md](reference/groups.md) | `scripts/groups.sh` | Managing groups, subgroups, group settings |
| Repositories | [reference/repositories.md](reference/repositories.md) | `scripts/repositories.sh` | Branches, tags, commits, files, tree |
| Merge Requests | [reference/merge-requests.md](reference/merge-requests.md) | `scripts/merge-requests.sh` | MRs, approvals, reviews, merge |
| Issues | [reference/issues.md](reference/issues.md) | `scripts/issues.sh` | Issues, labels, milestones, issue links |
| CI/CD | [reference/ci-cd.md](reference/ci-cd.md) | `scripts/ci-cd.sh` | Pipelines, jobs, runners, variables, schedules |
| Users | [reference/users.md](reference/users.md) | `scripts/users.sh` | Users, members, access tokens, SSH keys |
| Packages | [reference/packages.md](reference/packages.md) | `scripts/packages.sh` | Package registry (generic, npm, pypi, maven) |
| Container Registry | [reference/container-registry.md](reference/container-registry.md) | `scripts/container-registry.sh` | Container images, tags |
| Deployments | [reference/deployments.md](reference/deployments.md) | `scripts/deployments.sh` | Deployments, environments, releases, deploy keys |
| Admin | [reference/admin.md](reference/admin.md) | `scripts/admin.sh` | System hooks, features, broadcast messages |
| Search | [reference/search.md](reference/search.md) | `scripts/search.sh` | Global, project, group search |
| Wikis | [reference/wikis.md](reference/wikis.md) | `scripts/wikis.sh` | Wiki page operations |
| Snippets | [reference/snippets.md](reference/snippets.md) | `scripts/snippets.sh` | Snippet operations (project & personal) |
| **Markdown** | [reference/gitlab-flavored-markdown.md](reference/gitlab-flavored-markdown.md) | — | **GLFM syntax for all text fields** |

## Instructions

1. **API カテゴリを特定** — ユーザーのリクエストから判断
2. **リファレンスドキュメントを読む** — 利用可能なエンドポイントを把握
3. **`scripts/common.sh`** → カテゴリスクリプトの順にソース
4. **関数を呼び出す** — 必要パラメータを渡す
5. **JSON レスポンスは `jq` でパース** — `grep`/`sed` は使わない
6. **GLFM 記法** — `description`/`body` フィールドには [reference/gitlab-flavored-markdown.md](reference/gitlab-flavored-markdown.md) を参照

📖 共通パターン・エラーハンドリング・ファイル添付は [reference/common-patterns.md](reference/common-patterns.md) を参照
