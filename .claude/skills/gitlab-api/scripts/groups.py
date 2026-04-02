#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Groups API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_groups(client, search=None, order_by=None):
    """List groups accessible by the authenticated user."""
    qs = build_query_string({"search": search, "order_by": order_by})
    return client.api("GET", "/groups" + qs)


def get_group(client, group_id):
    """Get a single group by ID or path."""
    return client.api(
        "GET", "/groups/{}".format(client.encode_path(group_id))
    )


def create_group(
    client, name, path, visibility=None, description=None, parent_id=None
):
    """Create a new group."""
    data = {"name": name, "path": path}
    if visibility:
        data["visibility"] = visibility
    if description:
        data["description"] = description
    if parent_id:
        data["parent_id"] = int(parent_id)
    return client.api("POST", "/groups", data)


def update_group(client, group_id, data=None, **kwargs):
    """Update an existing group."""
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT", "/groups/{}".format(client.encode_path(group_id)), body
    )


def delete_group(client, group_id):
    """Delete a group."""
    return client.api(
        "DELETE", "/groups/{}".format(client.encode_path(group_id))
    )


def list_subgroups(client, group_id):
    """List direct subgroups of a group."""
    return client.api(
        "GET",
        "/groups/{}/subgroups".format(client.encode_path(group_id)),
    )


def list_group_projects(client, group_id):
    """List projects in a group."""
    return client.api(
        "GET",
        "/groups/{}/projects".format(client.encode_path(group_id)),
    )


def share_group_with_group(
    client, group_id, share_with_group_id, group_access
):
    """Share a group with another group."""
    data = {
        "group_id": int(share_with_group_id),
        "group_access": int(group_access),
    }
    return client.api(
        "POST",
        "/groups/{}/share".format(client.encode_path(group_id)),
        data,
    )


if __name__ == "__main__":
    run_cli({
        "list_groups": list_groups,
        "get_group": get_group,
        "create_group": create_group,
        "update_group": update_group,
        "delete_group": delete_group,
        "list_subgroups": list_subgroups,
        "list_group_projects": list_group_projects,
        "share_group_with_group": share_group_with_group,
    })
