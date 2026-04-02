#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Wikis API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, run_cli


def list_wiki_pages(client, project_id):
    """List all wiki pages for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/wikis".format(pid))


def get_wiki_page(client, project_id, slug):
    """Get a single wiki page by slug."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/wikis/{}".format(pid, client.encode_path(slug))
    )


def create_wiki_page(client, project_id, title, content, format=None):
    """Create wiki page with optional format (markdown, rdoc, asciidoc, org)."""
    pid = client.encode_path(project_id)
    data = {"title": title, "content": content}
    if format:
        data["format"] = format
    return client.api("POST", "/projects/{}/wikis".format(pid), data)


def edit_wiki_page(client, project_id, slug, content=None, title=None,
                   format=None):
    """Edit wiki page with optional title and format."""
    pid = client.encode_path(project_id)
    data = {}
    if content is not None:
        data["content"] = content
    if title is not None:
        data["title"] = title
    if format is not None:
        data["format"] = format
    return client.api(
        "PUT",
        "/projects/{}/wikis/{}".format(pid, client.encode_path(slug)),
        data,
    )


def delete_wiki_page(client, project_id, slug):
    """Delete a wiki page."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE",
        "/projects/{}/wikis/{}".format(pid, client.encode_path(slug)),
    )


def upload_wiki_attachment(client, project_id, file_path):
    """Upload attachment to project wiki."""
    pid = client.encode_path(project_id)
    return client.upload(
        "/projects/{}/wikis/attachments".format(pid), file_path
    )


if __name__ == "__main__":
    run_cli({
        "list_wiki_pages": list_wiki_pages,
        "get_wiki_page": get_wiki_page,
        "create_wiki_page": create_wiki_page,
        "edit_wiki_page": edit_wiki_page,
        "delete_wiki_page": delete_wiki_page,
        "upload_wiki_attachment": upload_wiki_attachment,
    })
