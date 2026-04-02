#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Projects API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_projects(client, visibility=None, search=None, order_by=None):
    """List projects accessible by the authenticated user."""
    qs = build_query_string({
        "visibility": visibility,
        "search": search,
        "order_by": order_by,
    })
    return client.api("GET", "/projects" + qs)


def get_project(client, project_id):
    """Get a single project by ID or path."""
    return client.api(
        "GET", "/projects/{}".format(client.encode_path(project_id))
    )


def create_project(
    client, name, visibility=None, description=None, namespace_id=None
):
    """Create a new project."""
    data = {"name": name}
    if visibility:
        data["visibility"] = visibility
    if description:
        data["description"] = description
    if namespace_id:
        data["namespace_id"] = int(namespace_id)
    return client.api("POST", "/projects", data)


def edit_project(client, project_id, data=None, **kwargs):
    """Edit an existing project."""
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT",
        "/projects/{}".format(client.encode_path(project_id)),
        body,
    )


def delete_project(client, project_id):
    """Delete a project (irreversible)."""
    return client.api(
        "DELETE", "/projects/{}".format(client.encode_path(project_id))
    )


def fork_project(client, project_id):
    """Fork a project into the authenticated user's namespace."""
    return client.api(
        "POST", "/projects/{}/fork".format(client.encode_path(project_id))
    )


def list_forks(client, project_id):
    """List forks of a project."""
    return client.api(
        "GET", "/projects/{}/forks".format(client.encode_path(project_id))
    )


def star_project(client, project_id):
    """Star a project."""
    return client.api(
        "POST", "/projects/{}/star".format(client.encode_path(project_id))
    )


def unstar_project(client, project_id):
    """Unstar a project."""
    return client.api(
        "POST", "/projects/{}/unstar".format(client.encode_path(project_id))
    )


def archive_project(client, project_id):
    """Archive a project (makes it read-only)."""
    return client.api(
        "POST", "/projects/{}/archive".format(client.encode_path(project_id))
    )


def unarchive_project(client, project_id):
    """Unarchive a project."""
    return client.api(
        "POST",
        "/projects/{}/unarchive".format(client.encode_path(project_id)),
    )


def get_project_languages(client, project_id):
    """Get languages used in a project (with percentage breakdown)."""
    return client.api(
        "GET",
        "/projects/{}/languages".format(client.encode_path(project_id)),
    )


def list_project_hooks(client, project_id):
    """List webhooks for a project."""
    return client.api(
        "GET", "/projects/{}/hooks".format(client.encode_path(project_id))
    )


def create_project_hook(
    client,
    project_id,
    url,
    push_events="true",
    merge_requests_events=None,
    token=None,
):
    """Create a webhook for a project."""
    data = {"url": url, "push_events": push_events == "true"}
    if merge_requests_events is not None:
        data["merge_requests_events"] = merge_requests_events == "true"
    if token:
        data["token"] = token
    return client.api(
        "POST",
        "/projects/{}/hooks".format(client.encode_path(project_id)),
        data,
    )


def delete_project_hook(client, project_id, hook_id):
    """Delete a webhook from a project."""
    return client.api(
        "DELETE",
        "/projects/{}/hooks/{}".format(
            client.encode_path(project_id), hook_id
        ),
    )


def upload_project_file(client, project_id, file_path):
    """Upload a file to a project. Returns markdown link."""
    return client.upload(
        "/projects/{}/uploads".format(client.encode_path(project_id)),
        file_path,
        "file",
    )


if __name__ == "__main__":
    run_cli({
        "list_projects": list_projects,
        "get_project": get_project,
        "create_project": create_project,
        "edit_project": edit_project,
        "delete_project": delete_project,
        "fork_project": fork_project,
        "list_forks": list_forks,
        "star_project": star_project,
        "unstar_project": unstar_project,
        "archive_project": archive_project,
        "unarchive_project": unarchive_project,
        "get_project_languages": get_project_languages,
        "list_project_hooks": list_project_hooks,
        "create_project_hook": create_project_hook,
        "delete_project_hook": delete_project_hook,
        "upload_project_file": upload_project_file,
    })
