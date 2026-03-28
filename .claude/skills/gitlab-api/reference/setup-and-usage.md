# Setup & Usage

## Environment Configuration

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

## Using the Scripts

All scripts source `scripts/common.sh` for token/URL resolution and shared helpers. To use any API function:

```bash
# Source common utilities (auto-resolves token and URL)
source scripts/common.sh

# Then source the category-specific script
source scripts/projects.sh

# Call the function
gitlab_list_projects
```
