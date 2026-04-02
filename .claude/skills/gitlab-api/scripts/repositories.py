#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Repositories API functions."""

from __future__ import print_function, unicode_literals

import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_repo_tree(client, project_id, path=None, ref=None, recursive=None):
    """List repository tree (files and directories)."""
    qs = build_query_string({
        "path": path,
        "ref": ref,
        "recursive": recursive,
    })
    return client.api(
        "GET",
        "/projects/{}/repository/tree{}".format(
            client.encode_path(project_id), qs
        ),
    )


def get_file(client, project_id, file_path, ref="main"):
    """Get file metadata and Base64 content."""
    qs = build_query_string({"ref": ref})
    return client.api(
        "GET",
        "/projects/{}/repository/files/{}{}".format(
            client.encode_path(project_id),
            client.encode_path(file_path),
            qs,
        ),
    )


def get_file_raw(client, project_id, file_path, ref="main"):
    """Get raw file content."""
    qs = build_query_string({"ref": ref})
    url = "{}/projects/{}/repository/files/{}/raw{}".format(
        client.api_base,
        client.encode_path(project_id),
        client.encode_path(file_path),
        qs,
    )
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError

    req = Request(url, method="GET")
    req.add_header("PRIVATE-TOKEN", client.token)
    try:
        resp = urlopen(req)
        return resp.read().decode("utf-8")
    except HTTPError as e:
        error_body = e.read().decode("utf-8")
        print(
            "ERROR: HTTP {} from GET raw file".format(e.code),
            file=sys.stderr,
        )
        print(error_body, file=sys.stderr)
        sys.exit(1)


def create_file(
    client, project_id, file_path, branch, content, commit_message
):
    """Create a new file in the repository."""
    data = {
        "branch": branch,
        "content": content,
        "commit_message": commit_message,
    }
    return client.api(
        "POST",
        "/projects/{}/repository/files/{}".format(
            client.encode_path(project_id),
            client.encode_path(file_path),
        ),
        data,
    )


def update_file(
    client, project_id, file_path, branch, content, commit_message
):
    """Update an existing file in the repository."""
    data = {
        "branch": branch,
        "content": content,
        "commit_message": commit_message,
    }
    return client.api(
        "PUT",
        "/projects/{}/repository/files/{}".format(
            client.encode_path(project_id),
            client.encode_path(file_path),
        ),
        data,
    )


def delete_file(client, project_id, file_path, branch, commit_message):
    """Delete a file from the repository."""
    data = {"branch": branch, "commit_message": commit_message}
    return client.api(
        "DELETE",
        "/projects/{}/repository/files/{}".format(
            client.encode_path(project_id),
            client.encode_path(file_path),
        ),
        data,
    )


def compare(client, project_id, from_ref, to_ref):
    """Compare branches, tags, or commits."""
    qs = build_query_string({"from": from_ref, "to": to_ref})
    return client.api(
        "GET",
        "/projects/{}/repository/compare{}".format(
            client.encode_path(project_id), qs
        ),
    )


def list_branches(client, project_id):
    """List all branches."""
    return client.api(
        "GET",
        "/projects/{}/repository/branches".format(
            client.encode_path(project_id)
        ),
    )


def get_branch(client, project_id, branch_name):
    """Get a single branch."""
    return client.api(
        "GET",
        "/projects/{}/repository/branches/{}".format(
            client.encode_path(project_id),
            client.encode_path(branch_name),
        ),
    )


def create_branch(client, project_id, branch, ref):
    """Create a new branch."""
    data = {"branch": branch, "ref": ref}
    return client.api(
        "POST",
        "/projects/{}/repository/branches".format(
            client.encode_path(project_id)
        ),
        data,
    )


def delete_branch(client, project_id, branch_name):
    """Delete a branch."""
    return client.api(
        "DELETE",
        "/projects/{}/repository/branches/{}".format(
            client.encode_path(project_id),
            client.encode_path(branch_name),
        ),
    )


def list_tags(client, project_id):
    """List all tags."""
    return client.api(
        "GET",
        "/projects/{}/repository/tags".format(
            client.encode_path(project_id)
        ),
    )


def create_tag(client, project_id, tag_name, ref, message=None):
    """Create a tag with optional message."""
    data = {"tag_name": tag_name, "ref": ref}
    if message:
        data["message"] = message
    return client.api(
        "POST",
        "/projects/{}/repository/tags".format(
            client.encode_path(project_id)
        ),
        data,
    )


def delete_tag(client, project_id, tag_name):
    """Delete a tag."""
    return client.api(
        "DELETE",
        "/projects/{}/repository/tags/{}".format(
            client.encode_path(project_id),
            client.encode_path(tag_name),
        ),
    )


def list_commits(client, project_id, ref_name=None):
    """List commits with optional ref_name filter."""
    qs = build_query_string({"ref_name": ref_name})
    return client.api(
        "GET",
        "/projects/{}/repository/commits{}".format(
            client.encode_path(project_id), qs
        ),
    )


def get_commit(client, project_id, sha):
    """Get a single commit by SHA."""
    return client.api(
        "GET",
        "/projects/{}/repository/commits/{}".format(
            client.encode_path(project_id), sha
        ),
    )


def get_commit_diff(client, project_id, sha):
    """Get commit diff."""
    return client.api(
        "GET",
        "/projects/{}/repository/commits/{}/diff".format(
            client.encode_path(project_id), sha
        ),
    )


if __name__ == "__main__":
    run_cli({
        "list_repo_tree": list_repo_tree,
        "get_file": get_file,
        "get_file_raw": get_file_raw,
        "create_file": create_file,
        "update_file": update_file,
        "delete_file": delete_file,
        "compare": compare,
        "list_branches": list_branches,
        "get_branch": get_branch,
        "create_branch": create_branch,
        "delete_branch": delete_branch,
        "list_tags": list_tags,
        "create_tag": create_tag,
        "delete_tag": delete_tag,
        "list_commits": list_commits,
        "get_commit": get_commit,
        "get_commit_diff": get_commit_diff,
    })
