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

All scripts import `common.py` for token/URL resolution and shared helpers. Each script can be run directly from the command line or imported as a Python module.

### CLI Usage

```bash
# Run any function directly (auto-resolves token and URL)
python3 scripts/projects.py list_projects --visibility private

# Get help (lists available functions)
python3 scripts/projects.py --help

# Pass positional args followed by keyword args
python3 scripts/merge_requests.py create_merge_request "my-group/my-project" feature/foo main "feat: new feature"
```

### Import Usage

```python
import sys, os
sys.path.insert(0, "path/to/scripts")
from common import GitLabClient
from projects import get_project

client = GitLabClient()
project = get_project(client, "my-group/my-project")
print(project["web_url"])
```

## Python Version Compatibility

Scripts are written for **Python 3.6+** using only the standard library (`urllib`, `json`, `os`, `sys`). No external packages required.