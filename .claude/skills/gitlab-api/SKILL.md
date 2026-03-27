---
name: gitlab-api
description: "Execute GitLab REST API operations using curl. TRIGGER when: user asks to interact with GitLab API, manage GitLab projects/groups/repos/pipelines/merge requests/issues, or automate GitLab workflows via API. DO NOT TRIGGER when: user is working with GitHub, Bitbucket, or other non-GitLab platforms."
---

# GitLab API Skill

This skill helps you execute GitLab REST API (v4) operations using curl shell scripts. It provides pre-built functions for common GitLab API operations organized by category.

## Setup

### Environment Configuration

The skill resolves `GITLAB_TOKEN` and `GITLAB_URL` with this priority:

1. **Environment variables** (highest priority): `GITLAB_TOKEN`, `GITLAB_URL`
2. **`$HOME/.config/skills/gitlab/.env`**
3. **`$HOME/.config/skills/.env`** (lowest priority)

The `.env` files should contain:

```
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_URL=https://gitlab.example.com
```

If `GITLAB_URL` is not set, it defaults to `https://gitlab.com`.

### Using the Scripts

All scripts source `scripts/common.sh` for token/URL resolution and shared helpers. To use any API function:

```bash
# Source common utilities (auto-resolves token and URL)
source scripts/common.sh

# Then source the category-specific script
source scripts/projects.sh

# Call the function
gitlab_list_projects
```

---

## API Categories

Read the appropriate reference document based on the user's request:

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

1. **Identify the API category** from the user's request
2. **Read the reference doc** for that category to understand available endpoints
3. **Source `scripts/common.sh`** first, then the category-specific script
4. **Call the appropriate function** with required parameters
5. **Parse the JSON response** using `jq` — never use `grep`/`sed` on JSON
6. **Use GitLab Flavored Markdown (GLFM)** for all `description` and `body` fields — refer to [reference/gitlab-flavored-markdown.md](reference/gitlab-flavored-markdown.md) for syntax

### Common Patterns

```bash
# URL-encode project paths (namespace/project → namespace%2Fproject)
PROJECT_ID=$(urlencode "my-group/my-project")

# Pagination
gitlab_api GET "/projects?per_page=100&page=2"

# POST with JSON body
gitlab_api POST "/projects" '{"name":"new-project","visibility":"private"}'

# PUT to update
gitlab_api PUT "/projects/$PROJECT_ID" '{"description":"Updated"}'

# DELETE
gitlab_api DELETE "/projects/$PROJECT_ID"
```

### Error Handling

All functions check HTTP status codes. On error, the response body (usually containing `{"message":"..."}`) is printed to stderr.

### File Attachment Workflow

To attach images or files to issues, merge requests, or comments:

1. **Upload the file** to the project using `gitlab_upload_project_file` (calls `POST /projects/:id/uploads`)
2. **Extract the `markdown` link** from the response JSON
3. **Embed the markdown** in the `description` or note `body`

```bash
source scripts/common.sh
source scripts/projects.sh
source scripts/issues.sh

# Upload file and get markdown link
UPLOAD=$(gitlab_upload_project_file "my-group/my-project" "/path/to/image.png")
IMAGE_MD=$(echo "$UPLOAD" | jq -r '.markdown')

# Use in issue description, MR description, or comment body
gitlab_create_issue "my-group/my-project" "Bug report" "Details:\n\n${IMAGE_MD}"
```

See [reference/projects.md](reference/projects.md#upload-a-file-to-a-project) for the upload API details.
