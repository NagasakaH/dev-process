#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Search API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def search_global(client, scope, search):
    """Search across all accessible projects.

    Scopes: projects, issues, merge_requests, milestones, snippet_titles,
    wiki_blobs, commits, blobs, notes, users.
    """
    qs = build_query_string({"scope": scope, "search": search})
    return client.api("GET", "/search" + qs)


def search_group(client, group_id, scope, search):
    """Search within a specific group."""
    gid = client.encode_path(group_id)
    qs = build_query_string({"scope": scope, "search": search})
    return client.api("GET", "/groups/{}/search{}".format(gid, qs))


def search_project(client, project_id, scope, search):
    """Search within a specific project."""
    pid = client.encode_path(project_id)
    qs = build_query_string({"scope": scope, "search": search})
    return client.api("GET", "/projects/{}/search{}".format(pid, qs))


if __name__ == "__main__":
    run_cli({
        "search_global": search_global,
        "search_group": search_group,
        "search_project": search_project,
    })
