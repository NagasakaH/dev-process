#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Container Registry API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_registry_repos(client, project_id):
    """List registry repositories for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/registry/repositories".format(pid))


def delete_registry_repo(client, project_id, repository_id):
    """Delete a registry repository."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE",
        "/projects/{}/registry/repositories/{}".format(pid, repository_id),
    )


def list_registry_tags(client, project_id, repository_id):
    """List tags for a registry repository."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET",
        "/projects/{}/registry/repositories/{}/tags".format(
            pid, repository_id
        ),
    )


def get_registry_tag(client, project_id, repository_id, tag_name):
    """Get details of a specific registry tag."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET",
        "/projects/{}/registry/repositories/{}/tags/{}".format(
            pid, repository_id, tag_name
        ),
    )


def delete_registry_tag(client, project_id, repository_id, tag_name):
    """Delete a specific registry tag."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE",
        "/projects/{}/registry/repositories/{}/tags/{}".format(
            pid, repository_id, tag_name
        ),
    )


def bulk_delete_registry_tags(client, project_id, repository_id,
                              name_regex_delete=None, keep_n=None,
                              older_than=None):
    """Bulk delete tags by regex and retention criteria."""
    pid = client.encode_path(project_id)
    data = {}
    if name_regex_delete:
        data["name_regex_delete"] = name_regex_delete
    if keep_n is not None:
        data["keep_n"] = int(keep_n)
    if older_than:
        data["older_than"] = older_than
    return client.api(
        "DELETE",
        "/projects/{}/registry/repositories/{}/tags".format(
            pid, repository_id
        ),
        data,
    )


def list_group_registry_repos(client, group_id):
    """List registry repositories for a group."""
    gid = client.encode_path(group_id)
    return client.api("GET", "/groups/{}/registry/repositories".format(gid))


if __name__ == "__main__":
    run_cli({
        "list_registry_repos": list_registry_repos,
        "delete_registry_repo": delete_registry_repo,
        "list_registry_tags": list_registry_tags,
        "get_registry_tag": get_registry_tag,
        "delete_registry_tag": delete_registry_tag,
        "bulk_delete_registry_tags": bulk_delete_registry_tags,
        "list_group_registry_repos": list_group_registry_repos,
    })
