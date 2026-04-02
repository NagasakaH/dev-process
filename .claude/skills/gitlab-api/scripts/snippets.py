#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Snippets API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, run_cli


# --- Personal Snippets ---

def list_snippets(client):
    """List authenticated user's snippets."""
    return client.api("GET", "/snippets")


def list_public_snippets(client):
    """List all public snippets."""
    return client.api("GET", "/snippets/public")


def get_snippet(client, snippet_id):
    """Get a single snippet."""
    return client.api("GET", "/snippets/{}".format(snippet_id))


def get_snippet_raw(client, snippet_id):
    """Get raw content of snippet."""
    url = "{}/snippets/{}/raw".format(client.api_base, snippet_id)
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError

    req = Request(url, method="GET")
    req.add_header("PRIVATE-TOKEN", client.token)
    try:
        resp = urlopen(req)
        return resp.read().decode("utf-8")
    except HTTPError as e:
        error_body = e.read().decode("utf-8")
        print("ERROR: HTTP {}".format(e.code), file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)


def create_snippet(client, title, file_name, content, visibility="private"):
    """Create personal snippet with title, filename, content, visibility."""
    data = {
        "title": title,
        "file_name": file_name,
        "content": content,
        "visibility": visibility,
    }
    return client.api("POST", "/snippets", data)


def update_snippet(client, snippet_id, title=None, file_name=None,
                   content=None, visibility=None):
    """Update a personal snippet."""
    data = {}
    if title is not None:
        data["title"] = title
    if file_name is not None:
        data["file_name"] = file_name
    if content is not None:
        data["content"] = content
    if visibility is not None:
        data["visibility"] = visibility
    return client.api("PUT", "/snippets/{}".format(snippet_id), data)


def delete_snippet(client, snippet_id):
    """Delete a personal snippet."""
    return client.api("DELETE", "/snippets/{}".format(snippet_id))


# --- Project Snippets ---

def list_project_snippets(client, project_id):
    """List snippets for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/snippets".format(pid))


def get_project_snippet(client, project_id, snippet_id):
    """Get a single project snippet."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/snippets/{}".format(pid, snippet_id)
    )


def get_project_snippet_raw(client, project_id, snippet_id):
    """Get raw content of project snippet."""
    pid = client.encode_path(project_id)
    url = "{}/projects/{}/snippets/{}/raw".format(
        client.api_base, pid, snippet_id
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
        print("ERROR: HTTP {}".format(e.code), file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)


def create_project_snippet(client, project_id, title, file_name, content,
                           visibility="private"):
    """Create project snippet."""
    pid = client.encode_path(project_id)
    data = {
        "title": title,
        "file_name": file_name,
        "content": content,
        "visibility": visibility,
    }
    return client.api("POST", "/projects/{}/snippets".format(pid), data)


def delete_project_snippet(client, project_id, snippet_id):
    """Delete a project snippet."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/snippets/{}".format(pid, snippet_id)
    )


if __name__ == "__main__":
    run_cli({
        "list_snippets": list_snippets,
        "list_public_snippets": list_public_snippets,
        "get_snippet": get_snippet,
        "get_snippet_raw": get_snippet_raw,
        "create_snippet": create_snippet,
        "update_snippet": update_snippet,
        "delete_snippet": delete_snippet,
        "list_project_snippets": list_project_snippets,
        "get_project_snippet": get_project_snippet,
        "get_project_snippet_raw": get_project_snippet_raw,
        "create_project_snippet": create_project_snippet,
        "delete_project_snippet": delete_project_snippet,
    })
